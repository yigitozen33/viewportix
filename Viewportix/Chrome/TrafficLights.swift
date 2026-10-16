import AppKit
import SwiftUI

extension View {
    /// Places the window's own close / minimise / zoom buttons: the first button's left edge at
    /// `leading`, their centre `centerY` points below the window's top. The system buttons stay
    /// (hover glyphs, accessibility, full screen); only their position follows our chrome —
    /// the sidebar's 48 pt top row, or the collapsed header capsule (DESIGN.md §6).
    func trafficLights(leading: CGFloat, centerY: CGFloat) -> some View {
        background(TrafficLightPlacer(leading: leading, centerY: centerY))
    }
}

private struct TrafficLightPlacer: NSViewRepresentable {
    let leading: CGFloat
    let centerY: CGFloat

    func makeNSView(context: Context) -> PlacerView { PlacerView() }

    func updateNSView(_ view: PlacerView, context: Context) {
        view.position = (leading, centerY)
    }

    final class PlacerView: NSView {
        var position: (leading: CGFloat, centerY: CGFloat) = (20, 24) {
            didSet { place() }
        }
        private var observers: [NSObjectProtocol] = []

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            observers.forEach(NotificationCenter.default.removeObserver)
            observers = []
            guard let window else { return }
            // AppKit lays the title bar out again on these; put the buttons back each time.
            for name in [NSWindow.didResizeNotification, NSWindow.didEndLiveResizeNotification,
                         NSWindow.didExitFullScreenNotification, NSWindow.didBecomeKeyNotification] {
                observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.place() }
                })
            }
            place()
            // AppKit also lays the title bar out on its own (title or edited state changes, a sheet,
            // focus moving into a web view) without a window notification; found in the live app.
            // Watching the frames catches every case.
            if let close = window.standardWindowButton(.closeButton), let container = close.superview?.superview {
                for view in [close, container] {
                    view.postsFrameChangedNotifications = true
                    observers.append(NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: view, queue: .main) { [weak self] _ in
                        MainActor.assumeIsolated { self?.placeIfMoved() }
                    })
                }
            }
        }

        private var isPlacing = false

        private func placeIfMoved() {
            guard !isPlacing else { return }
            // Out of AppKit's own layout pass, or it moves them right back.
            DispatchQueue.main.async { [weak self] in self?.place() }
        }

        /// Same approach as Electron's `trafficLightPosition`: grow the title bar container to fit,
        /// then move the buttons inside it.
        private func place() {
            guard let window, !window.styleMask.contains(.fullScreen),
                  let close = window.standardWindowButton(.closeButton),
                  let miniaturize = window.standardWindowButton(.miniaturizeButton),
                  let zoom = window.standardWindowButton(.zoomButton),
                  let container = close.superview?.superview else { return }
            isPlacing = true
            defer { isPlacing = false }
            let buttonHeight = close.frame.height
            let titleBarHeight = position.centerY * 2
            var frame = container.frame
            frame.size.height = titleBarHeight
            frame.origin.y = window.frame.height - titleBarHeight
            if container.frame != frame { container.frame = frame }
            let spacing: CGFloat = 20  // 12 pt lights, 8 pt gap (Sidebar/Header spec)
            for (index, button) in [close, miniaturize, zoom].enumerated() {
                let origin = NSPoint(x: position.leading + CGFloat(index) * spacing, y: (titleBarHeight - buttonHeight) / 2)
                if button.frame.origin != origin { button.setFrameOrigin(origin) }
            }
        }
    }
}

extension View {
    /// Reports whether the window is in full screen (DESIGN.md §5.20 b: no traffic lights there,
    /// the sidebar's 48 pt top row drops to 16).
    func onFullScreenChange(_ action: @escaping (Bool) -> Void) -> some View {
        background(FullScreenObserver(action: action))
    }
}

private struct FullScreenObserver: NSViewRepresentable {
    let action: (Bool) -> Void

    func makeNSView(context: Context) -> ObserverView { ObserverView() }

    func updateNSView(_ view: ObserverView, context: Context) {
        view.action = action
    }

    final class ObserverView: NSView {
        var action: ((Bool) -> Void)?
        private var observers: [NSObjectProtocol] = []

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            observers.forEach(NotificationCenter.default.removeObserver)
            observers = []
            guard let window else { return }
            for name in [NSWindow.willEnterFullScreenNotification, NSWindow.didExitFullScreenNotification] {
                let entering = name == NSWindow.willEnterFullScreenNotification
                observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.action?(entering)
                    }
                })
            }
            action?(window.styleMask.contains(.fullScreen))
        }
    }
}
