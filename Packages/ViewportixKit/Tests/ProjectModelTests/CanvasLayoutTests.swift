import CoreGraphics
import EngineCore
import Foundation
import ProjectModel
import Testing

struct CanvasLayoutTests {
    let phone = ViewportConfig(name: "Telefon", size: ViewportSize(width: 400, height: 800))
    let desktop = ViewportConfig(name: "Masaüstü", size: ViewportSize(width: 1400, height: 900))

    @Test func automaticRowIsTopAlignedWithGaps() {
        let frames = CanvasLayout.frames(for: [phone, desktop])
        #expect(frames[phone.id]?.origin == CGPoint(x: 64, y: 64))
        #expect(frames[desktop.id]?.origin == CGPoint(x: 64 + 400 + 48, y: 64))
    }

    @Test func draggedCardsKeepTheirPlaceAndOthersFollow() {
        var moved = phone
        moved.position = CanvasPoint(x: 1000, y: 300)
        let frames = CanvasLayout.frames(for: [moved, desktop])
        #expect(frames[moved.id]?.origin == CGPoint(x: 1000, y: 300))
        #expect(frames[desktop.id]?.origin.x == 1000 + 400 + 48)
    }

    @Test func snapsToNearbyEdgesWithinThreshold() {
        let other = CGRect(x: 100, y: 100, width: 400, height: 800)
        let dragged = CGRect(x: 553, y: 104, width: 300, height: 600)
        let (origin, guides) = CanvasLayout.snap(dragged, to: [other], threshold: 6)
        #expect(origin.y == 100)  // tops aligned
        #expect(guides.contains { $0.axis == .horizontal && $0.position == 100 })
        // 553 is 53 px from the other's right edge: no vertical snap.
        #expect(origin.x == 553)
    }

    @Test func noSnapBeyondThreshold() {
        let (origin, guides) = CanvasLayout.snap(CGRect(x: 0, y: 20, width: 10, height: 10),
                                                 to: [CGRect(x: 200, y: 200, width: 10, height: 10)], threshold: 6)
        #expect(origin == CGPoint(x: 0, y: 20) && guides.isEmpty)
    }

    @Test func positionRoundTripsAndOldFilesHaveNone() throws {
        var project = Project.new(url: URL(string: "https://marka.com")!)
        project.viewports[0].position = CanvasPoint(x: 10, y: 20)
        let decoded = try Project(data: project.encoded())
        #expect(decoded.viewports[0].position == CanvasPoint(x: 10, y: 20))
        #expect(decoded.viewports[1].position == nil)
    }
}
