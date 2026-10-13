// Generated from design/tokens/viewportix.tokens.json by gen_swift.py — do not edit by hand.
// Source of truth: design/viewportix.pen variables (DESIGN.md §6). Copy into the package; regenerate on change.
import SwiftUI

public enum DesignTokens {
    // MARK: Color — dark is the only shipped theme; `light` is kept for later.
    public enum Color {
        /// canvas · dark #161412 · light #F4F1EC
        public static let canvas = SwiftUI.Color(red: 0.0863, green: 0.0784, blue: 0.0706)
        /// surface/bar · dark #1F1C19 · light #ECE8E1
        public static let surfaceBar = SwiftUI.Color(red: 0.1216, green: 0.1098, blue: 0.0980)
        /// surface/card · dark #26221F · light #FFFFFF
        public static let surfaceCard = SwiftUI.Color(red: 0.1490, green: 0.1333, blue: 0.1216)
        /// surface/header · dark #2D2926 · light #E9E4DC
        public static let surfaceHeader = SwiftUI.Color(red: 0.1765, green: 0.1608, blue: 0.1490)
        /// surface/header-leader · dark #38322D · light #DDD7CD
        public static let surfaceHeaderLeader = SwiftUI.Color(red: 0.2196, green: 0.1961, blue: 0.1765)
        /// surface/pill · dark #3A3430 · light #E3DED5
        public static let surfacePill = SwiftUI.Color(red: 0.2275, green: 0.2039, blue: 0.1882)
        /// surface/tooltip · dark #0B0A09 · light #FBF9F6
        public static let surfaceTooltip = SwiftUI.Color(red: 0.0431, green: 0.0392, blue: 0.0353)
        /// line · dark #3A3532 · light #D9D3C9
        public static let line = SwiftUI.Color(red: 0.2275, green: 0.2078, blue: 0.1961)
        /// line-strong · dark #4F4945 · light #C7C0B4
        public static let lineStrong = SwiftUI.Color(red: 0.3098, green: 0.2863, blue: 0.2706)
        /// ink/primary · dark #F4EFE9 · light #1D1B19
        public static let inkPrimary = SwiftUI.Color(red: 0.9569, green: 0.9373, blue: 0.9137)
        /// ink/secondary · dark #9C9188 · light #6E6760
        public static let inkSecondary = SwiftUI.Color(red: 0.6118, green: 0.5686, blue: 0.5333)
        /// accent · dark #FFF36B · light #E6C800
        public static let accent = SwiftUI.Color(red: 1.0000, green: 0.9529, blue: 0.4196)
        /// accent-ink · dark #141210 · light #141210
        public static let accentInk = SwiftUI.Color(red: 0.0784, green: 0.0706, blue: 0.0627)
        /// status/leader · dark #8EC9E6 · light #2F8FBF
        public static let statusLeader = SwiftUI.Color(red: 0.5569, green: 0.7882, blue: 0.9020)
        /// status/warning · dark #FF8F85 · light #D9534A
        public static let statusWarning = SwiftUI.Color(red: 1.0000, green: 0.5608, blue: 0.5216)
        /// status/warning-bg · dark #3A2A28 · light #FBE4E1
        public static let statusWarningBg = SwiftUI.Color(red: 0.2275, green: 0.1647, blue: 0.1569)
    }
    public enum Radius {
        public static let badge: CGFloat = 6
        public static let control: CGFloat = 8
        public static let card: CGFloat = 12
        public static let bar: CGFloat = 14
        public static let window: CGFloat = 16
    }
    public enum Space {
        public static let s1: CGFloat = 4
        public static let s2: CGFloat = 8
        public static let s3: CGFloat = 12
        public static let s4: CGFloat = 16
        public static let s6: CGFloat = 24
        public static let s8: CGFloat = 32
    }
    public enum Size {
        public static let sidebar: CGFloat = 240
        public static let barHeight: CGFloat = 48
        public static let cardHeader: CGFloat = 36
        public static let icon: CGFloat = 16
        public static let iconSm: CGFloat = 14
        public static let rail: CGFloat = 44
        public static let panelOverlay: CGFloat = 340
        public static let panelDocked: CGFloat = 320
    }
    public enum Stroke {
        public static let hairline: CGFloat = 1
        public static let focus: CGFloat = 2
        public static let leader: CGFloat = 2
        public static let selectionRing: CGFloat = 1.5
        public static let selectionGap: CGFloat = 3
    }
    public enum FontSize {
        public static let title: CGFloat = 15
        public static let body: CGFloat = 13
        public static let label: CGFloat = 12
        public static let caption: CGFloat = 11
        public static let micro: CGFloat = 10
    }
    // MARK: Type — system fonts in the app (SF Pro / SF Mono); Inter / JetBrains Mono are design-file proxies only.
    public enum Font {
        public static let title = SwiftUI.Font.system(size: FontSize.title, weight: .semibold)
        public static let body = SwiftUI.Font.system(size: FontSize.body, weight: .regular)
        public static let label = SwiftUI.Font.system(size: FontSize.label, weight: .medium)
        public static let caption = SwiftUI.Font.system(size: FontSize.caption, weight: .regular)
        public static let micro = SwiftUI.Font.system(size: FontSize.micro, weight: .semibold)
        public static func mono(_ size: CGFloat = FontSize.label) -> SwiftUI.Font { .system(size: size, design: .monospaced) }
    }
    // MARK: Motion — durations from the interaction tables (DESIGN.md §3).
    public enum Motion {
        public static let hover: Double = 0.1
        public static let fast: Double = 0.12
        public static let standard: Double = 0.15
        public static let panel: Double = 0.2
        public static let canvasPan: Double = 0.25
        public static let tooltipDelay: Double = 0.4
    }
}
