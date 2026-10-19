import AppKit
import DesignSystem
import SwiftUI

/// `Action/Primary`, `Action/Secondary` (DESIGN.md §4 K4 f, §6): a word and its key. 24 pt,
/// `radius/badge`, caption. One primary (yellow) per surface. The key chip shows only on the focused
/// row (open row or keyboard focus) and always inside sheets and alerts.
struct ActionButton: View {
    enum Kind { case primary, secondary }

    let title: String
    var kind = Kind.secondary
    /// Shown in the chip: "⏎", "esc", "⌘Z", "A"…
    var key: String?
    var showsKey = true
    let action: () -> Void

    init(_ title: String, kind: Kind = .secondary, key: String? = nil, showsKey: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.kind = kind
        self.key = key
        self.showsKey = showsKey
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: DesignTokens.FontSize.caption, weight: kind == .primary ? .semibold : .regular))
                    .lineLimit(1)
                if let key, showsKey {
                    KeyChip(key: key, kind: kind)
                }
            }
        }
        .buttonStyle(ActionButtonStyle(kind: kind, hasKey: key != nil && showsKey))
        .accessibilityLabel(title)
    }

}

/// The key chip: micro, 4 pt corners, 1/3 padding; on yellow `accent/ink` 12 %, on grey
/// `surface/header` — and `surface/pill` while a grey button is pressed, whose own fill is then
/// `surface/header` (2026-10-19 decision; the chip disappeared).
private struct KeyChip: View {
    let key: String
    let kind: ActionButton.Kind
    @Environment(\.actionButtonIsPressed) private var isPressed

    var body: some View {
        Text(key)
            .font(.system(size: DesignTokens.FontSize.micro))
            .padding(EdgeInsets(top: 1, leading: 3, bottom: 1, trailing: 3))
            .background(fill, in: .rect(cornerRadius: 4))
            .foregroundStyle(kind == .primary ? DesignTokens.Color.accentInk : DesignTokens.Color.inkSecondary)
            .accessibilityHidden(true)
    }

    private var fill: Color {
        switch kind {
        case .primary: DesignTokens.Color.accentInk.opacity(0.12)
        case .secondary: isPressed ? DesignTokens.Color.surfacePill : DesignTokens.Color.surfaceHeader
        }
    }
}

/// Hover one tone lighter (yellow +6 %), mouse press 97 % + one tone darker + 1 pt inner shadow
/// (yellow −12 %) in 80 ms / 120 ms, no press animation from the keyboard (K5), focus 2 pt
/// `ink/primary`, disabled `surface/group` + `ink/secondary`.
struct ActionButtonStyle: ButtonStyle {
    let kind: ActionButton.Kind
    var hasKey = true

    func makeBody(configuration: Configuration) -> some View {
        StyledBody(configuration: configuration, kind: kind, hasKey: hasKey)
    }

    private struct StyledBody: View {
        let configuration: Configuration
        let kind: ActionButton.Kind
        let hasKey: Bool
        @State private var isHovered = false
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.isFocused) private var isFocused
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.actionButtonPreviewState) private var previewState

        /// `isPressed` is only set by the pointer: a keyboard shortcut or Space fires the action
        /// without it, so keyboard decisions don't move the button.
        private var isPressed: Bool { isEnabled && (configuration.isPressed || previewState == .pressed) }
        private var isHighlighted: Bool { isHovered || previewState == .hovered }
        private var showsFocus: Bool { isFocused || previewState == .focused }

        var body: some View {
            configuration.label
                .environment(\.actionButtonIsPressed, isPressed)
                .foregroundStyle(ink)
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: hasKey ? 5 : 8))
                .frame(height: 24)
                .background(fill, in: .rect(cornerRadius: DesignTokens.Radius.badge))
                .overlay {
                    if isPressed {
                        // 1 pt inner shadow along the top edge.
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.badge)
                            .stroke(Color.black.opacity(0.35), lineWidth: 1)
                            .blur(radius: 0.5)
                            .offset(y: 0.5)
                            .clipShape(.rect(cornerRadius: DesignTokens.Radius.badge))
                            .allowsHitTesting(false)
                    }
                }
                .contentShape(.rect(cornerRadius: DesignTokens.Radius.badge))
                .scaleEffect(isPressed && !reduceMotion ? Motion.pressScale : 1)
                .animation(Motion.curve(isPressed ? Motion.pressIn : Motion.pressOut), value: isPressed)
                .animation(.linear(duration: DesignTokens.Motion.hover), value: isHovered)
                .onHover { isHovered = $0 }
                .focusEffectDisabled()
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.badge + DesignTokens.Stroke.focus)
                        .strokeBorder(DesignTokens.Color.inkPrimary, lineWidth: DesignTokens.Stroke.focus)
                        .padding(-DesignTokens.Stroke.focus)
                        .opacity(showsFocus ? 1 : 0)
                        .allowsHitTesting(false)
                }
        }

        private var ink: Color {
            guard isEnabled else { return DesignTokens.Color.inkSecondary }
            return kind == .primary ? DesignTokens.Color.accentInk : DesignTokens.Color.inkPrimary
        }

        private var fill: Color {
            guard isEnabled else { return DesignTokens.Color.surfaceGroup }
            switch kind {
            case .primary:
                if isPressed { return DesignTokens.Color.accent.adjustingBrightness(by: -0.12) }
                // The yellow is already at full brightness: +6 % means 6 % towards white.
                return isHighlighted ? DesignTokens.Color.accent.mix(with: .white, by: 0.06) : DesignTokens.Color.accent
            case .secondary:
                if isPressed { return DesignTokens.Color.surfaceHeader }
                return isHighlighted ? DesignTokens.Color.lineStrong : DesignTokens.Color.surfacePill
            }
        }
    }
}

/// Snapshots draw hover, press and focus without a pointer or keyboard.
enum ActionButtonPreviewState { case hovered, pressed, focused }

extension EnvironmentValues {
    @Entry var actionButtonPreviewState: ActionButtonPreviewState?
    /// Set by the style for the label, so the key chip can follow the press.
    @Entry var actionButtonIsPressed = false
}

extension Color {
    /// The same colour with HSB brightness moved by `amount` (−1…1), clamped.
    func adjustingBrightness(by amount: CGFloat) -> Color {
        let color = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(nsColor: NSColor(hue: hue, saturation: saturation, brightness: min(max(brightness * (1 + amount), 0), 1), alpha: alpha))
    }
}
