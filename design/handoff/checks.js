// pen.dev `execute` snippet — read-only consistency checks over design/viewportix.pen (archive excluded).
// Prints `CHK|id|PASS/FAIL|n|detail` for CHK-1, 2, 5, 6 plus a `COMPONENTS` line that checks.py needs for
// CHK-3 (DESIGN.md §6 table). CHK-4 needs checks-hash.js (split: one snippet hits the execute time limit).
// Usage: run both snippets inside mcp__pencil__execute with design/viewportix.pen active; then
// `python3 checks.py <checks-output> <hash-output>` writes CHECKS.md (exit 1 when any check fails).
//   CHK-1 colour / type value outside tokens. Allowed: layers named Page, Thumb, Traffic Lights, Favicon, Alert*
//         (sample web content, system chrome mocks), shadow colours, gradient stops, token colour + alpha
//         (#RRGGBBAA whose RGB is a token), and documentation boards (BOARDS).
//   CHK-2 hand-drawn copy of a component: a non-instance frame named like a component.
//   CHK-5 component with no instance anywhere.  CHK-6 leftovers: temp / tmp / "copy" names, placeholder flags.
const ALLOW = /^(Page|Thumb|Traffic Lights|Favicon|Alert.*|NSAlert.*)$/;
const BOARDS = /^(Design System · Tokens|Shortcut Map|Engine Glyphs|App Icon|Selected Options)/;
const FONT = { 15: 1, 13: 1, 12: 1, 11: 1, 10: 1 };
const top = Get(document, (n, c) => { if (c.depth > 0) return undefined; c.skipChildren(); return n.type === "frame" && !/^(Archive|Future|Section ·)/.test(n.name || "") && !/Label$/.test(n.name || "") ? { id: n.id, name: n.name || "", r: !!n.reusable } : undefined; });
if (!top.some(t => t.name === "Viewport/Card" && t.r)) {
  Print("ERROR: active file is not viewportix.pen");
} else {
  const V = GetVariables().variables, RGB = {};
  for (const [k, d] of Object.entries(V)) if (d.type === "color") for (const x of (Array.isArray(d.value) ? d.value : [{ value: d.value }])) RGB[String(x.value).slice(0, 7).toUpperCase()] = k;
  const comps = top.filter(t => t.r), compNames = comps.map(c => c.name);
  const lastSeg = compNames.map(n => n.split("/").pop());
  const looksLike = name => { const s = (name || "").replace(/\s+/g, ""); return compNames.includes(name) || lastSeg.includes(s) && !["Card", "Row", "Button", "Header", "Picker"].includes(s); };
  const r1 = [], r1info = {}, r2 = [], r6 = [], used = {};
  const markRefs = n => { if (n.type === "ref") used[n.ref] = 1; for (const d of Object.values(n.descendants || {})) if (d && d.type) markRefs(d); for (const k of (n.children || [])) if (typeof k === "object") markRefs(k); };
  const where = (t, c, n) => { const p = []; for (let k = c.parentCtx; k && k.depth > 0; k = k.parentCtx) p.unshift(k.node.name || k.node.type); return t.name + " › " + p.slice(-2).concat(n.name || n.type).join(" › "); };
  for (const t of top) {
    const board = BOARDS.test(t.name);
    Get(t.id, (n, c) => {
      if (/\b(temp|tmp)\b|^copy of|\bcopy( \d+)?$/i.test(n.name || "") || n.placeholder) r6.push(where(t, c, n) + (n.placeholder ? " (placeholder)" : ""));
      if (n.type === "ref") { markRefs(n); c.skipChildren(); return undefined; }
      if (c.depth > 0 && !t.r && n.type === "frame" && looksLike(n.name)) r2.push(where(t, c, n));
      return undefined;
    });
    Get(t.id, (n, c) => {
      if (board || ALLOW.test(n.name || "")) { if (!board) c.skipChildren(); return undefined; }
      if (n.type === "text" && typeof n.fontSize === "number") r1.push(where(t, c, n) + " fontSize " + n.fontSize + (FONT[n.fontSize] ? " (token'a eşit)" : ""));
      if (n.type === "text" && typeof n.fontFamily === "string" && !n.fontFamily.startsWith("$")) r1.push(where(t, c, n) + " fontFamily " + n.fontFamily);
      for (const p of ["fill", "stroke"]) {
        const v = n[p];
        if (typeof v === "string" && v.startsWith("#")) {
          if (v.length === 9 && RGB[v.slice(0, 7).toUpperCase()]) r1info["token + alfa"] = (r1info["token + alfa"] || 0) + 1;
          else r1.push(where(t, c, n) + " " + p + " " + v + (RGB[v.slice(0, 7).toUpperCase()] ? " (token'a eşit)" : ""));
        } else if (v && typeof v === "object" && v.type === "gradient") r1info["gradyan durağı"] = (r1info["gradyan durağı"] || 0) + 1;
      }
      if (n.effect) r1info["gölge rengi"] = (r1info["gölge rengi"] || 0) + 1;
      return undefined;
    }, { resolveInstances: true });
  }
  const unused = comps.filter(c => !used[c.id]).map(c => c.name);
  const line = (id, list, extra) => Print(`CHK|${id}|${list.length ? "FAIL" : "PASS"}|${list.length}|${list.slice(0, 8).join(" ; ")}${list.length > 8 ? " ; …" : ""}${extra || ""}`);
  line(1, r1, " | izinli: " + Object.entries(r1info).map(([k, v]) => k + " " + v).join(", "));
  line(2, r2);
  line(5, unused);
  line(6, r6);
  Print("COMPONENTS " + JSON.stringify(compNames));
}
