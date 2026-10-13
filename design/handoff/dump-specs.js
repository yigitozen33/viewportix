// pen.dev `execute` snippet — read-only. Dumps every reusable component's master tree (raw values, variables
// unresolved) with resolved sizes, plus every component instance found in spec frames with its overrides, its
// wrapper frame (e.g. "Selection Ring"), the nearest preceding label text (= state name) and its "companions":
// non-instance siblings drawn next to it for that state (rename field, insertion line, menus), plus EXTRA nodes.
// Texts of Chrome Spec "Spec <pen> → <Swift>" blocks become `notes` (placement, anatomy).
// Instances inside screen frames come from dump-instances.js (split: one snippet would hit the execute time limit).
// Usage: run inside mcp__pencil__execute with design/viewportix.pen active; save the printed JSON line as
// design/handoff/specs-dump.json; then `python3 build_specs.py` (it verifies the printed `hash`).
const skip = n => /^(Archive|Future|Section ·)/.test(n) || /(Label|Options)$/.test(n);
const screen = n => /^(Project Window|Home Window|Dev Panel)/.test(n);
const top = Get(document, (n, c) => { if (c.depth > 0) return undefined; c.skipChildren(); return n.type === "frame" ? { id: n.id, name: n.name || "", r: !!n.reusable } : undefined; });
if (!top.some(t => t.name === "Viewport/Card" && t.r)) {
  Print("ERROR: active file is not viewportix.pen");
} else {
  const byId = Object.fromEntries(top.filter(t => t.r).map(t => [t.id, t.name]));
  const r = v => Math.round(v * 10) / 10;
  const bare = n => { const o = { ...n }; for (const k of ["id", "type", "ref", "x", "y", "children", "descendants"]) delete o[k]; return o; };
  const components = top.filter(t => t.r).map(t => {
    const size = {};
    Get(t.id, (n, c) => { size[n.id] = [r(c.bounds.width), r(c.bounds.height)]; return undefined; });
    return { id: t.id, name: t.name, tree: Get(t.id), size };
  });
  const EXTRA = { "a6LbD": "Window/DeviceStrip", "WJ4O4": "Window/DeviceStrip" };
  const states = [], companions = {}, extra = [];
  for (const [id, comp] of Object.entries(EXTRA)) {
    const t = Get(id);
    if (t) extra.push({ component: comp, nodeId: id, name: t.name || "", tree: t }); else Print("WARN: EXTRA node missing " + id);
  }
  for (const f of top.filter(t => !t.r && !skip(t.name) && !screen(t.name))) {
    const texts = {};
    Get(f.id, (n, c) => {
      if (n.type === "text" && c.parentCtx) (texts[c.parentCtx.node.id] = texts[c.parentCtx.node.id] || []).push([c.index, n.name || "", (n.content || "").split("\n")[0]]);
      return undefined;
    });
    Get(f.id, (n, c) => {
      if (n.type !== "ref" || !byId[n.ref]) return undefined;
      c.skipChildren();
      let label = null;
      for (let k = c; k && k.parentCtx; k = k.parentCtx) {
        const sib = (texts[k.parentCtx.node.id] || []).filter(s => s[0] < k.index || /^(Label|Cap)$/.test(s[1]));
        if (sib.length) { label = sib.sort((a, b) => b[0] - a[0])[0][2]; break; }
      }
      const p = c.parentCtx.node, o = { ...n };
      if (!companions[p.id]) companions[p.id] = (Get(p.id, { depth: 1 }).children || [])
        .filter(k => typeof k === "object" && k.type !== "ref" && k.type !== "text" && !/^(Section|Label|Title)$/.test(k.name || "")).map(k => Get(k.id));
      for (const k of ["id", "type", "ref", "x", "y"]) delete o[k];
      states.push({ frame: f.name, component: byId[n.ref], instanceId: n.id, label, size: [r(c.bounds.width), r(c.bounds.height)], overrides: o, parent: { id: p.id, name: p.name || "", ...bare(p) } });
      return undefined;
    });
  }
  const notes = {};
  Get(document, (n, c) => {
    if (c.depth > 2) { c.skipChildren(); return undefined; }
    const m = /^Spec (.+) → /.exec(n.name || "");
    if (m) { notes[m[1]] = Get(n.id, (k, cc) => k.type === "text" && k.content && cc.parentCtx.node.name === "Anatomy" ? k.content : undefined); c.skipChildren(); }
    return undefined;
  });
  const body = JSON.stringify({ generatedAt: new Date().toISOString().slice(0, 10), components, states, companions, extra, notes });
  let h = 2166136261;
  for (let i = 0; i < body.length; i++) { h ^= body.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0; }
  Print(body.slice(0, -1) + ',"hash":' + h + ',"length":' + body.length + "}");
}
