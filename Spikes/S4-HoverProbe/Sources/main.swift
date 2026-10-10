// S4: can a synthetic mouseMoved make CSS :hover apply in a WKWebView the real pointer is not over?
// Two web views side by side; the pointer stays elsewhere. Tries three delivery paths and prints results.
import AppKit
import WebKit

final class Probe: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let left = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
    let right = WKWebView(frame: NSRect(x: 620, y: 0, width: 600, height: 500))

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 1220, height: 500), styleMask: [.titled], backing: .buffered, defer: false)
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 1220, height: 500))
        for view in [left, right] {
            view.configuration.websiteDataStore = .nonPersistent()
            view.loadHTMLString("""
                <style>button{margin:120px;padding:20px} button:hover{background:rgb(255,0,0)}</style>
                <button id="b">Hover me</button>
                """, baseURL: nil)
            root.addSubview(view)
        }
        window.contentView = root
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        Task { @MainActor in await self.run() }
    }

    @MainActor func hovered(_ view: WKWebView) async -> Bool {
        (try? await view.evaluateJavaScript("document.getElementById('b').matches(':hover')")) as? Bool == true
    }

    @MainActor func event(_ view: WKWebView, _ point: NSPoint) -> NSEvent {
        NSEvent.mouseEvent(with: .mouseMoved, location: view.convert(point, to: nil), modifierFlags: [],
                           timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                           context: nil, eventNumber: 0, clickCount: 0, pressure: 0)!
    }

    @MainActor func run() async {
        for _ in 0..<100 where !(NSApp.isActive && window.isKeyWindow) { try? await Task.sleep(for: .milliseconds(100)) }
        try? await Task.sleep(for: .seconds(1))
        print("active=\(NSApp.isActive) key=\(window.isKeyWindow) flipped=\(right.isFlipped)")
        guard let rect = try? await right.evaluateJavaScript("(() => { const r = document.getElementById('b').getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height / 2]; })()") as? [Double] else { print("no rect"); exit(1) }
        let point = NSPoint(x: rect[0], y: right.isFlipped ? rect[1] : right.bounds.height - rect[1])
        let outside = NSPoint(x: -1, y: -1)

        // Variant: announce the pointer entering the view first (WebKit tracks mouse-inside state).
        if let enter = NSEvent.enterExitEvent(with: .mouseEntered, location: right.convert(point, to: nil), modifierFlags: [],
                                              timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                                              context: nil, eventNumber: 0, trackingNumber: 0, userData: nil) {
            right.mouseEntered(with: enter)
            right.mouseMoved(with: event(right, point))
            try? await Task.sleep(for: .milliseconds(400))
            print("mouseEntered+mouseMoved: hover=\(await hovered(right))")
            right.mouseMoved(with: event(right, outside))
            try? await Task.sleep(for: .milliseconds(300))
        }
        // Variant: a drag-less mouse down/up pair is a full hit test; does it leave :hover behind?
        let paths: [(String, (NSEvent) -> Void)] = [
            ("view.mouseMoved", { self.right.mouseMoved(with: $0) }),
            ("window.sendEvent", { self.window.sendEvent($0) }),
            ("NSApp.sendEvent", { NSApp.sendEvent($0) }),
        ]
        for (name, deliver) in paths {
            deliver(event(right, point))
            try? await Task.sleep(for: .milliseconds(400))
            let on = await hovered(right)
            deliver(event(right, outside))
            try? await Task.sleep(for: .milliseconds(400))
            let off = await hovered(right)
            print("\(name): hover=\(on) cleared=\(!off) leftUntouched=\(!(await hovered(left)))")
        }
        exit(0)
    }
}

let app = NSApplication.shared
let probe = Probe()
app.delegate = probe
app.setActivationPolicy(.regular)
app.run()
