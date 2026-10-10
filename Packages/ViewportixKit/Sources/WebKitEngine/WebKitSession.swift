import AppKit
import EngineCore
import SyncCore
import WebKit

/// A WebKit viewport: a WKWebView with the sync agent injected into an isolated content world.
@MainActor
public final class WebKitSession: NSObject, EngineSession {
    public let id: ViewportID
    public let kind = EngineKind.webKit
    public var engineVersion: String { WebKitInfo.version }
    public var currentURL: URL? { webView.url }
    public var view: NSView { webView }
    public var eventHandler: ((EngineEvent) -> Void)?

    let webView: WKWebView
    private var observations: [NSKeyValueObservation] = []

    static let world = WKContentWorld.world(name: "viewportix")

    /// - Parameters:
    ///   - mobileUserAgent: Send an iPhone Safari user agent so sites serve their phone layout.
    ///   - dataStore: Shared by all viewports of a project so one login covers every viewport.
    public init(
        id: ViewportID,
        size: ViewportSize,
        mobileUserAgent: Bool,
        dataStore: WKWebsiteDataStore = .default()
    ) {
        self.id = id
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = dataStore
        webView = WKWebView(
            frame: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            configuration: configuration
        )
        super.init()

        if mobileUserAgent {
            webView.customUserAgent = WebKitInfo.mobileUserAgent
        }
        webView.navigationDelegate = self
        let controller = configuration.userContentController
        controller.addUserScript(WKUserScript(
            source: SyncAgent.source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true,
            in: Self.world
        ))
        // The proxy breaks the content controller → session retain cycle.
        controller.add(MessageProxy(session: self), contentWorld: Self.world, name: SyncAgent.messageName)
        observe()
    }

    // MARK: EngineSession

    public func load(_ url: URL) {
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
    }

    public func reload() { webView.reload() }
    public func goBack() { webView.goBack() }
    public func goForward() { webView.goForward() }

    public func resize(to size: ViewportSize) {
        webView.setFrameSize(NSSize(width: size.width, height: size.height))
    }

    public func apply(_ event: SyncEvent) async -> ApplyResult {
        switch event {
        case .navigate(let url):
            load(url)
            return .applied("navigate")
        case .scroll(let anchor):
            return await callAgent("applyAnchor(value)", value: anchor)
        case .click(let target):
            return await callAgent("applyClick(value)", value: target)
        }
    }

    // MARK: Agent bridge

    private func callAgent(_ body: String, value: JSONValue) async -> ApplyResult {
        do {
            let result = try await webView.callAsyncJavaScript(
                "return window.__viewportix ? window.__viewportix.\(body) : 'not-ready'",
                arguments: ["value": value.anyValue],
                in: nil,
                contentWorld: Self.world
            )
            switch result as? String {
            case "missed": return .missed
            case "not-ready": return .failed("agent not loaded")
            case let method?: return .applied(method)
            case nil: return .failed("unexpected agent result")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    /// Runs JavaScript in the agent's world; for tests and diagnostics.
    func evaluateInAgentWorld(_ body: String) async throws -> Any? {
        try await webView.callAsyncJavaScript(body, arguments: [:], in: nil, contentWorld: Self.world)
    }

    func receive(_ body: Any) {
        guard let message = JSONValue(any: body) else { return }
        switch message["kind"]?.stringValue {
        case "scroll":
            if let anchor = message["anchor"] { eventHandler?(.interaction(.scroll(anchor))) }
        case "click":
            if let target = message["target"] { eventHandler?(.interaction(.click(target))) }
        default:
            break
        }
    }

    // MARK: Page state

    private func observe() {
        // KVO on `url` covers full loads and same-document navigations (pushState, popstate, fragments).
        observations = [
            webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
                MainActor.assumeIsolated {
                    guard let url = webView.url else { return }
                    self?.eventHandler?(.urlChanged(url))
                }
            },
            webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                MainActor.assumeIsolated {
                    self?.eventHandler?(.titleChanged(webView.title ?? ""))
                }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
                MainActor.assumeIsolated {
                    self?.eventHandler?(.loadingChanged(webView.isLoading))
                }
            },
        ]
    }
}

extension WebKitSession: WKNavigationDelegate {}

private final class MessageProxy: NSObject, WKScriptMessageHandler {
    weak var session: WebKitSession?

    init(session: WebKitSession) {
        self.session = session
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        session?.receive(message.body)
    }
}

enum WebKitInfo {
    /// The installed Safari's version names the WebKit build users actually get.
    static let version: String = {
        let safari = Bundle(path: "/Applications/Safari.app")?.infoDictionary?["CFBundleShortVersionString"] as? String
        return safari.map { "WebKit · Safari \($0)" } ?? "WebKit"
    }()

    static let mobileUserAgent: String = {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let safari = Bundle(path: "/Applications/Safari.app")?.infoDictionary?["CFBundleShortVersionString"] as? String ?? "\(os.majorVersion).0"
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(os.majorVersion)_\(os.minorVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(safari) Mobile/15E148 Safari/604.1"
    }()
}
