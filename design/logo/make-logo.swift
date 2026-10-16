// Viewportix app icon and logo, drawn procedurally (design/logo-dili.md).
// Usage (from repo root): swift design/logo/make-logo.swift [outDir]   — default design/logo/out
// CoreGraphics + AppKit text only; colors from design/tokens/viewportix.tokens.json (never hard-coded).
// Outputs: Icon Composer layers (background/brackets/monogram.png, 1024), Viewportix.iconset (flat fallback),
// logo-dark.png / logo-light.png (README <picture>), glyph-template.png (single color), check@2x.png.
import AppKit
import Foundation

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "design/logo/out")
try! FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let tokensURL = URL(fileURLWithPath: "design/tokens/viewportix.tokens.json")

// MARK: tokens
func hex(_ s: String) -> CGColor {
    let h = s.dropFirst(); var v: UInt64 = 0
    Scanner(string: String(h)).scanHexInt64(&v)
    let a: CGFloat = h.count == 8 ? CGFloat(v & 0xFF) / 255 : 1
    if h.count == 8 { v >>= 8 }
    return CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: a)
}
let tokens = try! JSONSerialization.jsonObject(with: Data(contentsOf: tokensURL)) as! [String: Any]
let colorTokens = tokens["color"] as! [String: Any]
func tokenNode(_ path: String) -> [String: Any] {
    var node: Any = colorTokens
    for part in path.split(separator: "/") { node = (node as! [String: Any])[String(part)]! }
    return node as! [String: Any]
}
func tokenHex(_ path: String, light: Bool = false) -> String {
    let n = tokenNode(path)
    if light { return (n["$extensions"] as! [String: Any])["viewportix.light"] as! String }
    return n["$value"] as! String
}
struct Palette { let tile: CGColor; let brackets: CGColor; let monogram: CGColor; let names: String }
let dark = Palette(tile: hex(tokenHex("canvas")), brackets: hex(tokenHex("accent")), monogram: hex(tokenHex("ink/primary")),
                   names: "canvas \(tokenHex("canvas")) · accent \(tokenHex("accent")) · ink/primary \(tokenHex("ink/primary"))")
let light = Palette(tile: hex(tokenHex("canvas", light: true)), brackets: hex(tokenHex("accent", light: true)),
                    monogram: hex(tokenHex("ink/primary", light: true)),
                    names: "canvas \(tokenHex("canvas", light: true)) · accent \(tokenHex("accent", light: true)) · ink/primary \(tokenHex("ink/primary", light: true))")

// MARK: geometry (1024 grid, logo-dili.md §2 and §5)
struct Geo { var margin: CGFloat; var arm: CGFloat; var stroke: CGFloat }
let fullGeo = Geo(margin: 204, arm: 140, stroke: 64)
let smallGeo = Geo(margin: 128, arm: 256, stroke: 128) // K1: 16 px → 2 / 4 / 2 px
let capHeight1024: CGFloat = 205
let tracking: CGFloat = -0.05 // em
let cornerRatio: CGFloat = 0.2237 // Apple squircle approximation for the flat fallback only

func makeContext(_ px: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setAllowsAntialiasing(true); ctx.setShouldAntialias(true)
    return ctx
}

func drawBrackets(_ ctx: CGContext, _ n: CGFloat, _ g: Geo, color: CGColor) {
    let s = n / 1024
    let m = g.margin * s, a = g.arm * s, w = g.stroke * s
    ctx.setFillColor(color)
    for (cx, cy) in [(m, m), (n - m, m), (m, n - m), (n - m, n - m)] {
        let dx: CGFloat = cx < n / 2 ? 1 : -1, dy: CGFloat = cy < n / 2 ? 1 : -1
        ctx.fill(CGRect(x: min(cx, cx + dx * a), y: min(cy, cy + dy * w), width: a, height: w))
        ctx.fill(CGRect(x: min(cx, cx + dx * w), y: min(cy, cy + dy * a), width: w, height: a))
    }
}

/// "Vx" as a filled path (SF Pro Display Bold, tight tracking), optically centered in the tile.
func drawMonogram(_ ctx: CGContext, _ n: CGFloat, color: CGColor) {
    let s = n / 1024
    let probe = NSFont.systemFont(ofSize: 100, weight: .bold)
    let size = capHeight1024 * s * 100 / probe.capHeight
    let font = NSFont.systemFont(ofSize: size, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .kern: tracking * size]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: "Vx", attributes: attrs))
    let path = CGMutablePath()
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let runFont = unsafeBitCast(CFDictionaryGetValue(CTRunGetAttributes(run), Unmanaged.passUnretained(kCTFontAttributeName).toOpaque()), to: CTFont.self)
        let count = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: count), positions = [CGPoint](repeating: .zero, count: count)
        CTRunGetGlyphs(run, CFRangeMake(0, 0), &glyphs); CTRunGetPositions(run, CFRangeMake(0, 0), &positions)
        for i in 0..<count {
            var t = CGAffineTransform(translationX: positions[i].x, y: positions[i].y)
            if let g = CTFontCreatePathForGlyph(runFont, glyphs[i], &t) { path.addPath(g) }
        }
    }
    let b = path.boundingBoxOfPath
    ctx.saveGState()
    ctx.translateBy(x: (n - b.width) / 2 - b.minX, y: (n - b.height) / 2 - b.minY)
    ctx.addPath(path); ctx.setFillColor(color); ctx.fillPath()
    ctx.restoreGState()
}

enum Layer { case tile, brackets, monogram }
/// Composite icon at `px`. `tile: false` leaves the background transparent (README / template use).
func icon(px: Int, palette: Palette, layers: Set<Layer> = [.tile, .brackets, .monogram], roundTile: Bool = true) -> CGImage {
    let n = CGFloat(px), ctx = makeContext(px)
    if layers.contains(.tile) {
        if roundTile {
            let r = n * cornerRatio
            ctx.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: n, height: n), cornerWidth: r, cornerHeight: r, transform: nil))
            ctx.setFillColor(palette.tile); ctx.fillPath()
        } else { ctx.setFillColor(palette.tile); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n)) }
    }
    let tiny = px <= 32 // K1
    if layers.contains(.brackets) { drawBrackets(ctx, n, tiny ? smallGeo : fullGeo, color: palette.brackets) }
    if layers.contains(.monogram) && !tiny { drawMonogram(ctx, n, color: palette.monogram) }
    return ctx.makeImage()!
}

func write(_ img: CGImage, _ name: String, dpi: CGFloat = 72) -> URL {
    let url = outDir.appendingPathComponent(name)
    let rep = NSBitmapImageRep(cgImage: img)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
    return url
}
var files: [String] = []

// 1. Icon Composer layers (full 1024 square; the system applies the shape)
files.append(write(icon(px: 1024, palette: dark, layers: [.tile], roundTile: false), "background.png").lastPathComponent)
files.append(write(icon(px: 1024, palette: dark, layers: [.brackets]), "brackets.png").lastPathComponent)
files.append(write(icon(px: 1024, palette: dark, layers: [.monogram]), "monogram.png").lastPathComponent)

// 2. Flat fallback iconset (+ icns via make-logo.sh)
let iconset = outDir.appendingPathComponent("Viewportix.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for pt in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(pt)x\(pt).png" : "icon_\(pt)x\(pt)@2x.png"
        let rep = NSBitmapImageRep(cgImage: icon(px: pt * scale, palette: dark))
        try! rep.representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name))
    }
}
files.append("Viewportix.iconset/ (10 files)")
files.append(write(icon(px: 1024, palette: dark), "icon-1024.png").lastPathComponent)

// 3. README logos: transparent, brackets + monogram, 512 px (2x of a 256 px slot)
files.append(write(icon(px: 512, palette: dark, layers: [.brackets, .monogram]), "logo-dark.png").lastPathComponent)
files.append(write(icon(px: 512, palette: light, layers: [.brackets, .monogram]), "logo-light.png").lastPathComponent)
let picture = """
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="design/logo/out/logo-dark.png">
  <img alt="Viewportix" src="design/logo/out/logo-light.png" width="128" height="128">
</picture>

"""
try! picture.write(to: outDir.appendingPathComponent("README-picture.html"), atomically: true, encoding: .utf8)
files.append("README-picture.html")

// 4. Single-color template glyph (black on transparent, 2x of 64 pt)
let mono = Palette(tile: .black, brackets: .black, monogram: .black, names: "template")
files.append(write(icon(px: 128, palette: mono, layers: [.brackets, .monogram]), "glyph-template@2x.png").lastPathComponent)

// 5. Contact sheet
do {
    let sizes = [16, 32, 64, 128, 256, 512]
    let scale: CGFloat = 2, pad: CGFloat = 40, gap: CGFloat = 40, top: CGFloat = 80
    let rowW = sizes.reduce(0) { $0 + CGFloat($1) } + gap * CGFloat(sizes.count - 1)
    let W = pad * 2 + rowW, H = top + 512 + pad + 30
    let board = CGContext(data: nil, width: Int(W * scale), height: Int(H * scale), bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    board.scaleBy(x: scale, y: scale)
    board.setFillColor(hex(tokenHex("surface/card"))); board.fill(CGRect(x: 0, y: 0, width: W, height: H))
    func label(_ s: String, x: CGFloat, y: CGFloat, size: CGFloat = 13, weight: NSFont.Weight = .regular, color: String = "ink/secondary") {
        let a: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: NSColor(cgColor: hex(tokenHex(color)))!]
        board.textPosition = CGPoint(x: x, y: H - y); CTLineDraw(CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: a)), board)
    }
    label("Viewportix app icon · flat fallback · \(dark.names)", x: pad, y: 40, size: 15, weight: .semibold, color: "ink/primary")
    var x = pad
    for px in sizes {
        let img = icon(px: px, palette: dark)
        board.interpolationQuality = .none
        board.draw(img, in: CGRect(x: x, y: pad + 30 + (512 - CGFloat(px)) / 2, width: CGFloat(px), height: CGFloat(px)))
        label("\(px) px", x: x, y: H - pad - 8)
        x += CGFloat(px) + gap
    }
    files.append(write(board.makeImage()!, "check@2x.png").lastPathComponent)
}

print("palette dark: \(dark.names)")
print("palette light: \(light.names)")
print("geometry @1024: brackets margin \(Int(fullGeo.margin)) arm \(Int(fullGeo.arm)) stroke \(Int(fullGeo.stroke)); K1 ≤32 px: \(Int(smallGeo.margin))/\(Int(smallGeo.arm))/\(Int(smallGeo.stroke)); Vx cap \(Int(capHeight1024)), tracking \(tracking) em")
for f in files { print("  \(f)") }
