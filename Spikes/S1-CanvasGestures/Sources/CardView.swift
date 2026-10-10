import AppKit
import WebKit

struct ClickReport {
    let target: String
    let x: Double
    let y: Double
}

/// One device viewport on the canvas: a header strip above a live WKWebView.
final class CardView: NSView, WKNavigationDelegate, WKScriptMessageHandler {
    static let headerHeight: CGFloat = 28

    let name: String
    let webView: WKWebView
    var isLoaded = false
    var lastClick: ClickReport?
    var onClick: ((CardView, ClickReport) -> Void)?

    override var isFlipped: Bool { true }

    init(name: String, size: NSSize, userAgent: String?) {
        self.name = name

        let contentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        // Ephemeral store: ad-hoc signed spike builds would otherwise trigger keychain prompts (WebCrypto keys).
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController = contentController
        webView = WKWebView(
            frame: NSRect(x: 0, y: Self.headerHeight, width: size.width, height: size.height),
            configuration: configuration
        )
        webView.customUserAgent = userAgent

        super.init(frame: NSRect(x: 0, y: 0, width: size.width, height: size.height + Self.headerHeight))

        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        layer?.cornerRadius = 8
        layer?.masksToBounds = true

        let label = NSTextField(labelWithString: "\(name) · \(Int(size.width))×\(Int(size.height)) · WebKit")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.frame = NSRect(x: 10, y: 6, width: size.width - 20, height: 16)
        addSubview(label)
        addSubview(webView)

        contentController.add(self, name: "spike")
        contentController.addUserScript(WKUserScript(
            source: Self.clickReporter,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        webView.navigationDelegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    func load(_ url: URL) {
        isLoaded = false
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
    }

    func isHeader(windowPoint: NSPoint) -> Bool {
        convert(windowPoint, from: nil).y < Self.headerHeight
    }

    /// Reached for scrolls over the header, and when the web view hands back a scroll it could not use
    /// (page already at its edge). The latter must not move the canvas, so only header scrolls go up.
    override func scrollWheel(with event: NSEvent) {
        if isHeader(windowPoint: event.locationInWindow) {
            enclosingScrollView?.scrollWheel(with: event)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], body["kind"] as? String == "click" else { return }
        let report = ClickReport(
            target: body["target"] as? String ?? "?",
            x: body["x"] as? Double ?? -1,
            y: body["y"] as? Double ?? -1
        )
        lastClick = report
        onClick?(self, report)
    }

    private static let clickReporter = """
    document.addEventListener('click', (event) => {
      const t = event.target;
      const target = t.id ? '#' + t.id : t.tagName.toLowerCase();
      window.webkit.messageHandlers.spike.postMessage({ kind: 'click', target, x: event.clientX, y: event.clientY });
    }, true);
    """
}
