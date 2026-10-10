import AppKit
import WebKit

/// One viewport and its bridge to the sync agent.
final class SyncedWebView: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let world = WKContentWorld.world(name: "viewportix")

    let name: String
    let webView: WKWebView
    var isLoaded = false
    var onAnchor: ((SyncedWebView, [String: Any]) -> Void)?

    init(name: String, size: NSSize, mobile: Bool, agentSource: String) {
        self.name = name
        let configuration = WKWebViewConfiguration()
        // Ephemeral store: ad-hoc signed spike builds would otherwise trigger keychain prompts (WebCrypto keys).
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: NSRect(origin: .zero, size: size), configuration: configuration)
        super.init()
        if mobile {
            webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"
        }
        let controller = configuration.userContentController
        controller.addUserScript(WKUserScript(source: agentSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: Self.world))
        controller.add(self, contentWorld: Self.world, name: "viewportix")
        webView.navigationDelegate = self
    }

    func load(_ url: URL) {
        isLoaded = false
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
    }

    /// Calls `window.__viewportix.<body>` in the agent's isolated world.
    @discardableResult
    func agent(_ body: String, _ arguments: [String: Any] = [:]) async -> Any? {
        try? await webView.callAsyncJavaScript("return window.__viewportix.\(body)", arguments: arguments, in: nil, contentWorld: Self.world)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoaded = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoaded = true
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let anchor = body["anchor"] as? [String: Any] else { return }
        onAnchor?(self, anchor)
    }
}

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

/// Three viewports side by side; the one under the pointer leads, the others follow its anchors.
final class SyncController: NSViewController {
    private(set) var viewports: [SyncedWebView] = []
    /// Self-test hook: forces a leader instead of reading the pointer position.
    var leaderOverride: SyncedWebView?
    private(set) var forwardedCount = 0
    private(set) var ignoredCount = 0
    private let urlField = NSTextField()
    private let status = NSTextField(labelWithString: "Scroll any viewport; the one under the pointer leads.")

    private static let devices: [(name: String, width: CGFloat, height: CGFloat, mobile: Bool)] = [
        ("iPhone 16", 393, 852, true),
        ("iPad Air 11\"", 820, 1180, false),
        ("Masaüstü", 1440, 900, false),
    ]

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 1400, height: 820))
        let agentSource = (try? String(contentsOf: Paths.agent, encoding: .utf8)) ?? ""

        let document = FlippedView()
        var x: CGFloat = 24
        for device in Self.devices {
            let viewport = SyncedWebView(
                name: device.name,
                size: NSSize(width: device.width, height: device.height),
                mobile: device.mobile,
                agentSource: agentSource
            )
            viewport.webView.frame.origin = NSPoint(x: x, y: 24)
            viewport.onAnchor = { [weak self] source, anchor in self?.forward(anchor, from: source) }
            document.addSubview(viewport.webView)
            viewports.append(viewport)
            x += device.width + 24
        }
        document.frame = NSRect(x: 0, y: 0, width: x, height: 1180 + 48)

        let scrollView = NSScrollView()
        scrollView.documentView = document
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.allowsMagnification = true
        scrollView.magnification = 0.5

        urlField.placeholderString = "URL — Enter loads it in every viewport"
        urlField.target = self
        urlField.action = #selector(urlEntered)
        status.font = .monospacedSystemFont(ofSize: 11, weight: .regular)

        for view in [urlField, status, scrollView] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            urlField.topAnchor.constraint(equalTo: root.topAnchor, constant: 8),
            urlField.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
            urlField.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
            status.topAnchor.constraint(equalTo: urlField.bottomAnchor, constant: 6),
            status.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
            scrollView.topAnchor.constraint(equalTo: status.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])
        view = root
    }

    func loadAll(_ url: URL, timeout: Duration = .seconds(20)) async {
        urlField.stringValue = url.absoluteString
        viewports.forEach { $0.load(url) }
        let deadline = ContinuousClock.now + timeout
        while !viewports.allSatisfy(\.isLoaded), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    @objc private func urlEntered() {
        var text = urlField.stringValue.trimmingCharacters(in: .whitespaces)
        if !text.contains("://") { text = "https://" + text }
        guard let url = URL(string: text) else { return }
        Task { await loadAll(url) }
    }

    /// Only the viewport under the pointer may lead; anything else is an echo or a page-driven scroll.
    private func forward(_ anchor: [String: Any], from source: SyncedWebView) {
        guard leader === source else {
            ignoredCount += 1
            return
        }
        forwardedCount += 1
        Task {
            var results: [String] = []
            for follower in viewports where follower !== source {
                let method = await follower.agent("applyAnchor(anchor)", ["anchor": anchor]) as? String ?? "error"
                results.append("\(follower.name): \(method)")
            }
            status.stringValue = "Leader \(source.name) → " + results.joined(separator: "  ·  ")
        }
    }

    func resetCounters() {
        forwardedCount = 0
        ignoredCount = 0
    }

    private var leader: SyncedWebView? {
        if let leaderOverride { return leaderOverride }
        guard let window = view.window else { return nil }
        let point = window.convertPoint(fromScreen: NSEvent.mouseLocation)
        return viewports.first { viewport in
            viewport.webView.bounds.contains(viewport.webView.convert(point, from: nil))
        }
    }
}
