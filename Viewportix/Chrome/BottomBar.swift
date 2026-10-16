import AppKit
import DesignSystem
import EngineCore
import SwiftUI

/// `Window/BottomBar` (specs/BottomBar.json): floating capsule centred under the canvas, 31 pt from
/// its bottom. Sync · Fit · zoom · screenshot; interactions BAR-01…07 (DESIGN.md §3.2).
/// Tooltips (BAR-01) are `ChromeTooltip`s, 8 pt above the control after 400 ms.
struct BottomBar: View {
    @Bindable var workspace: Workspace
    /// True while one of the bar's menus is open; the notice capsule hides meanwhile.
    @Binding var isMenuOpen: Bool

    static let bottomInset: CGFloat = 31

    private enum OpenMenu { case zoom, screenshot }

    @State private var openMenu: OpenMenu?
    @State private var menuAnchor = MenuAnchor()
    @State private var zoomMinX: CGFloat = 0
    @State private var cameraMinX: CGFloat = 0

    var body: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            SyncToggle(isOn: $workspace.isSyncEnabled)
                .chromeTooltip("Senkron", shortcut: "⇧⌘L")

            ChromeButton.iconOnly(.system("arrow.up.left.and.arrow.down.right"), title: "Sığdır") {
                workspace.canvas?.fit()
            }
            .chromeTooltip("Sığdır", shortcut: "⌘1")

            ZoomControl(
                zoom: workspace.zoom,
                isMenuOpen: openMenu == .zoom,
                onStep: { workspace.canvas?.stepZoom(up: $0) },
                onScrub: { workspace.canvas?.setZoomPercent($0 * 100) },
                onOpenMenu: { show(.zoom) }
            )
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(Self.space)).minX } action: { zoomMinX = $0 }
            .chromeTooltip("Yakınlaştırma")

            ChromeButton.iconOnly(.system("camera"), title: "Ekran görüntüsü al", isActive: openMenu == .screenshot) {
                show(.screenshot)
            }
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(Self.space)).minX } action: { cameraMinX = $0 }
            .chromeTooltip("Ekran görüntüsü", shortcut: "⌥⌘S")
        }
        .padding(.vertical, DesignTokens.Space.s2)
        .padding(.horizontal, 10)
        .background(DesignTokens.Color.surfaceHeader, in: .rect(cornerRadius: DesignTokens.Radius.bar))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.bar)
                .strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
        }
        // Zero-size anchor at the bar's top-left: menus open above the bar's top edge.
        .background(alignment: .topLeading) { MenuAnchorView(anchor: menuAnchor).frame(width: 0, height: 0) }
        .coordinateSpace(.named(Self.space))
        .onChange(of: openMenu) { _, menu in isMenuOpen = menu != nil }
    }

    private nonisolated static let space = "BottomBar"

    /// Menus open above the bar, left-aligned with their trigger (BAR-03, BAR-06).
    private func show(_ menu: OpenMenu) {
        openMenu = menu
        // Let the pressed look render before the menu's tracking loop takes over.
        DispatchQueue.main.async {
            switch menu {
            case .zoom: menuAnchor.popUpAbove(zoomMenu(), x: zoomMinX, gap: DesignTokens.Space.s2)
            case .screenshot: menuAnchor.popUpAbove(screenshotMenu(), x: cameraMinX, gap: DesignTokens.Space.s2)
            }
            openMenu = nil
        }
    }

    private func zoomMenu() -> NSMenu {
        let canvas = workspace.canvas
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(ActionMenuItem("Sığdır", key: "1") { canvas?.fit() })
        menu.addItem(ActionMenuItem("Seçimi Sığdır", key: "2", isEnabled: false) {})  // no selection yet (CARD-02)
        menu.addItem(.separator())
        for percent in [25, 50, 100, 200] {
            let isCurrent = Int((workspace.zoom * 100).rounded()) == percent
            menu.addItem(ActionMenuItem(ZoomControl.format(Double(percent) / 100), isChecked: isCurrent) {
                canvas?.setZoomPercent(Double(percent))
            })
        }
        menu.addItem(.separator())
        menu.addItem(ActionMenuItem("Gerçek Boyut", key: "0") { canvas?.actualSize() })
        // "=" like the View menu: on a Turkish keyboard "+" shows as "⌘:".
        menu.addItem(ActionMenuItem("Yakınlaştır", key: "=") { canvas?.zoomIn() })
        menu.addItem(ActionMenuItem("Uzaklaştır", key: "-") { canvas?.zoomOut() })
        return menu
    }

    private func screenshotMenu() -> NSMenu {
        let workspace = workspace
        let menu = NSMenu()
        menu.addItem(.sectionHeader(title: "EKRAN GÖRÜNTÜSÜ · \(workspace.viewports.count) VIEWPORT"))
        menu.addItem(ActionMenuItem("Görünen alan", key: "s", modifiers: [.command, .option], symbol: "viewfinder") {
            Task { await workspace.captureAll(area: .visible) }
        })
        menu.addItem(ActionMenuItem("Tam sayfa", key: "s", modifiers: [.command, .option, .control], symbol: "arrow.down.document") {
            Task { await workspace.captureAll(area: .fullPage) }
        })
        return menu
    }
}

/// Sync on: `accent` with a link; off: `surface/card` with `link.slash` in `ink/secondary` (BAR-02).
private struct SyncToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: DesignTokens.Motion.standard)) { isOn.toggle() }
        } label: {
            ChromeSymbol(isOn ? .system("link") : .asset("link.slash"), box: DesignTokens.Size.iconSm)
                .foregroundStyle(isOn ? DesignTokens.Color.accentInk : DesignTokens.Color.inkSecondary)
                .padding(DesignTokens.Space.s2)
                .background(isOn ? DesignTokens.Color.accent : DesignTokens.Color.surfaceCard,
                            in: .rect(cornerRadius: DesignTokens.Radius.control))
                .contentShape(.rect(cornerRadius: DesignTokens.Radius.control))
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .accessibilityLabel("Senkron")
        .accessibilityValue(isOn ? "Açık" : "Kapalı")
    }
}

#Preview("BottomBar") {
    @Previewable @State var workspace = Workspace()
    @Previewable @State var isMenuOpen = false
    BottomBar(workspace: workspace, isMenuOpen: $isMenuOpen)
        .padding(24)
        .background(DesignTokens.Color.canvas)
}
