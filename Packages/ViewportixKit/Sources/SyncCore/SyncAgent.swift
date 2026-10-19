import EngineCore
import Foundation

/// The page-side half of sync: one script, injected into every viewport regardless of engine.
public enum SyncAgent {
    /// Name of the message channel the agent posts to.
    public static let messageName = "viewportix"

    public static let source: String = {
        guard let url = Bundle.module.url(forResource: "sync-agent", withExtension: "js"),
              let source = try? String(contentsOf: url, encoding: .utf8) else {
            preconditionFailure("sync-agent.js missing from the SyncCore bundle")
        }
        return source
    }()

    /// What the agent posted, as a sync event (both engines): scroll anchor, click target, field
    /// state, hover target (`.null` when the pointer left the page).
    public static func event(from message: JSONValue) -> SyncEvent? {
        switch message["kind"]?.stringValue {
        case "scroll":
            return message["anchor"].map(SyncEvent.scroll)
        case "click":
            return message["target"].map(SyncEvent.click)
        case "input":
            guard let field = message["field"] else { return nil }
            return .input(.object([
                "field": field,
                "value": message["value"] ?? .string(""),
                "checked": message["checked"] ?? .bool(false),
            ]))
        case "hover":
            return .hover(message["target"] ?? .null)
        default:
            return nil
        }
    }
}
