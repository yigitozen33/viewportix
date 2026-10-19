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
    /// Where the last ⌘1 left the canvas. While nobody zooms or pans away from it, the canvas fits
    /// again when its size changes (window resize, sidebar or rail toggled); found in the live app:
    /// cards stayed in the left corner with the sidebar hidden.
    private var fitted: (origin: NSPoint, magnification: CGFloat, size: NSSize)?

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
        } else if let fitted, scrollView.bounds.size != fitted.size, isStill(at: fitted) {
            fit()
        }
    }

    // MARK: Cards

    func update(viewports: [ViewportConfig], grouping: Grouping, collapsed: Set<String>) {
        let groupingChanged = grouping != self.grouping || collapsed != collapsedGroups
        self.grouping = grouping
        collapsedGroups = collapsed
        if groupingChanged { layout = [] }  // forces a relayout below
        update(viewports: viewports)
    }

    private var grouping = Grouping.none
    private var collapsedGroups: Set<String> = []
    private var groupAreas: [String: GroupAreaView] = [:]
    /// Open groups' page-area unions and folded groups' chip anchors, in document coordinates.
    private var groupRects: [String: CGRect] = [:]

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
        for (id, card) in cards where !card.isHidden {
            card.setScreenCornerRadius(DesignTokens.Radius.card, magnification: magnification)
            let rect = scrollView.convert(card.frame, from: documentView)
            let top = scrollView.isFlipped ? rect.minY : scrollView.bounds.height - rect.maxY
            frames[id] = CGRect(x: rect.minX, y: top, width: rect.width, height: rect.height)
        }
        if frames != workspace.cardFrames { workspace.cardFrames = frames }
        layoutGroupAreas()
        var groupFrames: [String: CGRect] = [:]
        for (key, rect) in groupRects {
            groupFrames[key] = screenRect(rect)
        }
        if groupFrames != workspace.groupFrames { workspace.groupFrames = groupFrames }
    }

    private func screenRect(_ rect: CGRect) -> CGRect {
        let converted = scrollView.convert(rect, from: documentView)
        let top = scrollView.isFlipped ? converted.minY : scrollView.bounds.height - converted.maxY
        return CGRect(x: converted.minX, y: top, width: converted.width, height: converted.height)
    }

    // MARK: Group areas (PW-02)

    /// Screen-point padding of a group area around its cards' page areas: the group header (32), a
    /// card's hover strip (36) and header (36) above, the warning note below
    /// (`window-project-groups@2x.png`: area top to card header 68).
    static let groupPadding = NSEdgeInsets(top: 104, left: 14, bottom: 45, right: 14)

    private func updateGroupAreas() {
        let open = Set(groupRects.filter { !$0.value.isEmpty }.keys)
        for (key, view) in groupAreas where !open.contains(key) {
            view.removeFromSuperview()
            groupAreas[key] = nil
        }
        for key in open where groupAreas[key] == nil {
            let view = GroupAreaView()
            documentView.addSubview(view, positioned: .below, relativeTo: nil)
            groupAreas[key] = view
        }
    }

    /// Areas sit under the cards in document space; padding, border and radius are converted from
    /// screen points so they look the same at every zoom.
    private func layoutGroupAreas() {
        let m = max(scrollView.magnification, 0.01)
        let pad = Self.groupPadding
        for (key, view) in groupAreas {
            guard let rect = groupRects[key], !rect.isEmpty else { continue }
            view.frame = NSRect(x: rect.minX - pad.left / m, y: rect.minY - pad.top / m,
                                width: rect.width + (pad.left + pad.right) / m, height: rect.height + (pad.top + pad.bottom) / m)
            view.setScreenStyle(magnification: m)
        }
    }

    /// "Seçimi Sığdır" (⌘2): fits one card like ⌘1 fits all.
    func fitCard(_ id: ViewportID) {
        guard let card = cards[id] else { return }
        fit(rect: card.frame.insetBy(dx: -CanvasLayout.margin, dy: -CanvasLayout.margin))
    }

    /// "Grubu sığdır": fits the group's cards like ⌘1 fits all.
    func fitGroup(_ key: String) {
        guard let rect = groupRects[key], !rect.isEmpty else { return }
        fit(rect: rect.insetBy(dx: -CanvasLayout.margin, dy: -CanvasLayout.margin))
    }

    /// Dragged cards keep their place, the others line up in a row (`CanvasLayout`). "Kartları Diz"
    /// (positions cleared) animates back to the row (PW-01, 250 ms).
    private func layoutCards(animated: Bool = false) {
        let groups = grouping.groups(of: layout)
        let frames: [ViewportID: CGRect]
        if groups.isEmpty {
            frames = CanvasLayout.frames(for: layout)
            groupRects = [:]
        } else {
            let grouped = CanvasLayout.grouped(layout, groups: groups, collapsed: collapsedGroups)
            frames = grouped.frames
            groupRects = grouped.groups
        }
        workspace.groups = groups
        // Grouped: the group header row needs room under the strip too.
        scrollView.contentInsets.top = groups.isEmpty ? Self.chromeInsets.top : Self.chromeInsets.top + 36
        for (id, card) in cards { card.isHidden = frames[id] == nil }
        updateGroupAreas()
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
        let bounds = (Array(frames.values) + groupRects.values.map { $0.insetBy(dx: 0, dy: 0) })
            .reduce(CGRect.null) { $0.union($1) }
        let size = bounds.isNull ? .zero : NSSize(width: bounds.maxX + CanvasLayout.margin, height: bounds.maxY + CanvasLayout.margin)
        documentView.setFrameSize(size)
        publishFrames()
    }

    // MARK: Dragging (CARD-08, CARD-09)

    func beginDrag(_ id: ViewportID) {
        guard let card = cards[id] else { return }
        drag = (id, card.frame.origin)
        documentView.addSubview(card, positioned: .above, relativeTo: nil)  // in front of overlapped cards
    }

    /// Moves the card by a screen-point translation from where the drag began; snaps to the other
    /// cards' edges and centres within 6 screen px unless ⌥ is held, then to equal spacing between
    /// neighbours on the axes not already snapped. Returns guides and gaps in document units.
    func dragCard(by translation: CGSize, snapping: Bool) -> (guides: [CanvasLayout.Guide], gaps: [CanvasLayout.Gap]) {
        guard let drag, let card = cards[drag.id] else { return ([], []) }
        let magnification = scrollView.magnification
        var origin = NSPoint(x: max(drag.start.x + translation.width / magnification, 0),
                             y: max(drag.start.y + translation.height / magnification, 0))
        var guides: [CanvasLayout.Guide] = []
        var gaps: [CanvasLayout.Gap] = []
        if snapping {
            let others = cards.filter { $0.key != drag.id && !$0.value.isHidden }.map(\.value.frame)
            let rect = CGRect(origin: origin, size: card.frame.size)
            let threshold = 6 / magnification
            // Per axis, the nearer of edge snapping and equal spacing wins.
            let snapped = CanvasLayout.snap(rect, to: others, threshold: threshold)
            let spaced = CanvasLayout.equalSpacing(rect, to: others, threshold: threshold)
            let spacedX = spaced.gaps.contains { $0.axis == .horizontal }
                && (!snapped.guides.contains { $0.axis == .vertical } || abs(spaced.origin.x - rect.minX) < abs(snapped.origin.x - rect.minX))
            let spacedY = spaced.gaps.contains { $0.axis == .vertical }
                && (!snapped.guides.contains { $0.axis == .horizontal } || abs(spaced.origin.y - rect.minY) < abs(snapped.origin.y - rect.minY))
            origin = CGPoint(x: spacedX ? spaced.origin.x : snapped.origin.x, y: spacedY ? spaced.origin.y : snapped.origin.y)
            guides = snapped.guides.filter { $0.axis == .vertical ? !spacedX : !spacedY }
            gaps = spaced.gaps.filter { $0.axis == .horizontal ? spacedX : spacedY }
        }
        card.setFrameOrigin(origin)
        let maxPoint = NSPoint(x: max(documentView.frame.width, card.frame.maxX + CanvasLayout.margin),
                               y: max(documentView.frame.height, card.frame.maxY + CanvasLayout.margin))
        documentView.setFrameSize(NSSize(width: maxPoint.x, height: maxPoint.y))
        publishFrames()
        return (guides, gaps)
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

    /// A gap's line in screen points, for the chrome layer's spacing badge.
    func screenGap(_ gap: CanvasLayout.Gap) -> Workspace.DragGap {
        let guide = CanvasLayout.Guide(axis: gap.axis, position: gap.position, start: gap.start, end: gap.end)
        let (from, to) = screenGuide(guide)
        return Workspace.DragGap(from: from, to: to, label: "\(Int(gap.length.rounded()))")
    }

    /// The pointer in the chrome layer's coordinates (top-left origin), for the drag hint.
    func layerPoint(ofScreenPoint point: NSPoint) -> CGPoint? {
        guard let window = scrollView.window else { return nil }
        let local = scrollView.convert(window.convertPoint(fromScreen: point), from: nil)
        return CGPoint(x: local.x, y: scrollView.isFlipped ? local.y : scrollView.bounds.height - local.y)
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
    /// The canvas is where the last fit left it, within 2 screen points (resizing nudges the
    /// clip view by fractions of a point).
    private func isStill(at fitted: (origin: NSPoint, magnification: CGFloat, size: NSSize)) -> Bool {
        let magnification = scrollView.magnification
        let origin = scrollView.contentView.bounds.origin
        return abs(magnification - fitted.magnification) < 0.0005
            && abs(origin.x - fitted.origin.x) * magnification < 2
            && abs(origin.y - fitted.origin.y) * magnification < 2
    }

    func fit() {
        fit(rect: documentView.bounds)
        fitted = (scrollView.contentView.bounds.origin, scrollView.magnification, scrollView.bounds.size)
    }

    private func fit(rect: CGRect) {
        let content = rect.size
        guard content.width > 0, content.height > 0 else { return }
        let insets = scrollView.contentInsets
        let available = NSSize(width: scrollView.bounds.width - insets.left - insets.right,
                               height: scrollView.bounds.height - insets.top - insets.bottom)
        let fitted = min(available.width / content.width, available.height / content.height)
        scrollView.magnification = min(max(fitted, scrollView.minMagnification), scrollView.maxMagnification)
        let magnification = scrollView.magnification
        let clip = scrollView.contentView
        let origin = NSPoint(x: rect.minX + (content.width - scrollView.bounds.width / magnification) / 2,
                             y: rect.minY - insets.top / magnification)
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

        case .keyDown where event.keyCode == Self.escapeKeyCode && canTakeCardKeys && workspace.selectedViewportID != nil:
            workspace.selectedViewportID = nil
            return nil

        // Kaldır ⌫ (DESIGN.md §3.2.1) on the selected card. Not a menu key equivalent: that would take
        // ⌫ from web forms and text fields.
        case .keyDown where event.keyCode == Self.deleteKeyCode && canTakeCardKeys && workspace.selectedViewportID != nil
            && event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.function, .numericPad]).isEmpty:
            workspace.performOnSelection(.remove)
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
    private static let deleteKeyCode: UInt16 = 51

    private var isPointerOverCanvas: Bool {
        guard let window = view.window else { return false }
        let point = scrollView.convert(window.mouseLocationOutsideOfEventStream, from: nil)
        return scrollView.bounds.contains(point)
    }

    /// Esc and ⌫ belong to the card selection unless a page or a text field has the keyboard
    /// (Esc in the address field reverts it).
    private var canTakeCardKeys: Bool {
        !firstResponderIsWebContent && !(view.window?.firstResponder is NSText)
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
    /// A click gives it the keyboard (⌫, Esc, Space); Tab goes to the cards' own controls (PW-05).
    override var canBecomeKeyView: Bool { false }

    /// Clicking empty canvas takes keyboard focus away from web pages, so Space pans again, and
    /// clears the card selection (CARD-02).
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        onEmptyClick?()
    }
}

struct CanvasView: NSViewControllerRepresentable {
    let workspace: Workspace
    var grouping = Grouping.none
    var collapsedGroups: Set<String> = []

    func makeNSViewController(context: Context) -> CanvasController {
        let controller = CanvasController(workspace: workspace)
        workspace.canvas = controller
        return controller
    }

    func updateNSViewController(_ controller: CanvasController, context: Context) {
        controller.update(viewports: workspace.viewports, grouping: grouping, collapsed: collapsedGroups)
    }
}

/// A group's area under its cards: `surface/group` fill, `line` border, 16 pt corners on screen.
final class GroupAreaView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor(DesignTokens.Color.surfaceGroup).cgColor
        layer?.borderColor = NSColor(DesignTokens.Color.line).cgColor
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func setScreenStyle(magnification: CGFloat) {
        layer?.cornerRadius = DesignTokens.Radius.window / magnification
        layer?.borderWidth = DesignTokens.Stroke.hairline / magnification
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
