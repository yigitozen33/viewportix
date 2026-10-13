// Builds design/handoff/symbols/link.slash.symbolset/link.slash.svg — a static SF Symbols template (27 variants:
// 9 weights × S/M/L) for the custom symbol `link.slash` (DESIGN.md §4, 2026-10-13).
//
// Source glyphs: Apple's `link` from SF Symbols.app › Contents/Resources/Fonts/SFSymbolsFallback.otf (one face per
// weight; glyphs 13072 / 13073 / 13074 = scale S / M / L, matched by shape and by advance against
// NSImage(systemSymbolName: "link")). Slash rule measured on Apple's own `wifi.slash` vs `wifi` in the same font:
// 45°, top-left → bottom-right, through the body centre, vertical extent 87 % of the body (as `bell.slash`),
// line width and clear gap per weight below (font units at 100 pt, scale M).
// Template layout copied from the app's own component template (writer v101, "Template v.4.0").
//
// Usage: swift make_link_slash.swift <out-dir>     (needs SF Symbols.app installed; macOS 13+ for CGPath booleans)
import CoreText
import Foundation

let fontURL = URL(fileURLWithPath: "/Applications/SF Symbols.app/Contents/Resources/Fonts/SFSymbolsFallback.otf") as CFURL
let weights = ["Ultralight", "Thin", "Light", "Regular", "Medium", "Semibold", "Bold", "Heavy", "Black"]
// measured on wifi.slash (scale M, 100 pt): slash line width and clear gap on each side
let slashWidth: [CGFloat] = [2.36, 3.73, 6.08, 7.66, 7.84, 7.89, 8.27, 8.46, 8.91]
let slashGap: [CGFloat] = [3.69, 4.06, 4.94, 5.61, 5.93, 6.22, 6.48, 6.99, 7.20]
let scales: [(String, CGGlyph, CGFloat, CGFloat)] = [("S", 13072, 696, 0.796), ("M", 13073, 1126, 1.0), ("L", 13074, 1556, 1.272)]
let columns: [CGFloat] = (0..<9).map { 559.711 + CGFloat($0) * 296.711 }
let extent: CGFloat = 0.87

let faces = CTFontManagerCreateFontDescriptorsFromURL(fontURL) as! [CTFontDescriptor]
func font(_ w: String) -> CTFont {
    let d = faces.first { (CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as! String).hasSuffix("-" + w) }!
    return CTFontCreateWithFontDescriptor(d, 100, nil)
}

func slashed(_ glyph: CGPath, width: CGFloat, gap: CGFloat) -> CGPath {
    let b = glyph.boundingBoxOfPath
    let half = extent * b.height / 2
    let line = CGMutablePath()
    line.move(to: CGPoint(x: b.midX - half, y: b.midY + half))   // y up: top-left
    line.addLine(to: CGPoint(x: b.midX + half, y: b.midY - half)) // bottom-right
    let bar = line.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 4)
    let band = line.copy(strokingWithWidth: width + 2 * gap, lineCap: .round, lineJoin: .round, miterLimit: 4)
    return glyph.subtracting(band, using: .winding).union(bar, using: .winding)
}

func svgPath(_ p: CGPath) -> String {
    func f(_ v: CGFloat) -> String { String(format: "%.4g", Double(v)) }
    func pt(_ q: CGPoint) -> String { "\(f(q.x)) \(f(-q.y))" }   // font y-up → SVG y-down
    var d = ""
    p.applyWithBlock { e in
        let el = e.pointee, ps = el.points
        switch el.type {
        case .moveToPoint: d += "M\(pt(ps[0]))"
        case .addLineToPoint: d += "L\(pt(ps[0]))"
        case .addQuadCurveToPoint: d += "Q\(pt(ps[0])) \(pt(ps[1]))"
        case .addCurveToPoint: d += "C\(pt(ps[0])) \(pt(ps[1])) \(pt(ps[2]))"
        case .closeSubpath: d += "Z"
        @unknown default: break
        }
    }
    return d
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
var guides = "", symbols = ""
let hRef = #"<path d="M0.993654 0L3.63775 0L29.3281-67.1323L30.0303-67.1323L30.0303-70.459L28.1226-70.459ZM11.6885-24.4799L46.9815-24.4799L46.2315-26.7285L12.4385-26.7285ZM55.1196 0L57.7637 0L30.6382-70.459L29.4326-70.459L29.4326-67.1323Z"/>"#
for (s, _, base, _) in scales {
    guides += """
      <g id="H-reference" style="fill:#27AAE1;stroke:none;" transform="matrix(1 0 0 1 339 \(Int(base)))">
       \(hRef)
      </g>
      <line id="Baseline-\(s)" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="\(Int(base))" y2="\(Int(base))"/>
      <line id="Capline-\(s)" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="\(String(format: "%.3f", base - 70.459))" y2="\(String(format: "%.3f", base - 70.459))"/>

    """
}
for (wi, w) in weights.enumerated() {
    let f = font(w)
    for (s, g, base, k) in scales {
        var gl = g, adv = CGSize.zero
        CTFontGetAdvancesForGlyphs(f, .horizontal, &gl, &adv, 1)
        let glyph = CTFontCreatePathForGlyph(f, g, nil)!
        let p = slashed(glyph, width: slashWidth[wi] * k, gap: slashGap[wi] * k)
        let left = columns[wi] - adv.width / 2, right = left + adv.width
        let y0 = base - 95.215, y1 = base + 24.121
        let id = "\(w)-\(s)"
        guides += """
          <line id="left-margin-\(id)" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;" x1="\(String(format: "%.3f", left))" x2="\(String(format: "%.3f", left))" y1="\(String(format: "%.3f", y0))" y2="\(String(format: "%.3f", y1))"/>
          <line id="right-margin-\(id)" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;" x1="\(String(format: "%.3f", right))" x2="\(String(format: "%.3f", right))" y1="\(String(format: "%.3f", y0))" y2="\(String(format: "%.3f", y1))"/>

        """
        symbols += """
          <g id="\(id)" transform="matrix(1 0 0 1 \(String(format: "%.3f", left)) \(Int(base)))">
           <path class="monochrome-0 multicolor-0:tintColor hierarchical-0:primary SFSymbolsPreview000000" d="\(svgPath(p))"/>
          </g>

        """
    }
}
var notes = """
  <g id="Notes">
   <rect height="2200" id="artboard" style="fill:white;opacity:1" width="3300" x="0" y="0"/>
   <line style="fill:none;stroke:black;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="292" y2="292"/>
   <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13;font-weight:bold;" transform="matrix(1 0 0 1 263 322)">Weight/Scale Variations</text>

"""
for (i, w) in weights.enumerated() {
    notes += #"   <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13;text-anchor:middle;" transform="matrix(1 0 0 1 \#(String(format: "%.3f", columns[i])) 322)">\#(w)</text>"# + "\n"
}
notes += """
   <text id="template-version" style="stroke:none;fill:black;font-family:sans-serif;font-size:13;text-anchor:end;" transform="matrix(1 0 0 1 3036 1933)">Template v.4.0</text>
   <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13;text-anchor:end;" transform="matrix(1 0 0 1 3036 1951)">Requires Xcode 14 or greater</text>
   <text id="descriptive-name" style="stroke:none;fill:black;font-family:sans-serif;font-size:13;text-anchor:end;" transform="matrix(1 0 0 1 3036 1969)">Generated from link (Viewportix link.slash)</text>
  </g>

"""
let svg = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg
PUBLIC "-//W3C//DTD SVG 1.1//EN"
       "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="3300" height="2200">
 <!--glyph: "link.slash" (custom, Viewportix), point size: 100.0, generated by design/handoff/symbols/make_link_slash.swift-->
 <style>.monochrome-0 {fill:#000000}
.multicolor-0:tintColor {fill:#007AFF}
.hierarchical-0:primary {fill:#212121}
.SFSymbolsPreview000000 {fill:#000000;opacity:1.0}
</style>
\(notes) <g id="Guides">
\(guides) </g>
 <g id="Symbols">
\(symbols) </g>
</svg>

"""
let set = out.appendingPathComponent("link.slash.symbolset")
try FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
try svg.write(to: set.appendingPathComponent("link.slash.svg"), atomically: true, encoding: .utf8)
try #"{"info":{"author":"xcode","version":1},"symbols":[{"filename":"link.slash.svg","idiom":"universal"}]}"#.write(to: set.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("wrote \(set.path) (\(svg.count) chars, 27 variants)")
