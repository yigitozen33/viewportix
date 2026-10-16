import DesignSystem
import SwiftUI

/// `Toolbar/Button` (specs/ChromeButton.json): icon + label, or icon-only inside bars.
struct ChromeButton: View {
    let icon: ChromeSymbol.Source
    let title: String
    var showsTitle = true
    var iconBox: CGFloat = DesignTokens.Size.iconSm
    var insets = EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
    /// Pressed look while the button's menu or picker is open.
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                ChromeSymbol(icon, box: iconBox)
                if showsTitle {
                    Text(title).font(.system(size: DesignTokens.FontSize.label))
                }
            }
            .foregroundStyle(DesignTokens.Color.inkPrimary)
        }
        .buttonStyle(ChromeButtonStyle(insets: insets, isActive: isActive))
        .accessibilityLabel(title)
    }
}

extension ChromeButton {
    /// Icon-only variant used in the bottom bar: 16 pt icon box, 8 pt padding.
    static func iconOnly(_ icon: ChromeSymbol.Source, title: String, isActive: Bool = false, action: @escaping () -> Void) -> ChromeButton {
        ChromeButton(
            icon: icon, title: title, showsTitle: false, iconBox: DesignTokens.Size.icon,
            insets: EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8), isActive: isActive, action: action
        )
    }
}

/// Fill `surface/card`; hover, pressed and menu open `surface/header-leader`; keyboard focus ring.
struct ChromeButtonStyle: ButtonStyle {
    var insets: EdgeInsets
    var isActive = false

    func makeBody(configuration: Configuration) -> some View {
        StyledBody(configuration: configuration, insets: insets, isActive: isActive)
    }

    private struct StyledBody: View {
        let configuration: Configuration
        let insets: EdgeInsets
        let isActive: Bool
        @State private var isHovered = false
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .opacity(isEnabled ? 1 : 0.4)
                .padding(insets)
                .background(fill, in: .rect(cornerRadius: DesignTokens.Radius.control))
                .contentShape(.rect(cornerRadius: DesignTokens.Radius.control))
                .onHover { isHovered = $0 }
                .animation(.linear(duration: DesignTokens.Motion.hover), value: isHighlighted)
                .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        }

        private var isHighlighted: Bool { isEnabled && (isHovered || isActive || configuration.isPressed) }

        private var fill: Color {
            isHighlighted ? DesignTokens.Color.surfaceHeaderLeader : DesignTokens.Color.surfaceCard
        }
    }
}

extension View {
    /// Keyboard focus ring (DESIGN.md §4, F1): 2 pt `status/leader`, just outside the control,
    /// only for keyboard focus. Replaces the system ring.
    func chromeFocusRing(cornerRadius: CGFloat) -> some View {
        modifier(ChromeFocusRing(cornerRadius: cornerRadius))
    }
}

private struct ChromeFocusRing: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.isFocused) private var isFocused

    func body(content: Content) -> some View {
        content
            .focusEffectDisabled()
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius + DesignTokens.Stroke.focus)
                    .strokeBorder(DesignTokens.Color.statusLeader, lineWidth: DesignTokens.Stroke.focus)
                    .padding(-DesignTokens.Stroke.focus)
                    .opacity(isFocused ? 1 : 0)
                    .animation(.linear(duration: DesignTokens.Motion.hover), value: isFocused)
                    .allowsHitTesting(false)
            }
    }
}
