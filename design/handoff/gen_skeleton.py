#!/usr/bin/env python3
"""Stage 9 trial: SwiftUI skeleton from a component spec (specs/<SwiftName>.json) -> skeleton/<SwiftName>.swift.

What it emits per component: a `View` with HStack / VStack / ZStack from the layer tree, padding / spacing /
radius / colours / type as `DesignTokens` members (raw numbers stay literals), SF Symbols from icons.md
(build_icons.MAP), init parameters for every text and icon layer plus root background and padding (so
instances can override them), and a `State` enum from the drawn states whose overrides become ternaries.
Instances of other components become calls to their generated views (generated too). Companions (tooltips,
menus) are not emitted, only listed in a comment.

Usage: python3 gen_skeleton.py BottomBar   # writes skeleton/{BottomBar,ChromeButton,ZoomControl}.swift
stdlib only. Output is a starting point, not production code; regenerate rather than edit.
"""
import json, re, sys, unicodedata
from pathlib import Path

HERE = Path(__file__).resolve().parent
SPECS, OUT = HERE / "specs", HERE / "skeleton"
sys.path.insert(0, str(HERE))
from build_icons import MAP as ICONS  # noqa: E402
from build_specs import swift_member  # noqa: E402

PEN = {k: v["type"] for k, v in json.loads((HERE.parent / "tokens" / "pen-variables.json").read_text())["variables"].items()}
WEIGHT = {"normal": ".regular", "400": ".regular", "500": ".medium", "600": ".semibold", "700": ".bold"}


def ident(text, upper=False):
    t = unicodedata.normalize("NFKD", text.replace("ı", "i").replace("İ", "I"))
    words = [w for w in re.split(r"[^A-Za-z0-9]+", t.encode("ascii", "ignore").decode()) if w]
    s = "".join(w[:1].upper() + w[1:] for w in words) or "x"
    s = s if upper else s[:1].lower() + s[1:]
    return "_" + s if s[0].isdigit() else s


def tok(v):
    """pen value -> Swift expression."""
    if isinstance(v, str) and v.startswith("$"):
        name = v[1:]
        return swift_member(name, PEN.get(name, "number")) if name in PEN else f"/* unknown {v} */ 0"
    if isinstance(v, str) and v.startswith("#"):
        h = v[1:]
        r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
        a = f", opacity: {int(h[6:8], 16) / 255:.3f}" if len(h) == 8 else ""
        return f"Color(red: {r:.3f}, green: {g:.3f}, blue: {b:.3f}{a}) /* raw {v} */"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return f"{v:g}"
    return f"/* unsupported {json.dumps(v, ensure_ascii=False)} */"


def symbol(lucide):
    place, sf, kind, _ = ICONS.get(lucide, ("", lucide, "?", ""))
    if kind == "özel" or sf in ("—",) or "(özel)" in sf:
        return sf.replace(" (özel)", "") if sf != "—" else lucide, True
    return sf, False


def edge(p):
    t, r, b, l = p
    return f"EdgeInsets(top: {tok(t)}, leading: {tok(l)}, bottom: {tok(b)}, trailing: {tok(r)})"


class Gen:
    def __init__(self, swift):
        self.spec = json.loads((SPECS / f"{swift}.json").read_text())
        self.swift = swift
        self.params = {}      # nodeId -> (paramName, kind, default)
        self.order = []
        self.deps = set()
        # A state counts when its first sample changes more than data (text, icon, size); a state without any
        # override is kept only as the first one (the default look). Pure-data samples ("+ Cihaz" chip) are dropped.
        DATA = {"content", "icon", "width", "height"}
        def visual(s):
            o = s["samples"][0]
            return set(o.get("set", {})) - DATA or any(set(x.get("set", {})) - DATA or "replace" in x for x in o.get("overrides", []))
        drawn = [s for s in self.spec["states"] if s["samples"]]
        self.states = [s for i, s in enumerate(drawn) if visual(s) or (i == 0 and not s["samples"][0].get("overrides") and not s["samples"][0].get("set"))]
        if len(self.states) == 1:  # only a default look: no State enum
            self.states = []
        self.state_names = []
        self.overrides = {}   # nodeId -> {prop: {stateName: value}}
        used = set()
        for s in self.states:
            name = ident(s["state"])
            while name in used:
                name += "2"
            used.add(name)
            self.state_names.append(name)
            sample = s["samples"][0]
            for o in sample.get("overrides", []):
                for k, v in o.get("set", {}).items():
                    self.overrides.setdefault(o["nodeId"], {}).setdefault(k, {})[name] = v
        self.collect(self.spec["tree"], set())

    def collect(self, n, names):
        if n["type"] in ("text", "icon"):
            base = ident(n["name"])
            name = base
            i = 2
            while name in names:
                name, i = f"{base}{i}", i + 1
            names.add(name)
            if n["type"] == "text":
                default = None if n.get("hidden") else n["text"]["content"]
                self.params[n["nodeId"]] = (name, "text", default)
            else:
                sf, custom = symbol(n["icon"]["lucide"])
                self.params[n["nodeId"]] = (name, "icon", None if n.get("hidden") else sf)
                self.params[n["nodeId"] + ":size"] = (name + "Size", "size", n["size"]["w"])
            self.order.append(n["nodeId"])
        for c in n.get("children", []):
            self.collect(c, names)

    def val(self, node_id, prop, default_expr, conv=tok):
        """default value, or a ternary chain over states that override this prop."""
        per = self.overrides.get(node_id, {}).get(prop)
        if not per:
            return default_expr
        expr = default_expr
        for st, v in per.items():
            expr = f"(state == .{st} ? {conv(v)} : {expr})"
        return expr

    # --- emit -----------------------------------------------------------------------------------------------
    def node(self, n, ind, root=False):
        pad = "    " * ind
        t = n["type"]
        nid = n.get("nodeId", "")
        if t == "frame":
            lay = n.get("layout", {})
            axis = lay.get("axis", "horizontal")
            gap = tok(lay["gap"]) if "gap" in lay else "0"
            if axis == "vertical":
                align = {"center": ".center", "start": ".leading", "end": ".trailing"}.get(lay.get("alignItems"), ".leading")
                head = f"VStack(alignment: {align}, spacing: {gap})"
            elif axis == "horizontal":
                align = {"center": ".center", "start": ".top", "end": ".bottom"}.get(lay.get("alignItems"), ".center")
                head = f"HStack(alignment: {align}, spacing: {gap})"
            else:
                head = "ZStack(alignment: .topLeading)"
            L = [f"{pad}{head} {{  // {n['name']}"]
            kids = n.get("children", [])
            between = lay.get("justifyContent") == "space_between"
            for i, c in enumerate(kids):
                if between and i:
                    L.append(f"{pad}    Spacer(minLength: 0)")
                L += self.node(c, ind + 1)
            L.append(f"{pad}}}")
            mods = []
            if "padding" in lay:
                mods.append(f".padding({'padding' if root else edge(lay['padding'])})")
            mods += self.frame_mods(n)
            fill = n.get("fill")
            radius = tok(n["cornerRadius"]) if "cornerRadius" in n else "0"
            if root:
                mods.append(f".background(background, in: RoundedRectangle(cornerRadius: {radius}, style: .continuous))")
            elif fill is not None or nid in self.overrides:
                mods.append(f".background({self.val(nid, 'fill', tok(fill) if fill else 'Color.clear')}, in: RoundedRectangle(cornerRadius: {radius}, style: .continuous))")
            if n.get("clip"):
                mods.append(f".clipShape(RoundedRectangle(cornerRadius: {radius}, style: .continuous))")
            if "stroke" in n:
                width = tok(n.get("strokeWidth", 1)) if not isinstance(n.get("strokeWidth"), dict) else "1 /* one side only */"
                fn = "strokeBorder" if n.get("strokeAlignment") == "inner" else "stroke"
                mods.append(f".overlay(RoundedRectangle(cornerRadius: {radius}, style: .continuous).{fn}({tok(n['stroke'])}, lineWidth: {width}))")
            return L + [f"{pad}{m}" for m in mods]
        if t == "text":
            p = self.params[nid][0]
            tx = n["text"]
            weight = WEIGHT.get(str(tx.get("fontWeight", "normal")), ".regular")
            return [f"{pad}if let {p} {{",
                    f"{pad}    Text({p})",
                    f"{pad}        .font(.system(size: {tok(tx.get('fontSize', 13))}, weight: {weight}))",
                    f"{pad}        .foregroundStyle({self.val(nid, 'fill', tok(n.get('fill', '$ink/primary')))})",
                    f"{pad}}}"]
        if t == "icon":
            p, _, _ = self.params[nid]
            size = self.params[nid + ":size"][0]
            per = self.overrides.get(nid, {}).get("icon")
            sym = p
            if per:
                for st, v in per.items():
                    sym = f"(state == .{st} ? {json.dumps(symbol(v)[0])} : {sym})"
            return [f"{pad}if let {p} {{",
                    f"{pad}    SkeletonSymbol(name: {sym if per else p}, size: {size})",
                    f"{pad}        .frame(width: {size}, height: {size})",
                    f"{pad}        .foregroundStyle({self.val(nid, 'fill', tok(n.get('fill', '$ink/primary')))})",
                    f"{pad}}}"]
        if t == "ref":
            return self.ref(n, ind)
        if t == "ellipse":
            return [f"{pad}Circle().fill({tok(n.get('fill', '#000000'))})"] + [f"{pad}{m}" for m in self.frame_mods(n)]
        if t == "rectangle":
            return [f"{pad}RoundedRectangle(cornerRadius: {tok(n.get('cornerRadius', 0))}).fill({tok(n.get('fill', '#000000'))})"] + [f"{pad}{m}" for m in self.frame_mods(n)]
        if t == "path":
            return [f"{pad}Image({json.dumps(n['name'])})  // path glyph — custom symbol, see icons.md"] + [f"{pad}{m}" for m in self.frame_mods(n)]
        return [f"{pad}// {t} `{n['name']}` not emitted"]

    def frame_mods(self, n):
        s = n.get("size", {})
        w, h = s.get("w"), s.get("h")
        args = []
        if isinstance(w, (int, float)):
            args.append(f"width: {w:g}")
        if isinstance(h, (int, float)):
            args.append(f"height: {h:g}")
        mods = [f".frame({', '.join(args)})"] if args else []
        if w == "fill":
            mods.append(".frame(maxWidth: .infinity)")
        if h == "fill":
            mods.append(".frame(maxHeight: .infinity)")
        return mods

    def ref(self, n, ind):
        pad = "    " * ind
        child = n["swiftName"]
        self.deps.add(child)
        sub = Gen(child)
        args = []
        for o in n.get("overrides", []):
            key = o["nodeId"].split("/")[-1]
            st = o.get("set", {})
            if key in sub.params:
                pname, kind, _ = sub.params[key]
                if st.get("enabled") is False:
                    args.append(f"{pname}: nil")
                elif kind == "text" and "content" in st:
                    args.append(f"{pname}: {json.dumps(st['content'], ensure_ascii=False)}")
                elif kind == "icon" and "icon" in st:
                    args.append(f"{pname}: {json.dumps(symbol(st['icon'])[0])}")
                if kind == "icon" and "width" in st:
                    args.append(f"{pname}Size: {st['width']:g}")
        rs = n.get("set", {})
        if "padding" in rs:
            p = rs["padding"]
            p = [p] * 4 if not isinstance(p, list) else (p * 2 if len(p) == 2 else p)
            args.append(f"padding: {edge(p)}")
        nid = n["nodeId"]
        if "fill" in rs or nid in self.overrides:
            base = tok(rs["fill"]) if "fill" in rs else tok(sub.spec["tree"].get("fill", "#00000000"))
            args.append(f"background: {self.val(nid, 'fill', base)}")
        order = {p[0]: i for i, p in enumerate(sub.init_params())}
        args.sort(key=lambda a: order.get(a.split(":")[0], 99))
        return [f"{pad}{child}({', '.join(args)})  // {n['name']}"]

    def init_params(self):
        out = []
        for nid in self.order:
            name, kind, default = self.params[nid]
            out.append((name, "String?", json.dumps(default, ensure_ascii=False) if default is not None else "nil"))
            if kind == "icon":
                sname, _, sdefault = self.params[nid + ":size"]
                out.append((sname, "CGFloat", f"{sdefault:g}"))
        tree = self.spec["tree"]
        pad = tree.get("layout", {}).get("padding", [0, 0, 0, 0])
        out.append(("padding", "EdgeInsets", edge(pad)))
        out.append(("background", "Color", tok(tree["fill"]) if "fill" in tree else "Color.clear"))
        return out

    def emit(self):
        sp = self.spec
        L = [f"// Generated by design/handoff/gen_skeleton.py from specs/{self.swift}.json ({sp['generatedAt']}) — trial skeleton, regenerate, do not edit.",
             f"// pen.dev `{sp['penName']}` ({sp['nodeId']}), {sp['size'][0]}×{sp['size'][1]}. States in DESIGN.md §6: {sp['statesSummary']}"]
        for note in sp.get("notes", []):
            L += ["// " + line for line in note.splitlines()]
        comp = [c["name"] for s in sp["states"] for c in s.get("companions", [])]
        if comp:
            L.append(f"// Not emitted (drawn next to a state): {', '.join(sorted(set(comp)))} — see specs/{self.swift}.json › states[].companions")
        L += ["import SwiftUI", ""]
        params = self.init_params()
        L.append(f"public struct {self.swift}: View {{")
        if self.state_names:
            L.append(f"    public enum State {{ case {', '.join(self.state_names)} }}")
            L.append(f"    public var state: State = .{self.state_names[0]}")
        for name, typ, default in params:
            L.append(f"    public var {name}: {typ} = {default}")
        if self.state_names or params:
            args = ([f"state: State = .{self.state_names[0]}"] if self.state_names else []) + [f"{n}: {t} = {d}" for n, t, d in params]
            L.append(f"    public init({', '.join(args)}) {{")
            for n in (["state"] if self.state_names else []) + [p[0] for p in params]:
                L.append(f"        self.{n} = {n}")
            L.append("    }")
        L += ["", "    public var body: some View {"]
        L += self.node(sp["tree"], 2, root=True)
        L += ["    }", "}", ""]
        return "\n".join(L)


SUPPORT = '''// Generated by design/handoff/gen_skeleton.py — shared helper for skeleton views.
import SwiftUI

/// How big an SF Symbol is drawn relative to the Lucide box size in the design (`size`). SF Symbols at the same
/// point size look larger than Lucide icons; the ratio is a design decision (DESIGN.md §4, icon size).
public struct SkeletonIconStyle: Sendable {
    public var scale: CGFloat
    public var weight: Font.Weight
    /// Decided 2026-10-13 (DESIGN.md §4): SF Symbol point size = Lucide box × 0.875, regular (16 → 14 pt).
    public init(scale: CGFloat = 0.875, weight: Font.Weight = .regular) { self.scale = scale; self.weight = weight }
}
private struct SkeletonIconStyleKey: EnvironmentKey { static let defaultValue = SkeletonIconStyle() }
public extension EnvironmentValues {
    var skeletonIconStyle: SkeletonIconStyle {
        get { self[SkeletonIconStyleKey.self] }
        set { self[SkeletonIconStyleKey.self] = newValue }
    }
}

/// SF Symbol, or an asset-catalog symbol for the custom ones in design/handoff/icons.md: `link.slash`
/// (design/handoff/symbols/link.slash.symbolset) and the engine glyphs. `bundle` is where the asset catalog lives
/// (the app: `.main`; previews and tests can point it at another bundle).
public struct SkeletonSymbol: View {
    public static let custom: Set<String> = ["link.slash", "engine.webkit", "engine.chromium", "engine.firefox"]
    nonisolated(unsafe) public static var bundle: Bundle = .main
    @Environment(\.skeletonIconStyle) private var style
    public let name: String
    public let size: CGFloat
    public init(name: String, size: CGFloat) { self.name = name; self.size = size }
    public var body: some View {
        Group { if Self.custom.contains(name) { Image(name, bundle: Self.bundle) } else { Image(systemName: name) } }
            .font(.system(size: size * style.scale, weight: style.weight))
    }
}
'''


def main():
    todo, done = [sys.argv[1] if len(sys.argv) > 1 else "BottomBar"], set()
    OUT.mkdir(exist_ok=True)
    (OUT / "SkeletonSymbol.swift").write_text(SUPPORT)
    while todo:
        name = todo.pop()
        if name in done:
            continue
        g = Gen(name)
        src = g.emit()
        (OUT / f"{name}.swift").write_text(src)
        done.add(name)
        todo += sorted(g.deps - done)
        print(f"wrote skeleton/{name}.swift ({len(src.splitlines())} lines; states {len(g.state_names)}; params {len(g.init_params())})")


if __name__ == "__main__":
    main()
