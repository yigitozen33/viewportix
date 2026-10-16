import DeviceCatalog
import EngineCore
import ProjectModel
import Testing

struct DeviceSearchTests {
    @Test func parsesSizes() {
        #expect(ViewportSize(parsing: "1024×768") == ViewportSize(width: 1024, height: 768))
        #expect(ViewportSize(parsing: "1024 x 768") == ViewportSize(width: 1024, height: 768))
        #expect(ViewportSize(parsing: "390X844") == ViewportSize(width: 390, height: 844))
        #expect(ViewportSize(parsing: "iPhone") == nil)
        #expect(ViewportSize(parsing: "1024×") == nil)
    }

    @Test func filtersByNameOrSize() {
        #expect(DeviceSearch.presets(matching: "ipad").allSatisfy { $0.category == .tablet })
        #expect(DeviceSearch.presets(matching: "393").map(\.id) == ["iphone-16"])
        #expect(DeviceSearch.presets(matching: "").count == DeviceCatalog.all.count)
        #expect(DeviceSearch.presets(matching: "800×600").count == DeviceCatalog.all.count)
    }

    @Test func recentKeepsThreeNewestUnique() {
        var recent: [String] = []
        for id in ["a", "b", "c", "a", "d"] { recent = DeviceSearch.recordRecent(id, in: recent) }
        #expect(recent == ["d", "a", "c"])
    }
}
