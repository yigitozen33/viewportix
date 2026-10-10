import AppKit
import WebKit

/// Drives the canvas with synthetic events and checks the gesture rules that can be automated.
/// Pinch cannot be synthesized and stays a manual check (see README).
@MainActor
final class SelfTest {
    private let canvas: CanvasController
    private var failures = 0
    private let startTime = ProcessInfo.processInfo.systemUptime

    init(canvas: CanvasController) {
        self.canvas = canvas
    }

    func run() async -> Bool {
        guard let window = canvas.view.window else { return false }

        // An inactive app's first click only activates the window, so wait for focus.
        for _ in 0..<100 where !(NSApp.isActive && window.isKeyWindow) {
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard NSApp.isActive, window.isKeyWindow else {
            print("FAIL  app never became active; launch it with `open` so macOS grants focus")
            return false
        }

        // 1. Clicks land on the right element at every zoom level.
        await canvas.loadAll(Fixtures.spa)
        for zoom in [1.0, 0.5, 0.3] {
            canvas.setZoom(zoom, anchor: canvas.viewCenterInWindow)
            for card in canvas.cards {
                await checkClick(on: card, zoom: zoom, window: window)
            }
        }

        // 2. Scroll routing at 50%. Scroll events cannot be bound to a window without the window server,
        // so park the window at the screen origin: then screen and window coordinates coincide.
        window.setFrameOrigin(.zero)
        await canvas.loadAll(Fixtures.longPage)
        canvas.setZoom(0.5, anchor: canvas.viewCenterInWindow)
        // Start from the canvas origin so the phone and the gap after it are on screen.
        canvas.scrollView.contentView.scroll(to: .zero)
        canvas.scrollView.reflectScrolledClipView(canvas.scrollView.contentView)
        await checkScrollRouting(window: window)

        print(failures == 0 ? "S1 SELF-TEST: ALL PASSED" : "S1 SELF-TEST: \(failures) FAILED")
        return failures == 0
    }

    // MARK: Clicks

    private func checkClick(on card: CardView, zoom: Double, window: NSWindow) async {
        let label = "click @\(Int(zoom * 100))% \(card.name)"
        guard let center = try? await card.webView.evaluateJavaScript(
            "(() => { const r = document.querySelector('#add-to-cart').getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height / 2]; })()"
        ) as? [Double], center.count == 2 else {
            return record(label, passed: false, detail: "target not found")
        }

        let webPoint = NSPoint(x: center[0], y: card.webView.isFlipped ? center[1] : card.webView.bounds.height - center[1])
        // Bring the target on screen; hit testing only works for visible points.
        canvas.documentView.scrollToVisible(NSRect(origin: card.webView.convert(webPoint, to: canvas.documentView), size: .zero).insetBy(dx: -80, dy: -80))
        try? await Task.sleep(for: .milliseconds(100))

        let windowPoint = card.webView.convert(webPoint, to: nil)
        card.lastClick = nil
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = NSEvent.mouseEvent(
                with: type, location: windowPoint, modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseDown ? 1 : 0
            )!
            NSApp.sendEvent(event)
        }

        for _ in 0..<40 where card.lastClick == nil {
            try? await Task.sleep(for: .milliseconds(50))
        }
        guard let click = card.lastClick else {
            let hit = window.contentView?.hitTest(windowPoint).map { String(describing: type(of: $0)) } ?? "nil"
            return record(label, passed: false, detail: "no click reached the page (hit \(hit), key \(window.isKeyWindow), active \(NSApp.isActive), t=\(String(format: "%.1f", ProcessInfo.processInfo.systemUptime - startTime))s)")
        }
        let error = max(abs(click.x - center[0]), abs(click.y - center[1]))
        record(label, passed: click.target == "#add-to-cart" && error <= 3,
               detail: "\(click.target), off by \(String(format: "%.1f", error))px")
    }

    // MARK: Scrolling

    private func checkScrollRouting(window: NSWindow) async {
        let phone = canvas.cards[1]
        let pageCenter = phone.webView.convert(NSPoint(x: phone.webView.bounds.midX, y: phone.webView.bounds.midY), to: nil)
        let gap = NSPoint(
            x: (canvas.cards[1].convert(canvas.cards[1].bounds, to: nil).maxX + canvas.cards[2].convert(canvas.cards[2].bounds, to: nil).minX) / 2,
            y: pageCenter.y
        )

        // A: vertical scroll over a viewport scrolls the page, not the canvas.
        var before = await snapshot(phone)
        await postScroll(at: pageCenter, dy: -300, dx: 0, command: false, window: window)
        var after = await snapshot(phone)
        record("scroll over viewport → page", passed: after.pageY > before.pageY && after.canvas == before.canvas,
               detail: "pageY \(Int(before.pageY))→\(Int(after.pageY)), canvas \(before.canvas)→\(after.canvas)")

        // C (scroll a page cannot use must not leak into a canvas pan) is manual only: with CardView's
        // guard disabled the synthetic version still passed, so it does not exercise WebKit's hand-back.
        print("SKIP  unusable scroll over viewport → no canvas pan  —  not reproducible synthetically; manual check")

        // B: horizontal scroll over empty canvas pans the canvas.
        before = after
        await postScroll(at: gap, dy: 0, dx: -300, command: false, window: window)
        after = await snapshot(phone)
        record("scroll over gap → canvas pan", passed: after.canvas.x != before.canvas.x,
               detail: "canvas \(before.canvas)→\(after.canvas)")

        // D: ⌘-scroll over a viewport zooms the canvas and leaves the page alone.
        let pageCenterNow = phone.webView.convert(NSPoint(x: phone.webView.bounds.midX, y: phone.webView.bounds.midY), to: nil)
        before = after
        await postScroll(at: pageCenterNow, dy: -100, dx: 0, command: true, window: window)
        after = await snapshot(phone)
        record("⌘scroll over viewport → canvas zoom", passed: after.zoom != before.zoom && after.pageY == before.pageY,
               detail: "zoom \(before.zoom)→\(after.zoom), pageY \(Int(before.pageY))→\(Int(after.pageY))")
    }

    private struct Snapshot: Equatable {
        let pageY: Double
        let canvas: NSPoint
        let zoom: CGFloat
    }

    private func snapshot(_ card: CardView) async -> Snapshot {
        let pageY = (try? await card.webView.evaluateJavaScript("window.scrollY") as? Double) ?? -1
        return Snapshot(pageY: pageY, canvas: canvas.scrollView.contentView.bounds.origin, zoom: canvas.scrollView.magnification)
    }

    /// Builds a pixel-unit scroll event and replays what NSApplication does with it: local monitor first
    /// (the canvas router), then window dispatch. Posting through the system event queue would need
    /// Accessibility permission. Requires the window at the screen origin (see `run`).
    private func postScroll(at windowPoint: NSPoint, dy: Int32, dx: Int32, command: Bool, window: NSWindow) async {
        let screenPoint = window.convertPoint(toScreen: windowPoint)
        let primaryHeight = NSScreen.screens[0].frame.height
        guard let cgEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: dy, wheel2: dx, wheel3: 0) else { return }
        cgEvent.location = CGPoint(x: screenPoint.x, y: primaryHeight - screenPoint.y)
        if command { cgEvent.flags = .maskCommand }
        guard let event = NSEvent(cgEvent: cgEvent) else { return }
        if event.locationInWindow != windowPoint {
            print("DEBUG scroll location mismatch: event \(event.locationInWindow), wanted \(windowPoint)")
        }
        if let delivered = canvas.route(event) {
            window.sendEvent(delivered)
        }
        try? await Task.sleep(for: .milliseconds(600))
    }

    // MARK: Reporting

    private func record(_ label: String, passed: Bool, detail: String) {
        if !passed { failures += 1 }
        print("\(passed ? "PASS" : "FAIL")  \(label)  —  \(detail)")
    }
}
