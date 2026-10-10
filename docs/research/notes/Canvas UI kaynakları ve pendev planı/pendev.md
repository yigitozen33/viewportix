# pen.dev (formerly Pencil.dev) — practical research notes for designing a native macOS app UI

Research date: 2026-10-06. All sources dated where available. Several of the home-screen features the assignment describes ("Design Systems" templates section, "Recreate a screenshot" chip, model picker showing Claude Opus) could NOT be confirmed in any publicly indexed doc page or article; see Gaps under each question. The official X account (x.com/pendev) returned HTTP 402 to the fetch tool, so changelog items from X are only available second-hand via a search snippet.

## Q1. What exactly is pen.dev (company, launch, pricing, platforms, tool type, file format)?

### Takeaway
pen.dev is a desktop/IDE vector design canvas (Figma-like layers, components, variables, flex layout, WebGL) whose documents are open JSON ".pen" files that AI agents edit natively — it is NOT an HTML-generation tool like v0/Lovable. Made by High Agency Inc., launched as "Pencil" in late Jan 2026, rebranded to pen.dev around Aug 2026, free today with Pro ($16) / Ultra ($48) plans announced as "coming soon".

### Cited Findings
- Tagline "An agentic canvas for building bold software"; company High Agency Inc. (© 2026); backed by a16z speedrun; platforms macOS, Windows, web (share links), Chrome extension, VS Code / Cursor / OpenVSX extensions — [pen.dev homepage](https://www.pen.dev/)
- "pencil.dev is now pen.dev" — rebrand notice on the homepage and downloads page — [pen.dev downloads](https://www.pen.dev/downloads)
- It is "a powerful vector design tool that integrates directly into your development environment", usable inside the IDE, as a standalone desktop app, or headless CLI — [docs.pen.dev](https://docs.pen.dev/)
- File format: open ".pen" format, "a JSON file that allows agents to work with it natively", with fully documented schema — [pen.dev homepage](https://www.pen.dev/)
- ".pen files contain a JSON structure, that describes an object tree, not unlike HTML or SVG"; nodes have `id` and `type`; supports flex layout, fills/strokes/effects, components/instances, variables/themes, object types incl. rectangles, frames, text, icons, scripts, browsers; the TypeScript schema at the end of the page is "the authoritative, exhaustive reference" — [The .pen Format](https://docs.pen.dev/for-developers/the-pen-format)
- .pen files are stored in the project repository and tracked with Git; runs as desktop app, VS Code/Cursor/OpenVSX extensions and CLI; works with Claude, OpenAI, Gemini, Grok and other models — [The Rundown AI tool page, 2026-08-29](https://www.therundown.ai/tools/pencil)
- Rendering: "WebGL pipeline supporting thousands of layers at 60fps"; tools include shaders, pen tool for paths/SVG, gradients, flex layout, measurements; supported model providers listed: Claude, OpenAI, Grok, Qwen, Gemini, Kimi, Deepseek, Minimax — [pen.dev homepage](https://www.pen.dev/)
- Pencil "was officially launched in late January 2026 and hit a big milestone of 100,000 users shortly after its launch"; creator Tom Krcha (previously built Around, acquired by Miro) — WebSearch summary attributed to [uxmagic.ai review, 2026-09-25](https://uxmagic.ai/blog/pencil-dev-review) and [The Rundown](https://www.therundown.ai/tools/pencil); 100,000 users within 8 weeks of launch, figure attributed to Krcha — [wakib.ai, 2026-08-14](https://www.wakib.ai/en/articles/pencil-rebrands-to-pendev-lets-6-ai-agents-design-together-20260814)
- Rebrand to pen.dev reported 2026-08-14 along with "swarm mode" (up to 6 agents on one canvas) — [wakib.ai, 2026-08-14](https://www.wakib.ai/en/articles/pencil-rebrands-to-pendev-lets-6-ai-agents-design-together-20260814)
- Pricing page: Free $0 (5 "agent days"/month, 25 image/SVG generations/month, 1 parallel agent, full editor, components, variables, themes, scripts, shaders, imports/exports, CLI, MCP, sharing, snapshots, versions, comments, personal developer keys); Pro $16/user/month (unlimited agent days, 350 generations, up to 3 parallel agents, org developer keys, roles, billing); Ultra $48/user/month (750 generations, up to 6 parallel agents, shared usage pool, team workspaces); Enterprise custom. Note on page: "pen.dev stays free until plans launch" (plans "coming soon"); annual billing saves 20% — [pen.dev pricing](https://www.pen.dev/pricing)
- Hidden cost: using Claude via Claude Code / API means paying Anthropic separately ("Claude Code subscription: from $20/month", "Claude API usage (variable)"); "Free is not a business model, so build your workflows with that in mind" — [flowstep.ai, 2026-04-17](https://flowstep.ai/blog/pencil-dev-pricing/)
- Downloads: macOS builds for Apple Silicon and Intel; Windows x64 (ARM64 "coming soon"); Linux AppImage/tarball (x64/ARM); IDE extensions for VS Code, Cursor, Antigravity, Windsurf, Open VSX; Chrome extension "pen.dev web import"; CLI `npm install -g @pen.dev/cli` with an "Agent skill" for Cursor/Claude Code — [pen.dev downloads](https://www.pen.dev/downloads)
- Conflict on platforms: an older review states "Pencil runs only on Mac and Linux with no Windows or browser version" — [flowstep.ai search snippet, 2026-04-17](https://flowstep.ai/blog/pencil-dev-pricing/); contradicted by the current downloads page listing Windows x64 — [pen.dev downloads](https://www.pen.dev/downloads). Windows support appears to have been added after spring 2026.
- No browser (web) editor: "No browser version exists—fully local installation required" — [flowstep.ai, 2026-04-17](https://flowstep.ai/blog/pencil-dev-pricing/)
- The .pen format is called "proprietary JSON, not native HTML/CSS, requiring code generation" by one reviewer — [uxmagic.ai, 2026-09-25](https://uxmagic.ai/blog/pencil-dev-review); the official docs describe it as a documented, schema-published format but do not state an open-source license — [The .pen Format](https://docs.pen.dev/for-developers/the-pen-format)

### Inferences
- Because output is a vector object tree (frames, text, flex layout) rather than HTML, pen.dev's output is structurally closer to a Figma file than to a v0/Lovable web prototype; this matters for a macOS app designer, since nothing forces web idioms into the artboard.
- The free plan's "5 agent days/month" will throttle serious iteration once plans launch; a designer planning sustained work should budget for Pro, or bring their own Claude Code / API key (the "personal developer keys" line suggests BYO keys stay on Free).

### Gaps
- No public changelog page was found; the X account is the de-facto changelog but was not fetchable (HTTP 402).
- No official statement on whether the .pen format is open-source licensed vs. merely documented.
- No Product Hunt launch page or Hacker News thread about pen.dev/pencil.dev was found in search (HN results were for unrelated older "Pencil" projects).

## Q2. What are "Design Systems" in pen.dev? Custom design systems; built-in macOS/Apple HIG?

### Takeaway
pen.dev's design-system mechanism is Variables (color/number/string with Light/Dark themes) + Components + Slots, packaged as a `.lib.pen` library that other documents import and that the agent uses as context. No official doc lists built-in design-system libraries, and no source confirms a macOS/Apple HIG library; third-party guides mention "Shadcn/UI, Lunarus" style guides being selectable.

### Cited Findings
- Build-a-design-system guide: define variables (`surface`, `ink`, `accent`, `space` 16px, `font-body`, `font-size`) with Light/Dark themes overriding per variable; build Button (144×48) and Card (360 wide, flex layout) components bound to tokens; add Slots ("Add an empty frame named Actions ... Select Actions, click Make slot") to constrain what can be composed inside; export via Libraries panel as a reusable `.lib.pen`; import into consumer docs; "Changes to source variables and components automatically cascade to all instances in linked documents" — [Build a design system](https://docs.pen.dev/core-concepts/build-a-design-system)
- Design libraries: "Saved changes to a library's components and variables load in documents that import it when you reopen them"; create via Libraries tab → "Turn this file into a library" (`.lib.pen` suffix, irreversible); the docs reference "default libraries" as an import option but do not name them — [Design Libraries](https://docs.pen.dev/core-concepts/design-libraries)
- Homepage lists "Design Systems: Components, UI libraries, variables, slots" as a feature group — [pen.dev homepage](https://www.pen.dev/)
- Built-in icon libraries: Material Symbols (Outlined/Rounded/Sharp), Lucide, Feather, Phosphor; custom SVG icons supported — [Import and Export](https://docs.pen.dev/core-concepts/import-and-export)
- Variables sync with CSS both ways via prompts: "Create pen.dev variables from my globals.css" / "Update globals.css with these pen.dev variables" — [Design ↔ Code](https://docs.pen.dev/design-and-code/design-to-code)
- "Selecting a design system in Pencil (Shadcn/UI, Lunarus, etc.) fundamentally improves output consistency ... reduces token consumption and prevents generic AI-generated aesthetics"; prompts should "Specify design system constraints upfront ('Use the Shadcn/UI style guide')" — [atalupadhyay.wordpress.com, 2026-02-25](https://atalupadhyay.wordpress.com/2026/02/25/pencil-dev-claude-code-workflow-from-design-to-production-code-in-minutes/)
- "Pencil includes 'UI Kits' in two types with different functions" (article cut off before detailing) — [designwithai.substack.com, 2026-04-03](https://designwithai.substack.com/p/exploring-pencildev-walkthrough-and-impressions)
- "Limited custom UI kit support" listed as a limitation in March 2026 — [Geeky Gadgets, 2026-03-02](https://www.geeky-gadgets.com/pencil-dev-claude-code/)
- Code-side component libraries the agent can target: shadcn/ui, Radix UI, Chakra UI, Material UI, custom — [Design ↔ Code](https://docs.pen.dev/design-and-code/design-to-code)
- MCP tools exposed to external agents historically included `get_style_guide`, `get_canvas_context`, `get_selected_frames` — [atalupadhyay.wordpress.com, 2026-02-25](https://atalupadhyay.wordpress.com/2026/02/25/pencil-dev-claude-code-workflow-from-design-to-production-code-in-minutes/); current docs list six MCP tools incl. `get_app_state` and `execute` (plus conditional `browser`, `spawn_agents`) — [AI Integration](https://docs.pen.dev/getting-started/ai-integration)

### Inferences
- A custom "macOS HIG" library is feasible with the documented primitives: define SF Pro-like font variables, system-gray/accent colors with Light/Dark themes, 28/38/52 px toolbar/sidebar metrics as number variables, and components for toolbar button, sidebar row, inspector section, window chrome; turn it into `.lib.pen`, import into every screen file, and tell the agent to use only library components.
- Because the agent reads the document's variables/components (style guide) as context, consistency across screens depends mostly on (a) keeping screens in files that import the same library and (b) explicitly instructing the agent to reuse library components rather than draw new ones.

### Gaps
- No source documents the home-screen "Design Systems" templates section the user observed, nor which pre-made design systems it contains; cannot confirm whether a macOS/Apple HIG-style preset exists. Verify in the app.
- "Lunarus" (mentioned as a selectable design system in Feb 2026) has no other corroboration found.
- No doc explains precisely how the built-in agent consumes a library (e.g., whether it is auto-injected into the prompt or must be referenced).

## Q3. Does pen.dev have macOS/desktop-app templates or a "desktop app" mode? How does it handle desktop chrome?

### Takeaway
No public source documents a desktop-app/macOS template or mode; the official prompt gallery is oriented to web apps, websites and mobile apps. The canvas itself is artboard-agnostic (arbitrary frames, flex layout), so desktop chrome is possible but will rely on prompting and a custom library rather than built-in templates.

### Cited Findings
- Official Prompt Gallery examples are all web/mobile: "Design a web app for managing rocket launches. Use a technical style."; "Design a website for a specialty cafe in Haight Ashbury, San Francisco."; "Design a mobile app for tracking music royalties. Use a Scandinavian minimalistic style." — [pen.dev/prompts](https://www.pen.dev/prompts)
- Reviewers describe it as "Versatile for websites, dashboards, and terminal UIs" — [Geeky Gadgets, 2026-03-02](https://www.geeky-gadgets.com/pencil-dev-claude-code/)
- Canvas supports frames, flex layout, components, variables, shaders, pen tool paths, measurements (i.e., generic vector authoring, not web-only) — [pen.dev homepage](https://www.pen.dev/)
- Code export targets are web only (React, Next.js, Vue, Svelte, HTML/CSS; Tailwind/CSS Modules/Styled Components); "The documentation does not mention SwiftUI support" — [Design ↔ Code](https://docs.pen.dev/design-and-code/design-to-code)
- Web page import uses a built-in browser in the desktop app with "Customizable zoom and device settings" (device presets implied) — [Import and Export](https://docs.pen.dev/core-concepts/import-and-export)

### Inferences
- Home-screen chips the user saw ("Landing page / Mobile app / Web app / Slides / Dashboard") match the web/mobile orientation of the prompt gallery; "Dashboard" is the closest starting point for a sidebar + canvas + inspector layout.
- For a macOS app, the realistic workflow is: build (or import from Figma) a macOS HIG component library, then prompt with explicit window/toolbar/sidebar/inspector specifications; expect the agent's default to be web-flavored (Tailwind-like spacing, web buttons) unless constrained.

### Gaps
- No evidence of any "desktop app" template, macOS window-chrome component, or Apple HIG kit shipped with pen.dev. Not confirmed either way; check the in-app Design Systems section.
- No user reports found specifically about designing native desktop apps in pen.dev.

## Q4. Documented prompting best practices (structure, references, iterating on selection, Recreate a screenshot, import from Figma/browser)?

### Takeaway
The official guidance is: select the layers you want changed, then describe the change; attach images/files as references; use `/` skills (SKILL.md) for reusable instructions; use "Let it cook" and parallel agents for variants; and chain short continuation prompts ("Look at the selected design ... Create a new design for it"). Figma files and webpages import as editable layers; screenshots import as raster image layers (no official "screenshot → vector" doc was found).

### Cited Findings
- Core strategy: "Select the layers you want the agent to change, then describe the change." Canvas selections automatically appear as context in the composer; add context with "Add image or file" (PNG, JPEG, Markdown, source files) or drop files into the composer — [AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents)
- Skills: "Type `/` in the desktop composer, or select Add to context (+) → Pick a skill"; add custom skills via "Add SKILL.md file…"; "The folder name becomes the skill's name in the menu." — [AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents)
- Parallel agents (⚡): 1–6 agents; "Split Work" (different parts of a task) vs "Side by Side" (alternatives of the same task); "Let it cook" generates successive variants exploring "Layout" (keeps visual style) or "Style" (varies visual treatment), 2–6 variants or "Don't iterate" — [AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents)
- Built-in agent: "open or create a .pen document in the desktop app. Choose a model, then enter a request in the agent composer"; model picker supports "Claude models" with reasoning-effort options; provider set in Settings → Agents; external MCP clients connect to the running desktop/IDE host after enabling MCP in Settings — [AI Integration](https://docs.pen.dev/getting-started/ai-integration); [AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents)
- Official continuation-prompt patterns: "Use the selected design as the base design, that's my current app. Design a new page, the Missions page now."; "Look at the selected design. Explore a different layout, but keep the current design direction."; "Look at the selected design. Change it to the light mode. Create a new design for it."; "Great! Now use a sidenav. Create a new design for it."; "Look at the selected design. Change this to a simpler and cleaner design direction." — [pen.dev/prompts](https://www.pen.dev/prompts)
- Chat opens with Cmd/Ctrl+K; stack-specific prompts like "Generate Next.js 14 code with Tailwind CSS" — [Design ↔ Code](https://docs.pen.dev/design-and-code/design-to-code)
- Changelog items via X (search snippet, undated): "Queue and Steering were added to the chat agent, allowing users to queue multiple messages in an editable queue or immediately inject messages into the agent's context"; Present mode 100% zoom; Image Crop (Stretch/Fill/Fit); Scale (K) command — [x.com/pendev via search snippet](https://x.com/pendev)
- "Prompt blocks": sticky-note prompts placed on the canvas that execute in the agent, "making iterations trackable and shareable design artifacts" — [designwithai.substack.com, 2026-04-03](https://designwithai.substack.com/p/exploring-pencildev-walkthrough-and-impressions)
- Third-party tips: "The quality of AI-generated code is directly proportional to the quality of the context you give it"; specify design system upfront; include semantic details ("A circular avatar image placeholder (64px diameter)"); add behavioral annotations; "Reference selected design elements rather than requesting full canvas reads"; launch order: open Pencil before Claude Code — [atalupadhyay.wordpress.com, 2026-02-25](https://atalupadhyay.wordpress.com/2026/02/25/pencil-dev-claude-code-workflow-from-design-to-production-code-in-minutes/)
- Manual-edit advice: "Changing a label or nudging spacing by hand costs nothing, while the same change by prompt burns tokens and time." — [uxmagic.ai, 2026-09-25](https://uxmagic.ai/blog/pencil-dev-review)
- Claude 4.6 "noted as producing strongest design results" — [wakib.ai, 2026-08-14](https://www.wakib.ai/en/articles/pencil-rebrands-to-pendev-lets-6-ai-agents-design-together-20260814)
- Import from Figma: toolbar chevron under Rectangle → "Import Figma" (or File menu on desktop); individual Figma layers can be copy-pasted (images excluded) — [Import and Export](https://docs.pen.dev/core-concepts/import-and-export)
- Import from browser: desktop app has a built-in browser with URL entry; select individual elements or import entire pages; "Imported layers do not retain the page's JavaScript interactions"; a Chrome extension "pen.dev web import" also exists — [Import and Export](https://docs.pen.dev/core-concepts/import-and-export); [pen.dev downloads](https://www.pen.dev/downloads)
- "Browser agent": import HTML/React components into a fully editable canvas and export back to code — [fenado.ai](https://fenado.ai/articles/pendev-introduces-browser-agent-for-10x-faster-design-to-code-workflow)
- Images: drag/drop or paste PNG/JPEG/SVG; "SVGs become editable layers; raster formats become image layers" — [Import and Export](https://docs.pen.dev/core-concepts/import-and-export)
- Community skill "pen-screen-map" maps a running web app into .pen files by screenshotting routes and feeding each capture to the pen CLI — [GitHub issue, pooriaarab/skills #484](https://github.com/pooriaarab/skills/issues/484)

### Inferences
- "Recreate a screenshot" on the home screen most likely attaches the image as composer context and asks the agent to redraw it as vector layers (consistent with the documented "Add image or file" context and raster import behavior); exact fidelity undocumented.
- For a macOS app: paste real macOS screenshots (Finder, Xcode, Sketch) as references plus a written spec of the window regions; iterate region by region by selecting the toolbar frame, the sidebar frame, etc., which also keeps token costs down.
- A SKILL.md encoding "macOS HIG rules" (window metrics, SF typography scale, sidebar/inspector widths, vibrancy, traffic lights) is the mechanism pen.dev provides for making every prompt follow the same rules.

### Gaps
- No official document describes the "Recreate a screenshot" entry point; behavior inferred.
- No YouTube reviews/tutorials with substantive prompting guidance surfaced in search (results were generic prompt-engineering videos); no Discord content indexed.
- Official docs do not publish a list of selectable models (e.g., "Claude Opus"); only "Claude models" with reasoning effort is stated.

## Q5. Export options (Figma, PNG/SVG, HTML/CSS/React, tokens) — can a developer use output directly?

### Takeaway
Native exports are PNG/JPEG/WEBP/PDF (1x/2x/3x), HTML with Tailwind or CSS, and agent-generated React/Vue/Svelte code; Figma export is via third-party community plugins that import the `.pen` JSON; design tokens flow out as CSS variables through the agent. There is no SwiftUI target, so for a SwiftUI developer the useful deliverables are the images, the HTML/CSS spec, the `.pen` JSON (readable by an agent), and a Figma import.

### Cited Findings
- Element export formats: PNG, JPEG, WEBP, PDF; raster scale 1x/2x/3x; multi-selection → ZIP; PDF puts each layer on a separate page; right-click "Copy as PNG" — [Import and Export](https://docs.pen.dev/core-concepts/import-and-export)
- HTML export "with Tailwind or CSS", with configurable asset inclusion and HTML scaffold options; code via AI chat — [Import and Export](https://docs.pen.dev/core-concepts/import-and-export)
- Homepage export list: "HTML/CSS/Tailwind, PDF, PNG, JPEG, WEBP at multiple resolutions"; sharing by link — [pen.dev homepage](https://www.pen.dev/)
- Code generation targets: React, Next.js, Vue, Svelte, HTML/CSS; no SwiftUI mention — [Design ↔ Code](https://docs.pen.dev/design-and-code/design-to-code)
- Docs page "does not document SVG, React, Figma, .pen, or design token exports" as menu items — [Import and Export](https://docs.pen.dev/core-concepts/import-and-export)
- Figma export: multiple community Figma plugins import `.pen` files, e.g. "pen.dev to Figma" (frames, text, vector paths, rectangles, ellipses; Auto Layout; fills/strokes/radius/opacity; variables; Light/Dark themes; component references with overrides) — [Figma plugin](https://www.figma.com/community/plugin/1598907730561478304/pen-dev-to-figma); "Pen.dev to Figma · FREE" (editable SVG icons incl. Lucide/Feather/Phosphor/Material) — [Figma plugin](https://www.figma.com/community/plugin/1601664618009066049/pen-dev-to-figma-free); "PenFig" (native editable layers, "no conversion server") — [Figma plugin](https://www.figma.com/community/plugin/1643726402305223297/penfig-pencil-dev-pen-to-figma-importer); workflow: export `.pen` (or `.zip` with images) and drop into plugin — [penciltofigma.com](https://penciltofigma.com/)
- Token export via agent: "Update globals.css with these pen.dev variables" — [Design ↔ Code](https://docs.pen.dev/design-and-code/design-to-code)
- Generated code "requires responsive, accessibility, and interaction testing" — [The Rundown AI, 2026-08-29](https://www.therundown.ai/tools/pencil)
- CLI `@pen.dev/cli` plus MCP give agents headless read/write access to `.pen` files — [pen.dev downloads](https://www.pen.dev/downloads); [docs.pen.dev](https://docs.pen.dev/)

### Inferences
- For SwiftUI handoff: (1) export 2x PNGs per screen/state for visual reference, (2) export HTML/CSS to extract exact spacing, radii, colors, font sizes, (3) hand the `.pen` JSON to Claude Code with the pen.dev CLI/MCP and ask it to translate the object tree into SwiftUI views (not an official feature; relies on the agent), (4) optionally import into Figma via a plugin for Dev Mode measurements.
- Since Figma export is third-party, test a plugin early on a representative file (nested components, themes) before committing to a Figma-based handoff.

### Gaps
- No official pen.dev→Figma export and no official statement on plugin fidelity; the plugins are third-party with no reviews captured here.
- No source on SVG export of vector layers (homepage mentions pen tool/SVG paths but the export doc lists only raster/PDF/HTML).

## Q6. Reported limitations (consistency, editing precision, desktop designs)?

### Takeaway
Reviewers consistently flag: no automatic design↔code sync (you must re-prompt), single-screen focus with no multi-screen flow consistency, no real-time multiplayer, limited undo/redo, performance hiccups/bugs, fast token burn with Claude, and layout alignment inconsistencies on complex components. No reports specific to desktop-app design were found.

### Cited Findings
- "Single-Screen Focus: No multi-screen journey planning or flow consistency across frames"; "Manual Sync: Design and code update when you ask the agent to make a change. Review both files after each request."; "No Multiplayer: Limited to snapshot sharing"; "Intelligence Dependency: Output quality and costs tied entirely to user-selected model and prompts" — [uxmagic.ai, 2026-09-25](https://uxmagic.ai/blog/pencil-dev-review)
- "Undo and redo can be more limited than in established design editors"; rebrand confusion with older tutorials; "Not a full Figma replacement for mature teams" — [The Rundown AI, 2026-08-29](https://www.therundown.ai/tools/pencil)
- "Layout alignment inconsistencies have been reported in testing, particularly on complex components"; "slow response times and occasional unresponsiveness"; "no auto-save yet, so you need to save .pen files manually" (as of spring 2026); product documentation "sparse" — [flowstep.ai, 2026-04-17 (search snippet)](https://flowstep.ai/blog/pencil-dev-pricing/)
- Users report the tool "is not particularly intuitive", "Lacks versatility compared to Figma", "Fast token consumption with Claude" — [flowstep.ai, 2026-04-17](https://flowstep.ai/blog/pencil-dev-pricing/)
- "Persistent bugs affecting chat responsiveness and overlays"; "Limited custom UI kit support" — [Geeky Gadgets, 2026-03-02](https://www.geeky-gadgets.com/pencil-dev-claude-code/)
- "unlike Lovable or V0, 'you still need to prompt the AI agent to update the code after making changes'" — [designwithai.substack.com, 2026-04-03](https://designwithai.substack.com/p/exploring-pencildev-walkthrough-and-impressions)
- Workflow "primarily one-directional: design to code" with no automatic bidirectional sync — [atalupadhyay.wordpress.com, 2026-02-25](https://atalupadhyay.wordpress.com/2026/02/25/pencil-dev-claude-code-workflow-from-design-to-production-code-in-minutes/)
- "Clickable prototypes are not verified as available"; proprietary, not open source; "No user reviews or documented complaints are currently available on this page" — [itechguides.com, facts checked 2026-09-20](https://www.itechguides.com/products/pen-dev/)
- Positive: "Manual canvas adjustments are supported without triggering full regeneration" — [flowstep.ai, 2026-04-17](https://flowstep.ai/blog/pencil-dev-pricing/)
- Positive: WebGL rendering, Figma-like layers/components/variables/flex layout; parallel agents up to six — [uxmagic.ai, 2026-09-25](https://uxmagic.ai/blog/pencil-dev-review)

### Inferences
- Multi-screen consistency is the main risk for a 5-window macOS app (welcome, main window with toolbar/sidebar/canvas/inspector, settings...). Mitigation: a shared `.lib.pen`, one file per flow with all screens as frames, and continuation prompts anchored on "Use the selected design as the base design".
- Many complaints date from Feb–Apr 2026 (early release); some (Windows support, auto-save, undo) may be outdated by Oct 2026, but no source confirms fixes.

### Gaps
- No Product Hunt page, HN thread, G2 reviews (the G2 "Pencil" page in results is likely a different product), or Reddit threads with first-hand user quotes were retrieved.
- No reports found about designing native desktop/macOS apps specifically.

## Q7. Brief comparison with alternatives (Figma Make, Google Stitch, Lovable/v0, Paper, Subframe) for a desktop app

### Takeaway
pen.dev's differentiators are: local vector `.pen` files in the repo, BYO model, parallel agents, Figma/web import, and MCP/CLI access for coding agents. Paper is the closest analog (agentic canvas, but HTML/CSS-native with multiplayer); Stitch is faster for a first draft but weaker for editing/handoff; Figma Make is best if the team already lives in Figma; v0/Lovable produce web code, not editable vector designs. No source compares these tools specifically for desktop-app design.

### Cited Findings
- vs Paper.design: "Paper uses real HTML/CSS with multiplayer; pen.dev uses proprietary JSON with parallel agents"; vs Figma Make: Figma ecosystem more mature, pen.dev stores designs in repo; vs Stitch: "Stitch lighter on editing and code handoff"; vs UXMagic: multi-screen flows with unified themes — [uxmagic.ai, 2026-09-25](https://uxmagic.ai/blog/pencil-dev-review)
- Paper "ships 24 MCP tools: 11 reads, 8 writes, and 5 utilities. Agents can create artboards, write HTML, update styles" — [uithings.com Figma vs Paper](https://uithings.com/figma-vs-paper)
- Google Stitch: free beta; "produces a first draft in 20 minutes"; "Use Stitch to start. Use Figma to finish." — [sfailabs.com](https://sfailabs.com/guides/google-stitch-vs-figma); [justinmckelvey.com](https://justinmckelvey.com/blog/google-stitch-vs-figma)
- Figma Make: "interactive prototypes, existing design-system reuse, live data, and handoff. Best only if your workflow already lives in Figma." — [pinggy.io, 2026](https://pinggy.io/blog/best_ai_design_tools/)
- The Rundown lists Figma AI, Vercel v0 and Lovable as the comparison set; pen.dev's edge is "Keeps structured design files in the same repository as code" and "Two-way design and code workflow reduces static handoffs" — [The Rundown AI, 2026-08-29](https://www.therundown.ai/tools/pencil)
- Flowstep positions itself vs pen.dev on browser access, real-time collaboration, zero setup, React/TS/Tailwind export — [flowstep.ai, 2026-04-17](https://flowstep.ai/blog/pencil-dev-pricing/)
- itechguides' alternatives list: UX Pilot, Uizard, Prototyper (not the ones the assignment named) — [itechguides.com alternatives](https://www.itechguides.com/products/pen-dev/alternatives/)

### Inferences
- For a SwiftUI target, none of these tools produce native code; the choice hinges on editable vector fidelity + handoff. pen.dev (vector, variables, Figma import) and Figma Make (inside Figma) fit better than HTML-first tools (Paper, v0, Lovable, Stitch) for producing measurable specs of toolbar/sidebar/inspector layouts.

### Gaps
- No source found comparing Subframe with pen.dev; Subframe not covered.
- No benchmark or review that evaluates any of these tools on native desktop-app chrome.

## Practical guide synthesized from the above (for the report writer)

1. Setup: install the macOS desktop app (Apple Silicon build) — [downloads](https://www.pen.dev/downloads); in Settings → Agents pick a Claude model (reasoning effort configurable) — [AI Integration](https://docs.pen.dev/getting-started/ai-integration); optionally enable MCP so Claude Code can read/write the same `.pen` file — [AI Integration](https://docs.pen.dev/getting-started/ai-integration).
2. Build a macOS library first: create `macos-hig.lib.pen` with variables (system colors with Light/Dark themes, SF type scale, spacing, toolbar/sidebar/inspector widths) and components (window chrome with traffic lights, toolbar button, sidebar row/group, inspector section with disclosure, canvas placeholder); use Slots for toolbar item and inspector content areas — [Build a design system](https://docs.pen.dev/core-concepts/build-a-design-system). If a macOS kit exists in Figma, import it with "Import Figma" — [Import and Export](https://docs.pen.dev/core-concepts/import-and-export). Verify whether the in-app "Design Systems" section already offers something Apple-like (undocumented).
3. Write a SKILL.md ("macos-app-ui") capturing HIG rules and the library names, add it via `/` → "Add SKILL.md file…" so every prompt follows it — [AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents).
4. Prompt pattern: attach reference screenshots (Finder/Xcode/your current app) + one spec paragraph per window region; start from the "Dashboard" chip or a blank frame sized e.g. 1280×800; then iterate with selection context: select the toolbar frame → "Make this a unified macOS toolbar: 52pt tall, SF Symbols icons from Lucide equivalents, segmented control for view modes" — [AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents); use the gallery's continuation phrasing "Use the selected design as the base design ... Design the Welcome window now" — [prompts](https://www.pen.dev/prompts).
5. Explore: "Let it cook" with Layout (keep style) for sidebar/inspector arrangements; Side-by-Side parallel agents for 2–3 visual directions — [AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents). Make small changes by hand to save tokens — [uxmagic.ai](https://uxmagic.ai/blog/pencil-dev-review).
6. Export for SwiftUI dev: 2x PNG per state, HTML/CSS export for exact values, push variables to a CSS/tokens file via prompt, share link for review, `.pen` + CLI/MCP for Claude Code to translate into SwiftUI (unofficial), and a Figma import plugin if the dev wants Dev Mode — [Import and Export](https://docs.pen.dev/core-concepts/import-and-export); [Design ↔ Code](https://docs.pen.dev/design-and-code/design-to-code); [Figma plugin](https://www.figma.com/community/plugin/1598907730561478304/pen-dev-to-figma).
7. Known risks: multi-screen consistency, no auto code sync, limited undo, token burn — [uxmagic.ai](https://uxmagic.ai/blog/pencil-dev-review); [flowstep.ai](https://flowstep.ai/blog/pencil-dev-pricing/); [The Rundown](https://www.therundown.ai/tools/pencil).
