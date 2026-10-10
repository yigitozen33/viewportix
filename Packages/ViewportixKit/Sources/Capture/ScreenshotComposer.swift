import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Lays viewport screenshots side by side, top-aligned, each under its title, like the canvas.
public enum ScreenshotComposer {
    public struct Item: Sendable {
        public let title: String
        public let image: CGImage

        public init(title: String, image: CGImage) {
            self.title = title
            self.image = image
        }
    }

    /// Spacing in points; multiplied by `scale` (the screenshots' pixel density).
    static let margin: CGFloat = 48
    static let gap: CGFloat = 40
    static let titleHeight: CGFloat = 32
    static let titleSize: CGFloat = 15

    public static func compose(_ items: [Item], scale: CGFloat) -> CGImage? {
        guard !items.isEmpty else { return nil }
        let margin = margin * scale
        let gap = gap * scale
        let titleHeight = titleHeight * scale
        let width = items.reduce(0) { $0 + CGFloat($1.image.width) } + gap * CGFloat(items.count - 1) + 2 * margin
        let tallest = items.map { CGFloat($0.image.height) }.max() ?? 0
        let height = tallest + titleHeight + 2 * margin

        guard let context = CGContext(
            data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.setFillColor(CGColor(srgbRed: 0.95, green: 0.95, blue: 0.97, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Core Graphics origin is bottom-left; compute rows from the top.
        let titleBaseline = height - margin - titleHeight * 0.7
        let imageTop = height - margin - titleHeight
        let font = CTFontCreateUIFontForLanguage(.emphasizedSystem, titleSize * scale, nil)
        var x = margin
        for item in items {
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key(kCTFontAttributeName as String): font as Any,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(srgbRed: 0.24, green: 0.24, blue: 0.26, alpha: 1),
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: item.title, attributes: attributes))
            context.textPosition = CGPoint(x: x, y: titleBaseline)
            CTLineDraw(line, context)

            let imageWidth = CGFloat(item.image.width)
            let imageHeight = CGFloat(item.image.height)
            context.draw(item.image, in: CGRect(x: x, y: imageTop - imageHeight, width: imageWidth, height: imageHeight))
            x += imageWidth + gap
        }
        return context.makeImage()
    }

    public static func pngData(_ image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}

/// File names like "Viewportix — Ana sayfa — iPhone 16 — 2026-10-10 18.03.12.png".
public enum ScreenshotNaming {
    public static func fileName(subject: String, detail: String?, date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let parts = ["Viewportix", sanitize(subject), detail.map(sanitize), formatter.string(from: date)]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.joined(separator: " — ") + ".png"
    }

    /// Strips path separators and colons (Finder shows ":" as "/"), collapses whitespace, caps length.
    static func sanitize(_ text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        return String(cleaned.prefix(60)).trimmingCharacters(in: .whitespaces)
    }
}
