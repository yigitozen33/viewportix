import DeviceCatalog
import EngineCore
import Foundation
import Testing

struct DeviceLibraryTests {
    @Test func hidingRemovesFromPickerButKeepsInList() {
        var library = DeviceLibrary()
        library.setInPicker("iphone-se", false)
        #expect(!library.pickerPresets.contains { $0.id == "iphone-se" })
        #expect(library.all.contains { $0.id == "iphone-se" })
        library.setInPicker("iphone-se", true)
        #expect(library.pickerPresets.count == DeviceCatalog.all.count)
    }

    @Test func customDevicesAddEditDuplicateDelete() throws {
        var library = DeviceLibrary()
        let kiosk = library.addCustom(name: "Marka kiosk", size: ViewportSize(width: 1080, height: 1920))
        #expect(kiosk.category == .tablet)
        #expect(library.isCustom(kiosk.id))
        library.updateCustom(kiosk.id, name: "Kiosk", size: ViewportSize(width: 1920, height: 1080))
        #expect(library.preset(id: kiosk.id)?.category == .desktop)
        let duplicated = library.duplicate("iphone-16")
        let copy = try #require(duplicated)
        #expect(copy.name == "iPhone 16 kopya" && library.isCustom(copy.id))
        library.deleteCustom(kiosk.id)
        library.deleteCustom("iphone-16")  // built-ins are not deleted
        #expect(library.preset(id: kiosk.id) == nil)
        #expect(library.preset(id: "iphone-16") != nil)
    }

    @Test func roundTripsThroughJSON() throws {
        var library = DeviceLibrary()
        library.addCustom(name: "Özel", size: ViewportSize(width: 500, height: 700))
        library.setInPicker("desktop", false)
        let decoded = try JSONDecoder().decode(DeviceLibrary.self, from: JSONEncoder().encode(library))
        #expect(decoded == library)
    }
}

struct DeviceImportTests {
    @Test func importsListsAndSkipsWhatIsThere() throws {
        var library = DeviceLibrary()
        let list = Data(#"[{"name":"Kiosk","width":1080,"height":1920},{"title":"Saat","width":100,"height":100},{"name":"iPhone 16","width":393,"height":852}]"#.utf8)
        // "Saat" is under the size limits, iPhone 16 is built in: one new device.
        #expect(try library.importDevices(from: list) == 1)
        #expect(library.custom.map(\.name) == ["Kiosk"] && library.custom[0].category == .tablet)
        #expect(try library.importDevices(from: list) == 0)

        let nested = Data(#"{"customDevices":[{"title":"Katlanır","screen":{"vertical":{"width":344,"height":882}}}]}"#.utf8)
        #expect(try library.importDevices(from: nested) == 1)
        #expect(library.custom.last?.size == ViewportSize(width: 344, height: 882))

        #expect(throws: DeviceLibrary.ImportError.noDevices) { try library.importDevices(from: Data(#"{"a":1}"#.utf8)) }
    }
}
