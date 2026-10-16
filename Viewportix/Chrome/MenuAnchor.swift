import AppKit
import SwiftUI

/// Opens a `ChromeMenu` from SwiftUI chrome next to its trigger. SwiftUI's `Menu` owns its label's
/// clicks, which the zoom percentage can't give up (click opens the menu, drag zooms), and draws the
/// system menu, not ours.
@MainActor
final class MenuAnchor {
    fileprivate weak var view: NSView?

    /// Opens `menu` above (`.top`) or below (`.bottom`) the trigger, `gap` points from its edge, lined
    /// up with the trigger on `alignment`. `onClose` runs when the menu closes, chosen or not.
    func show(_ menu: ChromeMenu, edge: VerticalEdge, alignment: HorizontalAlignment = .leading, gap: CGFloat,
              onClose: (() -> Void)? = nil) {
        guard let view, let window = view.window else {
            onClose?()
            return
        }
        var menu = menu
        if menu.width == 0 { menu.width = view.bounds.width }
        let rect = view.convert(view.bounds, to: nil)
        let placement: ChromeMenuPresenter.Placement = edge == .top
            ? .above(rect, alignment, gap: gap)
            : .below(rect, alignment, gap: gap)
        ChromeMenuPresenter.show(menu, in: window, placement: placement, onClose: onClose)
    }
}

/// Put behind the trigger (`.background(MenuAnchorView(anchor:))`): the menu lines up with its frame.
struct MenuAnchorView: NSViewRepresentable {
    let anchor: MenuAnchor

    func makeNSView(context: Context) -> NSView {
        let view = PassthroughView()
        anchor.view = view
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        anchor.view = view
    }

    private final class PassthroughView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
}
