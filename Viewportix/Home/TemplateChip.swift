import ChromiumEngine
import DesignSystem
import ProjectModel
import SwiftUI

/// `Home/TemplateChip` (specs/TemplateChip.json): normal, selected (yellow border, brighter fill).
struct TemplateChip: View {
    let template: ProjectTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Space.s2) {
                ChromeSymbol(template.symbol, box: DesignTokens.Size.iconSm)
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                Text(template.title)
                    .font(.system(size: DesignTokens.FontSize.label))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
            }
            .padding(EdgeInsets(top: DesignTokens.Space.s2, leading: DesignTokens.Space.s3,
                                bottom: DesignTokens.Space.s2, trailing: DesignTokens.Space.s3))
            .background(isSelected ? DesignTokens.Color.surfaceHeader : DesignTokens.Color.surfaceCard,
                        in: .rect(cornerRadius: DesignTokens.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                    .strokeBorder(isSelected ? DesignTokens.Color.accent : DesignTokens.Color.line,
                                  lineWidth: DesignTokens.Stroke.hairline)
            }
            .contentShape(.rect(cornerRadius: DesignTokens.Radius.control))
            .animation(.linear(duration: DesignTokens.Motion.hover), value: isSelected)
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .disabled(!template.isAvailable)
        .opacity(template.isAvailable ? 1 : 0.5)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension ProjectTemplate {
    /// Engine comparison needs a Chrome to run Chromium in.
    var isAvailable: Bool {
        self != .engineComparison || ChromeBrowser.isAvailable
    }

    var title: String {
        switch self {
        case .mobileFocused: "Mobil odaklı"
        case .fullMatrix: "Tam matris"
        case .engineComparison: "Motor karşılaştırma"
        }
    }

    /// icons.md: smartphone → iphone, layout-grid → square.grid.2x2, git-compare → square.split.2x1.
    var symbol: String {
        switch self {
        case .mobileFocused: "iphone"
        case .fullMatrix: "square.grid.2x2"
        case .engineComparison: "square.split.2x1"
        }
    }
}
