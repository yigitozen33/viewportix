import AppKit
import Observation
import ProjectModel

/// The home screen's project list: the system's recent documents, minus the ones removed from the
/// list (HOME-08), plus relocated files (HOME-12); drafts from the app's drafts folder (PLAN.md §3.5).
@MainActor
@Observable
final class RecentProjects {
    private(set) var projects: [ProjectSummary] = []
    private(set) var drafts: [ProjectSummary] = []

    private static let hiddenKey = "hiddenRecentProjects"
    /// Fixed contents for previews and snapshots; `reload` leaves them alone.
    private let fixed: [ProjectSummary]?

    init(fixed: [ProjectSummary]? = nil) {
        self.fixed = fixed
    }

    func reload() {
        if let fixed {
            projects = fixed
            drafts = fixed.filter { isDraft($0.url) }
            return
        }
        let hidden = Set(UserDefaults.standard.stringArray(forKey: Self.hiddenKey) ?? [])
        let drafts = ProjectFiles.drafts
        projects = NSDocumentController.shared.recentDocumentURLs
            .filter { !hidden.contains($0.path(percentEncoded: false)) }
            // A saved or deleted draft leaves its old path in the recent list (or, through the
            // list's bookmarks, its place in the app's trash): neither is a project to show.
            .filter { !drafts.isTrashed($0) }
            .filter { !drafts.isDraft($0) || FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
            .map { ProjectSummary.read($0) }
        self.drafts = drafts.list().map { ProjectSummary.read($0) }
    }

    func isDraft(_ url: URL) -> Bool {
        ProjectFiles.drafts.isDraft(url)
    }

    /// HOME-08 "Taslağı sil": no question; the draft waits 30 days in the app's trash. Returns the undo.
    func deleteDraft(_ url: URL) throws -> () -> Void {
        let restore = try ProjectFiles.trashDraft(url)
        reload()
        return { [weak self] in
            restore()
            self?.reload()
        }
    }

    /// Listeden kaldır: the file stays on disk.
    func removeFromList(_ url: URL) {
        var hidden = UserDefaults.standard.stringArray(forKey: Self.hiddenKey) ?? []
        hidden.append(url.path(percentEncoded: false))
        UserDefaults.standard.set(hidden, forKey: Self.hiddenKey)
        reload()
    }

    /// Çöp Sepeti'ne taşı: recoverable from Finder, so no confirmation (DESIGN.md §3.1).
    func moveToTrash(_ url: URL) throws {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        removeFromList(url)
    }

    /// Çoğalt: "<ad> kopya.viewportix" next to the original, listed first.
    func duplicate(_ url: URL) throws {
        let folder = url.deletingLastPathComponent()
        let name = url.deletingPathExtension().lastPathComponent
        var copy = folder.appending(path: "\(name) kopya.viewportix")
        var counter = 2
        while FileManager.default.fileExists(atPath: copy.path(percentEncoded: false)) {
            copy = folder.appending(path: "\(name) kopya \(counter).viewportix")
            counter += 1
        }
        try FileManager.default.copyItem(at: url, to: copy)
        list(copy)
    }

    /// Bul…: the chosen file replaces the missing one in the list.
    func relocate(_ missing: URL, to found: URL) {
        removeFromList(missing)
        list(found)
    }

    /// Adds to the recent list, undoing an earlier "Listeden kaldır" of the same file.
    private func list(_ url: URL) {
        let path = url.path(percentEncoded: false)
        let hidden = (UserDefaults.standard.stringArray(forKey: Self.hiddenKey) ?? []).filter { $0 != path }
        UserDefaults.standard.set(hidden, forKey: Self.hiddenKey)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        reload()
    }
}
