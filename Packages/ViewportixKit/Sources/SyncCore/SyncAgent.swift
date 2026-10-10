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
}
