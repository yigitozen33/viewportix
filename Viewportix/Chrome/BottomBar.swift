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
    @State private var zoomAnchor = MenuAnchor()
    @State private var cameraAnchor = MenuAnchor()

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
            .background(MenuAnchorView(anchor: zoomAnchor))
            .chromeTooltip("Yakınlaştırma")

            ChromeButton.iconOnly(.system("camera"), title: "Ekran görüntüsü al", isActive: openMenu == .screenshot) {
                show(.screenshot)
            }
            .background(MenuAnchorView(anchor: cameraAnchor))
            .chromeTooltip("Ekran görüntüsü", shortcut: "⌥⌘S")
        }
        .padding(.vertical, DesignTokens.Space.s2)
        .padding(.horizontal, 10)
        .background(DesignTokens.Color.surfaceHeader, in: .rect(cornerRadius: DesignTokens.Radius.bar))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.bar)
                .strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
        }
        .onChange(of: openMenu) { _, menu in isMenuOpen = menu != nil }
    }

    /// Menus open 8 pt above the bar (16 above the control: the bar's 8 pt padding), the zoom menu
    /// lined up with the zoom control's left edge, the chooser with the camera's right edge
    /// (`window-project-zoom-menu-open@2x.png`, `window-project-screenshot-menu@2x.png`; BAR-03, BAR-06).
    private func show(_ menu: OpenMenu) {
        if openMenu == menu {
            openMenu = nil
            return
        }
        openMenu = menu
        let gap = DesignTokens.Space.s2 * 2
        switch menu {
        case .zoom: zoomAnchor.show(zoomMenu(), edge: .top, gap: gap) { openMenu = nil }
        case .screenshot: cameraAnchor.show(screenshotMenu(), edge: .top, alignment: .trailing, gap: gap) { openMenu = nil }
        }
    }

    /// `Zoom Menu`: a check column, the current stop ticked.
    private func zoomMenu() -> ChromeMenu {
        let canvas = workspace.canvas
        let workspace = workspace
        var items: [ChromeMenuItem] = [
            .button("Sığdır", shortcut: "⌘1") { canvas?.fit() },
            .button("Seçimi sığdır", shortcut: "⌘2", isEnabled: workspace.selectedViewportID != nil) { workspace.fitSelection() },
            .separator,
        ]
        for percent in [25, 50, 100, 200] {
            let isCurrent = Int((workspace.zoom * 100).rounded()) == percent
            items.append(.button(ZoomControl.format(Double(percent) / 100), isChecked: isCurrent) {
                canvas?.setZoomPercent(Double(percent))
            })
        }
        items += [
            .separator,
            .button("Gerçek boyut", shortcut: "⌘0") { canvas?.actualSize() },
            .button("Yakınlaştır", shortcut: "⌘+") { canvas?.zoomIn() },
            .button("Uzaklaştır", shortcut: "⌘−") { canvas?.zoomOut() },
        ]
        return ChromeMenu(width: 240, showsChecks: true, items: items)
    }

    /// `Screenshot Chooser`: both areas for every viewport, the settings in one line underneath.
    private func screenshotMenu() -> ChromeMenu {
        let workspace = workspace
        return ChromeMenu(style: .chooser, width: 300, items: [
            .header("EKRAN GÖRÜNTÜSÜ · \(workspace.viewports.count) VIEWPORT"),
            .button("Görünen alan", subtitle: "Her viewport'un şu an ekranda olan kısmı", symbol: "viewfinder", shortcut: "⌥⌘S") {
                Task { await workspace.captureAll(area: .visible) }
            },
            .button("Tam sayfa", subtitle: "Her viewport'un sayfanın tamamı", symbol: "arrow.down.document", shortcut: "⌃⌥⌘S") {
                Task { await workspace.captureAll(area: .fullPage) }
            },
            .separator,
            .footer(Self.settingsSummary) {
                withAnimation(.easeOut(duration: DesignTokens.Motion.panel)) { workspace.settingsTab = .general }
            },
        ])
    }

    /// "Panoya kopyala ✓ · 2× · ~/Pictures/Viewportix — Ayarlar'da".
    static var settingsSummary: String {
        let defaults = UserDefaults.standard
        let copy = defaults.bool(forKey: AppSettings.copyScreenshot) ? "Panoya kopyala ✓" : "Panoya kopyalanmaz"
        let folder = (AppSettings.screenshotFolderURL.path(percentEncoded: false) as NSString).abbreviatingWithTildeInPath
        return "\(copy) · \(defaults.integer(forKey: AppSettings.screenshotScale))× · \(folder) — Ayarlar'da"
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
