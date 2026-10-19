@testable import Capture
import CoreGraphics
import Foundation
import Testing

struct CaptureTests {
    private func solid(width: Int, height: Int) -> CGImage {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    @Test func composesSideBySideWithMarginsAndTitles() throws {
        let scale: CGFloat = 2
        let image = try #require(ScreenshotComposer.compose([
            .init(title: "iPhone 16 · 393×852", image: solid(width: 786, height: 1704)),
            .init(title: "Masaüstü · 1440×900", image: solid(width: 2880, height: 1800)),
        ], scale: scale))

        let m = ScreenshotComposer.margin * scale
        #expect(image.width == Int(786 + 2880 + ScreenshotComposer.gap * scale + 2 * m))
        #expect(image.height == Int(1800 + ScreenshotComposer.titleHeight * scale + 2 * m))
    }

    @Test func scalesToOneX() throws {
        let image = try #require(ScreenshotComposer.scaled(solid(width: 786, height: 1704), by: 0.5))
        #expect(image.width == 393 && image.height == 852)
    }

    @Test func composingNothingGivesNothing() {
        #expect(ScreenshotComposer.compose([], scale: 2) == nil)
    }

    @Test func encodesPNG() throws {
        let data = try #require(ScreenshotComposer.pngData(solid(width: 4, height: 4)))
        #expect(data.prefix(8) == Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
    }

    @Test func namesFilesReadablyAndSafely() {
        let date = Date(timeIntervalSince1970: 1_791_651_792)  // 2026-10-10 17:03:12 UTC
        let utc = TimeZone(identifier: "UTC")!
        #expect(ScreenshotNaming.fileName(subject: "Sepet: 3/4 ürün", detail: "iPhone 16", date: date, timeZone: utc)
                == "Viewportix — Sepet- 3-4 ürün — iPhone 16 — 2026-10-10 17.03.12.png")
        #expect(ScreenshotNaming.fileName(subject: "  ", detail: nil, date: date, timeZone: utc)
                == "Viewportix — 2026-10-10 17.03.12.png")
    }
}

struct ThumbnailComposerTests {
    @Test func cardsKeepTheirLayoutInsideTheThumbnail() throws {
        let cards = [
            ThumbnailComposer.Card(frame: CGRect(x: 64, y: 64, width: 400, height: 800), image: nil),
            ThumbnailComposer.Card(frame: CGRect(x: 512, y: 64, width: 1400, height: 900), image: nil),
        ]
        let image = try #require(ThumbnailComposer.compose(cards))
        #expect(image.width == 640 && image.height == 280)
        #expect(ThumbnailComposer.compose([]) != nil)
    }
}
