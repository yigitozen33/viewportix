import Foundation

/// Unsaved projects ("taslaklar") are real packages in the app's folder, so the system autosaves
/// them in place and the home screen can list them (PLAN.md §3.5, DESIGN.md §2 Taslaklar).
/// Deleted drafts wait 30 days in a folder of their own (HOME-08).
public struct DraftStore: Sendable {
    public let folder: URL
    public let trash: URL
    public static let baseName = "Untitled"
    public static let trashDays = 30

    public init(root: URL) {
        folder = root.appending(path: "Drafts", directoryHint: .isDirectory)
        trash = root.appending(path: "Deleted Drafts", directoryHint: .isDirectory)
    }

    /// `~/Library/Application Support/Viewportix`.
    public static let standard = DraftStore(
        root: URL.applicationSupportDirectory.appending(path: "Viewportix", directoryHint: .isDirectory)
    )

    public func isDraft(_ url: URL) -> Bool {
        url.deletingLastPathComponent().standardizedFileURL.path(percentEncoded: false)
            == folder.standardizedFileURL.path(percentEncoded: false)
    }

    /// In the app's trash. The system's recent list keeps bookmarks, which follow a deleted draft there.
    public func isTrashed(_ url: URL) -> Bool {
        url.standardizedFileURL.path(percentEncoded: false).hasPrefix(trash.standardizedFileURL.path(percentEncoded: false))
    }

    /// Writes `project` as a new draft: "Untitled", "Untitled 2"…
    public func create(_ project: Project, thumbnail: Data? = nil, fileManager: FileManager = .default) throws -> URL {
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = nextURL(fileManager: fileManager)
        try ProjectPackage.write(project: project, thumbnail: thumbnail, to: url)
        return url
    }

    func nextURL(fileManager: FileManager) -> URL {
        var number = 1
        while true {
            let name = number == 1 ? Self.baseName : "\(Self.baseName) \(number)"
            let url = folder.appending(path: "\(name).\(ProjectPackage.pathExtension)", directoryHint: .notDirectory)
            if !fileManager.fileExists(atPath: url.path(percentEncoded: false)) { return url }
            number += 1
        }
    }

    /// Drafts, most recently changed first.
    public func list(fileManager: FileManager = .default) -> [URL] {
        let keys: [URLResourceKey] = [.contentModificationDateKey]
        let urls = (try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys, options: .skipsHiddenFiles)) ?? []
        func modified(_ url: URL) -> Date {
            (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
        }
        return urls.filter { $0.pathExtension == ProjectPackage.pathExtension }.sorted { modified($0) > modified($1) }
    }

    /// Moves a draft to the app's trash; returns where it went, for undo. The date of deletion is
    /// in the folder name so purging doesn't depend on file dates.
    public func moveToTrash(_ url: URL, now: Date = .now, fileManager: FileManager = .default) throws -> URL {
        let stamp = Int(now.timeIntervalSince1970)
        let holder = trash.appending(path: "\(stamp)-\(UUID().uuidString)", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: holder, withIntermediateDirectories: true)
        let target = holder.appending(path: url.lastPathComponent, directoryHint: .notDirectory)
        try fileManager.moveItem(at: url, to: target)
        return target
    }

    /// Puts a trashed draft back where it was (Geri al).
    public func restore(_ trashed: URL, to original: URL, fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(at: original.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.moveItem(at: trashed, to: original)
        try? fileManager.removeItem(at: trashed.deletingLastPathComponent())
    }

    /// Deletes drafts that have been in the trash longer than 30 days.
    public func purgeTrash(now: Date = .now, fileManager: FileManager = .default) {
        let holders = (try? fileManager.contentsOfDirectory(at: trash, includingPropertiesForKeys: nil)) ?? []
        let limit = now.addingTimeInterval(-Double(Self.trashDays) * 24 * 3600).timeIntervalSince1970
        for holder in holders {
            guard let stamp = holder.lastPathComponent.split(separator: "-").first.flatMap({ Double($0) }), stamp < limit else { continue }
            try? fileManager.removeItem(at: holder)
        }
    }
}
