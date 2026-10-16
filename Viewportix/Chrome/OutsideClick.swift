import AppKit
import SwiftUI

extension View {
    /// Our own popovers and menus close on Esc or a click outside them (STRIP-11), like system ones.
    /// `extra` grows the kept area (e.g. to include the trigger above the popover).
    func dismissOnOutsideClick(extra: EdgeInsets = EdgeInsets(), _ dismiss: @escaping () -> Void) -> some View {
        modifier(OutsideClickDismissal(extra: extra, dismiss: dismiss))
    }
}

private struct OutsideClickDismissal: ViewModifier {
    let extra: EdgeInsets
    let dismiss: () -> Void

    @State private var frame: CGRect = .zero
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
            .onAppear(perform: start)
            .onDisappear(perform: stop)
    }

    private func start() {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { event in
            nonisolated(unsafe) let event = event
            MainActor.assumeIsolated {
                if event.type == .keyDown {
                    if event.keyCode == 53 { dismiss() }  // Esc
                } else if let window = event.window {
                    // SwiftUI's global frame is top-left based; AppKit's window points are bottom-left.
                    let point = event.locationInWindow
                    let flipped = CGPoint(x: point.x, y: window.contentLayoutRect.height - point.y)
                    let kept = CGRect(x: frame.minX - extra.leading, y: frame.minY - extra.top,
                                      width: frame.width + extra.leading + extra.trailing,
                                      height: frame.height + extra.top + extra.bottom)
                    if !kept.contains(flipped) { dismiss() }
                }
            }
            return event
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
