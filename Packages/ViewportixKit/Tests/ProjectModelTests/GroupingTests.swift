import CoreGraphics
import EngineCore
import Foundation
import ProjectModel
import Testing

struct GroupingTests {
    let project = Project.new(url: URL(string: "https://marka.com")!, template: .fullMatrix)

    @Test func groupsByDeviceTypeInOrder() {
        let groups = Grouping.deviceType.groups(of: project.viewports)
        #expect(groups.map(\.title) == ["Telefon", "Tablet", "Masaüstü"])
        #expect(groups.map(\.members.count) == [3, 2, 3])
        #expect(Grouping.none.groups(of: project.viewports).isEmpty)
        #expect(Grouping.engine.groups(of: project.viewports).map(\.title) == ["WebKit"])
    }

    @Test func groupedLayoutLeavesWiderGapsAndFoldsGroups() throws {
        let groups = Grouping.deviceType.groups(of: project.viewports)
        let open = CanvasLayout.grouped(project.viewports, groups: groups, collapsed: [])
        let phones = try #require(open.groups["phone"])
        let tablets = try #require(open.groups["tablet"])
        #expect(tablets.minX - phones.maxX == CanvasLayout.groupGap)

        let folded = CanvasLayout.grouped(project.viewports, groups: groups, collapsed: ["phone"])
        #expect(folded.frames.count == 5)
        #expect(folded.groups["phone"]?.size == .zero)
        #expect(folded.groups["tablet"]?.minX == CanvasLayout.margin + CanvasLayout.collapsedWidth)
    }

    @Test func groupingIsSavedAndOldFilesHaveNone() throws {
        var saved = project
        saved.canvas.grouping = .deviceType
        saved.canvas.collapsedGroups = ["phone"]
        let decoded = try Project(data: saved.encoded())
        #expect(decoded.canvas.grouping == .deviceType && decoded.canvas.collapsedGroups == ["phone"])
        let old = try Project(data: Data(#"{"schemaVersion":1,"pages":[],"viewports":[],"canvas":{"zoom":1,"offsetX":0,"offsetY":0}}"#.utf8))
        #expect(old.canvas.grouping == .none)
    }
}
