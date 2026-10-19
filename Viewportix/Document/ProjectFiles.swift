import AppKit
import UniformTypeIdentifiers
import ProjectModel

/// File work around projects that SwiftUI's `DocumentGroup` doesn't do our way (PLAN.md §3.5):
/// new projects open as drafts on disk, ⌘S on a draft goes through our save sheet, drafts are
/// deleted without asking (with undo), save errors get our texts and an error code.
@MainActor
enum ProjectFiles {
    static let drafts = DraftStore.standard

    // MARK: New and open

    /// Yeni (⌘N), the home screen's URL box and templates: a draft file, opened as a document.
    static func newDraft(_ project: Project) {
        do {
            open(try drafts.create(project))
        } catch {
            ErrorAlert.show(.draftCreateFailed, title: "Yeni proje açılamadı", error: error)
        }
    }

    static func open(_ url: URL, completion: ((Bool) -> Void)? = nil) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
            completion?(error == nil)
        }
    }

    /// The system document behind a project window.
    static func document(for window: NSWindow?) -> NSDocument? {
        window.flatMap { NSDocumentController.shared.document(for: $0) }
    }

    // MARK: Save (PW-06)

    struct SaveOptions {
        var name: String
        var folder: URL
        var includesThumbnail: Bool
        var removesDraft: Bool
    }

    static func target(name: String, in folder: URL) -> URL {
        folder.appending(path: "\(name).\(ProjectPackage.pathExtension)", directoryHint: .notDirectory)
    }

    /// Saves a draft under a name and folder: the window moves to the new file (Save As); the draft
    /// is deleted unless "Kaydedince taslağı listeden kaldır" was turned off.
    static func save(_ document: NSDocument, options: SaveOptions) async throws {
        let draft = document.fileURL
        try FileManager.default.createDirectory(at: options.folder, withIntermediateDirectories: true)
        let url = target(name: options.name, in: options.folder)
        try await document.save(to: url, ofType: document.fileType ?? UTType.viewportixProject.identifier, for: .saveAsOperation)
        SaveLocations.use(options.folder)
        if let draft, drafts.isDraft(draft), url != draft {
            if options.removesDraft {
                try? FileManager.default.removeItem(at: draft)
            } else {
                DraftOrigins.note(draft: draft, savedAs: url)
            }
        }
    }

    /// Çoğalt (⇧⌘S): a copy in the chosen folder, opened in its own window.
    static func duplicate(_ project: Project, thumbnail: Data?, options: SaveOptions) throws {
        var project = project
        project.includesThumbnail = options.includesThumbnail
        try FileManager.default.createDirectory(at: options.folder, withIntermediateDirectories: true)
        let url = target(name: options.name, in: options.folder)
        try ProjectPackage.write(project: project, thumbnail: thumbnail, to: url)
        SaveLocations.use(options.folder)
        open(url)
    }

    /// The newest date in a package: editing `project.json` in place leaves the folder's own date
    /// (the one the system document tracks) unchanged.
    static func lastModified(_ package: URL) -> Date? {
        let key = URLResourceKey.contentModificationDateKey
        let dates = ([package] + ((try? FileManager.default.contentsOfDirectory(at: package, includingPropertiesForKeys: [key])) ?? []))
            .compactMap { try? $0.resourceValues(forKeys: [key]).contentModificationDate }
        return dates.max()
    }

    // MARK: Drafts

    /// HOME-08 "Taslağı sil": its window closes, the draft goes to the app's trash. Returns the undo.
    static func trashDraft(_ url: URL) throws -> () -> Void {
        NSDocumentController.shared.document(for: url)?.close()
        let trashed = try drafts.moveToTrash(url)
        return { try? drafts.restore(trashed, to: url) }
    }

    /// "Taslakları sakla" off: a draft whose window closed goes to the app's trash.
    static func discardIfDraftsAreNotKept(_ url: URL?) {
        guard let url, drafts.isDraft(url), !UserDefaults.standard.bool(forKey: AppSettings.keepDrafts) else { return }
        // After the document has finished closing (and autosaving).
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard NSDocumentController.shared.document(for: url) == nil else { return }
            _ = try? drafts.moveToTrash(url)
        }
    }
}

/// Konum menüsü's SON KONUMLAR: the last five folders saved into, newest first; the first time
/// Belgeler › Viewportix.
@MainActor
enum SaveLocations {
    private static let key = "saveLocations"
    static let limit = 5

    static var defaultFolder: URL { URL.documentsDirectory.appending(path: "Viewportix", directoryHint: .isDirectory) }

    static var iCloudFolder: URL? {
        let drive = URL.homeDirectory.appending(path: "Library/Mobile Documents/com~apple~CloudDocs", directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: drive.path(percentEncoded: false)) else { return nil }
        return drive.appending(path: "Viewportix", directoryHint: .isDirectory)
    }

    static var recent: [URL] {
        let saved = (UserDefaults.standard.stringArray(forKey: key) ?? []).map { URL(filePath: $0, directoryHint: .isDirectory) }
        return saved.isEmpty ? [defaultFolder] : saved
    }

    static func use(_ folder: URL) {
        var paths = UserDefaults.standard.stringArray(forKey: key) ?? []
        let path = folder.path(percentEncoded: false)
        paths.removeAll { $0 == path }
        paths.insert(path, at: 0)
        UserDefaults.standard.set(Array(paths.prefix(limit)), forKey: key)
    }

    /// "Belgeler › Viewportix": the folder and its parent as Finder names them.
    static func display(_ folder: URL) -> String {
        let manager = FileManager.default
        let parent = folder.deletingLastPathComponent()
        let names = [parent, folder].map { url in
            url.path(percentEncoded: false) == URL.homeDirectory.path(percentEncoded: false)
                ? url.lastPathComponent : manager.displayName(atPath: url.path(percentEncoded: false))
        }
        return names.joined(separator: " › ")
    }
}

/// Saved projects whose draft was kept ("Kaydedince taslağı listeden kaldır" off): HOME-13 offers
/// "Son taslağı aç" when the saved file can't be read.
@MainActor
enum DraftOrigins {
    private static let key = "draftOrigins"

    static func note(draft: URL, savedAs url: URL) {
        var origins = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        origins[url.path(percentEncoded: false)] = draft.path(percentEncoded: false)
        UserDefaults.standard.set(origins, forKey: key)
    }

    static func draft(for url: URL) -> URL? {
        let origins = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        guard let path = origins[url.path(percentEncoded: false)], FileManager.default.fileExists(atPath: path) else { return nil }
        return URL(filePath: path)
    }
}
