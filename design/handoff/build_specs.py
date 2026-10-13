#!/usr/bin/env python3
"""Build design/handoff/specs/<SwiftName>.json (one per component) and specs/README.md from the pen.dev dump.

Inputs (design/handoff/ unless noted):
  specs-dump.json             output of dump-specs.js, saved with save_dump.py (hash-checked)
  instances-dump.json         output of dump-instances.js (instances inside screen frames), same way
  manifest.json               component -> swiftName / states / usedIn (build_manifest.py)
  ../tokens/pen-variables.json  pen variable types and values (export-variables.js)

Values are kept as pen.dev writes them: "$surface/card" is a token, "#2D2926" or 6 is raw. Each spec has a
`tokens` map (pen name -> DesignTokens member) and a `rawValues` list (colour / type values outside tokens,
the same rule as CHK-1; numbers are listed under `rawNumbers` with the token they equal, if any).

Usage: python3 build_specs.py   (exit 1 when there are open questions)
stdlib only.
"""
import json, re, sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
DUMP, INSTANCES, MANIFEST = HERE / "specs-dump.json", HERE / "instances-dump.json", HERE / "manifest.json"
PEN_VARS = HERE.parent / "tokens" / "pen-variables.json"
OUT = HERE / "specs"

# One caption on the canvas covers several samples, or the caption is a long note: name the state here.
LABEL_BY_INSTANCE = {
    "R93ZYb": "normal", "V1Ueb": "loading", "iWXSS": "syncMissed", "moRhV": "leader", "lPWH5": "snapshot",
    "IUsD2": "+ Cihaz (şeritte)",
    # Sidebar States › Hover: the same fill + dot marks the open page on every Project Window (23 instances).
    "oL6Jr": "selected (açık sayfa)", "OC7yZ": "Hover",
    "b9zRB": "+ Ekle satırı", "yOolk": "+ Ekle satırı", "zgjkA": "+ Ekle satırı", "v1LLj": "+ Ekle satırı",
}
LABEL_BY_PREFIX = {
    "Örnekler: düğme": "klavye odağı (focus ring)",
    "Öğenin solunda": "tooltip (ray öğesi)",
    "Aynı anda tek kapsül": "tek kapsül kuralı · Geri al",
    "Sayfa ajanı kabul etmiyorsa": "senkron kurulamıyor (‖)",
    "↑ ‖ üstünde": "senkron kurulamıyor · kapsül",
    "⇧ tık ile birden çok": "çoklu seçim (MVP dışı)",
    "Hepsi aynı hatada": "hepsi aynı hatada",
    "Sekmede: senkron kaçtı": "yükleme hatası (sekmede)",
    "Gruplu (Görünüm › Grupla)": "gruplu",
}
# Companions drawn next to an instance that belong to another component's spec.
COMPANION_OWNER = {"QvtkM": "Window/DeviceStrip"}


def load():
    dump = json.loads(DUMP.read_text())
    dump["inScreens"] = json.loads(INSTANCES.read_text())["inScreens"]
    manifest = json.loads(MANIFEST.read_text())
    pen = json.loads(PEN_VARS.read_text())["variables"]
    return dump, manifest, pen


def camel(name):
    head, *rest = re.split(r"[-/]", name)
    return head + "".join(p[:1].upper() + p[1:] for p in rest)


def swift_member(name, typ):
    if typ == "color":
        return "DesignTokens.Color." + camel(name)
    if typ == "string":
        return {"font/ui": "system font (SF Pro; Inter is a design proxy)",
                "font/mono": "system monospaced (SF Mono; JetBrains Mono is a design proxy)"}.get(name, name)
    group, _, leaf = name.partition("/")
    enum = {"radius": "Radius", "space": "Space", "size": "Size", "stroke": "Stroke", "font": "FontSize"}[group]
    return f"DesignTokens.{enum}." + ("s" + leaf if group == "space" else camel(leaf))


class Builder:
    def __init__(self, dump, manifest, pen):
        self.pen = {k: (v["type"], v["values"][0]["value"]) for k, v in pen.items()}
        self.by_hex = {v.upper(): k for k, (t, v) in self.pen.items() if t == "color"}
        self.by_num = defaultdict(list)
        for k, (t, v) in self.pen.items():
            if t == "number":
                self.by_num[float(v)].append(k)
        self.comp_by_id = {c["id"]: c for c in dump["components"]}
        self.comp_ids = {c["name"]: c["id"] for c in dump["components"]}
        self.meta = {c["penName"]: c for c in manifest["components"]}
        self.node_path = {}  # every master node id -> "Component › Child › …"
        self.master = {}  # every master node id -> raw node
        for c in dump["components"]:
            self._index(c["tree"], [])

    def _index(self, n, trail):
        here = trail + [n.get("name") or n["type"]]
        self.node_path[n["id"]] = " › ".join(here)
        self.master[n["id"]] = n
        for ch in n.get("children", []):
            if isinstance(ch, dict):
                self._index(ch, here)

    # --- values -------------------------------------------------------------------------------------------
    def scan(self, value, prop, path, ctx):
        """Record tokens and raw values found in one property value."""
        if isinstance(value, str) and value.startswith("$"):
            name = value[1:]
            if name in self.pen:
                ctx["tokens"][name] = swift_member(name, self.pen[name][0])
            else:
                ctx["questions"].append(f"bilinmeyen token `{value}` ({path} · {prop})")
        elif isinstance(value, str) and value.startswith("#"):
            opaque = len(value) == 7 or (len(value) == 9 and value.upper().endswith("FF"))
            ctx["raw"].append({"node": path, "prop": prop, "value": value,
                               "sameAsToken": self.by_hex.get(value.upper()[:7]) if opaque else None})
        elif isinstance(value, (int, float)) and not isinstance(value, bool):
            if prop in ("fontSize", "fontFamily"):
                ctx["raw"].append({"node": path, "prop": prop, "value": value,
                                   "sameAsToken": next((t for t in self.by_num.get(float(value), []) if t.startswith("font/")), None)})
            elif prop in ("gap", "padding", "cornerRadius", "strokeWidth"):
                group = {"gap": "space/", "padding": "space/", "cornerRadius": "radius/", "strokeWidth": "stroke/"}[prop]
                ctx["rawNumbers"].append({"node": path, "prop": prop, "value": value,
                                          "sameAsToken": next((t for t in self.by_num.get(float(value), []) if t.startswith(group)), None)})
        elif isinstance(value, list):
            for v in value:
                self.scan(v, prop, path, ctx)
        elif isinstance(value, dict):
            for k, v in value.items():
                if k == "color" or k == "colors":
                    self.scan(v, prop + "." + k, path, ctx)
                elif isinstance(v, (dict, list)):
                    self.scan(v, prop, path, ctx)
                elif k in ("left", "right", "top", "bottom"):
                    self.scan(v, prop, path, ctx)

    @staticmethod
    def size_of(n, axis):
        v = n.get(axis)
        if isinstance(v, (int, float)):
            return v
        if isinstance(v, str):
            return "fill" if v.startswith("fill_container") else "fit" if v.startswith("fit_content") else v
        if n["type"] == "text":
            return "fit"
        return "fit" if n["type"] == "frame" else None

    @staticmethod
    def padding(p):
        if p is None:
            return None
        if not isinstance(p, list):
            return [p, p, p, p]
        if len(p) == 2:
            return [p[0], p[1], p[0], p[1]]
        return p

    # --- nodes --------------------------------------------------------------------------------------------
    def node(self, n, ctx, px=None, trail=""):
        name = n.get("name") or n["type"]
        path = f"{trail} › {name}" if trail else name
        out = {"name": name, "type": n["type"]}
        if "id" in n:
            out["nodeId"] = n["id"]
        if n.get("enabled") is False:
            out["hidden"] = True  # present in the master, shown by a state override
        if n.get("layoutPosition") == "absolute":
            out["position"] = {"absolute": [n.get("x", 0), n.get("y", 0)]}
        elif trail and (n.get("x") or n.get("y")):
            out["position"] = {"at": [n.get("x", 0), n.get("y", 0)]}  # parent has no auto layout
        w, h = self.size_of(n, "width"), self.size_of(n, "height")
        if w is not None or h is not None:
            out["size"] = {"w": w, "h": h}
            if px and n.get("id") in px:
                out["size"]["px"] = px[n["id"]]
        if n["type"] == "frame":
            layout = n.get("layout", "horizontal")
            out["layout"] = {"axis": layout, "stack": {"horizontal": "HStack", "vertical": "VStack"}.get(layout, "ZStack (absolute)")}
            for k in ("gap", "alignItems", "justifyContent"):
                if k in n:
                    out["layout"][k] = n[k]
            if "padding" in n:
                out["layout"]["padding"] = self.padding(n["padding"])
            if n.get("clip"):
                out["clip"] = True
            if "slot" in n:
                out["slot"] = n["slot"]
        for k in ("cornerRadius", "fill", "stroke", "strokeWidth", "strokeAlignment", "opacity", "rotation", "effect"):
            if k in n:
                out[k] = n[k]
        if n["type"] == "text":
            out["text"] = {k: n[k] for k in ("content", "fontFamily", "fontSize", "fontWeight", "letterSpacing", "lineHeight", "textAlign", "textGrowth") if k in n}
        if n["type"] == "icon":
            out["icon"] = {"lucide": n.get("icon"), "library": n.get("library")}
        if n["type"] == "path":
            out["path"] = {k: n[k] for k in ("geometry", "viewBox", "fillRule") if k in n}
        if n["type"] == "ref":
            comp = self.comp_by_id.get(n["ref"])
            cname = comp["name"] if comp else n["ref"]
            out["component"] = cname
            out["swiftName"] = self.meta.get(cname, {}).get("swiftName")
            props = {k: v for k, v in n.items() if k not in ("type", "id", "ref", "name", "x", "y", "descendants", "children")}
            if props:
                out["set"] = props
            if n.get("descendants"):
                out["overrides"] = self.descendants(n["descendants"], ctx, path)
        for k, v in n.items():
            if k in ("fill", "stroke", "strokeWidth", "cornerRadius", "gap", "padding", "fontSize", "fontFamily", "effect"):
                self.scan(v, k, path, ctx)
        kids = [c for c in n.get("children", []) if isinstance(c, dict)]
        if kids:
            out["children"] = [self.node(c, ctx, px, path) for c in kids]
        return out

    def descendants(self, desc, ctx, trail):
        rows = []
        for nid, props in desc.items():
            where = self.node_path.get(nid.split("/")[-1], nid)
            if "type" in props:  # whole node replaced (slot content, error panel)
                rows.append({"node": where, "nodeId": nid, "replace": self.node(props, ctx, None, trail)})
            else:
                rows.append({"node": where, "nodeId": nid, "set": props})
                for k, v in props.items():
                    self.scan(v, k, f"{trail} › {where}", ctx)
        return rows

    # --- states -------------------------------------------------------------------------------------------
    @staticmethod
    def label(s):
        if s["instanceId"] in LABEL_BY_INSTANCE:
            return LABEL_BY_INSTANCE[s["instanceId"]]
        raw = s["label"] or s["frame"]
        for prefix, name in LABEL_BY_PREFIX.items():
            if raw.startswith(prefix):
                return name
        return raw

    def data_only(self, s):
        """True when the instance only changes data (text, icon, size) or repeats master values."""
        ref = self.comp_ids[s["component"]]
        return self.signature(s["overrides"], ref) == self.signature({}, ref)

    def states(self, comp_name, dump, ctx, used_companions):
        groups = defaultdict(list)
        for s in dump["states"]:
            if s["component"] == comp_name:
                groups[(s["frame"], self.label(s))].append(s)
        out = []
        for (frame, label), samples in groups.items():
            keep, seen = [], set()
            for s in samples:
                sig = self.signature(s["overrides"], self.comp_ids[comp_name])
                if sig in seen or (len(samples) > 1 and self.data_only(s)):
                    continue
                seen.add(sig)
                keep.append(s)
            entry = {"state": label, "frame": frame, "samples": []}
            for s in keep:
                o = dict(s["overrides"])
                inst = o.pop("name", None)
                desc = o.pop("descendants", {})
                sample = {"instanceId": s["instanceId"], "sizePx": s["size"]}
                if inst:
                    sample["instance"] = inst
                if o:
                    sample["set"] = o
                    for k, v in o.items():
                        self.scan(v, k, f"{comp_name} [{label}]", ctx)
                if desc:
                    sample["overrides"] = self.descendants(desc, ctx, f"{comp_name} [{label}]")
                p = s["parent"]
                if re.search(r"Ring", p.get("name", "")):
                    sample["wrapper"] = {k: v for k, v in p.items() if k != "id"}
                    for k in ("stroke", "strokeWidth", "padding", "cornerRadius"):
                        if k in p:
                            self.scan(p[k], k, f"{comp_name} [{label}] › {p['name']}", ctx)
                entry["samples"].append(sample)
            pids = {s["parent"]["id"] for s in samples}
            comps = []
            for pid in sorted(pids):
                if pid in used_companions or COMPANION_OWNER.get(pid, comp_name) != comp_name:
                    continue
                used_companions.add(pid)
                comps += [self.node(t, ctx, None, f"{comp_name} [{label}]") for t in dump["companions"].get(pid, [])]
            if comps:
                p = samples[0]["parent"]
                entry["arrangement"] = {"in": p.get("name"), "axis": p.get("layout", "horizontal"),
                                        **{k: p[k] for k in ("gap", "padding", "alignItems", "justifyContent") if k in p}}
                entry["companions"] = comps
            if not entry["samples"] and not comps:
                entry["note"] = "yalnız veri farkı olan örnekler; durum çizimi yok"
            out.append(entry)
        return out

    def signature(self, o, ref):
        """What makes an instance look different: overrides minus data (text, icon), sizes and master defaults."""
        base = self.master.get(ref, {})
        root = {k: v for k, v in o.items()
                if k not in ("name", "descendants", "width", "height", "layoutPosition", "strokeAlignment") and base.get(k) != v}
        desc = {}
        for nid, props in o.get("descendants", {}).items():
            if "type" in props:
                desc[nid] = "replaced"
                continue
            m = self.master.get(nid.split("/")[-1], {})
            q = {k: v for k, v in props.items()
                 if k not in ("content", "icon", "width", "height") and m.get(k, True if k == "enabled" else None) != v}
            if q:
                desc[nid] = q
        return json.dumps([root, desc], sort_keys=True, ensure_ascii=False)

    def screens(self, comp_name, dump, ctx):
        """Distinct looks of the component on screen frames, most used first; matched to a drawn state if equal."""
        ref = self.comp_ids[comp_name]
        known = {self.signature({}, ref): "default (ana kopya)"}
        for s in dump["states"]:
            sig = self.signature(s["overrides"], ref)
            if s["component"] == comp_name and '"replaced"' not in sig and not self.data_only(s):
                known.setdefault(sig, self.label(s))
        groups = defaultdict(list)
        for i in dump["inScreens"]:
            if i["component"] == comp_name:
                groups[self.signature(i["overrides"], ref)].append(i)
        out = []
        for sig, items in sorted(groups.items(), key=lambda kv: -len(kv[1])):
            frames = sorted({i["frame"] for i in items})
            first = items[0]
            o = dict(first["overrides"])
            desc = o.pop("descendants", {})
            v = {"count": len(items), "frames": frames[:6] + ([f"… +{len(frames) - 6}"] if len(frames) > 6 else []),
                 "sameAsState": known.get(sig), "sampleInstanceId": first["instanceId"], "sizePx": first["size"]}
            if o:
                v["set"] = o
                for k, val in o.items():
                    self.scan(val, k, f"{comp_name} (ekranda)", ctx)
            if desc:
                v["overrides"] = self.descendants(desc, ctx, f"{comp_name} (ekranda)")
            out.append(v)
        return out

    def extras(self, comp_name, dump, ctx):
        nodes = [self.node(e["tree"], ctx, None, comp_name) for e in dump["extra"] if e["component"] == comp_name]
        for pid, owner in COMPANION_OWNER.items():
            if owner == comp_name:
                nodes += [self.node(t, ctx, None, comp_name) for t in dump["companions"].get(pid, [])]
        return nodes


def main():
    dump, manifest, pen = load()
    b = Builder(dump, manifest, pen)
    OUT.mkdir(exist_ok=True)
    questions, index, all_raw = [], [], []
    used_companions = set()
    for c in dump["components"]:
        meta = b.meta.get(c["name"])
        if not meta:
            questions.append(f"manifest'te yok: `{c['name']}`")
            continue
        ctx = {"tokens": {}, "raw": [], "rawNumbers": [], "questions": []}
        tree = b.node(c["tree"], ctx, c["size"])
        states = b.states(c["name"], dump, ctx, used_companions)
        extra = b.extras(c["name"], dump, ctx)
        on_screens = b.screens(c["name"], dump, ctx)
        spec = {
            "$description": "Generated by build_specs.py from design/viewportix.pen — do not edit. Contract: design/handoff/README.md.",
            "generatedAt": dump["generatedAt"],
            "penName": c["name"], "nodeId": c["id"], "swiftName": meta["swiftName"],
            "size": meta["size"], "statesSummary": meta["states"],
            "notes": [t for t in dump.get("notes", {}).get(c["name"], []) if not t.startswith(c["name"] + " → ")],
            "usedIn": meta["usedIn"], "usedVia": meta["usedVia"],
            "tokens": dict(sorted(ctx["tokens"].items())),
            "tree": tree,
            "states": states,
        }
        if extra:
            spec["extra"] = extra
        spec["onScreens"] = on_screens
        spec["rawValues"] = ctx["raw"]
        spec["rawNumbers"] = ctx["rawNumbers"]
        questions += ctx["questions"]
        (OUT / f"{meta['swiftName']}.json").write_text(json.dumps(spec, ensure_ascii=False, indent=1) + "\n")
        drawn = [s["state"] for s in states if s["samples"] or s.get("companions")]
        unnamed = sum(1 for v in on_screens if not v["sameAsState"])
        index.append((c["name"], meta["swiftName"], meta["size"], len(drawn), len(ctx["raw"]), len(ctx["rawNumbers"]),
                      meta["states"], drawn, unnamed))
        all_raw += [(meta["swiftName"], r) for r in ctx["raw"]]
    for name in b.meta:
        if name not in {c["name"] for c in dump["components"]}:
            questions.append(f"manifest'te var, dökümde yok: `{name}`")
    write_readme(index, all_raw, questions, dump["generatedAt"])
    print(f"wrote {len(index)} specs; raw colour/type values {len(all_raw)}; open questions {len(questions)}")
    for q in questions:
        print("  ?", q)
    sys.exit(1 if questions else 0)


def write_readme(index, all_raw, questions, date):
    L = ["# Bileşen spec'leri (üretilir, elle düzenlenmez)", "",
         f"Kaynak: `design/viewportix.pen`, döküm {date}. Üretim: `dump-specs.js` → `save_dump.py` → `build_specs.py`.", "",
         "Her `<SwiftName>.json`: `tree` ana kopyanın katman ağacı (layout: eksen + `HStack`/`VStack`, gap, padding "
         "[üst, sağ, alt, sol], hizalama; boyut `w`/`h` = sayı (sabit) · `fill` · `fit`, `px` çözülmüş ölçü), "
         "`tokens` pen adı → `DesignTokens` üyesi, `states` durum frame'lerinden okunan override'lar "
         "(`samples[].overrides[].node` ana kopyadaki katman yolu; `companions` o durum için yanına çizilen parçalar), "
         "`extra` bileşene ait ama ayrı çizilmiş parçalar, `onScreens` ekran frame'lerinde görülen farklı görünümler "
         "(veri ve boyut farkı sayılmaz; çizili bir duruma eşitse `sameAsState`), "
         "`rawValues` token dışı renk/yazı değerleri, `rawNumbers` token dışı ölçüler (eşit token varsa `sameAsToken`).", "",
         "Değerler pen.dev'deki gibi: `$surface/card` token, `#2D2926` ya da `6` ham değer. `hidden: true` ana "
         "kopyada gizli, bir durumda görünür olan katman.", "",
         "| pen.dev | SwiftUI | Boyut | Durum | Ham renk/yazı | Ham ölçü |", "|---|---|---|---|---|---|"]
    for pen, swift, size, ns, nr, nn, *_ in index:
        L.append(f"| `{pen}` | [`{swift}`]({swift}.json) | {size[0]}×{size[1]} | {ns} | {nr} | {nn} |")
    L += ["", "## Durum kapsamı", "",
          "§6 tablosundaki durumlar ile durum frame'lerinde çizili olanlar yan yana. \"Ekranda adsız\" = ekran frame'lerinde "
          "görülen ama çizili bir duruma eşlenemeyen görünüm sayısı (`onScreens[].sameAsState: null`).", "",
          "| SwiftUI | §6 durumları | Çizili durumlar | Ekranda adsız |", "|---|---|---|---|"]
    for pen, swift, size, ns, nr, nn, summary, drawn, unnamed in index:
        L.append(f"| `{swift}` | {summary} | {', '.join(drawn) or '—'} | {unnamed} |")
    L += ["", "## Token dışı renk ve yazı değerleri", "",
          "CHK-1 ile aynı kural (aşama 4). `sameAsToken` dolu olanlar token'a bağlanabilir; boş olanlar bilinçli ham değer mi, karar gerekir.", "",
          "| Bileşen | Değer | Özellik | Eşit token | Adet | İlk katman |", "|---|---|---|---|---|---|"]
    groups = {}
    for swift, r in all_raw:
        key = (swift, str(r["value"]), r["prop"], r["sameAsToken"] or "")
        groups.setdefault(key, []).append(r["node"])
    for (swift, value, prop, same), nodes in groups.items():
        L.append(f"| `{swift}` | `{value}` | `{prop}` | {('`' + same + '`') if same else '—'} | {len(nodes)} | {nodes[0]} |")
    L += ["", "## Açık sorular", ""] + ([f"- {q}" for q in questions] or ["- (yok)"])
    (OUT / "README.md").write_text("\n".join(L) + "\n")


if __name__ == "__main__":
    main()
