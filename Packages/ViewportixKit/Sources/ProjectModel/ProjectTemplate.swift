import DeviceCatalog
import EngineCore
import Foundation

/// Device sets offered as chips on the home screen (DESIGN.md §3.1). The device lists are a code-side
/// default until the design names them (docs/tasarim-istekleri.md, 2026-10-16).
public enum ProjectTemplate: String, CaseIterable, Codable, Sendable {
    case mobileFocused
    case fullMatrix
    case engineComparison

    public static let `default` = ProjectTemplate.mobileFocused

    public var viewports: [ViewportConfig] {
        switch self {
        case .mobileFocused:
            Self.configs(["iphone-se", "iphone-16", "iphone-17-pro-max", "ipad-air-11"])
        case .fullMatrix:
            Self.configs(["iphone-se", "iphone-16", "iphone-17-pro-max", "ipad-mini", "ipad-pro-13", "laptop", "desktop", "desktop-full-hd"])
        case .engineComparison:
            Self.shippedEngines.flatMap { Self.configs(["iphone-16", "desktop"], engine: $0) }
        }
    }

    /// Engines with their own session; Firefox joins with M6.
    public static let shippedEngines: [EngineKind] = [.webKit, .chromium]

    private static func configs(_ ids: [String], engine: EngineKind = .webKit) -> [ViewportConfig] {
        ids.compactMap(DeviceCatalog.preset(id:)).map { ViewportConfig(preset: $0, engine: engine) }
    }
}

extension Project {
    /// A new project from the home screen: the template's devices, starting at `url`.
    public static func new(url: URL, template: ProjectTemplate) -> Project {
        Project(pages: [Page(name: "Ana sayfa", url: url)], viewports: template.viewports)
    }
}
