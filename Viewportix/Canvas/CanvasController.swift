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
    private let workspace: Workspace
    private let scrollView = NSScrollView()
    private let documentView = CanvasDocumentView()
    private var cards: [ViewportID: ViewportCardView] = [:]
    private var layout: [ViewportConfig] = []
    private var drag: (id: ViewportID, start: NSPoint)?
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
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(visibleRectChanged), name: NSView.boundsDidChangeNotification, object: scrollView.contentView)
        documentView.onEmptyClick = { [weak self] in self?.workspace.selectedViewportID = nil }
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
        publishFrames()
        if needsInitialFit, !layout.isEmpty, scrollView.bounds.width > 0 {
            needsInitialFit = false
            fit()
        }
    }

    // MARK: Cards

    func update(viewports: [ViewportConfig]) {
        let ids = viewports.map(\.id)
        for (id, card) in cards where !ids.contains(id) {
            card.removeFromSuperview()
            cards[id] = nil
        }
        for config in viewports {
            guard let session = workspace.session(for: config.id) else { continue }
            let card = cards[config.id] ?? makeCard(id: config.id, content: session.view)
            card.configure(size: config.size)
        }
        // Relayout when order, sizes or saved positions change (not for name or sync toggles).
        let changed = viewports.map(\.id) != layout.map(\.id)
            || viewports.map(\.size) != layout.map(\.size)
            || viewports.map(\.position) != layout.map(\.position)
        if changed, drag == nil {
            let rearranged = !layout.isEmpty && viewports.allSatisfy { $0.position == nil } && layout.contains { $0.position != nil }
            layout = viewports
            layoutCards(animated: rearranged)
        }
    }

    private func makeCard(id: ViewportID, content: NSView) -> ViewportCardView {
        let card = ViewportCardView(viewportID: id, content: content)
        card.onHover = { [weak self] id, inside in self?.workspace.cardHovered(id, inside) }
        documentView.addSubview(card)
        cards[id] = card
        return card
    }

    /// Card page areas in this view's coordinates (top-left origin, screen points) for the chrome
    /// drawn above the canvas; called on layout, scroll and zoom.
    func publishFrames() {
        let magnification = scrollView.magnification
        var frames: [ViewportID: CGRect] = [:]
        for (id, card) in cards {
            card.setScreenCornerRadius(DesignTokens.Radius.card, magnification: magnification)
            let rect = scrollView.convert(card.frame, from: documentView)
            let top = scrollView.isFlipped ? rect.minY : scrollView.bounds.height - rect.maxY
            frames[id] = CGRect(x: rect.minX, y: top, width: rect.width, height: rect.height)
        }
        if frames != workspace.cardFrames { workspace.cardFrames = frames }
    }

    /// Dragged cards keep their place, the others line up in a row (`CanvasLayout`). "Kartları Diz"
    /// (positions cleared) animates back to the row (PW-01, 250 ms).
    private func layoutCards(animated: Bool = false) {
        let frames = CanvasLayout.frames(for: layout)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animated ? 0.25 : 0
            context.allowsImplicitAnimation = animated
            for (id, frame) in frames {
                guard let card = cards[id] else { continue }
                if animated { card.animator().setFrameOrigin(frame.origin) } else { card.setFrameOrigin(frame.origin) }
            }
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated { self?.publishFrames() }
        }
        let bounds = frames.values.reduce(CGRect.null) { $0.union($1) }
        let size = bounds.isNull ? .zero : NSSize(width: bounds.maxX + CanvasLayout.margin, height: bounds.maxY + CanvasLayout.margin)
        documentView.setFrameSize(size)
        publishFrames()
    }

    // MARK: Dragging (CARD-08, CARD-09)

    func beginDrag(_ id: ViewportID) {
        guard let card = cards[id] else { return }
        drag = (id, card.frame.origin)
    }

    /// Moves the card by a screen-point translation from where the drag began; snaps to the other
    /// cards' edges and centres within 6 screen px unless ⌥ is held. Returns guides in screen points.
    func dragCard(by translation: CGSize, snapping: Bool) -> [CanvasLayout.Guide] {
        guard let drag, let card = cards[drag.id] else { return [] }
        let magnification = scrollView.magnification
        var origin = NSPoint(x: max(drag.start.x + translation.width / magnification, 0),
                             y: max(drag.start.y + translation.height / magnification, 0))
        var guides: [CanvasLayout.Guide] = []
        if snapping {
            let others = cards.filter { $0.key != drag.id }.map(\.value.frame)
            let snapped = CanvasLayout.snap(CGRect(origin: origin, size: card.frame.size), to: others, threshold: 6 / magnification)
            origin = snapped.origin
            guides = snapped.guides
        }
        card.setFrameOrigin(origin)
        let maxPoint = NSPoint(x: max(documentView.frame.width, card.frame.maxX + CanvasLayout.margin),
                               y: max(documentView.frame.height, card.frame.maxY + CanvasLayout.margin))
        documentView.setFrameSize(NSSize(width: maxPoint.x, height: maxPoint.y))
        publishFrames()
        return guides
    }

    /// Ends the drag and returns every card's origin, to be saved as positions (the layout is pinned
    /// once a card has been moved by hand).
    func endDrag() -> [ViewportID: CanvasPoint] {
        drag = nil
        return cards.mapValues { CanvasPoint(x: $0.frame.minX, y: $0.frame.minY) }
    }

    /// Converts a document-space guide to screen points for the chrome layer.
    func screenGuide(_ guide: CanvasLayout.Guide) -> (from: CGPoint, to: CGPoint) {
        func screen(_ point: NSPoint) -> CGPoint {
            let converted = scrollView.convert(point, from: documentView)
            return CGPoint(x: converted.x, y: scrollView.isFlipped ? converted.y : scrollView.bounds.height - converted.y)
        }
        switch guide.axis {
        case .vertical:
            return (screen(NSPoint(x: guide.position, y: guide.start)), screen(NSPoint(x: guide.position, y: guide.end)))
        case .horizontal:
            return (screen(NSPoint(x: guide.start, y: guide.position)), screen(NSPoint(x: guide.end, y: guide.position)))
        }
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

    /// Strip (16 + 35), hover strip and the 36 pt card header above the page area; bottom bar below.
    static let chromeInsets = NSEdgeInsets(top: 144, left: 0, bottom: 112, right: 0)

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
        publishFrames()
    }

    @objc private func magnificationEnded() {
        reportZoom()
    }

    @objc private func visibleRectChanged() {
        publishFrames()
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

        case .leftMouseDown where !spaceHeld:
            // CARD-02: clicking a page selects its card; the click still reaches the page.
            // Hit-test so clicks on the chrome floating above a card (bottom bar, strip) don't count.
            if let hit = view.window?.contentView?.hitTest(event.locationInWindow),
               let card = cards.values.first(where: { hit.isDescendant(of: $0) }) {
                workspace.selectedViewportID = card.viewportID
            }
            return event

        case .keyDown where event.keyCode == Self.escapeKeyCode && !firstResponderIsWebContent && workspace.selectedViewportID != nil:
            workspace.selectedViewportID = nil
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
    private static let escapeKeyCode: UInt16 = 53

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
    var onEmptyClick: (() -> Void)?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    /// Clicking empty canvas takes keyboard focus away from web pages, so Space pans again, and
    /// clears the card selection (CARD-02).
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        onEmptyClick?()
    }
}

struct CanvasView: NSViewControllerRepresentable {
    let workspace: Workspace

    func makeNSViewController(context: Context) -> CanvasController {
        let controller = CanvasController(workspace: workspace)
        workspace.canvas = controller
        return controller
    }

    func updateNSViewController(_ controller: CanvasController, context: Context) {
        controller.update(viewports: workspace.viewports)
    }
}
