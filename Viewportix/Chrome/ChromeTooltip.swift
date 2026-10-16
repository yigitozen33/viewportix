import DesignSystem
import SwiftUI

/// `Window/Tooltip` (specs/ChromeTooltip.json): dark body with name and optional shortcut, a caret
/// pointing at the target when it sits above it. Every tooltip in our chrome uses this, via
/// `.chromeTooltip(_:shortcut:edge:)`.
struct ChromeTooltip: View {
    let title: String
    var shortcut: String?
    var showsCaret = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignTokens.Space.s2) {
                Text(title)
                    .font(.system(size: DesignTokens.FontSize.label, weight: .medium))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: DesignTokens.FontSize.caption))
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                }
            }
            .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
            .background(DesignTokens.Color.surfaceTooltip, in: .rect(cornerRadius: DesignTokens.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                    .strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
            }
            if showsCaret {
                Caret()
                    .fill(DesignTokens.Color.surfaceTooltip)
                    .frame(width: 12, height: 6)
            }
        }
        .fixedSize()
    }

    /// Distance from the target to the caret tip (or to the body when there is no caret).
    static let gap: CGFloat = 8
    /// Hover delay before showing.
    static let delay = Duration.milliseconds(Int(DesignTokens.Motion.tooltipDelay * 1000))
}

/// Downward triangle, 12 × 6.
private struct Caret: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

extension View {
    /// Shows a `ChromeTooltip` 400 ms after the pointer rests on the view; hides on exit or press.
    /// `.top` draws the caret toward the target; side tooltips (`.leading`, `.trailing`) have none.
    func chromeTooltip(_ title: String, shortcut: String? = nil, edge: Edge = .top) -> some View {
        modifier(ChromeTooltipModifier(title: title, shortcut: shortcut, edge: edge))
    }
}

/// True while any chrome tooltip below is visible; the notice capsule hides meanwhile.
struct ChromeTooltipVisibleKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private struct ChromeTooltipModifier: ViewModifier {
    let title: String
    let shortcut: String?
    let edge: Edge

    @State private var isShown = false
    @State private var pending: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                pending?.cancel()
                if hovering {
                    pending = Task {
                        try? await Task.sleep(for: ChromeTooltip.delay)
                        if !Task.isCancelled { isShown = true }
                    }
                } else {
                    isShown = false
                }
            }
            .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in
                pending?.cancel()
                isShown = false
            })
            .overlay(alignment: alignment) {
                if isShown {
                    placed(ChromeTooltip(title: title, shortcut: shortcut, showsCaret: edge == .top))
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .animation(.linear(duration: DesignTokens.Motion.hover), value: isShown)
            .preference(key: ChromeTooltipVisibleKey.self, value: isShown)
    }

    private var alignment: Alignment {
        switch edge {
        case .top: .top
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }

    @ViewBuilder
    private func placed(_ tooltip: ChromeTooltip) -> some View {
        let gap = ChromeTooltip.gap
        switch edge {
        case .top: tooltip.alignmentGuide(.top) { $0[.bottom] + gap }
        case .bottom: tooltip.alignmentGuide(.bottom) { $0[.top] - gap }
        case .leading: tooltip.alignmentGuide(.leading) { $0[.trailing] + gap }
        case .trailing: tooltip.alignmentGuide(.trailing) { $0[.leading] - gap }
        }
    }
}
