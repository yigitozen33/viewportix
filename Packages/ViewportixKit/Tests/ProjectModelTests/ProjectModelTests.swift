import DeviceCatalog
import EngineCore
import Foundation
import ProjectModel
import Testing

struct ProjectModelTests {
    let url = URL(string: "https://example.com")!

    @Test func newProjectUsesDefaultDevicesAndSelectsFirstPage() throws {
        let project = Project.new(url: url)

        #expect(project.pages.count == 1)
        #expect(project.selectedPage?.url == url)
        #expect(project.viewports.map(\.presetID) == DeviceCatalog.defaultPresetIDs)
        #expect(project.viewports.allSatisfy { $0.engine == .webKit })
    }

    @Test func roundTripsThroughJSON() throws {
        var project = Project.new(url: url)
        project.pages.append(Page(name: "Sepet", url: URL(string: "https://example.com/cart")!))
        project.viewports.append(ViewportConfig(name: "Özel", size: ViewportSize(width: 500, height: 700)))
        project.canvas = CanvasState(zoom: 0.5, offsetX: 120, offsetY: -40)

        let decoded = try Project(data: project.encoded())

        #expect(decoded == project)
    }

    @Test func encodingIsStable() throws {
        let project = Project.new(url: url)
        #expect(try project.encoded() == project.encoded())
    }

    @Test func rejectsNewerSchemaVersion() throws {
        let data = Data(#"{"schemaVersion": 99}"#.utf8)

        #expect(throws: ProjectCodingError.unsupportedSchemaVersion(99)) {
            try Project(data: data)
        }
    }
}
