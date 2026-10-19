import DesignSystem
import SwiftUI

/// `Home/URLBox` (specs/URLBox.json): empty, filled, invalid. "Aç →" is always yellow; with an empty
/// field it focuses the field instead of opening (HOME-01).
struct URLBox: View {
    @Binding var text: String
    /// Coral border and the hint below; set by the owner after a failed open, cleared on edit.
    var isInvalid: Bool
    let onOpen: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s2) {
            HStack(spacing: DesignTokens.Space.s3) {
                ChromeSymbol("link", box: DesignTokens.Size.icon)
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                    .accessibilityHidden(true)
                TextField("", text: $text, prompt: Text("URL yapıştır…").foregroundStyle(DesignTokens.Color.inkSecondary))
                    .textFieldStyle(.plain)
                    .font(.system(size: DesignTokens.FontSize.title))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                    .focused($isFocused)
                    .onSubmit(open)
                    .accessibilityLabel("Adres")
                Button(action: open) {
                    HStack(spacing: DesignTokens.Space.s1) {
                        Text("Aç").font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                        ChromeSymbol("arrow.right", box: DesignTokens.Size.iconSm)
                    }
                    .foregroundStyle(DesignTokens.Color.accentInk)
                    .padding(EdgeInsets(top: DesignTokens.Space.s2, leading: DesignTokens.Space.s3,
                                        bottom: DesignTokens.Space.s2, trailing: DesignTokens.Space.s3))
                    .background(DesignTokens.Color.accent, in: .rect(cornerRadius: DesignTokens.Radius.control))
                    .contentShape(.rect(cornerRadius: DesignTokens.Radius.control))
                }
                .buttonStyle(.plain)
                .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
            }
            .padding(EdgeInsets(top: DesignTokens.Space.s2, leading: DesignTokens.Space.s4,
                                bottom: DesignTokens.Space.s2, trailing: DesignTokens.Space.s2))
            .frame(width: 560)
            .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .strokeBorder(isInvalid ? DesignTokens.Color.statusWarning : DesignTokens.Color.line,
                                  lineWidth: DesignTokens.Stroke.hairline)
            }
            .animation(.linear(duration: DesignTokens.Motion.hover), value: isInvalid)

            if isInvalid {
                Text("Bu bir web adresi değil · örnek: marka.com")
                    .font(.system(size: DesignTokens.FontSize.label))
                    .foregroundStyle(DesignTokens.Color.statusWarning)
            }
        }
    }

    private func open() {
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            isFocused = true
        } else {
            onOpen()
        }
    }
}
