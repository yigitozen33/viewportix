import AppKit
import DesignSystem
import Observation
import SwiftUI

extension View {
    /// Our sheet (U2, DESIGN.md §4 K7/K8; `dialogs-save-alerts@2x.png` 3. ve 5. bölüm): drops from
    /// the window's top, `surface/card`, `radius/card`, 20 inner padding, hairline, shadow 0 12 32
    /// 50 %, the window behind darkened with `canvas` 60 %. Drops in 240 ms on the one curve, leaves in
    /// 160 ms; Reduce Motion fades in 150 ms. The keyboard stays in the sheet; closing gives it back
    /// to the window (and the control that had it). The content puts its own ⏎ / esc buttons
    /// (`.keyboardShortcut(.defaultAction)` / `.cancelAction`).
    func chromeSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>, width: CGFloat = ChromeSheet.width, @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(ChromeSheetModifier(item: item, width: width, content: content))
    }
}

enum ChromeSheet {
    /// U2 sheets; the save sheet is 420.
    static let width: CGFloat = 360
    /// Inner padding; content spaces its rows itself (10, or 14 in the save sheet).
    static let padding: CGFloat = 20
    /// Where the sheet hangs: under the 36 pt title area drawn in the design frames.
    static let top: CGFloat = 36
}

private struct ChromeSheetModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    let width: CGFloat
    let content: (Item) -> SheetContent

    @State private var anchor = WindowAnchor()
    @State private var presenter: ChromeSheetPresenter?

    func body(content view: Content) -> some View {
        view
            .background(WindowAnchorView(anchor: anchor))
            .onChange(of: item?.id) { _, id in
                if id == nil {
                    presenter?.dismiss()
                    presenter = nil
                } else if let item, let window = anchor.window {
                    presenter?.dismiss()
                    // Closing from inside (Vazgeç, esc, done) clears the binding.
                    presenter = ChromeSheetPresenter(parent: window, width: width, content: AnyView(content(item))) {
                        self.item = nil
                    }
                }
            }
            .onDisappear {
                presenter?.dismiss()
                presenter = nil
            }
    }
}

/// Finds the window a SwiftUI view is in.
@MainActor
final class WindowAnchor {
    fileprivate weak var view: NSView?
    var window: NSWindow? { view?.window }
}

struct WindowAnchorView: NSViewRepresentable {
    let anchor: WindowAnchor

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

@MainActor
@Observable
private final class ChromeSheetModel {
    var isShown = false
}

/// A borderless child window over the whole parent: it takes the keyboard (so Tab, ⏎ and esc stay
/// in the sheet) and catches clicks meant for the window behind.
@MainActor
private final class ChromeSheetPresenter {
    private weak var parent: NSWindow?
    private let panel = ChromeSheetPanel()
    private let model = ChromeSheetModel()
    private var observers: [NSObjectProtocol] = []
    private var isDismissing = false
    private let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    init(parent: NSWindow, width: CGFloat, content: AnyView, close: @escaping () -> Void) {
        self.parent = parent
        let root = ChromeSheetContainer(model: model, width: width, content: content)
            .environment(\.chromeSheetClose, ChromeSheetClose(close))
        panel.contentView = NSHostingView(rootView: root)
        panel.setFrame(parent.frame, display: false)
        panel.setAccessibilityRole(.sheet)
        parent.addChildWindow(panel, ordered: .above)
        panel.makeKeyAndOrderFront(nil)
        withAnimation(Motion.curve(Motion.sheetIn, reduced: reduceMotion)) { model.isShown = true }

        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: NSWindow.didResizeNotification, object: parent, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.followParent() }
            },
            center.addObserver(forName: NSWindow.willCloseNotification, object: parent, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.remove() }
            },
        ]
    }

    private func followParent() {
        guard let parent else { return }
        panel.setFrame(parent.frame, display: true)
    }

    func dismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        withAnimation(Motion.curve(Motion.sheetOut, reduced: reduceMotion)) { model.isShown = false }
        let delay = reduceMotion ? 0.15 : Motion.sheetOut
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in remove() }
    }

    private func remove() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        guard panel.parent != nil || panel.isVisible else { return }
        parent?.removeChildWindow(panel)
        panel.orderOut(nil)
        // Back to the window; its first responder (the control that opened the sheet) is unchanged.
        parent?.makeKeyAndOrderFront(nil)
    }
}

private final class ChromeSheetPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: true)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Lets sheet content close itself (Vazgeç, esc, after saving) without knowing how it was shown.
struct ChromeSheetClose {
    private let action: () -> Void

    init(_ action: @escaping () -> Void) {
        self.action = action
    }

    func callAsFunction() { action() }
}

extension EnvironmentValues {
    @Entry var chromeSheetClose = ChromeSheetClose {}
}

private struct ChromeSheetContainer: View {
    let model: ChromeSheetModel
    let width: CGFloat
    let content: AnyView
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // The title area stays undimmed but takes clicks, as under a system sheet.
            Color.clear
                .frame(height: ChromeSheet.top)
                .contentShape(.rect)
            ZStack(alignment: .top) {
                DesignTokens.Color.canvas.opacity(0.6)
                    .opacity(model.isShown ? 1 : 0)
                    .contentShape(.rect)
                if model.isShown {
                    card
                        .transition(reduceMotion ? .opacity : .move(edge: .top))
                }
            }
            .clipped()
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private var card: some View {
        content
            .padding(ChromeSheet.padding)
            .frame(width: width, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .fill(DesignTokens.Color.surfaceCard)
                    .shadow(color: .black.opacity(0.5), radius: 16, y: 12)
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
            }
            .padding(.bottom, 44)  // room for the shadow while it slides
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
    }
}
