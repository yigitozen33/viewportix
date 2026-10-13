// pen.dev `execute` snippet — read-only. Prints the design file's variables as JSON.
// Usage: run inside mcp__pencil__execute with design/viewportix.pen active, then save the
// printed JSON as design/tokens/pen-variables.json and run `python3 gen_swift.py --diff`.
// Guard: refuses to print if the active file does not look like Viewportix (no `ink/primary`).
const v = GetVariables();
const vars = v.variables || {};
if (!vars["ink/primary"] || !vars["accent"]) {
  Print("ERROR: active file is not viewportix.pen (missing ink/primary / accent)");
} else {
  const out = { themes: v.themes || {}, variables: {} };
  for (const [name, def] of Object.entries(vars)) {
    const values = Array.isArray(def.value) ? def.value : [{ value: def.value }];
    out.variables[name] = { type: def.type, values };
  }
  Print(JSON.stringify(out));
}
