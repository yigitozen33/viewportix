import DeviceCatalog
import EngineCore
import Foundation

/// The contents of a `.viewportix` document: one brand's pages, viewports and canvas layout.
public struct Project: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var pages: [Page]
    public var selectedPageID: Page.ID?
    public var viewports: [ViewportConfig]
    public var canvas: CanvasState

    public init(
        pages: [Page] = [],
        selectedPageID: Page.ID? = nil,
        viewports: [ViewportConfig] = [],
        canvas: CanvasState = CanvasState()
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.pages = pages
        self.selectedPageID = selectedPageID ?? pages.first?.id
        self.viewports = viewports
        self.canvas = canvas
    }

    /// A new project opened from the home screen URL box, using the default device set.
    public static func new(url: URL) -> Project {
        let page = Page(name: "Ana sayfa", url: url)
        let viewports = DeviceCatalog.defaultPresetIDs
            .compactMap(DeviceCatalog.preset(id:))
            .map { ViewportConfig(preset: $0) }
        return Project(pages: [page], viewports: viewports)
    }

    public var selectedPage: Page? {
        pages.first { $0.id == selectedPageID }
    }
}

public struct Page: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var url: URL

    public init(id: UUID = UUID(), name: String, url: URL) {
        self.id = id
        self.name = name
        self.url = url
    }
}

public struct ViewportConfig: Identifiable, Codable, Hashable, Sendable {
    public var id: ViewportID
    public var name: String
    public var size: ViewportSize
    public var engine: EngineKind
    /// The preset this viewport was created from; nil for custom sizes.
    public var presetID: String?

    public init(
        id: ViewportID = ViewportID(),
        name: String,
        size: ViewportSize,
        engine: EngineKind = .webKit,
        presetID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.engine = engine
        self.presetID = presetID
    }

    public init(preset: DevicePreset, engine: EngineKind = .webKit) {
        self.init(name: preset.name, size: preset.size, engine: engine, presetID: preset.id)
    }
}

public struct CanvasState: Codable, Hashable, Sendable {
    public var zoom: Double
    public var offsetX: Double
    public var offsetY: Double

    public init(zoom: Double = 1, offsetX: Double = 0, offsetY: Double = 0) {
        self.zoom = zoom
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
}
