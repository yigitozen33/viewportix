import AppKit
import DesignSystem
import SwiftUI

/// A menu drawn as in the design (`Context Menu`, `Card Context Menu`, `Zoom Menu`, `Screenshot
/// Chooser`, `Remove Submenu`): opaque `surface/header`, 12 pt corners, hairline, shadow
/// `#00000066` 0/8/24. Never the system menu: our own surfaces have no Liquid Glass (DESIGN.md §4).
struct ChromeMenu {
    enum Style {
        /// Card, home, zoom, group and settings menus: 12 pt rows, 7/10 padding, 2 pt apart.
        case standard
        /// Sidebar page menu (`sidebar-page-context-menu@2x.png`): 13 pt rows, 5/10 padding.
        case list
        /// Screenshot choosers: header, options with a 16 pt icon and a description, footer.
        case chooser
    }

    var style = Style.standard
    /// The design's width; longer rows widen the menu. 0: as wide as the trigger.
    var width: CGFloat = 220
    /// Zoom menu: a check column on every row, ticked on the current one.
    var showsChecks = false
    var items: [ChromeMenuItem]
}

struct ChromeMenuItem {
    enum Kind { case action, info, separator, header, footer }
    enum Role { case normal, destructive }

    var kind = Kind.action
    var title = ""
    var subtitle: String?
    var symbol: String?
    /// Shown on the right in `ink/secondary`: a shortcut ("⌥⌘R", "Çift tık") or, for info rows, a value.
    var shortcut: String?
    var role = Role.normal
    var isChecked = false
    var isEnabled = true
    var submenu: ChromeMenu?
    var action: (() -> Void)?

    static func button(_ title: String, subtitle: String? = nil, symbol: String? = nil, shortcut: String? = nil,
                       role: Role = .normal, isChecked: Bool = false, isEnabled: Bool = true,
                       action: @escaping () -> Void) -> Self {
        Self(title: title, subtitle: subtitle, symbol: symbol, shortcut: shortcut, role: role,
             isChecked: isChecked, isEnabled: isEnabled, action: action)
    }

    static func submenu(_ title: String, symbol: String? = nil, role: Role = .normal, isEnabled: Bool = true,
                        _ menu: ChromeMenu) -> Self {
        Self(title: title, symbol: symbol, shortcut: "›", role: role, isEnabled: isEnabled, submenu: menu)
    }

    /// A secondary row with a value on the right, not chosen ("Motor · WebKit 26 ›").
    static func info(_ title: String, value: String) -> Self {
        Self(kind: .info, title: title, shortcut: value)
    }

    static var separator: Self { Self(kind: .separator) }

    /// Chooser heading ("EKRAN GÖRÜNTÜSÜ · 3 VIEWPORT").
    static func header(_ title: String) -> Self {
        Self(kind: .header, title: title)
    }

    /// One-line summary under a chooser; with an action it can be clicked.
    static func footer(_ text: String, action: (() -> Void)? = nil) -> Self {
        Self(kind: .footer, title: text, action: action)
    }

    var isSelectable: Bool {
        isEnabled && (kind == .action || (kind == .footer && action != nil))
    }
}

// MARK: - Drawing

/// One open menu (the root or a submenu): the model and what the pointer or keys highlight.
@MainActor
@Observable
final class ChromeMenuState {
    let menu: ChromeMenu
    var highlighted: Int?
    /// Row frames and the menu's frame in the panel's view (top-left origin), for hit-testing.
    @ObservationIgnored var rowFrames: [Int: CGRect] = [:]
    @ObservationIgnored var menuFrame: CGRect = .zero
    @ObservationIgnored var hasHadPointer = false

    init(menu: ChromeMenu) {
        self.menu = menu
        // The choosers open with their first option highlighted (window-project-screenshot-menu@2x.png).
        if menu.style == .chooser { highlighted = menu.items.firstIndex(where: \.isSelectable) }
    }

    func row(at point: CGPoint) -> Int? {
        rowFrames.first { menu.items[$0.key].kind != .separator && $0.value.contains(point) }?.key
    }
}

struct ChromeMenuView: View {
    let state: ChromeMenuState

    private var menu: ChromeMenu { state.menu }

    var body: some View {
        VStack(alignment: .leading, spacing: menu.style == .list ? 0 : 2) {
            ForEach(Array(menu.items.enumerated()), id: \.offset) { index, item in
                row(item, at: index)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { state.rowFrames[index] = $0 }
            }
        }
        .padding(menu.style == .list ? 5 : 6)
        .frame(minWidth: menu.width, alignment: .leading)
        .fixedSize()
        .chromeSurface(shadowOpacity: 0.4, shadowRadius: 12)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { state.menuFrame = $0 }
        .padding(ChromeMenuPresenter.margin)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private func row(_ item: ChromeMenuItem, at index: Int) -> some View {
        switch item.kind {
        case .separator:
            if menu.style == .list {
                Rectangle().fill(DesignTokens.Color.line).frame(height: 1).padding(.horizontal, 10).frame(height: 9)
            } else {
                Rectangle().fill(DesignTokens.Color.line).frame(height: 1)
            }
        case .header:
            Text(item.title)
                .font(.system(size: DesignTokens.FontSize.micro, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
                .lineLimit(1)
                .padding(EdgeInsets(top: 6, leading: 10, bottom: 4, trailing: 10))
                .accessibilityAddTraits(.isHeader)
        case .footer:
            Text(item.title)
                .font(.system(size: DesignTokens.FontSize.caption))
                .foregroundStyle(DesignTokens.Color.inkSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                .background(state.highlighted == index ? DesignTokens.Color.surfaceHeaderLeader : .clear,
                            in: .rect(cornerRadius: DesignTokens.Radius.control))
        case .action, .info:
            actionRow(item, isHighlighted: state.highlighted == index)
        }
    }

    private func actionRow(_ item: ChromeMenuItem, isHighlighted: Bool) -> some View {
        let isChooser = menu.style == .chooser
        let labelColor = item.kind == .info ? DesignTokens.Color.inkSecondary
            : item.role == .destructive ? DesignTokens.Color.statusWarning : DesignTokens.Color.inkPrimary
        let iconColor = item.role == .destructive ? DesignTokens.Color.statusWarning
            : isChooser ? DesignTokens.Color.inkPrimary : DesignTokens.Color.inkSecondary
        // Two-line rows with a 14 pt icon sit at the top (`Remove Submenu`); the rest centre.
        let alignment: VerticalAlignment = item.subtitle != nil && !isChooser ? .top : .center
        return HStack(alignment: alignment, spacing: isChooser ? 10 : 8) {
            if menu.showsChecks {
                ChromeSymbol("checkmark", box: DesignTokens.Size.iconSm)
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                    .opacity(item.isChecked ? 1 : 0)
            }
            if let symbol = item.symbol {
                ChromeSymbol(symbol, box: isChooser ? DesignTokens.Size.icon : DesignTokens.Size.iconSm)
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: menu.style == .list ? DesignTokens.FontSize.body : DesignTokens.FontSize.label,
                                  weight: isChooser ? .medium : .regular))
                    .foregroundStyle(labelColor)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: DesignTokens.FontSize.micro))
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            if let shortcut = item.shortcut {
                Text(shortcut)
                    .font(.system(size: DesignTokens.FontSize.caption))
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                    .lineLimit(1)
            }
        }
        .padding(rowPadding)
        .background(isHighlighted && item.kind != .info ? DesignTokens.Color.surfaceHeaderLeader : .clear,
                    in: .rect(cornerRadius: DesignTokens.Radius.control))
        .opacity(item.isEnabled ? 1 : 0.4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(item.kind == .action ? .isButton : [])
        .accessibilityAddTraits(item.isChecked ? .isSelected : [])
    }

    private var rowPadding: EdgeInsets {
        switch menu.style {
        case .standard: EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10)
        case .list: EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        case .chooser: EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
        }
    }
}

// MARK: - Presenting

/// Shows a `ChromeMenu` in a borderless panel and runs it like a menu: the pointer or ↑↓ highlight,
/// a click or ⏎ chooses, → and ← open and close a submenu, Esc or a click elsewhere closes. The
/// window keeps the keyboard; keys reach the menu through a local event monitor.
@MainActor
final class ChromeMenuPresenter {
    enum Placement {
        /// Above or below `rect` (window coordinates), `gap` away, lined up on `alignment`.
        case above(NSRect, HorizontalAlignment, gap: CGFloat)
        case below(NSRect, HorizontalAlignment, gap: CGFloat)
        /// Top-left corner at the pointer (context menus), in window coordinates.
        case at(NSPoint)
    }

    /// Room around the menu in its panel for the shadow.
    nonisolated static let margin: CGFloat = 32

    private static var current: ChromeMenuPresenter?

    static var isOpen: Bool { current != nil }

    /// Opens `menu`, closing any other; `onClose` runs once when it closes, chosen or not.
    static func show(_ menu: ChromeMenu, in window: NSWindow, placement: Placement, onClose: (() -> Void)? = nil) {
        current?.close()
        let presenter = ChromeMenuPresenter(window: window, onClose: onClose)
        current = presenter
        presenter.open(menu, placement: presenter.screenPlacement(placement, in: window))
        presenter.startMonitoring()
    }

    private struct Level {
        let state: ChromeMenuState
        let panel: ChromeMenuPanel
    }

    private enum ScreenPlacement {
        case above(NSRect, HorizontalAlignment, CGFloat)
        case below(NSRect, HorizontalAlignment, CGFloat)
        case at(NSPoint)
        /// Next to a submenu's row: left of the parent menu as in `window-home-remove-submenu@2x.png`,
        /// its last row level with the row; right when there is no room on the left.
        case beside(row: NSRect, menu: NSRect)
    }

    private weak var window: NSWindow?
    private var onClose: (() -> Void)?
    private var levels: [Level] = []
    private var monitors: [Any] = []
    private var observers: [NSObjectProtocol] = []

    private init(window: NSWindow, onClose: (() -> Void)?) {
        self.window = window
        self.onClose = onClose
    }

    private func screenPlacement(_ placement: Placement, in window: NSWindow) -> ScreenPlacement {
        switch placement {
        case .above(let rect, let alignment, let gap): .above(window.convertToScreen(rect), alignment, gap)
        case .below(let rect, let alignment, let gap): .below(window.convertToScreen(rect), alignment, gap)
        case .at(let point): .at(window.convertPoint(toScreen: point))
        }
    }

    private func open(_ menu: ChromeMenu, placement: ScreenPlacement) {
        let state = ChromeMenuState(menu: menu)
        let host = ChromeMenuHostingView(rootView: AnyView(ChromeMenuView(state: state)))
        host.presenter = self
        host.level = levels.count
        let size = host.fittingSize
        let margin = Self.margin
        let menuSize = NSSize(width: size.width - 2 * margin, height: size.height - 2 * margin)
        let origin = menuOrigin(for: menuSize, placement: placement)
        let panel = ChromeMenuPanel()
        panel.contentView = host
        panel.setFrame(NSRect(x: origin.x - margin, y: origin.y - margin, width: size.width, height: size.height), display: true)
        panel.alphaValue = 0
        panel.orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.Motion.fast
            panel.animator().alphaValue = 1
        }
        levels.append(Level(state: state, panel: panel))
    }

    /// The menu's bottom-left corner on screen, kept inside the screen's visible frame.
    private func menuOrigin(for size: NSSize, placement: ScreenPlacement) -> NSPoint {
        let screen = (window?.screen ?? NSScreen.main)?.visibleFrame ?? .infinite
        func x(_ rect: NSRect, _ alignment: HorizontalAlignment) -> CGFloat {
            switch alignment {
            case .trailing: rect.maxX - size.width
            case .center: rect.midX - size.width / 2
            default: rect.minX
            }
        }
        var origin: NSPoint
        switch placement {
        case .above(let rect, let alignment, let gap):
            origin = NSPoint(x: x(rect, alignment), y: rect.maxY + gap)
            if origin.y + size.height > screen.maxY { origin.y = rect.minY - gap - size.height }
        case .below(let rect, let alignment, let gap):
            origin = NSPoint(x: x(rect, alignment), y: rect.minY - gap - size.height)
            if origin.y < screen.minY { origin.y = rect.maxY + gap }
        case .at(let point):
            origin = NSPoint(x: point.x, y: point.y - size.height)
            if origin.y < screen.minY { origin.y = point.y }
            if origin.x + size.width > screen.maxX { origin.x = point.x - size.width }
        case .beside(let row, let menu):
            let padding: CGFloat = 6
            origin = NSPoint(x: menu.minX - 4 - size.width, y: row.minY - padding)
            if origin.x < screen.minX { origin.x = menu.maxX + 4 }
        }
        origin.x = min(max(origin.x, screen.minX + 4), screen.maxX - 4 - size.width)
        origin.y = min(max(origin.y, screen.minY + 4), screen.maxY - 4 - size.height)
        return origin
    }

    // MARK: Pointer (from the panels' views)

    /// Panels overlap by their shadow margins, so a point goes to the menu that contains it, not to
    /// the panel that got the event; `level` (the event's panel) when none does.
    private func target(_ screenPoint: NSPoint, from level: Int) -> (level: Int, point: CGPoint) {
        let hit = levels.indices.reversed().first { screenRect(levels[$0].state.menuFrame, in: levels[$0].panel).contains(screenPoint) }
        let index = hit ?? level
        let frame = levels[index].panel.frame
        return (index, CGPoint(x: screenPoint.x - frame.minX, y: frame.maxY - screenPoint.y))
    }

    /// A rect in a panel's (flipped) view on screen.
    private func screenRect(_ rect: CGRect, in panel: NSPanel) -> NSRect {
        let frame = panel.frame
        return NSRect(x: frame.minX + rect.minX, y: frame.maxY - rect.maxY, width: rect.width, height: rect.height)
    }

    fileprivate func pointerMoved(level: Int, to screenPoint: NSPoint) {
        guard levels.indices.contains(level) else { return }
        let (level, point) = target(screenPoint, from: level)
        let state = levels[level].state
        // The panel's shadow margin is not the menu: the pointer there (often still on the trigger)
        // leaves the highlight alone until it has been in the menu.
        guard state.menuFrame.contains(point) || state.hasHadPointer else { return }
        state.hasHadPointer = true
        let row = state.row(at: point).flatMap { state.menu.items[$0].isSelectable ? $0 : nil }
        // Leaving the rows keeps an open submenu's row highlighted.
        if row == nil, levels.count > level + 1 { return }
        guard row != state.highlighted else { return }
        state.highlighted = row
        closeSubmenus(above: level)
        if let row, state.menu.items[row].submenu != nil { openSubmenu(level: level, row: row) }
    }

    fileprivate func pointerExited(level: Int) {
        guard levels.indices.contains(level), levels.count == level + 1, levels[level].state.hasHadPointer else { return }
        levels[level].state.highlighted = nil
    }

    fileprivate func pointerUp(level: Int, at screenPoint: NSPoint) {
        guard levels.indices.contains(level) else { return }
        let (level, point) = target(screenPoint, from: level)
        let state = levels[level].state
        guard state.menuFrame.contains(point) else { return close() }
        guard let row = state.row(at: point) else { return }
        choose(level: level, row: row)
    }

    // MARK: Choosing

    private func choose(level: Int, row: Int) {
        let item = levels[level].state.menu.items[row]
        guard item.isSelectable else { return }
        if item.submenu != nil {
            if levels.count <= level + 1 { openSubmenu(level: level, row: row) }
            return
        }
        close()
        // After the menu is gone: the action may open a sheet or another menu.
        if let action = item.action { DispatchQueue.main.async(execute: action) }
    }

    private func openSubmenu(level: Int, row: Int) {
        let parent = levels[level]
        guard let submenu = parent.state.menu.items[row].submenu,
              let rowFrame = parent.state.rowFrames[row] else { return }
        closeSubmenus(above: level)
        open(submenu, placement: .beside(row: screenRect(rowFrame, in: parent.panel),
                                         menu: screenRect(parent.state.menuFrame, in: parent.panel)))
    }

    private func closeSubmenus(above level: Int) {
        while levels.count > level + 1 {
            levels.removeLast().panel.orderOut(nil)
        }
    }

    // MARK: Keys and outside clicks

    private func startMonitoring() {
        let local = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel]) { [weak self] event in
            nonisolated(unsafe) let event = event
            let used = MainActor.assumeIsolated { self.map { $0.handle(event) == nil } ?? false }
            return used ? nil : event
        }
        let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }
        monitors = [local, global].compactMap(\.self)
        let center = NotificationCenter.default
        var names: [(Notification.Name, AnyObject?)] = [(NSApplication.didResignActiveNotification, NSApp)]
        if let window {
            for name in [NSWindow.didResizeNotification, NSWindow.didMoveNotification, NSWindow.willCloseNotification,
                         NSWindow.didMiniaturizeNotification, NSWindow.didResignKeyNotification] {
                names.append((name, window))
            }
        }
        observers = names.map { name, object in
            center.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.close() }
            }
        }
    }

    /// Returns the event to deliver, or nil when the menu used it.
    private func handle(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .keyDown:
            return handleKey(event) ? nil : event
        case .scrollWheel:
            close()
            return event
        default:
            if levels.contains(where: { $0.panel === event.window }) { return event }
            close()
            // A click elsewhere only closes the menu, like a system menu; a right click goes on so a
            // context menu can open where it landed.
            return event.type == .leftMouseDown ? nil : event
        }
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        guard let level = levels.indices.last else { return false }
        let state = levels[level].state
        switch event.keyCode {
        case 125, 126:  // ↓ ↑
            move(in: state, by: event.keyCode == 125 ? 1 : -1)
        case 124:  // →
            if let row = state.highlighted, state.menu.items[row].submenu != nil {
                openSubmenu(level: level, row: row)
                move(in: levels[level + 1].state, by: 1)
            }
        case 123:  // ←
            if level > 0 { closeSubmenus(above: level - 1) }
        case 36, 76, 49:  // ⏎, enter, space
            if let row = state.highlighted {
                choose(level: level, row: row)
                if levels.count > level + 1 { move(in: levels[level + 1].state, by: 1) }
            }
        case 53:  // Esc
            close()
        default:
            // Another key closes the menu and goes on (a shortcut still works).
            close()
            return false
        }
        return true
    }

    private func move(in state: ChromeMenuState, by step: Int) {
        let rows = state.menu.items.indices.filter { state.menu.items[$0].isSelectable }
        guard !rows.isEmpty else { return }
        guard let current = state.highlighted, let position = rows.firstIndex(of: current) else {
            state.highlighted = step > 0 ? rows.first : rows.last
            return
        }
        state.highlighted = rows[(position + step + rows.count) % rows.count]
    }

    func close() {
        guard Self.current === self else { return }
        Self.current = nil
        for level in levels { level.panel.orderOut(nil) }
        levels = []
        monitors.forEach(NSEvent.removeMonitor)
        monitors = []
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        let onClose = onClose
        self.onClose = nil
        onClose?()
    }
}

/// Borderless panel over everything, never key: the window keeps the keyboard and its look.
private final class ChromeMenuPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false  // drawn by the menu itself, as in the design
        level = .popUpMenu
        isReleasedWhenClosed = false
        hidesOnDeactivate = true
        animationBehavior = .none
        collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        acceptsMouseMovedEvents = true
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Draws the menu with SwiftUI; pointer handling is AppKit's, so it works in a window that is
/// never key (hover tracking is `activeAlways`).
private final class ChromeMenuHostingView: NSHostingView<AnyView> {
    weak var presenter: ChromeMenuPresenter?
    var level = 0
    private var tracking: NSTrackingArea?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                  owner: self, userInfo: nil)
        addTrackingArea(area)
        tracking = area
    }

    private func point(of event: NSEvent) -> NSPoint {
        window?.convertPoint(toScreen: event.locationInWindow) ?? NSEvent.mouseLocation
    }

    override func mouseMoved(with event: NSEvent) { presenter?.pointerMoved(level: level, to: point(of: event)) }
    override func mouseDragged(with event: NSEvent) { presenter?.pointerMoved(level: level, to: point(of: event)) }
    override func mouseEntered(with event: NSEvent) { presenter?.pointerMoved(level: level, to: point(of: event)) }
    override func mouseExited(with event: NSEvent) { presenter?.pointerExited(level: level) }
    override func mouseDown(with event: NSEvent) { presenter?.pointerMoved(level: level, to: point(of: event)) }
    override func mouseUp(with event: NSEvent) { presenter?.pointerUp(level: level, at: point(of: event)) }
    override func rightMouseDown(with event: NSEvent) { presenter?.pointerMoved(level: level, to: point(of: event)) }
    override func rightMouseUp(with event: NSEvent) { presenter?.pointerUp(level: level, at: point(of: event)) }
}
