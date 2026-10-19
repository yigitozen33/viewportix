import SwiftUI

/// The motion language's values in one place (`design/exports/motion-spec@2x.png`, DESIGN.md §4
/// K1–K6, K5 2026-10-19). One curve for everything that moves; keyboard-triggered actions do not
/// animate; Reduce Motion falls back to short fades. Older chrome still uses `DesignTokens.Motion`.
public enum Motion {
    /// cubic-bezier(0.23, 1, 0.32, 1): the only easing for movement (K5).
    public static func curve(_ duration: Double) -> Animation {
        .timingCurve(0.23, 1, 0.32, 1, duration: duration)
    }

    /// Short opacity fade used instead of movement when Reduce Motion is on.
    public static let reducedFade = Animation.linear(duration: 0.15)

    /// `curve(duration)`, or the 150 ms fade under Reduce Motion.
    public static func curve(_ duration: Double, reduced: Bool) -> Animation {
        reduced ? reducedFade : curve(duration)
    }

    // MARK: AI/Glyph (AIActivityGlyph)

    /// One pass of the three bars; each 120 ms step lights the next bar.
    public static let glyphCycle: Double = 0.72
    public static let glyphStep: Double = 0.12
    /// A bar's opacity in the steps after it lights; afterwards it stays at the last value.
    public static let glyphFade: [Double] = [1, 0.6, 0.4, 0.25]
    /// Paused (waiting for approval) and Reduce Motion: bars stand still at this opacity.
    public static let glyphPausedOpacity: Double = 0.6

    // MARK: AI box and steps

    /// Light sweep across the active step: 0.9 s pass + 0.3 s rest, ease-in-out.
    public static let sweep: Double = 0.9
    public static let sweepRest: Double = 0.3
    /// Seconds counter: the new digit rises 4 px in 200 ms.
    public static let counter: Double = 0.2
    /// The box opens: 220 ms, opacity + 4 px.
    public static let boxOpen: Double = 0.22
    /// A new step: 220 ms, 4 px from above, blur 4 → 0.
    public static let newStep: Double = 0.22
    public static let newStepBlur: CGFloat = 4
    /// "okunuyor" → "okundu": 200 ms blur replace, ease-in-out.
    public static let modeChange: Double = 0.2
    /// Finishing title: 130 ms out + 130 ms in, ease-in-out.
    public static let finishTitle: Double = 0.13
    /// K3: steps fold into the title 2 s after finishing (waits while the pointer is in the box).
    public static let collapseDelay: Double = 2
    public static let collapse: Double = 0.3
    /// Opening the folded steps with ⌄: 40 ms apart, at most 6 staggered.
    public static let stagger: Double = 0.04
    public static let staggerLimit = 6

    /// Shared offset for "comes in from 4 px away".
    public static let nudge: CGFloat = 4

    // MARK: Buttons (K4)

    /// Mouse press: 97 % in 80 ms, back in 120 ms. Keyboard-triggered presses do not animate.
    public static let pressIn: Double = 0.08
    public static let pressOut: Double = 0.12
    public static let pressScale: CGFloat = 0.97
    /// The row's result after a keyboard decision: 150 ms opacity.
    public static let decision: Double = 0.15

    // MARK: Surfaces

    /// Our sheet (ChromeSheet): drops in 240 ms, leaves in 160 ms.
    public static let sheetIn: Double = 0.24
    public static let sheetOut: Double = 0.16
    /// PW-07 "Dosya başka yerde değişti" strip drops in.
    public static let strip: Double = 0.2
    /// HOME-08: a deleted draft's card narrows.
    public static let cardRemove: Double = 0.15
    /// Notice stack (M7): 400 ms ease, each older notice −10 px and −5 % scale, at most 3.
    public static let stack: Double = 0.4
    public static let stackOffset: CGFloat = 10
    public static let stackScale: CGFloat = 0.05
    public static let stackLimit = 3
}
