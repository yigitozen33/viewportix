import AppKit
import WebKit

final class CanvasDocumentView: NSView {
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    /// Clicking empty canvas takes keyboard focus away from web pages, so Space pans again.
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }
}

/// Zoomable canvas of live viewports.
///
/// Gesture rules under test (PLAN.md 3.4):
/// - two-finger scroll over a viewport scrolls the page; over empty canvas it pans the canvas
/// - pinch and ⌘-scroll always zoom the canvas, never the page
/// - Space + drag pans the canvas (unless a web page has keyboard focus)
/// - ⌘0 100%, ⌘1 fit, ⌘= / ⌘- zoom in/out
final class CanvasController: NSViewController {
    let scrollView = NSScrollView()
    let documentView = CanvasDocumentView()
    private(set) var cards: [CardView] = []

    private let urlField = NSTextField()
    private let hud = NSTextField(labelWithString: "")
    private var lastEvent = "—"
    private var monitor: Any?
    private var spaceHeld = false
    private var panStart: (mouse: NSPoint, origin: NSPoint)?

    private static let devices: [(name: String, width: CGFloat, height: CGFloat, mobile: Bool)] = [
        ("iPhone SE", 375, 667, true),
        ("iPhone 16", 393, 852, true),
        ("iPad Air 11\"", 820, 1180, false),  // iPadOS Safari sends a desktop UA by default
        ("Dizüstü", 1280, 800, false),
        ("Masaüstü", 1440, 900, false),
    ]
    private static let mobileUserAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"
    private static let margin: CGFloat = 64
    private static let gap: CGFloat = 48

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 1400, height: 900))

        urlField.placeholderString = "URL — Enter loads it in every viewport"
        urlField.target = self
        urlField.action = #selector(urlEntered)

        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.1
        scrollView.maxMagnification = 2
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .underPageBackgroundColor
        scrollView.documentView = documentView

        hud.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        hud.textColor = .white
        hud.drawsBackground = true
        hud.backgroundColor = NSColor.black.withAlphaComponent(0.75)

        for view in [urlField, scrollView, hud] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            urlField.topAnchor.constraint(equalTo: root.topAnchor, constant: 8),
            urlField.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
            urlField.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
            scrollView.topAnchor.constraint(equalTo: urlField.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            hud.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
            hud.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8),
        ])
        view = root
        layoutCards()

        NotificationCenter.default.addObserver(
            forName: NSScrollView.didEndLiveMagnifyNotification, object: scrollView, queue: .main
        ) { [weak self] _ in self?.refreshHUD() }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.scrollWheel, .magnify, .keyDown, .keyUp, .leftMouseDown, .leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            guard let self, event.window === self.view.window else { return event }
            return self.route(event)
        }
    }

    // MARK: Layout and loading

    private func layoutCards() {
        var x = Self.margin
        var maxHeight: CGFloat = 0
        for device in Self.devices {
            let card = CardView(
                name: device.name,
                size: NSSize(width: device.width, height: device.height),
                userAgent: device.mobile ? Self.mobileUserAgent : nil
            )
            card.frame.origin = NSPoint(x: x, y: Self.margin)
            card.onClick = { [weak self] card, click in
                self?.log("click \(card.name) → \(click.target) (\(Int(click.x)), \(Int(click.y)))")
            }
            documentView.addSubview(card)
            cards.append(card)
            x += device.width + Self.gap
            maxHeight = max(maxHeight, card.frame.height)
        }
        documentView.frame = NSRect(x: 0, y: 0, width: x - Self.gap + Self.margin, height: maxHeight + 2 * Self.margin)
    }

    func loadAll(_ url: URL) async {
        urlField.stringValue = url.absoluteString
        cards.forEach { $0.load(url) }
        for _ in 0..<200 where !cards.allSatisfy(\.isLoaded) {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    @objc private func urlEntered() {
        var text = urlField.stringValue.trimmingCharacters(in: .whitespaces)
        if !text.contains("://") { text = "https://" + text }
        guard let url = URL(string: text) else { return }
        Task { await loadAll(url) }
    }

    // MARK: Zoom

    var viewCenterInWindow: NSPoint {
        scrollView.convert(NSPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY), to: nil)
    }

    /// Sets the zoom while keeping the document point under `anchor` (window coordinates) in place.
    func setZoom(_ value: CGFloat, anchor: NSPoint) {
        let clamped = min(max(value, scrollView.minMagnification), scrollView.maxMagnification)
        let before = documentView.convert(anchor, from: nil)
        scrollView.magnification = clamped
        let after = documentView.convert(anchor, from: nil)
        let clip = scrollView.contentView
        var bounds = clip.bounds
        bounds.origin.x += before.x - after.x
        bounds.origin.y += before.y - after.y
        clip.scroll(to: clip.constrainBoundsRect(bounds).origin)
        scrollView.reflectScrolledClipView(clip)
        refreshHUD()
    }

    func fit() {
        scrollView.magnify(toFit: documentView.bounds)
        refreshHUD()
    }

    // MARK: Event routing

    /// Returns the event to let AppKit deliver it normally, or nil when the canvas consumed it.
    func route(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .magnify:
            // Always the canvas: hand the gesture to NSScrollView's own anchored, phase-aware pinch.
            scrollView.magnify(with: event)
            log("pinch → canvas zoom")
            return nil

        case .scrollWheel:
            if event.modifierFlags.contains(.command) {
                let step = event.hasPreciseScrollingDeltas ? 0.01 : 0.1
                setZoom(scrollView.magnification * exp(event.scrollingDeltaY * step), anchor: event.locationInWindow)
                log("⌘scroll → canvas zoom")
                return nil
            }
            if let card = card(at: event.locationInWindow), !card.isHeader(windowPoint: event.locationInWindow) {
                log("scroll → page (\(card.name))")
            } else {
                log("scroll → canvas pan")
            }
            return event

        case .keyDown:
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
                switch event.charactersIgnoringModifiers {
                case "0": setZoom(1, anchor: viewCenterInWindow); return nil
                case "1": fit(); return nil
                case "=", "+": setZoom(scrollView.magnification * 1.25, anchor: viewCenterInWindow); return nil
                case "-": setZoom(scrollView.magnification / 1.25, anchor: viewCenterInWindow); return nil
                default: return event
                }
            }
            if event.keyCode == 49 {  // Space
                if spaceHeld { return nil }  // swallow key repeat
                if firstResponderIsWebContent { return event }  // typing or page scrolling
                spaceHeld = true
                NSCursor.openHand.push()
                log("space → hand tool")
                return nil
            }
            return event

        case .keyUp:
            if event.keyCode == 49, spaceHeld {
                spaceHeld = false
                NSCursor.pop()
                return nil
            }
            return event

        case .leftMouseDown:
            if spaceHeld {
                panStart = (event.locationInWindow, scrollView.contentView.bounds.origin)
                NSCursor.closedHand.push()
                return nil
            }
            return event

        case .leftMouseDragged:
            guard let start = panStart else { return event }
            let magnification = scrollView.magnification
            let dx = (event.locationInWindow.x - start.mouse.x) / magnification
            let dy = (event.locationInWindow.y - start.mouse.y) / magnification
            let clip = scrollView.contentView
            var bounds = clip.bounds
            bounds.origin = NSPoint(x: start.origin.x - dx, y: start.origin.y + dy)  // document is flipped
            clip.scroll(to: clip.constrainBoundsRect(bounds).origin)
            scrollView.reflectScrolledClipView(clip)
            log("space+drag → canvas pan")
            return nil

        case .leftMouseUp:
            guard panStart != nil else { return event }
            panStart = nil
            NSCursor.pop()
            return nil

        default:
            return event
        }
    }

    func card(at windowPoint: NSPoint) -> CardView? {
        var view = view.window?.contentView?.hitTest(windowPoint)
        while let current = view {
            if let card = current as? CardView { return card }
            view = current.superview
        }
        return nil
    }

    private var firstResponderIsWebContent: Bool {
        var responder = view.window?.firstResponder as? NSView
        while let current = responder {
            if current is WKWebView { return true }
            responder = current.superview
        }
        return false
    }

    // MARK: HUD

    func log(_ message: String) {
        lastEvent = message
        refreshHUD()
    }

    private func refreshHUD() {
        hud.stringValue = " Zoom \(Int((scrollView.magnification * 100).rounded()))%  ·  \(lastEvent) "
    }
}
