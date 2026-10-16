import AppKit
import SwiftUI

extension View {
    /// AppKit context menu on right-click / ⌃-click that also reports while it is open, so the target
    /// can show its "context target" look (HOME-06). SwiftUI's `.contextMenu` reports neither.
    func chromeContextMenu(isOpen: Binding<Bool>, menu: @escaping () -> NSMenu) -> some View {
        overlay(ContextMenuArea(isOpen: isOpen, makeMenu: menu))
    }
}

private struct ContextMenuArea: NSViewRepresentable {
    @Binding var isOpen: Bool
    let makeMenu: () -> NSMenu

    func makeNSView(context: Context) -> ContextMenuView {
        ContextMenuView()
    }

    func updateNSView(_ view: ContextMenuView, context: Context) {
        view.makeMenu = makeMenu
        view.onOpenChange = { isOpen = $0 }
    }

    final class ContextMenuView: NSView, NSMenuDelegate {
        var makeMenu: (() -> NSMenu)?
        var onOpenChange: ((Bool) -> Void)?

        /// Only right-clicks (and ⌃-clicks) land here; everything else passes through to SwiftUI.
        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let event = NSApp.currentEvent else { return nil }
            let isContextClick = event.type == .rightMouseDown
                || (event.type == .leftMouseDown && event.modifierFlags.contains(.control))
            return isContextClick ? super.hitTest(point) : nil
        }

        override func menu(for event: NSEvent) -> NSMenu? {
            guard let menu = makeMenu?() else { return nil }
            menu.delegate = self
            return menu
        }

        override func mouseDown(with event: NSEvent) {
            // ⌃-click arrives as a left click.
            guard let menu = menu(for: event) else { return }
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }

        func menuWillOpen(_ menu: NSMenu) { onOpenChange?(true) }
        func menuDidClose(_ menu: NSMenu) { onOpenChange?(false) }
    }
}
