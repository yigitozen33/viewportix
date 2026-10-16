import AppKit
import SwiftUI

/// Opens an AppKit menu from SwiftUI chrome at a chosen spot. SwiftUI's `Menu` owns its label's
/// clicks, which the zoom percentage can't give up (click opens the menu, drag zooms).
@MainActor
final class MenuAnchor {
    fileprivate weak var view: NSView?

    /// Pops `menu` so its bottom edge sits `gap` points above the anchor view's top, left edge at `x`
    /// points from the anchor's left. Returns when the menu closes.
    func popUpAbove(_ menu: NSMenu, x: CGFloat, gap: CGFloat) {
        guard let view else { return }
        // popUp takes the menu's top-left corner; the anchor view is not flipped.
        let topLeft = NSPoint(x: x, y: view.bounds.height + gap + menu.size.height)
        menu.popUp(positioning: nil, at: topLeft, in: view)
    }
}

/// Place behind the view the menu should open relative to.
struct MenuAnchorView: NSViewRepresentable {
    let anchor: MenuAnchor

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        anchor.view = view
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        anchor.view = view
    }
}

/// Menu item that runs a closure.
final class ActionMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String = "", modifiers: NSEvent.ModifierFlags = .command, symbol: String? = nil,
         isChecked: Bool = false, isEnabled: Bool = true, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(runHandler), keyEquivalent: key)
        keyEquivalentModifierMask = modifiers
        target = self
        state = isChecked ? .on : .off
        self.isEnabled = isEnabled
        if let symbol { image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) }
    }

    required init(coder: NSCoder) { fatalError("not used") }

    @objc private func runHandler() { handler() }
}
