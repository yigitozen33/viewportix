// S5 — Does a CDP screencast feel live? (PLAN.md §5.1)
//
// Launches the installed Chrome headless with a throwaway profile, opens N viewports (one CDP target
// each, device metrics overridden to a phone/tablet/desktop size at DPR 2), streams them with
// Page.startScreencast into NSImageViews, and forwards mouse, wheel and keys from the views with
// Input.dispatch*. `--self-test` measures: launch → first frame, frames per second while scrolling,
// input → first changed frame latency, frame size vs. the view (retina), and N viewports at once.
import AppKit
import Foundation

// MARK: - CDP connection

/// One WebSocket to the browser; page sessions are multiplexed with `sessionId` (flatten mode).
@MainActor
final class CDP {
    private let task: URLSessionWebSocketTask
    private var nextID = 1
    var lastMethod = ""
    private var pending: [Int: CheckedContinuation<[String: Any], Error>] = [:]
    var onEvent: ((_ method: String, _ params: [String: Any], _ sessionID: String?) -> Void)?

    struct Failure: Error, CustomStringConvertible { let description: String }

    init(url: URL) {
        let session = URLSession(configuration: .default)
        task = session.webSocketTask(with: url)
        task.maximumMessageSize = 64 * 1024 * 1024  // screencast frames are big
        task.resume()
        receive()
    }

    @discardableResult
    func send(_ method: String, _ params: [String: Any] = [:], session: String? = nil) async throws -> [String: Any] {
        let id = nextID
        nextID += 1
        lastMethod = method
        var message: [String: Any] = ["id": id, "method": method, "params": params]
        if let session { message["sessionId"] = session }
        let data = try JSONSerialization.data(withJSONObject: message)
        return try await withCheckedThrowingContinuation { continuation in
            pending[id] = continuation
            task.send(.string(String(decoding: data, as: UTF8.self))) { error in
                if let error {
                    Task { @MainActor in self.pending.removeValue(forKey: id)?.resume(throwing: error) }
                }
            }
        }
    }

    /// Fire and forget (screencast acks, input during a burst).
    func post(_ method: String, _ params: [String: Any] = [:], session: String? = nil) {
        Task { try? await send(method, params, session: session) }
    }

    private func receive() {
        task.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .failure(let error):
                    for continuation in self.pending.values { continuation.resume(throwing: error) }
                    self.pending = [:]
                case .success(let message):
                    let data: Data
                    switch message {
                    case .string(let text): data = Data(text.utf8)
                    case .data(let bytes): data = bytes
                    @unknown default: data = Data()
                    }
                    if let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                        self.handle(object)
                    }
                    self.receive()
                }
            }
        }
    }

    private func handle(_ object: [String: Any]) {
        if let id = object["id"] as? Int, let continuation = pending.removeValue(forKey: id) {
            if let error = object["error"] as? [String: Any] {
                continuation.resume(throwing: Failure(description: "\(error["message"] ?? error) (id \(id))"))
            } else {
                continuation.resume(returning: object["result"] as? [String: Any] ?? [:])
            }
        } else if let method = object["method"] as? String {
            onEvent?(method, object["params"] as? [String: Any] ?? [:], object["sessionId"] as? String)
        }
    }
}

// MARK: - Chrome

enum Chrome {
    static let candidates = [
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Chromium.app/Contents/MacOS/Chromium",
        "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
        "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
    ]

    /// Starts headless Chrome on a free port with a throwaway profile; returns the process and the
    /// browser WebSocket URL (read from DevToolsActivePort).
    static func launch() async throws -> (Process, URL) {
        guard let path = candidates.first(where: FileManager.default.isExecutableFile(atPath:)) else {
            throw CDP.Failure(description: "Chrome bulunamadı")
        }
        let profile = FileManager.default.temporaryDirectory.appending(path: "viewportix-s5-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: profile, withIntermediateDirectories: true)
        let process = Process()
        process.executableURL = URL(filePath: path)
        process.arguments = [
            "--headless=new", "--remote-debugging-port=0", "--user-data-dir=\(profile.path)",
            "--no-first-run", "--no-default-browser-check", "--disable-extensions", "--hide-scrollbars",
            "--mute-audio", "--force-device-scale-factor=2", "--disable-background-networking", "--disable-component-update",
            "--disable-background-timer-throttling", "--disable-renderer-backgrounding",
            "--disable-backgrounding-occluded-windows", "about:blank",
        ]
        process.standardError = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        try process.run()
        let portFile = profile.appending(path: "DevToolsActivePort")
        for _ in 0..<200 {
            if let text = try? String(contentsOf: portFile, encoding: .utf8) {
                let lines = text.split(separator: "\n")
                if lines.count >= 2 { return (process, URL(string: "ws://127.0.0.1:\(lines[0])\(lines[1])")!) }
            }
            try await Task.sleep(for: .milliseconds(25))
        }
        process.terminate()
        throw CDP.Failure(description: "DevToolsActivePort gelmedi")
    }
}

// MARK: - One viewport

@MainActor
final class Viewport {
    let name: String
    let width: Int
    let height: Int
    let mobile: Bool
    let view: FrameView
    var session: String?
    let cdp: CDP

    // Measurements
    var frames: [CFTimeInterval] = []
    var lastFrameSize = CGSize.zero
    var decodeTime: CFTimeInterval = 0
    var frameBytes = 0
    var firstFrameAt: CFTimeInterval?
    var inputSentAt: CFTimeInterval?
    var latencies: [CFTimeInterval] = []

    init(name: String, width: Int, height: Int, mobile: Bool, cdp: CDP, scale: CGFloat) {
        self.name = name
        self.width = width
        self.height = height
        self.mobile = mobile
        self.cdp = cdp
        view = FrameView(frame: NSRect(x: 0, y: 0, width: CGFloat(width) * scale, height: CGFloat(height) * scale))
        view.viewport = self
    }

    /// `--cap`: frames no larger than the card shows them (view points × 2 for retina); else full 2×.
    var maxFrame: (width: Int, height: Int) {
        CommandLine.arguments.contains("--cap")
            ? (min(width * 2, Int(view.frame.width * 2)), min(height * 2, Int(view.frame.height * 2)))
            : (width * 2, height * 2)
    }

    func open(_ url: String) async throws {
        // Own window per viewport: headless Chrome only paints (and streams) the front tab of a window.
        let target = try await cdp.send("Target.createTarget", ["url": "about:blank", "newWindow": true])
        let targetID = target["targetId"] as! String
        let attached = try await cdp.send("Target.attachToTarget", ["targetId": targetID, "flatten": true])
        session = attached["sessionId"] as? String
        print("S5 attached \(name): \(session ?? "nil")")
        try await cdp.send("Page.enable", session: session)
        // Every viewport behaves as focused (focus/blur, :focus styles, timers not throttled).
        try await cdp.send("Emulation.setFocusEmulationEnabled", ["enabled": true], session: session)
        try await cdp.send("Emulation.setDeviceMetricsOverride",
                           ["width": width, "height": height, "deviceScaleFactor": 2, "mobile": mobile], session: session)
        if mobile {
            try await cdp.send("Emulation.setTouchEmulationEnabled", ["enabled": true, "maxTouchPoints": 5], session: session)
            try await cdp.send("Emulation.setUserAgentOverride", ["userAgent":
                "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"],
                               session: session)
        }
        try await cdp.send("Page.startScreencast", [
            "format": "jpeg", "quality": 80, "everyNthFrame": 1,
            "maxWidth": maxFrame.width, "maxHeight": maxFrame.height,
        ], session: session)
        // Started on about:blank: starting during a cross-site navigation fails ("Not attached to an active page").
        try await cdp.send("Page.navigate", ["url": url], session: session)
    }

    func frame(_ params: [String: Any]) {
        let now = CACurrentMediaTime()
        if let ack = params["sessionId"] as? Int {
            cdp.post("Page.screencastFrameAck", ["sessionId": ack], session: session)
        }
        guard let base64 = params["data"] as? String, let data = Data(base64Encoded: base64) else { return }
        let start = CACurrentMediaTime()
        guard let image = NSImage(data: data) else { return }
        view.image = image
        decodeTime += CACurrentMediaTime() - start
        frameBytes = data.count
        if let rep = image.representations.first { lastFrameSize = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh) }
        frames.append(now)
        if firstFrameAt == nil { firstFrameAt = now }
        if let sent = inputSentAt {
            latencies.append(now - sent)
            inputSentAt = nil
        }
    }

    // MARK: Input (view points → CSS px)

    func cssPoint(_ point: NSPoint) -> (Double, Double) {
        let x = point.x / view.bounds.width * CGFloat(width)
        let y = (view.bounds.height - point.y) / view.bounds.height * CGFloat(height)
        return (Double(x), Double(y))
    }

    func mouse(_ type: String, at point: NSPoint, button: String = "left", clicks: Int = 1) {
        let (x, y) = cssPoint(point)
        cdp.post("Input.dispatchMouseEvent", ["type": type, "x": x, "y": y, "button": button, "clickCount": clicks], session: session)
    }

    func wheel(at point: NSPoint, dx: Double, dy: Double) {
        let (x, y) = cssPoint(point)
        inputSentAt = inputSentAt ?? CACurrentMediaTime()
        cdp.post("Input.dispatchMouseEvent", ["type": "mouseWheel", "x": x, "y": y, "deltaX": dx, "deltaY": dy], session: session)
    }

    /// macOS key codes are not Windows virtual key codes (Chrome's `windowsVirtualKeyCode`): "m" is 46
    /// on the Mac, which Chrome reads as VK_DELETE. Letters and digits use their upper-case ASCII,
    /// the rest a small table.
    static let virtualKeys: [UInt16: (vk: Int, key: String, code: String)] = [
        36: (13, "Enter", "Enter"), 48: (9, "Tab", "Tab"), 51: (8, "Backspace", "Backspace"), 53: (27, "Escape", "Escape"),
        117: (46, "Delete", "Delete"), 123: (37, "ArrowLeft", "ArrowLeft"), 124: (39, "ArrowRight", "ArrowRight"),
        125: (40, "ArrowDown", "ArrowDown"), 126: (38, "ArrowUp", "ArrowUp"), 49: (32, " ", "Space"),
    ]

    func key(_ event: NSEvent, down: Bool) {
        let text = event.characters ?? ""
        var params: [String: Any] = ["type": down ? (text.isEmpty ? "rawKeyDown" : "keyDown") : "keyUp"]
        if let special = Self.virtualKeys[event.keyCode] {
            params["windowsVirtualKeyCode"] = special.vk
            params["key"] = special.key
            params["code"] = special.code
        } else if let scalar = event.charactersIgnoringModifiers?.uppercased().unicodeScalars.first, scalar.isASCII {
            params["windowsVirtualKeyCode"] = Int(scalar.value)
            params["key"] = event.charactersIgnoringModifiers ?? ""
        } else {
            params["key"] = event.charactersIgnoringModifiers ?? ""
        }
        if down, !text.isEmpty, text.unicodeScalars.allSatisfy({ $0.value >= 32 && $0.value != 127 }) { params["text"] = text }
        if down, event.keyCode == 36 { params["text"] = "\r" }
        cdp.post("Input.dispatchKeyEvent", params, session: session)
    }
}

/// Shows the frames; turns AppKit input into CDP input.
final class FrameView: NSImageView {
    weak var viewport: Viewport?

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        MainActor.assumeIsolated { viewport?.mouse("mousePressed", at: point, clicks: event.clickCount) }
    }
    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        MainActor.assumeIsolated { viewport?.mouse("mouseReleased", at: point, clicks: event.clickCount) }
    }
    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        MainActor.assumeIsolated { viewport?.mouse("mouseMoved", at: point, button: "none") }
    }
    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        MainActor.assumeIsolated { viewport?.mouse("mouseMoved", at: point) }
    }
    override func scrollWheel(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        MainActor.assumeIsolated { viewport?.wheel(at: point, dx: -event.scrollingDeltaX, dy: -event.scrollingDeltaY) }
    }
    override func keyDown(with event: NSEvent) { MainActor.assumeIsolated { viewport?.key(event, down: true) } }
    override func keyUp(with event: NSEvent) { MainActor.assumeIsolated { viewport?.key(event, down: false) } }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect], owner: self))
    }
}

// MARK: - App

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var chrome: Process?
    var cdp: CDP!
    var viewports: [Viewport] = []
    let selfTest = CommandLine.arguments.contains("--self-test")
    let url = CommandLine.arguments.first { $0.hasPrefix("http") || $0.hasPrefix("file:") }
        ?? "http://localhost:8765/long-page.html"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Canvas zoom (`--zoom=0.3`).
        let scale = CommandLine.arguments.first { $0.hasPrefix("--zoom=") }.flatMap { Double($0.dropFirst(7)) }.map { CGFloat($0) } ?? 0.3
        window = NSWindow(contentRect: NSRect(x: 80, y: 80, width: 1500, height: 900), styleMask: [.titled, .closable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "S5 · CDP screencast"
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .top
        stack.spacing = 24
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        window.contentView = stack
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()

        Task {
            do {
                let launchStart = CACurrentMediaTime()
                let (process, socket) = try await Chrome.launch()
                chrome = process
                cdp = CDP(url: socket)
                cdp.onEvent = { [weak self] method, params, session in
                    guard method == "Page.screencastFrame", let viewport = self?.viewports.first(where: { $0.session == session }) else { return }
                    viewport.frame(params)
                }
                let sizes = [("iPhone 16", 393, 852, true), ("iPad Air 11\"", 820, 1180, true), ("Masaüstü", 1440, 900, false), ("Full HD", 1920, 1080, false)]
                for (name, width, height, mobile) in sizes {
                    let viewport = Viewport(name: name, width: width, height: height, mobile: mobile, cdp: cdp, scale: scale)
                    viewports.append(viewport)
                    stack.addArrangedSubview(viewport.view)
                    viewport.view.widthAnchor.constraint(equalToConstant: viewport.view.frame.width).isActive = true
                    viewport.view.heightAnchor.constraint(equalToConstant: viewport.view.frame.height).isActive = true
                    try await viewport.open(url)
                }
                if selfTest { try await runSelfTest(launchStart: launchStart) }
            } catch {
                print("S5 HATA: \(error)")
                if selfTest { quit() }
            }
        }
    }

    // MARK: Self-test

    func runSelfTest(launchStart: CFTimeInterval) async throws {
        try await Task.sleep(for: .seconds(3))  // pages load and settle
        let firsts = viewports.compactMap { $0.firstFrameAt.map { ($0 - launchStart) * 1000 } }
        print(String(format: "SELF-TEST launch→first frame: %.0f ms (en geç viewport)", firsts.max() ?? -1))
        for viewport in viewports {
            print("SELF-TEST \(viewport.name): frame \(Int(viewport.lastFrameSize.width))×\(Int(viewport.lastFrameSize.height)) px, "
                + "view \(Int(viewport.view.frame.width))×\(Int(viewport.view.frame.height)) pt, jpeg \(viewport.frameBytes / 1024) KB")
        }

        // 1) One viewport scrolls: 60 wheel events over ~1 s (a trackpad flick).
        try await scroll(viewports, only: [viewports[0]], label: "1 viewport kayıyor")
        // 2) All of them scroll at once (sync: the followers scroll too).
        try await scroll(viewports, only: viewports, label: "4 viewport birlikte kayıyor")

        // 3) Click → first changed frame: open a details element / focus a field at the top.
        let viewport = viewports[0]
        try await cdp.send("Runtime.evaluate", ["expression": "scrollTo(0,0)"], session: viewport.session)
        try await Task.sleep(for: .milliseconds(500))
        var clicks: [CFTimeInterval] = []
        for i in 0..<5 {
            viewport.latencies = []
            viewport.inputSentAt = CACurrentMediaTime()
            let color = i % 2 == 0 ? "tomato" : "white"
            try await cdp.send("Runtime.evaluate", ["expression": "document.body.style.background='\(color)'"], session: viewport.session)
            try await Task.sleep(for: .milliseconds(400))
            if let latency = viewport.latencies.first { clicks.append(latency) }
        }
        print(String(format: "SELF-TEST değişiklik→kare gecikmesi (5 ölçüm): ort %.0f ms, en çok %.0f ms", average(clicks) * 1000, (clicks.max() ?? 0) * 1000))

        // 4) Keep a frame to look at sharpness.
        if let image = viewports[0].view.image, let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            let url = URL(filePath: CommandLine.arguments.first { $0.hasPrefix("--frame=") }.map { String($0.dropFirst(8)) } ?? "/tmp/s5-frame.png")
            try png.write(to: url)
            print("SELF-TEST kare kaydedildi: \(url.path)")
        }
        let decode = viewports.map { $0.decodeTime / Double(max($0.frames.count, 1)) * 1000 }
        print(String(format: "SELF-TEST JPEG çözme ort: %.1f ms / kare", average(decode)))
        print("SELF-TEST CPU (Chrome süreçleri, %): \(chromeCPU())")
        print("SELF-TEST bitti")
        quit()
    }

    func scroll(_ all: [Viewport], only scrolling: [Viewport], label: String) async throws {
        for viewport in all {
            try await cdp.send("Runtime.evaluate", ["expression": "scrollTo(0,0)"], session: viewport.session)
        }
        try await Task.sleep(for: .milliseconds(600))
        for viewport in all { viewport.frames = []; viewport.latencies = []; viewport.inputSentAt = nil }
        let start = CACurrentMediaTime()
        for _ in 0..<60 {
            for viewport in scrolling {
                viewport.wheel(at: NSPoint(x: viewport.view.bounds.midX, y: viewport.view.bounds.midY), dx: 0, dy: 25)
            }
            try await Task.sleep(for: .milliseconds(16))
        }
        let end = CACurrentMediaTime()
        try await Task.sleep(for: .milliseconds(300))
        for viewport in scrolling {
            let during = viewport.frames.filter { $0 >= start && $0 <= end + 0.1 }
            let fps = Double(during.count) / (end - start + 0.1)
            let gaps = zip(during.dropFirst(), during).map { $0 - $1 }
            let first = viewport.latencies.first.map { $0 * 1000 } ?? -1
            print(String(format: "SELF-TEST %@ · %@: %.0f fps, en uzun boşluk %.0f ms, ilk tepki %.0f ms",
                         label, viewport.name, fps, (gaps.max() ?? 0) * 1000, first))
        }
    }

    func average(_ values: [Double]) -> Double { values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count) }

    func chromeCPU() -> String {
        let ps = Process()
        ps.executableURL = URL(filePath: "/bin/ps")
        ps.arguments = ["-A", "-o", "%cpu=,command="]
        let pipe = Pipe()
        ps.standardOutput = pipe
        try? ps.run()
        ps.waitUntilExit()
        let text = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let total = text.split(separator: "\n").filter { $0.contains("viewportix-s5-") }.compactMap { Double($0.split(separator: " ").first ?? "") }.reduce(0, +)
        return String(format: "%.0f", total)
    }

    func quit() {
        chrome?.terminate()
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        chrome?.terminate()
    }
}

setvbuf(stdout, nil, _IOLBF, 0)
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
}
