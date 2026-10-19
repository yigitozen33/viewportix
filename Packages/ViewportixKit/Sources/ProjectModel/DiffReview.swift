import Foundation

/// What the user decided in Farklar (DESIGN.md §3.4, DEV-03…05), saved with the project.
/// Kabul: this difference, with these values, is intended — it leaves the list until a value
/// changes. Yoksay: a selector the user doesn't want compared at all. Takip et: stays in the list,
/// marked, measured again each time.
public struct DiffReview: Codable, Hashable, Sendable {
    /// "<compared viewport>|<selector>|<property>" → "<baseline value> → <compared value>" accepted.
    public var accepted: [String: String]
    public var ignoredSelectors: Set<String>
    /// "<compared viewport>|<selector>|<property>"
    public var tracked: Set<String>

    public init(accepted: [String: String] = [:], ignoredSelectors: Set<String> = [], tracked: Set<String> = []) {
        self.accepted = accepted
        self.ignoredSelectors = ignoredSelectors
        self.tracked = tracked
    }

    public static func key(viewport: UUID, difference id: String) -> String {
        "\(viewport.uuidString)|\(id)"
    }

    public func isAccepted(_ key: String, change: String) -> Bool {
        accepted[key] == change
    }
}
