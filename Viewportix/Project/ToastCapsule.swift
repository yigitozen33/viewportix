import DesignSystem
import SwiftUI

/// `Window/Toast` (specs/ToastCapsule.json): the notice capsule above the bottom bar. Progress
/// (spinner, no action), success (yellow check, "Finder'da Göster"), partial failure (coral border
/// and triangle, "Yeniden dene"), failure (coral, stays until closed), undo ("Geri al"), info.
/// Hidden while a menu or tooltip is open (the window decides).
struct ToastCapsule: View {
    let notice: Workspace.Notice
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            icon
            Text(notice.text)
                .font(.system(size: DesignTokens.FontSize.label))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .lineLimit(1)
            if let action = notice.action {
                Button {
                    action.perform()
                    if !notice.isProgress { dismiss() }
                } label: {
                    Text(action.title)
                        .font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                        .foregroundStyle(DesignTokens.Color.accent)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .chromeFocusRing(cornerRadius: 4)
            }
            if notice.isError {
                // Errors stay until closed; the spec has no close control, so a quiet ✕.
                ChromeIconButton(symbol: "xmark", label: "Kapat", box: 12, action: dismiss)
            }
        }
        .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        .background(DesignTokens.Color.surfaceHeader, in: .capsule)
        .overlay {
            Capsule().strokeBorder(notice.kind == .partialFailure ? DesignTokens.Color.statusWarning : DesignTokens.Color.line,
                                   lineWidth: DesignTokens.Stroke.hairline)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var icon: some View {
        switch notice.kind {
        case .progress:
            ProgressView().controlSize(.small).frame(width: 16, height: 16)
        case .success:
            ChromeSymbol("checkmark", box: DesignTokens.Size.icon).foregroundStyle(DesignTokens.Color.accent)
        case .partialFailure, .failure:
            ChromeSymbol("exclamationmark.triangle", box: DesignTokens.Size.icon).foregroundStyle(DesignTokens.Color.statusWarning)
        case .info:
            ChromeSymbol("info.circle", box: DesignTokens.Size.icon).foregroundStyle(DesignTokens.Color.inkSecondary)
        case .undo:
            ChromeSymbol("xmark", box: DesignTokens.Size.icon).foregroundStyle(DesignTokens.Color.inkSecondary)
        }
    }
}
