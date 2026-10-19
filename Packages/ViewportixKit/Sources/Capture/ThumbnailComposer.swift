import CoreGraphics
import Foundation

/// `thumbnail.png` for a project (PLAN.md §3.5, DESIGN.md §3.1 kart küçük resmi): the canvas's last
/// state — every card where it sits in the layout, its page drawn from a screenshot of what the
/// viewport shows — scaled into a fixed size, top-left, on the canvas colour.
public enum ThumbnailComposer {
    public struct Card: Sendable {
        /// Page area in canvas (document) coordinates, y down.
        public let frame: CGRect
        /// The viewport's visible area; nil draws a blank page.
        public let image: CGImage?

        public init(frame: CGRect, image: CGImage?) {
            self.frame = frame
            self.image = image
        }
    }

    /// Pixels: 2× of the home card's 140 pt thumbnail band, wide enough for the widest card.
    public static let size = CGSize(width: 640, height: 280)
    /// Token values (DESIGN.md §6) as sRGB: canvas, surface/header, line; the blank page colour from
    /// the home card's mini cards.
    static let canvas = CGColor(srgbRed: 0x16 / 255, green: 0x14 / 255, blue: 0x12 / 255, alpha: 1)
    static let header = CGColor(srgbRed: 0x2D / 255, green: 0x29 / 255, blue: 0x26 / 255, alpha: 1)
    static let line = CGColor(srgbRed: 0x3A / 255, green: 0x35 / 255, blue: 0x32 / 255, alpha: 1)
    static let page = CGColor(srgbRed: 0xFA / 255, green: 0xF8 / 255, blue: 0xF5 / 255, alpha: 1)
    /// As the drawn mini cards: 14 pt padding, 6 pt header, 3 pt corners (×2 for pixels).
    static let padding: CGFloat = 28
    static let headerHeight: CGFloat = 12
    static let corner: CGFloat = 6

    public static func compose(_ cards: [Card], size: CGSize = size) -> CGImage? {
        guard let context = CGContext(
            data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.setFillColor(canvas)
        context.fill(CGRect(origin: .zero, size: size))
        let bounds = cards.map(\.frame).reduce(CGRect.null) { $0.union($1) }
        guard !bounds.isNull, bounds.width > 0, bounds.height > 0 else { return context.makeImage() }

        // Headers sit above the page areas, so leave room for them in the fit.
        let room = CGSize(width: size.width - 2 * padding, height: size.height - 2 * padding - headerHeight)
        let scale = min(room.width / bounds.width, room.height / bounds.height)
        context.interpolationQuality = .high
        for card in cards {
            // Flip to Core Graphics' bottom-left origin.
            let x = padding + (card.frame.minX - bounds.minX) * scale
            let top = padding + headerHeight + (card.frame.minY - bounds.minY) * scale
            let pageRect = CGRect(x: x, y: size.height - top - card.frame.height * scale,
                                  width: card.frame.width * scale, height: card.frame.height * scale)
            let cardRect = CGRect(x: pageRect.minX, y: pageRect.minY, width: pageRect.width, height: pageRect.height + headerHeight)
            let shape = CGPath(roundedRect: cardRect, cornerWidth: corner, cornerHeight: corner, transform: nil)

            context.saveGState()
            context.addPath(shape)
            context.clip()
            context.setFillColor(header)
            context.fill(cardRect)
            context.setFillColor(page)
            context.fill(pageRect)
            if let image = card.image {
                // Top of the screenshot, as wide as the page.
                let height = CGFloat(image.height) * pageRect.width / CGFloat(image.width)
                context.draw(image, in: CGRect(x: pageRect.minX, y: pageRect.maxY - height, width: pageRect.width, height: height))
            }
            context.restoreGState()

            context.addPath(shape)
            context.setStrokeColor(line)
            context.setLineWidth(2)
            context.strokePath()
        }
        return context.makeImage()
    }
}
