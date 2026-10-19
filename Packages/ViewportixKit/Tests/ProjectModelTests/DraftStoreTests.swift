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
        #expect(first.lastPathComponent == "Adsız.viewportix")
        #expect(second.lastPathComponent == "Adsız 2.viewportix")
        #expect(try store.create(.new(), name: "Marka (senin sürümün)").lastPathComponent == "Marka (senin sürümün).viewportix")
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -60)], ofItemAtPath: first.path(percentEncoded: false))
        #expect(store.list().map(\.lastPathComponent).suffix(2) == ["Adsız 2.viewportix", "Adsız.viewportix"])
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

    @Test func suggestedNamesDropTheSiteSuffix() {
        #expect(SuggestedName.fromTitle("Keten Gömlek · Marka") == "Keten Gömlek")
        #expect(SuggestedName.fromTitle("Sepet | Marka - Online") == "Sepet | Marka")
        #expect(SuggestedName.fromTitle("Ürün – A – B") == "Ürün – A")
        #expect(SuggestedName.fromTitle("Kampanya") == "Kampanya")
        #expect(SuggestedName.fromTitle(" · Marka") == "· Marka")
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
        #expect(old.diffReview == DiffReview())

        var reviewed = Project.new()
        reviewed.diffReview.ignoredSelectors = [".promo"]
        reviewed.diffReview.accepted["v|.price|font-weight"] = "500 → 600"
        #expect(try Project(data: reviewed.encoded()).diffReview == reviewed.diffReview)
    }
}
