import DesignSystem
import SwiftUI

/// `AI/Glyph` (DESIGN.md §4 K1/K2, §6; `motion-spec@2x.png` 1. bölüm): three viewports — phone
/// 2×9, tablet 3×7, desktop 5×5 — in 12 × 12. Running: yellow, each bar lights in turn and fades
/// 1 → .6 → .4 → .25 in 120 ms steps (720 ms cycle, linear, stepped). Paused (waiting for approval):
/// still, `ink/secondary` 60 % (the coral dot belongs to the title next to it). Done: all three ink.
/// Reduce Motion: still at 60 %.
struct AIActivityGlyph: View {
    enum Phase { case running, paused, done }

    var phase = Phase.running
    /// Steps already taken when the glyph appears; rows next to each other shift their phase so
    /// they don't blink together ("satırlar arası faz kaydırılır").
    var phaseOffset = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let bars: [CGSize] = [CGSize(width: 2, height: 9), CGSize(width: 3, height: 7), CGSize(width: 5, height: 5)]

    var body: some View {
        Group {
            if phase == .running, !reduceMotion {
                TimelineView(.periodic(from: .now, by: Motion.glyphStep)) { context in
                    bars(step: step(at: context.date))
                }
            } else {
                bars(step: nil)
            }
        }
        .frame(width: 12, height: 12)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private func bars(step: Int?) -> some View {
        HStack(alignment: .bottom, spacing: 1) {
            ForEach(Self.bars.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 0.6)
                    .fill(color)
                    .frame(width: Self.bars[index].width, height: Self.bars[index].height)
                    .opacity(opacity(bar: index, step: step))
            }
        }
        .frame(height: 9, alignment: .bottom)
    }

    private var color: Color {
        switch phase {
        case .running: DesignTokens.Color.accent
        case .paused: DesignTokens.Color.inkSecondary
        case .done: DesignTokens.Color.inkPrimary
        }
    }

    private func opacity(bar: Int, step: Int?) -> Double {
        guard let step else { return phase == .done ? 1 : Motion.glyphPausedOpacity }
        let since = step - bar  // bar i lights at step i
        return Motion.glyphFade.indices.contains(since) ? Motion.glyphFade[since] : Motion.glyphFade.last!
    }

    /// Step 0…5 of the 720 ms cycle.
    private func step(at date: Date) -> Int {
        let steps = Int((Motion.glyphCycle / Motion.glyphStep).rounded())
        let elapsed = Int(date.timeIntervalSinceReferenceDate / Motion.glyphStep)
        return (elapsed + phaseOffset) % steps
    }

    private var accessibilityText: String {
        switch phase {
        case .running: "Çalışıyor"
        case .paused: "Onay bekliyor"
        case .done: "Bitti"
        }
    }
}
