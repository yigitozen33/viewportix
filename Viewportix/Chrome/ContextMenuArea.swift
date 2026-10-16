import AppKit
import SwiftUI

extension View {
    /// Our context menu (`ChromeMenu`) on right-click / ⌃-click, top-left at the pointer; reports
    /// while it is open, so the target can show its "context target" look (HOME-06).
    func chromeContextMenu(isOpen: Binding<Bool>, menu: @escaping () -> ChromeMenu) -> some View {
        overlay(ContextMenuArea(isOpen: isOpen, makeMenu: menu))
    }
}

private struct ContextMenuArea: NSViewRepresentable {
    @Binding var isOpen: Bool
    let makeMenu: () -> ChromeMenu

    func makeNSView(context: Context) -> ContextMenuView {
        ContextMenuView()
    }

    func updateNSView(_ view: ContextMenuView, context: Context) {
        view.makeMenu = makeMenu
        view.onOpenChange = { isOpen = $0 }
    }

    final class ContextMenuView: NSView {
        var makeMenu: (() -> ChromeMenu)?
        var onOpenChange: ((Bool) -> Void)?

        /// Only right-clicks (and ⌃-clicks) land here; everything else passes through to SwiftUI.
        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let event = NSApp.currentEvent else { return nil }
            let isContextClick = event.type == .rightMouseDown
                || (event.type == .leftMouseDown && event.modifierFlags.contains(.control))
            return isContextClick ? super.hitTest(point) : nil
        }

        override func rightMouseDown(with event: NSEvent) { present(event) }

        /// ⌃-click arrives as a left click.
        override func mouseDown(with event: NSEvent) { present(event) }

        private func present(_ event: NSEvent) {
            guard let window, let menu = makeMenu?() else { return }
            onOpenChange?(true)
            let onOpenChange = onOpenChange
            ChromeMenuPresenter.show(menu, in: window, placement: .at(event.locationInWindow)) {
                onOpenChange?(false)
            }
        }
    }
}
