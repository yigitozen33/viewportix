#!/usr/bin/env python3
"""Token chain for Viewportix: viewportix.tokens.json -> DesignTokens.swift, plus a diff against pen.dev.

Usage (from design/tokens/):
  python3 gen_swift.py            # write DesignTokens.swift from viewportix.tokens.json
  python3 gen_swift.py --check    # exit 1 if DesignTokens.swift is stale
  python3 gen_swift.py --diff     # compare viewportix.tokens.json with pen-variables.json (from export-variables.js)

stdlib only. Pen variable names map to token paths as in PEN_TO_TOKEN below; tokens that exist only in code
(sizes pen.dev cannot resolve, extra strokes, glyphs, motion) are listed in CODE_ONLY and are not reported.
"""
import json, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TOKENS = HERE / "viewportix.tokens.json"
SWIFT = HERE / "DesignTokens.swift"
PEN = HERE / "pen-variables.json"

CODE_ONLY = {
    "size/rail", "size/panel-overlay", "size/panel-docked",
    "stroke/leader", "stroke/selection-ring", "stroke/selection-gap",
    "glyph/webkit", "glyph/chromium", "glyph/firefox",
    "motion/hover", "motion/fast", "motion/standard", "motion/panel", "motion/canvas-pan", "motion/tooltip-delay",
}


def flatten(obj, prefix=""):
    out = {}
    for k, v in obj.items():
        if k.startswith("$"):
            continue
        if isinstance(v, dict) and "$value" in v:
            out[prefix + k] = v
        elif isinstance(v, dict):
            out.update(flatten(v, prefix + k + "/"))
    return out


def camel(name):
    parts = re.split(r"[-/]", name)
    head, *rest = parts
    return head + "".join(p[:1].upper() + p[1:] for p in rest)


def px(v):
    return float(v[:-2]) if isinstance(v, str) and v.endswith("px") else float(v)


def fmt(n):
    return str(int(n)) if float(n).is_integer() else str(n)


def rgb(hexstr):
    h = hexstr.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"SwiftUI.Color(red: {r:.4f}, green: {g:.4f}, blue: {b:.4f})"


def generate(tokens):
    flat = flatten(tokens)
    L = []
    L.append("// Generated from design/tokens/viewportix.tokens.json by gen_swift.py — do not edit by hand.")
    L.append("// Source of truth: design/viewportix.pen variables (DESIGN.md §6). Copy into the package; regenerate on change.")
    L.append("import SwiftUI")
    L.append("")
    L.append("public enum DesignTokens {")
    L.append("    // MARK: Color — dark is the only shipped theme; `light` is kept for later.")
    L.append("    public enum Color {")
    for k, v in flat.items():
        if not k.startswith("color/"):
            continue
        name = k[len("color/"):]
        light = v.get("$extensions", {}).get("viewportix.light", "")
        L.append(f"        /// {name} · dark {v['$value']} · light {light}")
        L.append(f"        public static let {camel(name)} = {rgb(v['$value'])}")
    L.append("    }")

    def group(title, prefix, enum, rename=None, typ="CGFloat"):
        L.append(f"    public enum {enum} {{")
        for k, v in flat.items():
            if not k.startswith(prefix + "/"):
                continue
            name = k[len(prefix) + 1:]
            ident = rename(name) if rename else camel(name)
            L.append(f"        public static let {ident}: {typ} = {fmt(px(v['$value']))}")
        L.append("    }")

    group("Radius", "radius", "Radius")
    group("Space", "space", "Space", rename=lambda n: "s" + n)
    group("Size", "size", "Size")
    group("Stroke", "stroke", "Stroke")
    group("FontSize", "font-size", "FontSize")
    L.append("    // MARK: Type — system fonts in the app (SF Pro / SF Mono); Inter / JetBrains Mono are design-file proxies only.")
    L.append("    public enum Font {")
    L.append("        public static let title = SwiftUI.Font.system(size: FontSize.title, weight: .semibold)")
    L.append("        public static let body = SwiftUI.Font.system(size: FontSize.body, weight: .regular)")
    L.append("        public static let label = SwiftUI.Font.system(size: FontSize.label, weight: .medium)")
    L.append("        public static let caption = SwiftUI.Font.system(size: FontSize.caption, weight: .regular)")
    L.append("        public static let micro = SwiftUI.Font.system(size: FontSize.micro, weight: .semibold)")
    L.append("        public static func mono(_ size: CGFloat = FontSize.label) -> SwiftUI.Font { .system(size: size, design: .monospaced) }")
    L.append("    }")
    L.append("    // MARK: Motion — durations from the interaction tables (DESIGN.md §3).")
    L.append("    public enum Motion {")
    for k, v in flat.items():
        if not k.startswith("motion/"):
            continue
        ms = float(v["$value"][:-2])
        L.append(f"        public static let {camel(k[len('motion/'):])}: Double = {fmt(ms / 1000)}")
    L.append("    }")
    L.append("}")
    return "\n".join(L) + "\n"


PEN_RENAME = {"accent/ink": "color/accent-ink", "line/strong": "color/line-strong"}  # pen nests under a leaf; W3C groups cannot be leaves


def pen_to_token(name, typ):
    if name in PEN_RENAME:
        return PEN_RENAME[name]
    if typ == "color":
        return "color/" + name
    if name.startswith("font/") and typ == "number":
        return "font-size/" + name[len("font/"):]
    return name


def diff(tokens, pen):
    flat = flatten(tokens)
    problems, seen = [], set()
    for name, d in pen["variables"].items():
        path = pen_to_token(name, d["type"])
        seen.add(path)
        tok = flat.get(path)
        if tok is None:
            problems.append(f"pen-only  {name}")
            continue
        vals = {tuple(sorted((v.get("theme") or {}).items())): v["value"] for v in d["values"]}
        if d["type"] == "color":
            dark, light = vals.get((("mode", "dark"),)), vals.get((("mode", "light"),))
            if dark.upper() != tok["$value"].upper():
                problems.append(f"value     {name}: pen {dark} ≠ json {tok['$value']}")
            jl = tok.get("$extensions", {}).get("viewportix.light")
            if light and jl and light.upper() != jl.upper():
                problems.append(f"light     {name}: pen {light} ≠ json {jl}")
        elif d["type"] == "number":
            if px(tok["$value"]) != float(d["values"][0]["value"]):
                problems.append(f"value     {name}: pen {d['values'][0]['value']} ≠ json {tok['$value']}")
        elif d["type"] == "string":
            proxy = tok.get("$extensions", {}).get("viewportix.designProxy")
            if proxy != d["values"][0]["value"]:
                problems.append(f"proxy     {name}: pen {d['values'][0]['value']} ≠ json designProxy {proxy}")
    for path in flat:
        if path not in seen and path not in CODE_ONLY:
            problems.append(f"json-only {path}")
    return problems


def main():
    tokens = json.loads(TOKENS.read_text())
    if "--diff" in sys.argv:
        if not PEN.exists():
            print("pen-variables.json missing: run export-variables.js in pen.dev first"); sys.exit(2)
        problems = diff(tokens, json.loads(PEN.read_text()))
        print("DIFF: none" if not problems else "DIFF:\n  " + "\n  ".join(problems))
        sys.exit(1 if problems else 0)
    out = generate(tokens)
    if "--check" in sys.argv:
        stale = not SWIFT.exists() or SWIFT.read_text() != out
        print("DesignTokens.swift is " + ("STALE" if stale else "up to date"))
        sys.exit(1 if stale else 0)
    SWIFT.write_text(out)
    print(f"wrote {SWIFT.name} ({len(out.splitlines())} lines)")


if __name__ == "__main__":
    main()
