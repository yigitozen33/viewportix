import DeviceCatalog
import EngineCore
import Foundation

extension ViewportSize {
    /// "1024×768", "1024x768", "1024 x 768", "1024*768" (device picker search, STRIP-10).
    public init?(parsing text: String) {
        let parts = text.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .split(whereSeparator: { "×x*".contains($0) })
        guard parts.count == 2, let width = Int(parts[0]), let height = Int(parts[1]) else { return nil }
        self.init(width: width, height: height)
    }
}

/// Device picker logic: search over the catalogue and the last three devices added (app-wide).
public enum DeviceSearch {
    /// Presets whose name contains `query`; all when it is empty or a size.
    public static func presets(matching query: String, in catalogue: [DevicePreset] = DeviceCatalog.all) -> [DevicePreset] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty, ViewportSize(parsing: query) == nil else { return catalogue }
        return catalogue.filter { $0.name.localizedStandardContains(query) || "\($0.size.width)×\($0.size.height)".contains(query) }
    }

    /// Newest first, unique, at most `limit`.
    public static func recordRecent(_ id: String, in recent: [String], limit: Int = 3) -> [String] {
        Array(([id] + recent.filter { $0 != id }).prefix(limit))
    }
}
