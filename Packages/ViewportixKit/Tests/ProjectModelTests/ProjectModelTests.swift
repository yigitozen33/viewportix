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

struct ViewportEditingTests {
    @Test func rotatingSwapsTheSizeAndKeepsTheDevice() throws {
        let preset = try #require(DeviceCatalog.preset(id: "iphone-16"))
        var viewport = ViewportConfig(preset: preset)

        viewport.rotate()

        #expect(viewport.size == ViewportSize(width: 852, height: 393))
        #expect(viewport.presetID == "iphone-16")
        #expect(viewport.name == "iPhone 16")
    }

    @Test func syncFlagDefaultsToOnForFilesWrittenBeforeIt() throws {
        let json = #"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"iPhone 16","size":{"width":393,"height":852},"engine":"webKit","presetID":"iphone-16"}"#
        let viewport = try JSONDecoder().decode(ViewportConfig.self, from: Data(json.utf8))
        #expect(viewport.isSyncEnabled)
    }

    @Test func syncFlagRoundTrips() throws {
        var viewport = ViewportConfig(name: "Özel", size: ViewportSize(width: 500, height: 700))
        viewport.isSyncEnabled = false
        let decoded = try JSONDecoder().decode(ViewportConfig.self, from: JSONEncoder().encode(viewport))
        #expect(decoded == viewport)
    }

    @Test func sizeLimits() {
        #expect(ViewportSize(width: 393, height: 852).isWithinLimits)
        #expect(ViewportSize(width: 3840, height: 2160).isWithinLimits)
        #expect(!ViewportSize(width: 199, height: 800).isWithinLimits)
        #expect(!ViewportSize(width: 1024, height: 5000).isWithinLimits)
        // Every built-in preset fits, in both orientations.
        for preset in DeviceCatalog.all {
            #expect(preset.size.isWithinLimits && preset.size.rotated.isWithinLimits, "\(preset.id)")
        }
    }
}
