import EngineCore
import Foundation

/// The user's device list (Ayarlar › Cihazlar): built-in presets that can be hidden from the
/// picker, plus custom devices kept with the app. Built-ins are never deleted, only hidden.
public struct DeviceLibrary: Codable, Hashable, Sendable {
    public private(set) var hiddenIDs: Set<String>
    public private(set) var custom: [DevicePreset]

    public init(hiddenIDs: Set<String> = [], custom: [DevicePreset] = []) {
        self.hiddenIDs = hiddenIDs
        self.custom = custom
    }

    /// Built-ins first, then custom devices in the order they were made.
    public var all: [DevicePreset] { DeviceCatalog.all + custom }

    /// What the device picker offers (SETTINGS-03).
    public var pickerPresets: [DevicePreset] { all.filter { !hiddenIDs.contains($0.id) } }

    public func preset(id: String) -> DevicePreset? {
        all.first { $0.id == id }
    }

    public func isCustom(_ id: String) -> Bool {
        custom.contains { $0.id == id }
    }

    public func isInPicker(_ id: String) -> Bool {
        !hiddenIDs.contains(id)
    }

    public mutating func setInPicker(_ id: String, _ visible: Bool) {
        if visible { hiddenIDs.remove(id) } else { hiddenIDs.insert(id) }
    }

    /// Custom devices take their type from their width (phone < 600 ≤ tablet < 1100 ≤ desktop).
    public static func category(for size: ViewportSize) -> DevicePreset.Category {
        size.width < 600 ? .phone : size.width < 1100 ? .tablet : .desktop
    }

    @discardableResult
    public mutating func addCustom(name: String, size: ViewportSize) -> DevicePreset {
        let preset = DevicePreset(id: "custom-\(UUID().uuidString.lowercased())", name: name, category: Self.category(for: size), size: size)
        custom.append(preset)
        return preset
    }

    public mutating func updateCustom(_ id: String, name: String, size: ViewportSize) {
        guard let index = custom.firstIndex(where: { $0.id == id }) else { return }
        custom[index] = DevicePreset(id: id, name: name, category: Self.category(for: size), size: size)
    }

    /// Çoğalt: a custom copy of any device, "<ad> kopya".
    @discardableResult
    public mutating func duplicate(_ id: String) -> DevicePreset? {
        guard let source = preset(id: id) else { return nil }
        return addCustom(name: "\(source.name) kopya", size: source.size)
    }

    /// Only custom devices can be deleted; open cards made from it stay (SETTINGS-04).
    public mutating func deleteCustom(_ id: String) {
        custom.removeAll { $0.id == id }
        hiddenIDs.remove(id)
    }
}
