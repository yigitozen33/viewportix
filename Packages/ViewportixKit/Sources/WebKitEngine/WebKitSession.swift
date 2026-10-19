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
        webView = ViewportWebView(
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
        case .input(let payload):
            return await callAgent("applyInput(value)", value: payload)
        case .hover(let target):
            return await callAgent("applyHover(value)", value: target)
        }
    }

    public func setMediaPlaybackSuspended(_ suspended: Bool) {
        webView.setAllMediaPlaybackSuspended(suspended, completionHandler: nil)
    }

    public func evaluate(_ script: String) async throws -> JSONValue? {
        let result = try await webView.evaluateJavaScript(script)
        return result.flatMap { JSONValue(any: $0) }
    }

    /// Tallest full-page capture, in CSS px; protects against endless pages.
    static let maxFullPageHeight: CGFloat = 32_000

    public func snapshot(_ area: SnapshotArea) async throws -> CGImage {
        switch area {
        case .visible:
            let configuration = WKSnapshotConfiguration()
            configuration.afterScreenUpdates = true
            let image = try await webView.takeSnapshot(configuration: configuration)
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw SnapshotError.noImage
            }
            return cgImage
        case .fullPage:
            return try await fullPageSnapshot()
        }
    }

    /// A bitmap snapshot only contains tiles WebKit has rendered near the visible area, so the full page
    /// is drawn into a PDF (which paints the whole rect) and rasterized. Tall content comes back as
    /// several PDF pages (PDF caps page size), which are stacked top to bottom.
    private func fullPageSnapshot() async throws -> CGImage {
        let documentHeight = try await webView.evaluateJavaScript(
            "Math.max(document.documentElement.scrollHeight, document.body ? document.body.scrollHeight : 0)"
        ) as? Double ?? 0
        let width = webView.bounds.width
        let height = min(max(webView.bounds.height, CGFloat(documentHeight)), Self.maxFullPageHeight)
        let configuration = WKPDFConfiguration()
        // PDF rects are in document coordinates, independent of the current scroll position.
        configuration.rect = CGRect(x: 0, y: 0, width: width, height: height)
        let pdf = try await webView.pdf(configuration: configuration)

        guard let provider = CGDataProvider(data: pdf as CFData),
              let document = CGPDFDocument(provider), document.numberOfPages > 0 else { throw SnapshotError.noImage }
        let pages = (1...document.numberOfPages).compactMap { document.page(at: $0) }
        let boxes = pages.map { $0.getBoxRect(.mediaBox) }
        let contentWidth = boxes.map(\.width).max() ?? width
        let contentHeight = boxes.reduce(0) { $0 + $1.height }
        // Keep the bitmap bounded on very tall pages by dropping to 1x.
        let preferred = webView.window?.backingScaleFactor ?? 2
        let scale = contentWidth * contentHeight * preferred * preferred * 4 > 256_000_000 ? 1 : preferred
        let pixelWidth = Int((contentWidth * scale).rounded())
        let pixelHeight = Int((contentHeight * scale).rounded())
        guard let context = CGContext(
            data: nil, width: pixelWidth, height: pixelHeight, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw SnapshotError.noImage }
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        context.scaleBy(x: scale, y: scale)
        // Core Graphics origin is bottom-left: the first page goes at the top.
        var top = contentHeight
        for (page, box) in zip(pages, boxes) {
            top -= box.height
            context.saveGState()
            context.translateBy(x: -box.origin.x, y: top - box.origin.y)
            context.drawPDFPage(page)
            context.restoreGState()
        }
        guard let image = context.makeImage() else { throw SnapshotError.noImage }
        return image
    }

    public enum SnapshotError: Error {
        case noImage
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
        case "input":
            if let field = message["field"] {
                eventHandler?(.interaction(.input(.object([
                    "field": field,
                    "value": message["value"] ?? .string(""),
                    "checked": message["checked"] ?? .bool(false),
                ]))))
            }
        case "hover":
            eventHandler?(.interaction(.hover(message["target"] ?? .null)))
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

extension WebKitSession: WKNavigationDelegate {
    /// Hosts the user trusted for this run of the app (CARD-12); shared by every viewport.
    static var trustedHosts: Set<String> = []

    public func trustCertificates(forHost host: String) {
        Self.trustedHosts.insert(host.lowercased())
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        eventHandler?(.loadFailure(nil))
    }

    /// Asked once the load ends: the agent (a document-end user script) must be there and the page
    /// must be a web document. WebKit wraps PDFs and images in a document the agent does get into,
    /// but there is nothing in it to scroll or click in step; about:blank has nothing either.
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task {
            let type = (try? await evaluateInAgentWorld("return window.__viewportix ? document.contentType : ''")) as? String ?? ""
            let isBlank = webView.url?.absoluteString == "about:blank"
            eventHandler?(.syncAvailable(!isBlank && (type == "text/html" || type == "application/xhtml+xml")))
        }
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        report(error)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        report(error)
    }

    private func report(_ error: any Error) {
        let error = error as NSError
        let url = (error.userInfo[NSURLErrorFailingURLErrorKey] as? URL) ?? webView.url ?? URL(string: "about:blank")!
        guard let failure = LoadFailure(domain: error.domain, code: error.code, url: url) else { return }
        eventHandler?(.loadFailure(failure))
    }

    public func webView(_ webView: WKWebView, respondTo challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let space = challenge.protectionSpace
        if space.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           Self.trustedHosts.contains(space.host.lowercased()),
           let trust = space.serverTrust {
            return (.useCredential, URLCredential(trust: trust))
        }
        return (.performDefaultHandling, nil)
    }
}

/// Tab moves between the app's controls, not through every page's links and fields (PW-05): the
/// page is left out of the key view loop. A click still puts the keyboard in the page.
final class ViewportWebView: WKWebView {
    override var canBecomeKeyView: Bool { false }
}

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
