import DeviceCatalog
import Testing

struct DeviceCatalogTests {
    @Test func presetIDsAreUnique() {
        let ids = DeviceCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func defaultPresetsExist() {
        for id in DeviceCatalog.defaultPresetIDs {
            #expect(DeviceCatalog.preset(id: id) != nil, "missing default preset \(id)")
        }
    }

    @Test func presetsArePortraitExceptDesktops() {
        for preset in DeviceCatalog.all where preset.category != .desktop {
            #expect(preset.size.height > preset.size.width, "\(preset.id) should be portrait")
        }
    }
}
