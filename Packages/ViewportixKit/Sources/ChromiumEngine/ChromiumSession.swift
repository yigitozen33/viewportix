import AppKit
import EngineCore
import SyncCore

/// A Chromium viewport (PLAN.md §5.2): its own window in the shared headless Chrome, streamed with
/// `Page.startScreencast` into `ChromiumView`; input goes back with `Input.dispatch*`. The sync agent
/// runs in an isolated world, posting through a CDP binding.
@MainActor
public final class ChromiumSession: EngineSession {
    public let id: ViewportID
    public let kind = EngineKind.chromium
    public var engineVersion: String { browser.version }
    public private(set) var currentURL: URL?
    public var view: NSView { chromiumView }
    public var eventHandler: ((EngineEvent) -> Void)?

    let chromiumView = ChromiumView()
    private let browser: ChromeBrowser
    private var size: ViewportSize
    private let mobile: Bool
    private let tablet: Bool
    private var connection: CDPConnection?
    private var session: String?
    private var targetID: String?
    private var listener: UUID?
    private var setup: Task<Void, Error>?
    private var agentContext: Int?
    private var logsDeveloperMessages = false
    private var mediaSuspended = false
    private(set) var isLoading = false
    /// The frame size the screencast runs at (px); restarted when the card's on-screen size changes.
    private var streamSize: (width: Int, height: Int)?
    private var history: [String] = []

    static let world = "viewportix"
    static let binding = "__viewportixPost"
    static let selectBinding = "__viewportixSelect"

    /// A `<select>` the user opened: headless Chrome never paints its popup, so the app shows the
    /// options itself (PLAN.md §5.2). `rect` is in this session's view coordinates (CSS px).
    public struct SelectMenu: Sendable {
        public struct Option: Sendable {
            public let label: String
            public let isEnabled: Bool
            /// The `<optgroup>` label, if any.
            public let group: String?
        }
        public let options: [Option]
        public let selectedIndex: Int
        public let rect: CGRect
    }

    /// Set by the app to show `SelectMenu`s; the choice comes back through `chooseSelectOption`.
    public var onSelectMenu: ((SelectMenu) -> Void)?

    /// Phones and tablets get Chrome on Android's user agent (with this Chrome's major version) and
    /// touch, as Chromium really ships there; a tablet's has no "Mobile".
    static func userAgent(version: String, tablet: Bool) -> String {
        let major = version.split(separator: " ").last?.split(separator: ".").first.map(String.init) ?? "141"
        let device = tablet ? "Pixel Tablet" : "Pixel 8"
        return "Mozilla/5.0 (Linux; Android 14; \(device)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/\(major).0.0.0 \(tablet ? "" : "Mobile ")Safari/537.36"
    }

    /// `mobile`: phone or tablet (touch, mobile viewport, Android UA); a tablet's UA has no "Mobile".
    public init(id: ViewportID, size: ViewportSize, mobile: Bool, tablet: Bool = false, browser: ChromeBrowser = .shared) {
        self.id = id
        self.size = size
        self.mobile = mobile
        self.tablet = tablet
        self.browser = browser
        chromiumView.session = self
        chromiumView.frame = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        setup = Task { try await start() }
    }

    isolated deinit {
        if let listener { connection?.stopListening(listener) }
        if let targetID { connection?.post("Target.closeTarget", ["targetId": targetID]) }
    }

    // MARK: Setup

    private func start() async throws {
        do {
            let connection = try await browser.connect()
            self.connection = connection
            let target = try await connection.send("Target.createTarget", ["url": "about:blank", "newWindow": true])
            guard let targetID = target["targetId"]?.stringValue else { throw CDPConnection.Failure(description: "hedef yok") }
            self.targetID = targetID
            let attached = try await connection.send("Target.attachToTarget", ["targetId": targetID, "flatten": true])
            session = attached["sessionId"]?.stringValue
            listener = connection.listen { [weak self] event in self?.handle(event) }

            try await send("Page.enable")
            try await send("Runtime.enable")
            try await send("Network.enable")
            try await send("Emulation.setFocusEmulationEnabled", ["enabled": true])
            try await applyMetrics()
            if mobile {
                try await send("Emulation.setTouchEmulationEnabled", ["enabled": true, "maxTouchPoints": 5])
                try await send("Emulation.setUserAgentOverride", ["userAgent": Self.userAgent(version: browser.version, tablet: tablet)])
            }
            try await send("Runtime.addBinding", ["name": Self.binding, "executionContextName": Self.world])
            try await send("Runtime.addBinding", ["name": Self.selectBinding, "executionContextName": Self.world])
            try await send("Page.addScriptToEvaluateOnNewDocument", ["source": Self.agentSource, "worldName": Self.world])
            try await restartStream()
        } catch {
            chromiumView.showUnavailable(ChromeBrowser.isAvailable ? "Chromium başlatılamadı" : "Chrome bulunamadı")
            throw error
        }
    }

    /// The agent waits for the DOM; its messages go through the binding as JSON strings.
    static let agentSource = """
    window.webkit = { messageHandlers: { \(SyncAgent.messageName): { postMessage: (m) => \(binding)(JSON.stringify(m)) } } };
    (() => {
      const run = () => { \(SyncAgent.source) };
      if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run, { once: true }); else run();
    })();
    addEventListener('mousedown', (event) => {
      const select = event.isTrusted && event.button === 0 && event.target instanceof Element ? event.target.closest('select') : null;
      if (!select || select.multiple || select.size > 1 || select.disabled) return;
      event.preventDefault();
      select.focus();
      window.__viewportixSelectTarget = select;
      const r = select.getBoundingClientRect();
      \(selectBinding)(JSON.stringify({
        x: r.left, y: r.top, w: r.width, h: r.height, selected: select.selectedIndex,
        options: [...select.options].map(o => ({ label: o.label || o.text, disabled: o.disabled,
          group: o.parentElement && o.parentElement.tagName === 'OPTGROUP' ? o.parentElement.label : null }))
      }));
    }, true);
    """

    private func applyMetrics() async throws {
        try await send("Emulation.setDeviceMetricsOverride",
                       ["width": size.width, "height": size.height, "deviceScaleFactor": 2, "mobile": mobile])
    }

    @discardableResult
    private func send(_ method: String, _ params: [String: Any] = [:]) async throws -> JSONValue {
        guard let connection else { throw CDPConnection.Failure(description: "Chrome bağlı değil") }
        return try await connection.send(method, params, session: session)
    }

    private func post(_ method: String, _ params: [String: Any] = [:]) {
        connection?.post(method, params, session: session)
    }

    /// Runs `body` once the target is ready; dropped (with the viewport showing why) if Chrome failed.
    private func whenReady(_ body: @escaping @MainActor () async throws -> Void) {
        Task {
            guard (try? await setup?.value) != nil else { return }
            try? await body()
        }
    }

    // MARK: Streaming (S5: frames no larger than the card shows them)

    /// Pixels the card covers on screen now (zoom × backing scale), at most 2× the CSS size.
    private var wantedStreamSize: (width: Int, height: Int) {
        let shown = chromiumView.onScreenPixelSize
        let width = max(64, min(size.width * 2, Int(shown.width.rounded(.up))))
        let height = max(64, min(size.height * 2, Int(shown.height.rounded(.up))))
        return (width, height)
    }

    func restartStream() async throws {
        let wanted = wantedStreamSize
        streamSize = wanted
        try await send("Page.stopScreencast")
        try await send("Page.startScreencast", ["format": "jpeg", "quality": 80, "everyNthFrame": 1,
                                                "maxWidth": wanted.width, "maxHeight": wanted.height])
    }

    /// Called by the view when its on-screen size changed (zoom, resize); 15 % hysteresis.
    func onScreenSizeChanged() {
        guard let current = streamSize else { return }
        let wanted = wantedStreamSize
        let change = abs(Double(wanted.width - current.width)) / Double(max(current.width, 1))
        guard change > 0.15 else { return }
        whenReady { try await self.restartStream() }
    }

    // MARK: Events

    private func handle(_ event: CDPConnection.Event) {
        if event.sessionID == nil {
            // Browser-level: the title of our target.
            if event.method == "Target.targetInfoChanged", event.params["targetInfo"]?["targetId"]?.stringValue == targetID,
               let title = event.params["targetInfo"]?["title"]?.stringValue {
                eventHandler?(.titleChanged(title))
            }
            return
        }
        guard event.sessionID == session else { return }
        let params = event.params
        switch event.method {
        case "Page.screencastFrame":
            if let ack = params["sessionId"]?.numberValue { post("Page.screencastFrameAck", ["sessionId": Int(ack)]) }
            if let data = params["data"]?.stringValue { chromiumView.showFrame(base64: data) }
        case "Page.frameNavigated":
            guard params["frame"]?["parentId"] == nil, let url = params["frame"]?["url"]?.stringValue.flatMap(URL.init(string:)) else { return }
            guard url.scheme != "chrome-error" else { return }
            currentURL = url
            agentContext = nil
            eventHandler?(.loadFailure(nil))
            eventHandler?(.urlChanged(url))
        case "Page.navigatedWithinDocument":
            if let url = params["url"]?.stringValue.flatMap(URL.init(string:)) {
                currentURL = url
                eventHandler?(.urlChanged(url))
            }
        case "Page.frameStartedLoading" where params["frameId"]?.stringValue == targetID:
            setLoading(true)
        case "Page.frameStoppedLoading" where params["frameId"]?.stringValue == targetID:
            setLoading(false)
            reportSyncAvailability()
        case "Runtime.executionContextCreated":
            let context = params["context"]
            if context?["name"]?.stringValue == Self.world, context?["auxData"]?["frameId"]?.stringValue == targetID {
                agentContext = context?["id"]?.numberValue.map(Int.init)
            }
        case "Runtime.bindingCalled" where params["name"]?.stringValue == Self.binding:
            if let payload = params["payload"]?.stringValue,
               let object = try? JSONSerialization.jsonObject(with: Data(payload.utf8)),
               let message = JSONValue(any: object), let sync = SyncAgent.event(from: message) {
                eventHandler?(.interaction(sync))
            }
        case "Runtime.bindingCalled" where params["name"]?.stringValue == Self.selectBinding:
            if let payload = params["payload"]?.stringValue,
               let object = try? JSONSerialization.jsonObject(with: Data(payload.utf8)), let json = JSONValue(any: object) {
                showSelectMenu(json)
            }
        case "Network.loadingFailed" where params["type"]?.stringValue == "Document":
            guard params["canceled"]?.boolValue != true, let error = params["errorText"]?.stringValue,
                  let url = pendingDocumentURLs[params["requestId"]?.stringValue ?? ""] ?? currentURL,
                  let failure = LoadFailure(chromiumError: error, url: url) else { return }
            setLoading(false)
            eventHandler?(.loadFailure(failure))
        case "Network.requestWillBeSent" where params["type"]?.stringValue == "Document":
            if let id = params["requestId"]?.stringValue, let url = params["request"]?["url"]?.stringValue.flatMap(URL.init(string:)) {
                pendingDocumentURLs[id] = url
            }
        case "Network.responseReceived":
            developerResponse(params)
        case "Runtime.consoleAPICalled":
            developerConsole(params)
        case "Runtime.exceptionThrown":
            guard logsDeveloperMessages else { return }
            let details = params["exceptionDetails"]
            let text = details?["exception"]?["description"]?.stringValue ?? details?["text"]?.stringValue ?? "Hata"
            eventHandler?(.developer(DeveloperMessage(kind: .console, level: .error, text: String(text.prefix(300)), url: details?["url"]?.stringValue)))
        case "Page.javascriptDialogOpening":
            // alert / confirm / prompt would stall the page unseen in a headless window: accept them
            // (prompt with its default) and say so in the developer scope.
            post("Page.handleJavaScriptDialog", ["accept": true, "promptText": params["defaultPrompt"]?.stringValue ?? ""])
            let message = params["message"]?.stringValue ?? ""
            eventHandler?(.developer(DeveloperMessage(kind: .console, level: .warning, text: "\(params["type"]?.stringValue ?? "alert"): \(message)")))
        default:
            break
        }
    }

    private var pendingDocumentURLs: [String: URL] = [:]

    private func showSelectMenu(_ json: JSONValue) {
        guard case .array(let items)? = json["options"] else { return }
        let options = items.map { item in
            SelectMenu.Option(label: item["label"]?.stringValue ?? "", isEnabled: item["disabled"]?.boolValue != true,
                              group: item["group"]?.stringValue)
        }
        let rect = CGRect(x: json["x"]?.numberValue ?? 0, y: json["y"]?.numberValue ?? 0,
                          width: json["w"]?.numberValue ?? 0, height: json["h"]?.numberValue ?? 0)
        onSelectMenu?(SelectMenu(options: options, selectedIndex: Int(json["selected"]?.numberValue ?? -1), rect: rect))
    }

    /// Picks an option of the `<select>` last opened and tells the others, like a user's change.
    /// Script events aren't trusted, so the agent wouldn't report this one itself.
    public func chooseSelectOption(_ index: Int) {
        whenReady {
            let result = try await self.evaluateInAgentWorld("""
            (() => {
              const select = window.__viewportixSelectTarget;
              if (!select || !window.__viewportix) return null;
              if (select.selectedIndex !== \(index)) {
                select.selectedIndex = \(index);
                select.dispatchEvent(new Event('input', { bubbles: true }));
                select.dispatchEvent(new Event('change', { bubbles: true }));
              }
              return { kind: 'input', field: window.__viewportix.describeField(select), value: select.value, checked: false };
            })()
            """)
            if let result, let event = SyncAgent.event(from: result) { self.eventHandler?(.interaction(event)) }
        }
    }

    private func setLoading(_ loading: Bool) {
        guard loading != isLoading else { return }
        isLoading = loading
        eventHandler?(.loadingChanged(loading))
    }

    private func reportSyncAvailability() {
        whenReady {
            let type = try? await self.evaluateInAgentWorld("window.__viewportix ? document.contentType : ''")
            let available = self.currentURL?.absoluteString != "about:blank"
                && (type?.stringValue == "text/html" || type?.stringValue == "application/xhtml+xml")
            self.eventHandler?(.syncAvailable(available))
        }
    }

    private func developerConsole(_ params: JSONValue) {
        guard logsDeveloperMessages, let type = params["type"]?.stringValue, type == "error" || type == "warning" else { return }
        var parts: [String] = []
        if case .array(let args)? = params["args"] {
            for arg in args {
                if let text = arg["value"]?.stringValue { parts.append(text) }
                else if let number = arg["value"]?.numberValue { parts.append(String(number)) }
                else if let text = arg["description"]?.stringValue { parts.append(text) }
            }
        }
        eventHandler?(.developer(DeveloperMessage(kind: .console, level: type == "error" ? .error : .warning,
                                                  text: String(parts.joined(separator: " ").prefix(300)))))
    }

    private func developerResponse(_ params: JSONValue) {
        guard logsDeveloperMessages, let status = params["response"]?["status"]?.numberValue, status >= 400 else { return }
        eventHandler?(.developer(DeveloperMessage(kind: .network, level: status >= 500 ? .error : .warning,
                                                  text: "\(Int(status))", url: params["response"]?["url"]?.stringValue)))
    }

    // MARK: EngineSession

    public func load(_ url: URL) {
        currentURL = url
        whenReady {
            let result = try await self.send("Page.navigate", ["url": url.absoluteString])
            if let error = result["errorText"]?.stringValue, let failure = LoadFailure(chromiumError: error, url: url) {
                self.setLoading(false)
                self.eventHandler?(.loadFailure(failure))
            }
        }
    }

    public func reload() { whenReady { try await self.send("Page.reload") } }
    public func goBack() { whenReady { try await self.step(-1) } }
    public func goForward() { whenReady { try await self.step(1) } }

    private func step(_ offset: Int) async throws {
        let history = try await send("Page.getNavigationHistory")
        guard let index = history["currentIndex"]?.numberValue.map(Int.init),
              case .array(let entries)? = history["entries"], entries.indices.contains(index + offset),
              let entry = entries[index + offset]["id"]?.numberValue else { return }
        try await send("Page.navigateToHistoryEntry", ["entryId": Int(entry)])
    }

    public func resize(to size: ViewportSize) {
        self.size = size
        chromiumView.setFrameSize(NSSize(width: size.width, height: size.height))
        whenReady {
            try await self.applyMetrics()
            try await self.restartStream()
        }
    }

    public func apply(_ event: SyncEvent) async -> ApplyResult {
        guard (try? await setup?.value) != nil else { return .failed("Chromium hazır değil") }
        switch event {
        case .navigate(let url):
            load(url)
            return .applied("navigate")
        case .scroll(let anchor): return await callAgent("applyAnchor", anchor)
        case .click(let target): return await callAgent("applyClick", target)
        case .input(let payload): return await callAgent("applyInput", payload)
        case .hover(let target): return await callAgent("applyHover", target)
        }
    }

    private func callAgent(_ function: String, _ value: JSONValue) async -> ApplyResult {
        guard let data = try? JSONSerialization.data(withJSONObject: value.anyValue, options: [.fragmentsAllowed]) else {
            return .failed("geçersiz değer")
        }
        do {
            let result = try await evaluateInAgentWorld("window.__viewportix ? window.__viewportix.\(function)(\(String(decoding: data, as: UTF8.self))) : 'not-ready'")
            switch result?.stringValue {
            case "missed": return .missed
            case "not-ready": return .failed("agent not loaded")
            case let method?: return .applied(method)
            case nil: return .failed("unexpected agent result")
            }
        } catch {
            return .failed("\(error)")
        }
    }

    /// Runs an expression in the agent's isolated world.
    func evaluateInAgentWorld(_ expression: String) async throws -> JSONValue? {
        guard let agentContext else { throw CDPConnection.Failure(description: "agent context yok") }
        let result = try await send("Runtime.evaluate", ["expression": expression, "contextId": agentContext,
                                                         "returnByValue": true, "awaitPromise": true])
        return result["result"]?["value"]
    }

    public func evaluate(_ script: String) async throws -> JSONValue? {
        try await setup?.value
        let result = try await send("Runtime.evaluate", ["expression": script, "returnByValue": true, "awaitPromise": true])
        if let exception = result["exceptionDetails"] {
            throw CDPConnection.Failure(description: exception["text"]?.stringValue ?? "JavaScript hatası")
        }
        return result["result"]?["value"]
    }

    /// Tallest full-page capture, in CSS px (same limit as WebKit).
    static let maxFullPageHeight = 32_000

    public func snapshot(_ area: SnapshotArea) async throws -> CGImage {
        try await setup?.value
        var params: [String: Any] = ["format": "png"]
        if area == .fullPage {
            let metrics = try await send("Page.getLayoutMetrics")
            let width = metrics["cssContentSize"]?["width"]?.numberValue ?? Double(size.width)
            let height = min(metrics["cssContentSize"]?["height"]?.numberValue ?? Double(size.height), Double(Self.maxFullPageHeight))
            params["captureBeyondViewport"] = true
            params["clip"] = ["x": 0, "y": 0, "width": max(width, Double(size.width)), "height": height, "scale": 1]
        }
        let result = try await send("Page.captureScreenshot", params)
        guard let base64 = result["data"]?.stringValue, let data = Data(base64Encoded: base64),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw CDPConnection.Failure(description: "ekran görüntüsü alınamadı")
        }
        return image
    }

    public func setMediaPlaybackSuspended(_ suspended: Bool) {
        guard suspended != mediaSuspended else { return }
        mediaSuspended = suspended
        let script = suspended
            ? "document.querySelectorAll('video,audio').forEach(m => { m.dataset.vpxWasPlaying = String(!m.paused); m.pause(); })"
            : "document.querySelectorAll('video,audio').forEach(m => { if (m.dataset.vpxWasPlaying === 'true') m.play().catch(() => {}); })"
        whenReady { _ = try? await self.send("Runtime.evaluate", ["expression": script]) }
    }

    /// Chromium can only skip certificate checks browser-wide (every Chromium viewport, this run).
    public func trustCertificates(forHost host: String) {
        whenReady { try await self.connection?.send("Security.setIgnoreCertificateErrors", ["ignore": true]) }
    }

    public func setDeveloperLogging(_ enabled: Bool) {
        logsDeveloperMessages = enabled
    }

    // MARK: Input (from ChromiumView)

    func dispatchMouse(_ type: String, at point: CGPoint, button: String, clicks: Int, modifiers: Int) {
        post("Input.dispatchMouseEvent", ["type": type, "x": point.x, "y": point.y, "button": button,
                                          "clickCount": clicks, "modifiers": modifiers])
    }

    func dispatchWheel(at point: CGPoint, dx: Double, dy: Double, modifiers: Int) {
        post("Input.dispatchMouseEvent", ["type": "mouseWheel", "x": point.x, "y": point.y, "deltaX": dx, "deltaY": dy, "modifiers": modifiers])
    }

    func dispatchKey(_ params: [String: Any]) {
        post("Input.dispatchKeyEvent", params)
    }

    func insertText(_ text: String) {
        post("Input.insertText", ["text": text])
    }

    func editCommand(_ command: String) {
        post("Input.dispatchKeyEvent", ["type": "rawKeyDown", "commands": [command], "modifiers": 4])
    }

    /// The page's selection, for Kopyala.
    func selectedText() async -> String? {
        try? await evaluate("String(getSelection())")?.stringValue
    }

    var cssSize: CGSize { CGSize(width: size.width, height: size.height) }
}
