// pen.dev `execute` snippet — read-only. Lists every component instance inside screen frames (Project Window,
// Home Window, Dev Panel) with its overrides, for states that are drawn only on screens (TemplateChip selected,
// URLBox invalid, …). Usage: run inside mcp__pencil__execute with design/viewportix.pen active; save with
// `python3 save_dump.py <tool-output> instances-dump.json`; then `python3 build_specs.py`.
const skip = n => /^(Archive|Future|Section ·)/.test(n);
const screen = n => /^(Project Window|Home Window|Dev Panel)/.test(n);
const top = Get(document, (n, c) => { if (c.depth > 0) return undefined; c.skipChildren(); return n.type === "frame" ? { id: n.id, name: n.name || "", r: !!n.reusable } : undefined; });
if (!top.some(t => t.name === "Viewport/Card" && t.r)) {
  Print("ERROR: active file is not viewportix.pen");
} else {
  const byId = Object.fromEntries(top.filter(t => t.r).map(t => [t.id, t.name]));
  const r = v => Math.round(v * 10) / 10;
  const inScreens = [];
  for (const f of top.filter(t => !t.r && !skip(t.name) && screen(t.name))) {
    Get(f.id, (n, c) => {
      if (n.type !== "ref") return undefined;
      c.skipChildren();
      if (!byId[n.ref]) return undefined;
      const o = { ...n };
      for (const k of ["id", "type", "ref", "x", "y", "name"]) delete o[k];
      inScreens.push({ frame: f.name, component: byId[n.ref], instanceId: n.id, size: [r(c.bounds.width), r(c.bounds.height)], overrides: o });
      return undefined;
    });
  }
  const body = JSON.stringify({ generatedAt: new Date().toISOString().slice(0, 10), inScreens });
  let h = 2166136261;
  for (let i = 0; i < body.length; i++) { h ^= body.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0; }
  Print(body.slice(0, -1) + ',"hash":' + h + ',"length":' + body.length + "}");
}
