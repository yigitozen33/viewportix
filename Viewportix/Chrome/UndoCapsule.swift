import DesignSystem
import SwiftUI

/// The undo capsule for work done without asking (K8 U3; `dialogs-save-alerts@2x.png` 4. bölüm,
/// pen `Undo Capsule` ThiBH): 36 pt, `surface/tooltip`, `line/strong` hairline, text in caption,
/// "Geri al ⌘Z" as the one yellow action, the seconds left in micro. It leaves after 5 s; the
/// countdown stops while the pointer is on it (HOME-08).
struct UndoCapsule: View {
    let text: String
    let undo: () -> Void
    let expire: () -> Void

    static let duration = 5

    @State private var remaining = Self.duration
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Text(text)
                .font(DesignTokens.Font.caption)
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .lineLimit(1)
            ActionButton("Geri al", kind: .primary, key: "⌘Z", action: undo)
            Text("\(remaining) sn")
                .font(.system(size: DesignTokens.FontSize.micro))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.Color.inkSecondary)
                .accessibilityHidden(true)
        }
        .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 8))
        .frame(height: 36)
        .background(DesignTokens.Color.surfaceTooltip, in: .capsule)
        .overlay { Capsule().strokeBorder(DesignTokens.Color.lineStrong, lineWidth: DesignTokens.Stroke.hairline) }
        .onHover { isHovered = $0 }
        .task(id: isHovered) {
            guard !isHovered else { return }
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                remaining -= 1
            }
            expire()
        }
        .accessibilityElement(children: .contain)
    }
}
