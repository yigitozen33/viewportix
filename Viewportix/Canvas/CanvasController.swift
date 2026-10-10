import AppKit
import EngineCore
import ProjectModel
import SwiftUI

/// Zoomable canvas of live viewports (validated in Spikes/S1-CanvasGestures).
///
/// Gesture rules (PLAN.md 3.4):
/// - two-finger scroll over a viewport scrolls the page; over empty canvas it pans the canvas
/// - pinch and ⌘-scroll always zoom the canvas, never the page
/// - Space + drag pans the canvas, unless a web page has keyboard focus
@MainActor
final class CanvasController: NSViewController {
    private static let margin: CGFloat = 64
    private static let gap: CGFloat = 48

    var onClose: ((ViewportID) -> Void)?

    private let workspace: Workspace
    private let scrollView = NSScrollView()
    private let documentView = CanvasDocumentView()
    private var cards: [ViewportID: ViewportCardView] = [:]
    private var order: [ViewportID] = []
    private var layoutSizes: [ViewportSize] = []
    private var monitor: Any?
    private var spaceHeld = false
    private var panStart: (mouse: NSPoint, origin: NSPoint)?
    private var needsInitialFit = true

    init(workspace: Workspace) {
        self.workspace = workspace
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override func loadView() {
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.1
        scrollView.maxMagnification = 2
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .underPageBackgroundColor
        scrollView.documentView = documentView
        view = scrollView

        NotificationCenter.default.addObserver(self, selector: #selector(magnificationEnded), name: NSScrollView.didEndLiveMagnifyNotification, object: scrollView)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.scrollWheel, .magnify, .keyDown, .keyUp, .leftMouseDown, .leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            // Local monitors run on the main thread; NSEvent just isn't annotated Sendable.
            nonisolated(unsafe) let event = event
            let consumed = MainActor.assumeIsolated {
                guard let self, event.window === self.view.window else { return false }
                return self.route(event) == nil
            }
            return consumed ? nil : event
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        if needsInitialFit, !order.isEmpty, scrollView.bounds.width > 0 {
            needsInitialFit = false
            fit()
        }
    }

    // MARK: Cards

    func update(viewports: [ViewportConfig], leader: ViewportID?, missed: Set<ViewportID>) {
        let ids = viewports.map(\.id)
        for (id, card) in cards where !ids.contains(id) {
            card.removeFromSuperview()
            cards[id] = nil
        }
        for config in viewports {
            guard let session = workspace.session(for: config.id) else { continue }
            let card = cards[config.id] ?? makeCard(id: config.id, content: session.view)
            card.configure(config: config, engineVersion: session.engineVersion, isLeader: leader == config.id, syncMissed: missed.contains(config.id))
        }
        let sizes = viewports.map(\.size)
        if ids != order || sizes != layoutSizes {
            order = ids
            layoutSizes = sizes
            layoutCards()
        }
    }

    private func makeCard(id: ViewportID, content: NSView) -> ViewportCardView {
        let card = ViewportCardView(viewportID: id, content: content)
        card.onHover = { [weak self] id in self?.workspace.setLeader(id) }
        card.onClose = { [weak self] id in self?.onClose?(id) }
        documentView.addSubview(card)
        cards[id] = card
        return card
    }

    /// One row, top-aligned. Free placement and grouping come in M3.
    private func layoutCards() {
        var x = Self.margin
        var maxHeight: CGFloat = 0
        for id in order {
            guard let card = cards[id] else { continue }
            card.setFrameOrigin(NSPoint(x: x, y: Self.margin))
            x += card.frame.width + Self.gap
            maxHeight = max(maxHeight, card.frame.height)
        }
        let width = order.isEmpty ? 0 : x - Self.gap + Self.margin
        documentView.setFrameSize(NSSize(width: width, height: maxHeight + 2 * Self.margin))
    }

    // MARK: Zoom

    func zoomIn() { setZoom(scrollView.magnification * 1.25, anchor: viewCenterInWindow) }
    func zoomOut() { setZoom(scrollView.magnification / 1.25, anchor: viewCenterInWindow) }
    func actualSize() { setZoom(1, anchor: viewCenterInWindow) }

    func setZoomPercent(_ percent: Double) {
        setZoom(percent / 100, anchor: viewCenterInWindow)
    }

    func fit() {
        guard documentView.bounds.width > 0 else { return }
        scrollView.magnify(toFit: documentView.bounds)
        reportZoom()
    }

    private var viewCenterInWindow: NSPoint {
        scrollView.convert(NSPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY), to: nil)
    }

    /// Sets the zoom while keeping the document point under `anchor` (window coordinates) in place.
    private func setZoom(_ value: CGFloat, anchor: NSPoint) {
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
        reportZoom()
    }

    private func reportZoom() {
        workspace.zoom = scrollView.magnification
    }

    @objc private func magnificationEnded() {
        reportZoom()
    }

    // MARK: Event routing

    /// Returns the event to let AppKit deliver it normally, or nil when the canvas consumed it.
    private func route(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .magnify:
            // Always the canvas: NSScrollView's own pinch is anchored under the pointer and phase-aware.
            scrollView.magnify(with: event)
            reportZoom()
            return nil

        case .scrollWheel where event.modifierFlags.contains(.command):
            let step = event.hasPreciseScrollingDeltas ? 0.01 : 0.1
            setZoom(scrollView.magnification * exp(event.scrollingDeltaY * step), anchor: event.locationInWindow)
            return nil

        case .keyDown where event.keyCode == Self.spaceKeyCode:
            if spaceHeld { return nil }  // swallow key repeat
            if firstResponderIsWebContent || !isPointerOverCanvas { return event }
            spaceHeld = true
            NSCursor.openHand.push()
            return nil

        case .keyUp where event.keyCode == Self.spaceKeyCode && spaceHeld:
            spaceHeld = false
            NSCursor.pop()
            return nil

        case .leftMouseDown where spaceHeld:
            panStart = (event.locationInWindow, scrollView.contentView.bounds.origin)
            NSCursor.closedHand.push()
            return nil

        case .leftMouseDragged where panStart != nil:
            guard let start = panStart else { return event }
            let magnification = scrollView.magnification
            let dx = (event.locationInWindow.x - start.mouse.x) / magnification
            let dy = (event.locationInWindow.y - start.mouse.y) / magnification
            let clip = scrollView.contentView
            var bounds = clip.bounds
            bounds.origin = NSPoint(x: start.origin.x - dx, y: start.origin.y + dy)  // document is flipped
            clip.scroll(to: clip.constrainBoundsRect(bounds).origin)
            scrollView.reflectScrolledClipView(clip)
            return nil

        case .leftMouseUp where panStart != nil:
            panStart = nil
            NSCursor.pop()
            return nil

        default:
            return event
        }
    }

    private static let spaceKeyCode: UInt16 = 49

    private var isPointerOverCanvas: Bool {
        guard let window = view.window else { return false }
        let point = scrollView.convert(window.mouseLocationOutsideOfEventStream, from: nil)
        return scrollView.bounds.contains(point)
    }

    private var firstResponderIsWebContent: Bool {
        guard let responder = view.window?.firstResponder as? NSView else { return false }
        return cards.values.contains { responder.isDescendant(of: $0) }
    }
}

final class CanvasDocumentView: NSView {
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    /// Clicking empty canvas takes keyboard focus away from web pages, so Space pans again.
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }
}

struct CanvasView: NSViewControllerRepresentable {
    let workspace: Workspace
    let onClose: (ViewportID) -> Void

    func makeNSViewController(context: Context) -> CanvasController {
        let controller = CanvasController(workspace: workspace)
        workspace.canvas = controller
        return controller
    }

    func updateNSViewController(_ controller: CanvasController, context: Context) {
        controller.onClose = onClose
        controller.update(viewports: workspace.viewports, leader: workspace.leaderID, missed: workspace.missedIDs)
    }
}
