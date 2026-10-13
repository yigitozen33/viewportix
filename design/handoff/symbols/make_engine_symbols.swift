// Builds design/handoff/symbols/engine.<webkit|chromium|firefox>.symbolset — static SF Symbols templates (27 variants:
// 9 weights × S/M/L) from the engine glyphs drawn in design/viewportix.pen › Engine Glyphs (16×16 grid, 2-unit band;
// nodes Q2Kww / LDfw0 / GPc6v, geometry copied below).
//
// Size and weight come from Apple's `circle` ring (SF Symbols.app fallback font, glyphs 8852 / 8853 / 8854 = S / M / L,
// advances 92.5 / 117.1 / 149.8 = NSImage(systemSymbolName: "circle") at S / M / L): the glyph's outer diameter (14 grid
// units) is mapped onto the ring's diameter for each weight and scale, and the 2-unit band is offset per weight:
//   W1  band = Apple's ring thickness, at least 0.6 grid units (chosen 2026-10-13, DESIGN.md §4: the glyph sits at
//       the same weight as SF symbols, as it sat with the Lucide camera in the design; the floor keeps the flame whole)
//   W2  band = 2 × ring / ring(Regular)          (rejected: clogs at Black)
//   W3  band = 2 at every weight                 (rejected: heavier than SF symbols, no weight response)
// Usage: swift make_engine_symbols.swift <W1|W2|W3> <out-dir>     (needs SF Symbols.app; macOS 13+)
import CoreText
import Foundation

let rule = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "W1"
let out = URL(fileURLWithPath: CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ".")
let engines: [(String, String)] = [
    ("engine.webkit", "M8 1a7 7 0 1 1 0 14 7 7 0 1 1 0-14z m0 2a5 5 0 1 0 0 10 5 5 0 1 0 0-10z m0 1.5l1.2 2.3 2.3 1.2-2.3 1.2-1.2 2.3-1.2-2.3-2.3-1.2 2.3-1.2z"),
    ("engine.chromium", "M9.22 1.11a7 7 0 0 1 5.36 9.28l-1.88-0.68a5 5 0 0 0-3.83-6.63z m4.14 11.39a7 7 0 0 1-10.72 0l1.53-1.29a5 5 0 0 0 7.66 0z m-11.94-2.11a7 7 0 0 1 5.36-9.28l0.35 1.97a5 5 0 0 0-3.83 6.63z m6.58-4.39a2 2 0 1 1 0 4 2 2 0 1 1 0-4z"),
    ("engine.firefox", "M8 1c1 3 5 5 5 9.5 0 2.8-2.2 4.5-5 4.5-2.8 0-5-1.7-5-4.5 0-2.3 1.2-3.9 2.6-5.1-0.2 1.8 0.8 2.9 1.7 2.9-0.4-2.5-0.1-5.1 0.7-7.3z m0.3 4c0.7 1.6 2.7 2.8 2.7 5.6 0 1.7-1.3 2.4-3 2.4-1.7 0-3-0.7-3-2.4 0-0.9 0.3-1.6 0.8-2.2 0.7 1.4 2.2 1.9 3.3 1.6-0.6-1.6-0.8-3.2-0.8-5z"),
]
let weights = ["Ultralight", "Thin", "Light", "Regular", "Medium", "Semibold", "Bold", "Heavy", "Black"]
let scales: [(String, CGGlyph, CGFloat)] = [("S", 8852, 696), ("M", 8853, 1126), ("L", 8854, 1556)]
let columns: [CGFloat] = (0..<9).map { 559.711 + CGFloat($0) * 296.711 }

// MARK: SVG path → CGPath (M L H V C S Q T A Z, absolute and relative, implicit repeats)
func parse(_ d: String) -> CGMutablePath {
    var toks: [String] = []
    var cur = ""
    for ch in d {
        if ch.isLetter { if !cur.isEmpty { toks.append(cur); cur = "" }; toks.append(String(ch)) }
        else if ch == "," || ch == " " { if !cur.isEmpty { toks.append(cur); cur = "" } }
        else if ch == "-" { if !cur.isEmpty && !cur.hasSuffix("e") { toks.append(cur); cur = "" }; cur.append(ch) }
        else if ch == "." && cur.contains(".") { toks.append(cur); cur = "." }
        else { cur.append(ch) }
    }
    if !cur.isEmpty { toks.append(cur) }
    let p = CGMutablePath()
    var i = 0, cmd = "M", pt = CGPoint.zero, start = CGPoint.zero, lastCtrl: CGPoint? = nil
    func num() -> CGFloat { defer { i += 1 }; return CGFloat(Double(toks[i])!) }
    func arc(_ rx0: CGFloat, _ ry0: CGFloat, _ phiDeg: CGFloat, _ large: Bool, _ sweep: Bool, _ end: CGPoint) {
        var rx = abs(rx0), ry = abs(ry0)
        let phi = phiDeg * .pi / 180, c = cos(phi), s = sin(phi)
        let dx = (pt.x - end.x) / 2, dy = (pt.y - end.y) / 2
        let x1 = c * dx + s * dy, y1 = -s * dx + c * dy
        let lam = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
        if lam > 1 { rx *= sqrt(lam); ry *= sqrt(lam) }
        let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        var co = sqrt(max(0, num / (rx * rx * y1 * y1 + ry * ry * x1 * x1)))
        if large == sweep { co = -co }
        let cx1 = co * rx * y1 / ry, cy1 = -co * ry * x1 / rx
        let cx = c * cx1 - s * cy1 + (pt.x + end.x) / 2, cy = s * cx1 + c * cy1 + (pt.y + end.y) / 2
        func ang(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy); return a
        }
        let t1 = ang(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
        var dt = ang((x1 - cx1) / rx, (y1 - cy1) / ry, (-x1 - cx1) / rx, (-y1 - cy1) / ry)
        if !sweep && dt > 0 { dt -= 2 * .pi } else if sweep && dt < 0 { dt += 2 * .pi }
        let n = Int(ceil(abs(dt) / (.pi / 2)))
        let step = dt / CGFloat(n), k = 4.0 / 3.0 * tan(step / 4)
        var t = t1
        for _ in 0..<n {
            let (c1, s1, c2, s2) = (cos(t), sin(t), cos(t + step), sin(t + step))
            func mp(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: cx + c * rx * x - s * ry * y, y: cy + s * rx * x + c * ry * y) }
            p.addCurve(to: mp(c2, s2), control1: mp(c1 - k * s1, s1 + k * c1), control2: mp(c2 + k * s2, s2 - k * c2))
            t += step
        }
        pt = end
    }
    while i < toks.count {
        if Double(toks[i]) == nil { cmd = toks[i]; i += 1 }
        let rel = cmd == cmd.lowercased()
        let o = rel ? pt : .zero
        switch cmd.uppercased() {
        case "M": pt = CGPoint(x: o.x + num(), y: o.y + num()); p.move(to: pt); start = pt; cmd = rel ? "l" : "L"; lastCtrl = nil
        case "L": pt = CGPoint(x: o.x + num(), y: o.y + num()); p.addLine(to: pt); lastCtrl = nil
        case "H": pt = CGPoint(x: (rel ? pt.x : 0) + num(), y: pt.y); p.addLine(to: pt); lastCtrl = nil
        case "V": pt = CGPoint(x: pt.x, y: (rel ? pt.y : 0) + num()); p.addLine(to: pt); lastCtrl = nil
        case "C":
            let c1 = CGPoint(x: o.x + num(), y: o.y + num()), c2 = CGPoint(x: o.x + num(), y: o.y + num()), e = CGPoint(x: o.x + num(), y: o.y + num())
            p.addCurve(to: e, control1: c1, control2: c2); pt = e; lastCtrl = c2
        case "S":
            let c1 = lastCtrl.map { CGPoint(x: 2 * pt.x - $0.x, y: 2 * pt.y - $0.y) } ?? pt
            let c2 = CGPoint(x: o.x + num(), y: o.y + num()), e = CGPoint(x: o.x + num(), y: o.y + num())
            p.addCurve(to: e, control1: c1, control2: c2); pt = e; lastCtrl = c2
        case "Q":
            let c1 = CGPoint(x: o.x + num(), y: o.y + num()), e = CGPoint(x: o.x + num(), y: o.y + num())
            p.addQuadCurve(to: e, control: c1); pt = e; lastCtrl = nil
        case "A":
            let rx = num(), ry = num(), rot = num(), la = num() != 0, sw = num() != 0
            arc(rx, ry, rot, la, sw, CGPoint(x: o.x + num(), y: o.y + num())); lastCtrl = nil
        case "Z": p.closeSubpath(); pt = start; lastCtrl = nil
        default: fatalError("unsupported path command \(cmd)")
        }
    }
    return p
}

let faces = CTFontManagerCreateFontDescriptorsFromURL(URL(fileURLWithPath: "/Applications/SF Symbols.app/Contents/Resources/Fonts/SFSymbolsFallback.otf") as CFURL) as! [CTFontDescriptor]
func font(_ w: String) -> CTFont {
    CTFontCreateWithFontDescriptor(faces.first { (CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as! String).hasSuffix("-" + w) }!, 100, nil)
}
func ring(_ f: CTFont, _ g: CGGlyph) -> (box: CGRect, band: CGFloat, adv: CGFloat) {
    let p = CTFontCreatePathForGlyph(f, g, nil)!, b = p.boundingBoxOfPath
    var x = b.minX; while x < b.midX && p.contains(CGPoint(x: x + 0.01, y: b.midY), using: .winding) { x += 0.01 }
    var gg = g, adv = CGSize.zero; CTFontGetAdvancesForGlyphs(f, .horizontal, &gg, &adv, 1)
    return (b, x - b.minX, adv.width)
}

func variant(_ grid: CGPath, weight: String, glyph: CGGlyph) -> (CGPath, CGFloat) {
    let r = ring(font(weight), glyph)
    let k = r.box.width / 14                        // grid unit → font unit (outer diameter 14 ↔ ring diameter)
    let band: CGFloat
    switch rule {
    case "W1": band = max(0.6, r.band / k)
    case "W3": band = 2
    default:                                        // design band at Regular of this scale, SF ratio elsewhere
        let reg = ring(font("Regular"), glyph)
        band = 2 * (reg.box.width / r.box.width) * (r.band / reg.band)
    }
    let off = (band - 2) / 2                        // per side, grid units
    var shape: CGPath = grid.normalized(using: .evenOdd)
    if off > 0.001 { shape = shape.union(shape.copy(strokingWithWidth: 2 * off, lineCap: .round, lineJoin: .round, miterLimit: 4), using: .winding) }
    if off < -0.001 { shape = shape.subtracting(shape.copy(strokingWithWidth: -2 * off, lineCap: .round, lineJoin: .round, miterLimit: 4), using: .winding) }
    // grid (y down, centre 8,8) → font units (y up), centred on the ring's box
    var t = CGAffineTransform(translationX: r.box.midX, y: r.box.midY).scaledBy(x: k, y: -k).translatedBy(x: -8, y: -8)
    return (shape.copy(using: &t)!, r.adv)
}

func svgPath(_ p: CGPath) -> String {
    func f(_ v: CGFloat) -> String { String(format: "%.4g", Double(v)) }
    func pt(_ q: CGPoint) -> String { "\(f(q.x)) \(f(-q.y))" }
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

let hRef = #"<path d="M0.993654 0L3.63775 0L29.3281-67.1323L30.0303-67.1323L30.0303-70.459L28.1226-70.459ZM11.6885-24.4799L46.9815-24.4799L46.2315-26.7285L12.4385-26.7285ZM55.1196 0L57.7637 0L30.6382-70.459L29.4326-70.459L29.4326-67.1323Z"/>"#
for (name, d) in engines {
    let grid = parse(d)
    var guides = "", symbols = ""
    for (s, _, base) in scales {
        guides += """
          <g id="H-reference" style="fill:#27AAE1;stroke:none;" transform="matrix(1 0 0 1 339 \(Int(base)))">
           \(hRef)
          </g>
          <line id="Baseline-\(s)" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="\(Int(base))" y2="\(Int(base))"/>
          <line id="Capline-\(s)" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="\(String(format: "%.3f", base - 70.459))" y2="\(String(format: "%.3f", base - 70.459))"/>

        """
    }
    for (wi, w) in weights.enumerated() {
        for (s, g, base) in scales {
            let (p, adv) = variant(grid, weight: w, glyph: g)
            let left = columns[wi] - adv / 2, right = left + adv
            let id = "\(w)-\(s)"
            guides += """
              <line id="left-margin-\(id)" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;" x1="\(String(format: "%.3f", left))" x2="\(String(format: "%.3f", left))" y1="\(String(format: "%.3f", base - 95.215))" y2="\(String(format: "%.3f", base + 24.121))"/>
              <line id="right-margin-\(id)" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;" x1="\(String(format: "%.3f", right))" x2="\(String(format: "%.3f", right))" y1="\(String(format: "%.3f", base - 95.215))" y2="\(String(format: "%.3f", base + 24.121))"/>

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
       <text id="descriptive-name" style="stroke:none;fill:black;font-family:sans-serif;font-size:13;text-anchor:end;" transform="matrix(1 0 0 1 3036 1969)">Viewportix \(name) (\(rule))</text>
      </g>

    """
    let svg = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE svg
    PUBLIC "-//W3C//DTD SVG 1.1//EN"
           "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
    <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="3300" height="2200">
     <!--glyph: "\(name)" (custom, Viewportix, rule \(rule)), point size: 100.0, generated by design/handoff/symbols/make_engine_symbols.swift-->
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
    let set = out.appendingPathComponent("\(name).symbolset")
    try FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
    try svg.write(to: set.appendingPathComponent("\(name).svg"), atomically: true, encoding: .utf8)
    try #"{"info":{"author":"xcode","version":1},"symbols":[{"filename":"\#(name).svg","idiom":"universal"}]}"#.write(to: set.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
    print("wrote \(set.lastPathComponent) (\(rule), \(svg.count) chars)")
}
