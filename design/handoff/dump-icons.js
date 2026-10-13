// pen.dev `execute` snippet — read-only. Lists every visible icon node outside archive frames (instances resolved):
// icon -> count, layer names, components whose master contains it, spec frames that show it and screen counts per window type.
// Usage: run inside mcp__pencil__execute with design/viewportix.pen active; save with
// `python3 save_dump.py <tool-output|-> icons-dump.json`; then `python3 build_icons.py`.
const top = Get(document, (n, c) => { if (c.depth > 0) return undefined; c.skipChildren(); return n.type === "frame" && !/^(Archive|Future|Section ·)/.test(n.name || "") && !/Label$/.test(n.name || "") ? { id: n.id, name: n.name || "", r: !!n.reusable } : undefined; });
if (!top.some(t => t.name === "Viewport/Card" && t.r)) {
  Print("ERROR: active file is not viewportix.pen");
} else {
  const icons = {};
  for (const t of top) Get(t.id, (n, c) => {
    if (n.type !== "icon" || n.enabled === false) return undefined;
    const e = icons[n.icon] = icons[n.icon] || { library: n.library, count: 0, layers: {}, components: {}, frames: {} };
    e.count++;
    e.layers[n.name || "?"] = 1;
    (t.r ? e.components : e.frames)[t.name] = 1;
    return undefined;
  }, { resolveInstances: true });
  const out = {};
  for (const k of Object.keys(icons).sort()) {
    const e = icons[k];
    const fr = Object.keys(e.frames).sort(), scr = fr.filter(f => /^(Project Window|Home Window|Dev Panel)/.test(f));
    out[k] = { library: e.library, count: e.count, layers: Object.keys(e.layers).sort(), components: Object.keys(e.components).sort(), specFrames: fr.filter(f => !scr.includes(f)), screens: scr.reduce((a, f) => { const g = f.split(" · ")[0]; a[g] = (a[g] || 0) + 1; return a; }, {}) };
  }
  const body = JSON.stringify({ generatedAt: new Date().toISOString().slice(0, 10), icons: out });
  let h = 2166136261;
  for (let i = 0; i < body.length; i++) { h ^= body.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0; }
  Print(body.slice(0, -1) + ',"hash":' + h + ',"length":' + body.length + "}");
}
