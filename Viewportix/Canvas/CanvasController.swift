import AppKit
import DesignSystem
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

    /// Card commands that change the document (remove, rotate, edit size). Captures stay in the workspace.
    var onCommand: ((ViewportID, ViewportCommand) -> Void)?

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
        scrollView.maxMagnification = 4  // the last zoom stop (BAR-04)
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(DesignTokens.Color.canvas)
        // Floating chrome covers the canvas's top (device strip) and bottom (bottom bar); content
        // scrolls under it but fits and starts between them.
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = Self.chromeInsets
        scrollView.scrollerInsets = NSEdgeInsets(top: -Self.chromeInsets.top, left: 0, bottom: -Self.chromeInsets.bottom, right: 0)
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
        card.onCommand = { [weak self] id, command in
            guard let self else { return }
            if case .capture(let area) = command {
                let workspace = self.workspace
                Task { await workspace.capture([id], area: area) }
            } else {
                self.onCommand?(id, command)
            }
        }
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

    /// Pans so the card is centred horizontally and its top shows below the strip (250 ms ease-out).
    func reveal(_ id: ViewportID) {
        guard let card = cards[id] else { return }
        let clip = scrollView.contentView
        let visible = clip.bounds
        let insetTop = scrollView.contentInsets.top / scrollView.magnification
        var origin = NSPoint(x: card.frame.midX - visible.width / 2, y: visible.origin.y)
        let topVisible = visible.minY + insetTop
        if card.frame.minY < topVisible || card.frame.minY > visible.maxY - 100 / scrollView.magnification {
            origin.y = card.frame.minY - insetTop - 16 / scrollView.magnification
        }
        let target = clip.constrainBoundsRect(NSRect(origin: origin, size: visible.size)).origin
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            clip.animator().setBoundsOrigin(target)
        }
        scrollView.reflectScrolledClipView(clip)
    }

    // MARK: Zoom

    func zoomIn() { setZoom(scrollView.magnification * 1.25, anchor: viewCenterInWindow) }
    func zoomOut() { setZoom(scrollView.magnification / 1.25, anchor: viewCenterInWindow) }
    func actualSize() { setZoom(1, anchor: viewCenterInWindow) }

    func setZoomPercent(_ percent: Double) {
        setZoom(percent / 100, anchor: viewCenterInWindow)
    }

    /// Zoom stops for the bottom bar's ▲▼ (BAR-04) and ⇧-drag (BAR-05).
    static let zoomSteps: [CGFloat] = [0.25, 0.5, 1, 2, 4]

    /// Moves to the next zoom stop above or below the current zoom, animated (150 ms ease-out).
    func stepZoom(up: Bool) {
        let current = scrollView.magnification
        let tolerance: CGFloat = 0.001
        let target = up
            ? Self.zoomSteps.first { $0 > current + tolerance }
            : Self.zoomSteps.last { $0 < current - tolerance }
        guard let target else { return }
        let center = documentView.convert(viewCenterInWindow, from: nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            scrollView.animator().setMagnification(target, centeredAt: center)
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated { self?.reportZoom() }
        }
        workspace.zoom = target
    }

    /// Strip (16 + 35) and bar (31 + 49) plus breathing room; DESIGN.md §6 "Pencere chrome'u".
    static let chromeInsets = NSEdgeInsets(top: 72, left: 0, bottom: 96, right: 0)

    /// Fits all cards between the strip and the bottom bar, centred horizontally, top-aligned.
    func fit() {
        let content = documentView.bounds.size
        guard content.width > 0, content.height > 0 else { return }
        let insets = scrollView.contentInsets
        let available = NSSize(width: scrollView.bounds.width - insets.left - insets.right,
                               height: scrollView.bounds.height - insets.top - insets.bottom)
        let fitted = min(available.width / content.width, available.height / content.height)
        scrollView.magnification = min(max(fitted, scrollView.minMagnification), scrollView.maxMagnification)
        let magnification = scrollView.magnification
        let clip = scrollView.contentView
        let origin = NSPoint(x: (content.width - scrollView.bounds.width / magnification) / 2,
                             y: -insets.top / magnification)
        clip.scroll(to: clip.constrainBoundsRect(NSRect(origin: origin, size: clip.bounds.size)).origin)
        scrollView.reflectScrolledClipView(clip)
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
    let onCommand: (ViewportID, ViewportCommand) -> Void

    func makeNSViewController(context: Context) -> CanvasController {
        let controller = CanvasController(workspace: workspace)
        workspace.canvas = controller
        return controller
    }

    func updateNSViewController(_ controller: CanvasController, context: Context) {
        controller.onCommand = onCommand
        controller.update(viewports: workspace.viewports, leader: workspace.leaderID, missed: workspace.missedIDs)
    }
}
