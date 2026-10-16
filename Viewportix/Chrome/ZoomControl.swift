import AppKit
import DesignSystem
import SwiftUI

/// `Toolbar/ZoomControl` (specs/ZoomControl.json): percentage + vertical mini stepper.
/// Click on the percentage opens the zoom menu (BAR-03), ▲▼ step through the zoom stops and repeat
/// while held (BAR-04), dragging the percentage sideways zooms 1 pt = 1 % (BAR-05).
struct ZoomControl: View {
    /// Current zoom, 1 = 100 %.
    let zoom: Double
    var isMenuOpen = false
    let onStep: (_ up: Bool) -> Void
    /// Continuous zoom from dragging the percentage; ⇧ snaps to `steps`.
    let onScrub: (Double) -> Void
    let onOpenMenu: () -> Void
    var steps: [Double] = [0.25, 0.5, 1, 2, 4]

    @State private var isHovered = false
    @State private var scrubStart: Double?
    @State private var isScrubbing = false

    var body: some View {
        HStack(spacing: 0) {
            percentage
                .padding(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: DesignTokens.Space.s2))
                .contentShape(.rect)
                .pointerStyle(.columnResize)
                .gesture(scrubOrClick)
                .onHover { isHovered = $0 }
            stepper
                .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 4))
        }
        .background(fill, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .animation(.linear(duration: DesignTokens.Motion.hover), value: isHighlighted)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Yakınlaştırma")
        .accessibilityValue(Self.format(zoom))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onStep(true)
            case .decrement: onStep(false)
            @unknown default: break
            }
        }
    }

    /// "%100" in Turkish, "100%" elsewhere: the system locale decides (DESIGN.md §3.2).
    static func format(_ zoom: Double) -> String {
        zoom.formatted(.percent.precision(.fractionLength(0)))
    }

    private var isHighlighted: Bool { isHovered || isScrubbing || isMenuOpen }

    private var fill: Color {
        isHighlighted ? DesignTokens.Color.surfaceHeaderLeader : DesignTokens.Color.surfaceCard
    }

    private var percentage: some View {
        // Tabular digits and a width reserved for a three-digit value keep the bar from jumping while
        // zooming. Costs 2 pt: "%100" is 32 pt proportional (as in the design), 34 tabular.
        ZStack(alignment: .leading) {
            Text(Self.format(4)).hidden()
            Text(Self.format(zoom))
        }
        .font(.system(size: DesignTokens.FontSize.label))
        .monospacedDigit()
        .foregroundStyle(DesignTokens.Color.inkPrimary)
    }

    private var stepper: some View {
        VStack(spacing: 1) {
            StepperHalf(symbol: "chevron.up") { onStep(true) }
            StepperHalf(symbol: "chevron.down") { onStep(false) }
        }
        .background(DesignTokens.Color.line)
        .clipShape(.rect(cornerRadius: 5))
    }

    private var scrubOrClick: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                let start = scrubStart ?? zoom
                scrubStart = start
                let dx = value.translation.width
                guard isScrubbing || abs(dx) >= 3 else { return }
                isScrubbing = true
                var target = start + dx / 100
                if NSEvent.modifierFlags.contains(.shift) {
                    target = steps.min { abs($0 - target) < abs($1 - target) } ?? target
                }
                onScrub(target)
            }
            .onEnded { _ in
                let wasScrubbing = isScrubbing
                scrubStart = nil
                isScrubbing = false
                if !wasScrubbing { onOpenMenu() }
            }
    }
}

/// One half of the mini stepper; fires once on press, then repeats while held.
private struct StepperHalf: View {
    let symbol: String
    let action: () -> Void

    @State private var repeatTask: Task<Void, Never>?

    var body: some View {
        ChromeSymbol(symbol, box: 10)
            .foregroundStyle(repeatTask == nil ? DesignTokens.Color.inkSecondary : DesignTokens.Color.inkPrimary)
            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
            .background(DesignTokens.Color.surfacePill)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard repeatTask == nil else { return }
                        action()
                        repeatTask = Task {
                            try? await Task.sleep(for: .milliseconds(400))
                            while !Task.isCancelled {
                                action()
                                try? await Task.sleep(for: .milliseconds(200))
                            }
                        }
                    }
                    .onEnded { _ in
                        repeatTask?.cancel()
                        repeatTask = nil
                    }
            )
    }
}
