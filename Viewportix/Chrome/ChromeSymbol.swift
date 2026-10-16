import AppKit
import SwiftUI

/// An icon from the design, drawn as an SF Symbol (names: design/handoff/icons.md).
///
/// The design draws Lucide icons in a square box; SF Symbols look larger at the same size, so the
/// point size is the box × 0.875, regular weight, centred in the box (DESIGN.md §4, 2026-10-13).
/// Custom symbols (`link.slash`, `engine.*`) live in the app's asset catalog.
struct ChromeSymbol: View {
    enum Source {
        case system(String)
        case asset(String)
    }

    let source: Source
    let box: CGFloat

    init(_ systemName: String, box: CGFloat) {
        source = .system(systemName)
        self.box = box
    }

    init(asset name: String, box: CGFloat) {
        source = .asset(name)
        self.box = box
    }

    static func pointSize(box: CGFloat) -> CGFloat { box * 0.875 }

    var body: some View {
        image
            .font(.system(size: Self.pointSize(box: box), weight: .regular))
            .frame(width: box, height: box)
    }

    private var image: Image {
        switch source {
        case .system(let name): Image(systemName: name)
        case .asset(let name): Image(name)
        }
    }
}

extension NSImage {
    /// AppKit counterpart of `ChromeSymbol`: box × 0.875 points, regular weight.
    static func chromeSymbol(_ name: String, box: CGFloat, label: String?) -> NSImage? {
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: label)
            ?? NSImage(symbolName: name, bundle: .main, variableValue: 0) else { return nil }
        image.accessibilityDescription = label
        return image.withSymbolConfiguration(.init(pointSize: ChromeSymbol.pointSize(box: box), weight: .regular))
    }
}
