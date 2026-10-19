import AppKit

/// Something a user did in one viewport that the others should mirror.
public enum SyncEvent: Hashable, Sendable {
    /// Agent-produced scroll anchor (candidates, heading section, percent).
    case scroll(JSONValue)
    /// Agent-produced click target (selector, tag, text, href).
    case click(JSONValue)
    /// Agent-produced field state: `{ field, value, checked }`.
    case input(JSONValue)
    /// Agent-produced target under the leader's pointer, or `.null` when the pointer left the page.
    case hover(JSONValue)
    case navigate(URL)
}

/// What a session reports to its owner.
public enum EngineEvent: Hashable, Sendable {
    /// A user interaction observed in the page, to be mirrored if this viewport leads.
    case interaction(SyncEvent)
    case urlChanged(URL)
    case titleChanged(String)
    case loadingChanged(Bool)
    /// The main frame failed to load (`LoadFailure`), or nil once a page loads again.
    case loadFailure(LoadFailure?)
    /// After each page load: whether the sync agent runs in it. False for pages that take no script
    /// (PDF, images, about:blank…): the viewport can't lead or follow (§5.20 h, "senkron kurulamıyor").
    case syncAvailable(Bool)
}

/// What a screenshot covers.
public enum SnapshotArea: Hashable, Sendable {
    /// What the viewport shows right now.
    case visible
    /// The whole document, top to bottom, without scrolling the page.
    case fullPage
}

/// Outcome of mirroring a `SyncEvent` in one viewport.
public enum ApplyResult: Hashable, Sendable {
    /// Applied; the associated value names the strategy (e.g. "anchor:strong", "section", "click:text").
    case applied(String)
    /// The target does not exist or is hidden at this viewport's width ("sync missed").
    case missed
    case failed(String)
}

/// One live viewport, independent of the browser engine behind it.
/// Canvas and sync code talk to engines only through this protocol.
@MainActor
public protocol EngineSession: AnyObject {
    var id: ViewportID { get }
    var kind: EngineKind { get }
    /// Human-readable engine version for the viewport header, e.g. "WebKit · Safari 26.1".
    var engineVersion: String { get }
    var currentURL: URL? { get }
    /// The live view placed on the canvas. Snapshot-based engines will need a frame-based surface later.
    var view: NSView { get }
    var eventHandler: ((EngineEvent) -> Void)? { get set }

    func load(_ url: URL)
    func reload()
    func goBack()
    func goForward()
    func resize(to size: ViewportSize)
    func apply(_ event: SyncEvent) async -> ApplyResult
    /// Runs a script in the page's own world and returns its JSON-compatible result.
    /// For diagnostics, profiling and (later) the MCP server.
    func evaluate(_ script: String) async throws -> JSONValue?
    func snapshot(_ area: SnapshotArea) async throws -> CGImage
    /// Holds audio and video paused even if the page calls play(); saves CPU in viewports nobody is
    /// looking at. Does not touch layout, CSS animations or scripts.
    func setMediaPlaybackSuspended(_ suspended: Bool)
    /// "Bu oturumda güven": accept this host's certificate in every viewport until the app quits.
    func trustCertificates(forHost host: String)
}
