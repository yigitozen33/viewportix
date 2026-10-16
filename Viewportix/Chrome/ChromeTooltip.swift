import AppKit
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
    /// `alignment` lines a top/bottom tooltip up with the target's leading edge instead of its
    /// centre, for wide targets near the window edge (sidebar rows).
    func chromeTooltip(_ title: String, shortcut: String? = nil, edge: Edge = .top,
                       alignment: HorizontalAlignment = .center) -> some View {
        modifier(ChromeTooltipModifier(title: title, shortcut: shortcut, edge: edge, alignment: alignment))
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
    let alignment: HorizontalAlignment

    @State private var isShown = false
    @State private var pending: Task<Void, Never>?
    @State private var monitor: Any?
    /// Target in window coordinates and the tooltip's width, to keep it inside the window.
    @State private var targetFrame: CGRect = .zero
    @State private var tooltipWidth: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                pending?.cancel()
                if hovering {
                    pending = Task {
                        try? await Task.sleep(for: ChromeTooltip.delay)
                        if !Task.isCancelled { isShown = true }
                    }
                    watchPresses()
                } else {
                    isShown = false
                    stopWatching()
                }
            }
            .onDisappear(perform: stopWatching)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { targetFrame = $0 }
            .outside(edge, alignment: alignment, gap: ChromeTooltip.gap) {
                if isShown {
                    ChromeTooltip(title: title, shortcut: shortcut, showsCaret: edge == .top)
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { tooltipWidth = $0 }
                        .offset(x: horizontalShift)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            // Above the following siblings in its stack, which would otherwise cover it.
            .zIndex(isShown ? 1 : 0)
            .animation(.linear(duration: DesignTokens.Motion.hover), value: isShown)
            .preference(key: ChromeTooltipVisibleKey.self, value: isShown)
    }

    /// A top or bottom tooltip wider than its target can run past the window's edge (found in the
    /// live app: sidebar rows, ‹ Geri); it moves in to stay `margin` inside.
    private var horizontalShift: CGFloat {
        guard edge == .top || edge == .bottom, tooltipWidth > 0 else { return 0 }
        let margin: CGFloat = 8
        let minX = switch alignment {
        case .leading: targetFrame.minX
        case .trailing: targetFrame.maxX - tooltipWidth
        default: targetFrame.midX - tooltipWidth / 2
        }
        if minX < margin { return margin - minX }
        let windowWidth = NSApp.keyWindow?.contentLayoutRect.width ?? .infinity
        if minX + tooltipWidth > windowWidth - margin { return windowWidth - margin - minX - tooltipWidth }
        return 0
    }

    /// Any press (left, right — a context menu opening — or a key) hides the tooltip and cancels a
    /// pending one; a gesture would only see left clicks (found in the live app: the page row's
    /// tooltip stayed under its context menu).
    private func watchPresses() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown, .scrollWheel]) { event in
            pending?.cancel()
            isShown = false
            return event
        }
    }

    private func stopWatching() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

extension View {
    /// Places `content` outside this view's `edge`, `gap` points away, aligned along that edge by
    /// `alignment` (`.leading`, `.center`, `.trailing` for top/bottom; ignored for sides, which centre).
    /// Uses a zero-thickness anchor on the edge, because `alignmentGuide` is not applied to overlay
    /// content here (found in the live app: tooltips and the hover strip landed on their targets).
    func outside<Content: View>(_ edge: Edge, alignment: HorizontalAlignment = .center, gap: CGFloat,
                                @ViewBuilder _ content: () -> Content) -> some View {
        let content = content()
        return overlay(alignment: Self.alignment(on: edge, alignment)) {
            switch edge {
            case .top:
                Color.clear.frame(height: 0).overlay(alignment: Alignment(horizontal: alignment, vertical: .bottom)) {
                    content.fixedSize().padding(.bottom, gap)
                }
            case .bottom:
                Color.clear.frame(height: 0).overlay(alignment: Alignment(horizontal: alignment, vertical: .top)) {
                    content.fixedSize().padding(.top, gap)
                }
            case .leading:
                Color.clear.frame(width: 0).overlay(alignment: .trailing) {
                    content.fixedSize().padding(.trailing, gap)
                }
            case .trailing:
                Color.clear.frame(width: 0).overlay(alignment: .leading) {
                    content.fixedSize().padding(.leading, gap)
                }
            }
        }
    }

    private static func alignment(on edge: Edge, _ horizontal: HorizontalAlignment) -> Alignment {
        switch edge {
        case .top: Alignment(horizontal: horizontal, vertical: .top)
        case .bottom: Alignment(horizontal: horizontal, vertical: .bottom)
        case .leading: .leading
        case .trailing: .trailing
        }
    }
}
