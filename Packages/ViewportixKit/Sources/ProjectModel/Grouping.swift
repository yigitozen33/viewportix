import CoreGraphics
import DeviceCatalog
import EngineCore
import Foundation

/// Görünüm › Grupla: Yok / Cihaz türü / Motor (DESIGN.md §4, PW-02).
public enum Grouping: String, Codable, Hashable, Sendable, CaseIterable {
    case none, deviceType, engine
}

/// One group of cards on the canvas and in the strip.
public struct ViewportGroup: Hashable, Sendable {
    /// Stable key saved in `CanvasState.collapsedGroups`: "phone", "tablet", "desktop", "webKit"…
    public let key: String
    /// "Telefon", "Tablet", "Masaüstü", "WebKit"…
    public let title: String
    public let members: [ViewportID]
}

extension ViewportConfig {
    /// Device type from the preset, or from the width for custom sizes.
    public var category: DevicePreset.Category {
        presetID.flatMap(DeviceCatalog.preset(id:))?.category ?? DeviceLibrary.category(for: size)
    }
}

extension Grouping {
    /// Groups in a fixed order (phone, tablet, desktop / WebKit, Chromium, Firefox); empty ones left out.
    public func groups(of viewports: [ViewportConfig]) -> [ViewportGroup] {
        switch self {
        case .none:
            return []
        case .deviceType:
            let titles: [DevicePreset.Category: String] = [.phone: "Telefon", .tablet: "Tablet", .desktop: "Masaüstü"]
            return DevicePreset.Category.allCases.compactMap { category in
                let members = viewports.filter { $0.category == category }.map(\.id)
                return members.isEmpty ? nil : ViewportGroup(key: category.rawValue, title: titles[category]!, members: members)
            }
        case .engine:
            let titles: [EngineKind: String] = [.webKit: "WebKit", .chromium: "Chromium", .firefox: "Firefox"]
            return EngineKind.allCases.compactMap { engine in
                let members = viewports.filter { $0.engine == engine }.map(\.id)
                return members.isEmpty ? nil : ViewportGroup(key: engine.rawValue, title: titles[engine]!, members: members)
            }
        }
    }
}

extension CanvasLayout {
    /// Gap between groups, wide enough for the group areas' on-screen padding at usual zooms.
    public static let groupGap: Double = 168
    /// Width kept for a folded group's chip, in document units.
    public static let collapsedWidth: Double = 360

    public struct GroupedLayout: Sendable {
        /// Page-area frames of visible cards.
        public var frames: [ViewportID: CGRect]
        /// Union of each open group's page areas; folded groups: the chip's top-left (zero size).
        public var groups: [String: CGRect]
    }

    /// Groups side by side, each a top-aligned row; folded groups keep a chip-wide slot and hide
    /// their cards. Hand-placed positions do not apply while grouped.
    public static func grouped(_ viewports: [ViewportConfig], groups: [ViewportGroup], collapsed: Set<String>) -> GroupedLayout {
        var result = GroupedLayout(frames: [:], groups: [:])
        var x = margin
        let byID = Dictionary(uniqueKeysWithValues: viewports.map { ($0.id, $0) })
        for group in groups {
            if collapsed.contains(group.key) {
                result.groups[group.key] = CGRect(x: x, y: margin, width: 0, height: 0)
                x += collapsedWidth
                continue
            }
            var union = CGRect.null
            for id in group.members {
                guard let viewport = byID[id] else { continue }
                let frame = CGRect(x: x, y: margin, width: Double(viewport.size.width), height: Double(viewport.size.height))
                result.frames[id] = frame
                union = union.union(frame)
                x += Double(viewport.size.width) + gap
            }
            result.groups[group.key] = union
            x += groupGap - gap
        }
        return result
    }
}
