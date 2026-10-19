import Foundation
import ProjectModel
import Testing

struct DraftStoreTests {
    let root = FileManager.default.temporaryDirectory.appending(path: "DraftStoreTests-\(UUID().uuidString)")
    var store: DraftStore { DraftStore(root: root) }

    @Test func draftsAreNumberedAndListedNewestFirst() throws {
        defer { try? FileManager.default.removeItem(at: root) }
        let first = try store.create(.new())
        let second = try store.create(.new(), thumbnail: Data([1, 2, 3]))
        #expect(first.lastPathComponent == "Untitled.viewportix")
        #expect(second.lastPathComponent == "Untitled 2.viewportix")
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -60)], ofItemAtPath: first.path(percentEncoded: false))
        #expect(store.list().map(\.lastPathComponent) == ["Untitled 2.viewportix", "Untitled.viewportix"])
        #expect(store.isDraft(first) && !store.isDraft(root.appending(path: "Marka.viewportix")))
        #expect(ProjectSummary.read(second).thumbnail != nil && ProjectSummary.read(first).thumbnail == nil)
    }

    @Test func trashRestoresAndPurgesAfterThirtyDays() throws {
        defer { try? FileManager.default.removeItem(at: root) }
        let draft = try store.create(.new())
        let trashed = try store.moveToTrash(draft)
        #expect(store.list().isEmpty)
        #expect(store.isTrashed(trashed) && !store.isTrashed(draft))
        try store.restore(trashed, to: draft)
        #expect(store.list().count == 1)

        _ = try store.moveToTrash(draft, now: Date(timeIntervalSinceNow: -31 * 24 * 3600))
        let recent = try store.moveToTrash(try store.create(.new()))
        store.purgeTrash()
        let left = try FileManager.default.contentsOfDirectory(at: store.trash, includingPropertiesForKeys: nil)
        #expect(left.map(\.lastPathComponent) == [recent.deletingLastPathComponent().lastPathComponent])
    }

    @Test func thumbnailIsLeftOutWhenTurnedOff() throws {
        defer { try? FileManager.default.removeItem(at: root) }
        var project = Project.new()
        project.includesThumbnail = false
        let wrapper = try ProjectPackage.fileWrapper(project: project, thumbnail: Data([1]))
        #expect(wrapper.fileWrappers?.keys.sorted() == ["project.json"])
        let decoded = try ProjectPackage.read(wrapper)
        #expect(decoded.project.includesThumbnail == false && decoded.thumbnail == nil)
        // Files from before the field open with thumbnails on.
        let old = try Project(data: Data(#"{"schemaVersion":1,"pages":[],"viewports":[],"canvas":{"zoom":1,"offsetX":0,"offsetY":0}}"#.utf8))
        #expect(old.includesThumbnail)
    }
}
