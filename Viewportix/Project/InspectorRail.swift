import DesignSystem
import SwiftUI

/// `Window/Rail` (specs/InspectorRail.json): 44 pt on the window's right edge. Ayarlar, Cihazlar and
/// Hesap open the settings panel (RAIL-01); MCP (M7), Farklar and Senkron (M5) are disabled until
/// their panels exist. The collapse button hides the rail (RAIL-03).
struct InspectorRail: View {
    @Bindable var workspace: Workspace

    var body: some View {
        VStack(spacing: 6) {
            panelItem(.general, label: "Ayarlar", shortcut: "⌘,")
            panelItem(.devices, label: "Cihazlar")
            RailItem(symbol: "powerplug.portrait", label: "MCP", isEnabled: false) {}  // M7
            panelItem(.account, label: "Hesap")
            Rectangle().fill(DesignTokens.Color.line).frame(width: 20, height: 1)
            RailItem(symbol: "square.split.2x1", label: "Farklar", shortcut: "⌥⌘1", isEnabled: false) {}
            RailItem(symbol: "waveform.path.ecg", label: "Senkron Kaydı", shortcut: "⌥⌘2", isEnabled: false) {}
            Spacer()
            RailItem(symbol: "sidebar.right", label: "Rayı Gizle", shortcut: "⌥⌘0") {
                withAnimation(.easeInOut(duration: DesignTokens.Motion.panel)) { workspace.isRailVisible = false }
            }
        }
        .padding(EdgeInsets(top: DesignTokens.Space.s3, leading: 6, bottom: DesignTokens.Space.s3, trailing: 6))
        .frame(width: DesignTokens.Size.rail)
        .frame(maxHeight: .infinity)
        .background(DesignTokens.Color.surfaceBar)
        .overlay(alignment: .leading) {
            Rectangle().fill(DesignTokens.Color.line).frame(width: DesignTokens.Stroke.hairline)
        }
    }
}

private extension InspectorRail {
    /// RAIL-01: opens the settings panel on that tab; the same icon again closes it.
    func panelItem(_ tab: SettingsTab, label: String, shortcut: String? = nil) -> some View {
        RailItem(symbol: tab.symbol, label: label, shortcut: shortcut, isActive: workspace.settingsTab == tab) {
            withAnimation(.easeOut(duration: DesignTokens.Motion.panel)) {
                workspace.settingsTab = workspace.settingsTab == tab ? nil : tab
            }
        }
    }
}

/// 32 × 32 rail item: hover and active `surface/header-leader`, active icon `ink/primary`, optional
/// 7 pt coral badge at (22, 4). Tooltip on its left (DESIGN.md §5.20 c).
private struct RailItem: View {
    let symbol: String
    let label: String
    var shortcut: String?
    var isActive = false
    var hasBadge = false
    var isEnabled = true
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ChromeSymbol(symbol, box: DesignTokens.Size.icon)
                .foregroundStyle(isActive ? DesignTokens.Color.inkPrimary : DesignTokens.Color.inkSecondary)
                .frame(width: 32, height: 32)
                .background((isHovered && isEnabled) || isActive ? DesignTokens.Color.surfaceHeaderLeader : .clear,
                            in: .rect(cornerRadius: DesignTokens.Radius.control))
                .overlay(alignment: .topLeading) {
                    if hasBadge {
                        Circle().fill(DesignTokens.Color.statusWarning).frame(width: 7, height: 7).offset(x: 22, y: 4)
                    }
                }
                .contentShape(.rect)
                .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { isHovered = $0 }
        .animation(.linear(duration: DesignTokens.Motion.hover), value: isHovered)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .chromeTooltip(label, shortcut: shortcut, edge: .leading)
        .accessibilityLabel(label)
    }
}

/// `Window/RailHandle` (specs/RailHandle.json): with the rail hidden, a 24 × 56 tab on the right edge,
/// 16 pt from the top; click or ⌥⌘0 brings the rail back (RAIL-04, RAIL-05).
struct RailHandle: View {
    @Bindable var workspace: Workspace
    var hasBadge = false

    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: DesignTokens.Motion.panel)) { workspace.isRailVisible = true }
        } label: {
            VStack(spacing: DesignTokens.Space.s2) {
                ChromeSymbol("sidebar.right", box: DesignTokens.Size.iconSm)
                    .foregroundStyle(isHovered ? DesignTokens.Color.inkPrimary : DesignTokens.Color.inkSecondary)
                if hasBadge {
                    Circle().fill(DesignTokens.Color.statusWarning).frame(width: 7, height: 7)
                }
            }
            .frame(width: 24, height: 56)
            .background(DesignTokens.Color.surfaceBar, in: UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8))
            .overlay {
                UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8)
                    .strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .chromeTooltip("Rayı göster", shortcut: "⌥⌘0", edge: .leading)
        .accessibilityLabel("Rayı göster")
        .accessibilityHint("⌥⌘0")
    }
}
