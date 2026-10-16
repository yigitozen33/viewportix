import EngineCore

public struct DevicePreset: Identifiable, Codable, Hashable, Sendable {
    public enum Category: String, Codable, Hashable, Sendable, CaseIterable {
        case phone
        case tablet
        case desktop
    }

    public let id: String
    public let name: String
    public let category: Category
    public let size: ViewportSize

    public init(id: String, name: String, category: Category, size: ViewportSize) {
        self.id = id
        self.name = name
        self.category = category
        self.size = size
    }
}

/// Built-in device presets. Sizes are CSS viewport sizes in portrait orientation.
public enum DeviceCatalog {
    public static let all: [DevicePreset] = [
        DevicePreset(id: "iphone-se", name: "iPhone SE", category: .phone, size: ViewportSize(width: 375, height: 667)),
        DevicePreset(id: "iphone-16", name: "iPhone 16", category: .phone, size: ViewportSize(width: 393, height: 852)),
        DevicePreset(id: "iphone-17-pro", name: "iPhone 17 Pro", category: .phone, size: ViewportSize(width: 402, height: 874)),
        DevicePreset(id: "iphone-17-pro-max", name: "iPhone 17 Pro Max", category: .phone, size: ViewportSize(width: 440, height: 956)),
        DevicePreset(id: "ipad-mini", name: "iPad mini", category: .tablet, size: ViewportSize(width: 744, height: 1133)),
        DevicePreset(id: "ipad-air-11", name: "iPad Air 11\"", category: .tablet, size: ViewportSize(width: 820, height: 1180)),
        DevicePreset(id: "ipad-pro-13", name: "iPad Pro 13\"", category: .tablet, size: ViewportSize(width: 1032, height: 1376)),
        DevicePreset(id: "laptop", name: "Dizüstü", category: .desktop, size: ViewportSize(width: 1280, height: 800)),
        DevicePreset(id: "desktop", name: "Masaüstü", category: .desktop, size: ViewportSize(width: 1440, height: 900)),
        DevicePreset(id: "desktop-full-hd", name: "Full HD", category: .desktop, size: ViewportSize(width: 1920, height: 1080)),
    ]

    /// Presets used for a new project when no template is chosen.
    public static let defaultPresetIDs = ["iphone-16", "ipad-air-11", "desktop"]

    public static func preset(id: String) -> DevicePreset? {
        all.first { $0.id == id }
    }
}
