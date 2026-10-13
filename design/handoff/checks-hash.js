// pen.dev `execute` snippet — read-only. Prints `HASHES {frame name: FNV-1a}` of every exported frame's resolved
// tree (instances and variables resolved, canvas position zeroed) for CHK-4: a frame whose hash differs from the
// one recorded at export time (export-hashes.json) has a stale PNG. See checks.js / checks.py.
const top = Get(document, (n, c) => { if (c.depth > 0) return undefined; c.skipChildren(); return n.type === "frame" && !n.reusable && !/^(Archive|Future|Section ·)/.test(n.name || "") && !/Label$/.test(n.name || "") ? { id: n.id, name: n.name || "" } : undefined; });
if (!top.some(t => t.name === "Project Window")) {
  Print("ERROR: active file is not viewportix.pen");
} else {
  const fnv = s => { let h = 2166136261; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0; } return h; };
  const hashes = {};
  for (const t of top) { const tree = Get(t.id, { resolveInstances: true, resolveVariables: true }); tree.x = 0; tree.y = 0; hashes[t.name] = fnv(JSON.stringify(tree)); }
  Print("HASHES " + JSON.stringify(hashes));
}
