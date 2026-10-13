// pen.dev `execute` snippet — read-only. Dumps reusable components and non-archive top-level frames
// with the components each one uses. Usage: run inside mcp__pencil__execute with design/viewportix.pen
// active; save with `python3 save_dump.py <tool-output> canvas-dump.json`; then `python3 build_manifest.py`.
const skip = n => /^(Archive|Future|Section ·)/.test(n) || /Label$/.test(n);
const top = Get(document, (n, c) => {
  if (c.depth > 0) return undefined;
  c.skipChildren();
  return n.type === "frame" ? { id: n.id, name: n.name || "", r: !!n.reusable, x: Math.round(c.bounds.x), y: Math.round(c.bounds.y), w: Math.round(c.bounds.width), h: Math.round(c.bounds.height) } : undefined;
});
if (!top.some(t => t.name === "Viewport/Card" && t.r)) {
  Print("ERROR: active file is not viewportix.pen");
} else {
  const comps = top.filter(t => t.r);
  const byId = Object.fromEntries(comps.map(c => [c.id, c.name]));
  const refsIn = id => [...new Set(Get(id, n => n.type === "ref" && byId[n.ref] ? byId[n.ref] : undefined))].sort();
  const out = {
    generatedAt: new Date().toISOString().slice(0, 10),
    components: comps.map(c => ({ id: c.id, name: c.name, w: c.w, h: c.h, contains: refsIn(c.id) })),
    frames: top.filter(t => !t.r && !skip(t.name)).map(f => ({ id: f.id, name: f.name, x: f.x, y: f.y, w: f.w, h: f.h, uses: refsIn(f.id) })),
  };
  const body = JSON.stringify(out);
  let hh = 2166136261;
  for (let i = 0; i < body.length; i++) { hh ^= body.charCodeAt(i); hh = Math.imul(hh, 16777619) >>> 0; }
  Print(body.slice(0, -1) + ',"hash":' + hh + ',"length":' + body.length + "}");
}
