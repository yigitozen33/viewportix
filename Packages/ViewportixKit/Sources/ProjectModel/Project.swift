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
    /// "Küçük resmi dosyaya ekle" (PW-06): when false the package has no `thumbnail.png`.
    public var includesThumbnail: Bool

    public init(
        pages: [Page] = [],
        selectedPageID: Page.ID? = nil,
        viewports: [ViewportConfig] = [],
        canvas: CanvasState = CanvasState(),
        includesThumbnail: Bool = true
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.pages = pages
        self.selectedPageID = selectedPageID ?? pages.first?.id
        self.viewports = viewports
        self.canvas = canvas
        self.includesThumbnail = includesThumbnail
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, pages, selectedPageID, viewports, canvas, includesThumbnail
    }

    /// Fields added after schema version 1 decode with defaults, so older files still open.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        pages = try container.decode([Page].self, forKey: .pages)
        selectedPageID = try container.decodeIfPresent(Page.ID.self, forKey: .selectedPageID)
        viewports = try container.decode([ViewportConfig].self, forKey: .viewports)
        canvas = try container.decode(CanvasState.self, forKey: .canvas)
        includesThumbnail = try container.decodeIfPresent(Bool.self, forKey: .includesThumbnail) ?? true
    }

    /// A new project with the default device set, starting at `url` when given (home screen URL box)
    /// or empty (File > New).
    public static func new(url: URL? = nil) -> Project {
        let pages = url.map { [Page(name: "Ana sayfa", url: $0)] } ?? []
        let viewports = DeviceCatalog.defaultPresetIDs
            .compactMap(DeviceCatalog.preset(id:))
            .map { ViewportConfig(preset: $0) }
        return Project(pages: pages, viewports: viewports)
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
    /// When false the viewport neither leads nor follows sync (explicit page loads still reach it).
    public var isSyncEnabled: Bool
    /// Top-left of the page area on the canvas, in CSS px, once the user dragged cards (CARD-08);
    /// nil means automatic placement (Kartları Diz clears it).
    public var position: CanvasPoint?

    public init(
        id: ViewportID = ViewportID(),
        name: String,
        size: ViewportSize,
        engine: EngineKind = .webKit,
        presetID: String? = nil,
        isSyncEnabled: Bool = true,
        position: CanvasPoint? = nil
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.engine = engine
        self.presetID = presetID
        self.isSyncEnabled = isSyncEnabled
        self.position = position
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, size, engine, presetID, isSyncEnabled, position
    }

    /// Fields added after schema version 1 decode with defaults, so older files still open.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ViewportID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        size = try container.decode(ViewportSize.self, forKey: .size)
        engine = try container.decode(EngineKind.self, forKey: .engine)
        presetID = try container.decodeIfPresent(String.self, forKey: .presetID)
        isSyncEnabled = try container.decodeIfPresent(Bool.self, forKey: .isSyncEnabled) ?? true
        position = try container.decodeIfPresent(CanvasPoint.self, forKey: .position)
    }

    public init(preset: DevicePreset, engine: EngineKind = .webKit) {
        self.init(name: preset.name, size: preset.size, engine: engine, presetID: preset.id)
    }
}

public struct CanvasState: Codable, Hashable, Sendable {
    public var zoom: Double
    public var offsetX: Double
    public var offsetY: Double
    /// Görünüm › Grupla (PW-02) and the groups folded to a chip (PW-03).
    public var grouping: Grouping
    public var collapsedGroups: Set<String>

    public init(zoom: Double = 1, offsetX: Double = 0, offsetY: Double = 0, grouping: Grouping = .none, collapsedGroups: Set<String> = []) {
        self.zoom = zoom
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.grouping = grouping
        self.collapsedGroups = collapsedGroups
    }

    private enum CodingKeys: String, CodingKey {
        case zoom, offsetX, offsetY, grouping, collapsedGroups
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        zoom = try container.decode(Double.self, forKey: .zoom)
        offsetX = try container.decode(Double.self, forKey: .offsetX)
        offsetY = try container.decode(Double.self, forKey: .offsetY)
        grouping = try container.decodeIfPresent(Grouping.self, forKey: .grouping) ?? .none
        collapsedGroups = try container.decodeIfPresent(Set<String>.self, forKey: .collapsedGroups) ?? []
    }
}

extension ViewportSize {
    /// CSS pixel limits for a viewport: narrower than any phone or larger than 4K is not useful,
    /// and very large web views cost a lot of memory.
    public static let widthRange = 200...3840
    public static let heightRange = 200...4320

    public var isWithinLimits: Bool {
        Self.widthRange.contains(width) && Self.heightRange.contains(height)
    }
}

extension ViewportConfig {
    /// Portrait ↔ landscape. The device (preset) stays the same.
    public mutating func rotate() {
        size = size.rotated
    }
}
