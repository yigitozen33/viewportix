// Options board for the app icon at small sizes (design/logo-dili.md §5, K1/K2/K3).
// Usage (from repo root): swift design/logo/make-small-options.swift design/logo/small-size-options@2x.png
// CoreGraphics + AppKit text only; colors from design/tokens/viewportix.tokens.json.
import AppKit
import Foundation

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "small-size-options@2x.png"
// Run from the repo root (cwd); `#filePath` is unreliable in interpreted mode.
let tokensURL = URL(fileURLWithPath: "design/tokens/viewportix.tokens.json")

func hex(_ s: String) -> CGColor {
    let h = s.dropFirst(); var v: UInt64 = 0
    Scanner(string: String(h)).scanHexInt64(&v)
    let a: CGFloat = h.count == 8 ? CGFloat(v & 0xFF) / 255 : 1
    if h.count == 8 { v >>= 8 }
    return CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: a)
}
let tokens = try! JSONSerialization.jsonObject(with: Data(contentsOf: tokensURL)) as! [String: Any]
let colorTokens = tokens["color"] as! [String: Any]
func token(_ path: String) -> CGColor { // "ink/primary" → color.ink.primary.$value
    var node: Any = colorTokens
    for part in path.split(separator: "/") { node = (node as! [String: Any])[String(part)]! }
    return hex((node as! [String: Any])["$value"] as! String)
}
let canvas = token("canvas"), accent = token("accent"), ink = token("ink/primary")
let inkSecondary = token("ink/secondary")

enum Option: String, CaseIterable { case k1 = "K1 · Yalnız bracket'ler", k2 = "K2 · Bracket + V", k3 = "K3 · Değişmez" }

// 1024-grid geometry from design/logo-dili.md §2
struct Geo { var margin: CGFloat; var arm: CGFloat; var stroke: CGFloat }
let full = Geo(margin: 204, arm: 140, stroke: 64)
let small = Geo(margin: 128, arm: 256, stroke: 128) // K1 at ≤32 px: 16 px → margin 2, arm 4, stroke 2, gap 4

func brackets(_ ctx: CGContext, _ n: CGFloat, _ g: Geo) {
    let s = n / 1024
    let m = g.margin * s, a = g.arm * s, w = g.stroke * s
    ctx.setFillColor(accent)
    for (cx, cy) in [(m, m), (n - m, m), (m, n - m), (n - m, n - m)] {
        let dx: CGFloat = cx < n / 2 ? 1 : -1, dy: CGFloat = cy < n / 2 ? 1 : -1
        // horizontal arm
        ctx.fill(CGRect(x: min(cx, cx + dx * a), y: min(cy, cy + dy * w), width: a, height: w))
        // vertical arm
        ctx.fill(CGRect(x: min(cx, cx + dx * w), y: min(cy, cy + dy * a), width: w, height: a))
    }
}

func monogram(_ ctx: CGContext, _ n: CGFloat, text: String, capHeight: CGFloat) {
    let s = n / 1024
    let font = NSFont.systemFont(ofSize: 100, weight: .bold)
    let size = capHeight * s * 100 / font.capHeight
    let f = NSFont.systemFont(ofSize: size, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [.font: f, .kern: -0.05 * size, .foregroundColor: NSColor(cgColor: ink)!]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
    let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
    ctx.saveGState()
    ctx.textPosition = CGPoint(x: (n - bounds.width) / 2 - bounds.minX, y: (n - bounds.height) / 2 - bounds.minY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

func icon(_ opt: Option, px: Int) -> CGImage {
    let n = CGFloat(px)
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setAllowsAntialiasing(true); ctx.setShouldAntialias(true)
    let r = n * 0.2237
    ctx.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: n, height: n), cornerWidth: r, cornerHeight: r, transform: nil))
    ctx.setFillColor(canvas); ctx.fillPath()
    let tiny = px <= 32
    switch opt {
    case .k1:
        if tiny { brackets(ctx, n, small) } else { brackets(ctx, n, full); monogram(ctx, n, text: "Vx", capHeight: 205) }
    case .k2:
        brackets(ctx, n, full)
        if tiny { monogram(ctx, n, text: "V", capHeight: 300) } else { monogram(ctx, n, text: "Vx", capHeight: 205) }
    case .k3:
        brackets(ctx, n, full); monogram(ctx, n, text: "Vx", capHeight: 205)
    }
    return ctx.makeImage()!
}

// ---- board (2x) ----
let sizes = [16, 32, 64, 128]
let scale: CGFloat = 2
let colW: CGFloat = 150, rowH: CGFloat = 170, left: CGFloat = 40, top: CGFloat = 70, labelW: CGFloat = 230
let magCols: [(Int, Int)] = [(16, 8), (32, 4)] // (px, magnification)
let W = left * 2 + labelW + colW * CGFloat(sizes.count) + 40 + CGFloat(magCols.count) * 180
let H = top + rowH * CGFloat(Option.allCases.count) + 40
let board = CGContext(data: nil, width: Int(W * scale), height: Int(H * scale), bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
board.scaleBy(x: scale, y: scale)
board.setFillColor(hex("#26221F")); board.fill(CGRect(x: 0, y: 0, width: W, height: H))

func label(_ s: String, x: CGFloat, y: CGFloat, size: CGFloat = 13, color: CGColor = ink, weight: NSFont.Weight = .regular) {
    let a: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: NSColor(cgColor: color)!]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: a))
    board.textPosition = CGPoint(x: x, y: H - y); CTLineDraw(line, board)
}
label("Uygulama ikonu · küçük boyut seçenekleri · gerçek piksel (1x) ve büyütülmüş", x: left, y: 36, size: 16, weight: .semibold)
for (i, px) in sizes.enumerated() {
    label("\(px) px", x: left + labelW + colW * CGFloat(i), y: top - 8, color: inkSecondary)
}
for (j, (px, mag)) in magCols.enumerated() {
    label("\(px) px × \(mag)", x: left + labelW + colW * CGFloat(sizes.count) + 40 + CGFloat(j) * 180, y: top - 8, color: inkSecondary)
}
for (r, opt) in Option.allCases.enumerated() {
    let y0 = H - top - rowH * CGFloat(r + 1) + 20
    label(opt.rawValue, x: left, y: top + rowH * CGFloat(r) + rowH / 2, size: 14, weight: .semibold)
    for (i, px) in sizes.enumerated() {
        let img = icon(opt, px: px)
        let x = left + labelW + colW * CGFloat(i)
        let yy = y0 + (rowH - 40 - CGFloat(px)) / 2
        board.interpolationQuality = .none
        board.draw(img, in: CGRect(x: x, y: yy, width: CGFloat(px), height: CGFloat(px)))
    }
    for (j, (px, mag)) in magCols.enumerated() {
        let img = icon(opt, px: px)
        let x = left + labelW + colW * CGFloat(sizes.count) + 40 + CGFloat(j) * 180
        let sz = CGFloat(px * mag)
        board.interpolationQuality = .none
        board.draw(img, in: CGRect(x: x, y: y0 + (rowH - 40 - sz) / 2, width: sz, height: sz))
    }
}
let rep = NSBitmapImageRep(cgImage: board.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
