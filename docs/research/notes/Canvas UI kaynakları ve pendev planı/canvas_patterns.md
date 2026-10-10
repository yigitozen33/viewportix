# Canvas UI/UX Pattern Catalog: Infinite-Canvas Desktop Apps and Welcome/Home Screens (as of October 2026)

Scope: zoom/pan/fit, frames & artboards, selection/grouping/tidy-up, live/interactive content inside canvas frames, macOS trackpad/keyboard conventions, welcome/home windows with recents, and open-source Swift/AppKit canvas implementations. Research was done against official help docs, GitHub repos and (where official docs were silent) secondary shortcut references, which are flagged as such.

---

## Key Question 1: How do Figma, Sketch, Framer, tldraw, Excalidraw, Freeform, Miro and Xcode Previews implement zoom controls, pan, pinch, minimap, frame titles, selection, grouping/sections, tidy-up?

### Takeaway
All eight apps converge on the same core model: a zoom percentage readout/menu in a toolbar corner (bottom-right for Framer/Freeform-style apps, top-right for Figma), `⌘+`/`⌘−` for stepped zoom, `⌘0` for 100%, a single-key chord for "fit all" (`⌘1` in Sketch, `⇧1` in Figma/Excalidraw, `⌥1` in Miro) and the next key up for "fit selection" (`⌘2`/`⇧2`/`⌥2`), Space+drag to pan, two-finger scroll to pan, and trackpad pinch to zoom. Frame/artboard titles are drawn as a label on the canvas above the frame; Figma and Miro additionally have "sections"/"frames" as organizational containers with editable titles, and Figma has a "Tidy up" command for auto-arranging.

### Cited Findings

**Figma (Figma Design, help docs current 2026)**
- Zoom menu is reached via "the zoom level in the toolbar" or "the top-right corner of the right sidebar"; users can "enter a custom percentage value or choose from the default zoom percentages." — [Figma Help: Adjust your zoom and view options](https://help.figma.com/hc/en-us/articles/360041065034-Adjust-your-zoom-and-view-options)
- Shortcuts: Zoom in `Shift +`, Zoom out `Shift -`, Zoom to fit `Shift 1`, Zoom to selection `Shift 2`; the default opening state is "Zoom to fit," which "focuses the viewport so you can see everything on the current page." — [Figma Help: Adjust your zoom and view options](https://help.figma.com/hc/en-us/articles/360041065034-Adjust-your-zoom-and-view-options)
- Zoom to 100% is `Shift 0`; `⌘ +`/`⌘ −` also zoom; with nothing selected, arrow keys pan the canvas. — [figmaplugins.co zoom guide](https://figmaplugins.co/guides/figma-zoom-shortcuts/) (secondary source; consistent with Figma help)
- Trackpad: "Stretch two fingers apart to zoom in" / "Pinch two fingers together to zoom out"; Magic Mouse and mouse wheel: "Hold down Command (Mac) or Ctrl (Windows) and scroll." — [Figma Help: Adjust your zoom and view options](https://help.figma.com/hc/en-us/articles/360041065034-Adjust-your-zoom-and-view-options)
- Plugin API: `figma.viewport.zoom` — "A value of 1.0 means 100% zoom, 0.5 means 50% zoom"; `scrollAndZoomIntoView(nodes)` "Automatically sets the viewport coordinates such that the nodes are visible on screen. It is the equivalent of pressing Shift-1." — [Figma Plugin API: figma.viewport](https://developers.figma.com/docs/plugins/api/figma-viewport/)
- Frame navigation: `N` zooms to the next frame, `Shift N` to the previous frame. — [Figma Community Forum thread](https://forum.figma.com/ask-the-community-7/jumping-to-next-frame-in-order-with-shortcut-n-25720); also [usethekeyboard.com/figma](https://usethekeyboard.com/figma/)
- Frames: "Enable the Frame tool by selecting it in the toolbar, or by using one of the keyboard shortcuts: F or A." Figma "bolds top-level frames in the layers panel and shows the name of any top-level frames on the canvas." Presets include Phone, Tablet, Desktop, Presentation, Watch, Paper, Social Media. "Clip Content: Hide any objects within the frame that extend beyond the frame's bounds." "Select a child object by using the keyboard shortcut: Enter or Return." — [Figma Help: Frames in Figma Design](https://help.figma.com/hc/en-us/articles/360041539473-Frames-in-Figma)
- Sections: `⇧ Shift S` activates the section tool. "Sections in Figma Design are a top-level element on the canvas by default. Sections can contain all layer types, including other sections, but cannot be contained within frames or groups." Section titles are shown on canvas and are editable by double-clicking the title. Fill and stroke of a section are customizable. Sections can be flagged "ready for development," and the status auto-updates to "Changed" if contents change. — [Figma Help: Organize your canvas with sections](https://help.figma.com/hc/en-us/articles/9771500257687-Organize-your-canvas-with-sections)
- Groups vs frames vs sections: "A group in Figma is just a wrapper: its size is always the combined size of its children, and its bounds change as they move." Frames have their own size, clip content, auto layout, layout guides, fill/stroke/effects, constraints and prototyping. Sections "act as labels for groups of objects." — [LogRocket: Figma groups vs frames vs sections](https://blog.logrocket.com/ux-design/figma-groups-frames-sections/); [Figma best practices: groups versus frames](https://www.figma.com/best-practices/groups-versus-frames/)
- Tidy up (auto-arrange selected objects into a grid/row with equal spacing): Mac shortcut `Ctrl–Option–T`. — [Noble Desktop Figma Mac shortcuts](https://www.nobledesktop.com/shortcuts/figma/mac); a user bug thread confirms the chord — [Figma forum](https://forum.figma.com/report-a-problem-6/tidy-up-ctrl-opt-alt-t-does-not-work-14133)
- Figma has no built-in minimap; none of the help pages fetched mention one (see Gaps).

**Sketch (Mac app docs, 2026)**
- Zoom shortcuts: Zoom in `⌘+`, Zoom out `⌘−`, Zoom to 100% `⌘0`, Zoom to fit all layers `⌘1`, Zoom to fit selection `⌘2`, Center selection `⌘3`. "Hold the ⌘ key and use your mouse's scroll wheel" or use the Zoom menu in the toolbar; pinch on trackpad; Zoom tool `Z` (click to zoom in, `⌥`-click to zoom out, drag a marquee to zoom to area). — [Sketch Docs: The Canvas](https://www.sketch.com/docs/canvas/)
- Panning: "hold the spacebar, click and drag to pan around the Canvas, or use the arrow keys if you haven't selected any layers." — [Sketch Docs: The Canvas](https://www.sketch.com/docs/canvas/)
- Pixel zoom: "View > Canvas > Show Pixels on Zoom" (`⌃P`) to see individual pixels past 100%; pixel grid past 600% via `⌃X`. Grid `⌃G`, Layout settings `⌃⌘L`. Smart guides show measurements against nearby layers while moving. — [Sketch Docs: The Canvas](https://www.sketch.com/docs/canvas/)
- Full Mac shortcut list (artboards, groups `⌘G`, etc.) lives at [Sketch Docs: Mac app shortcuts](https://www.sketch.com/docs/shortcuts/mac/).

**Framer (help, 2026)**
- Zoom menu is "on the right side of the toolbar" in the bottom canvas controls area; it lets you "Zoom in or out", "Fit the canvas to your current selection", or "Choose a specific zoom percentage". Default zoom is 100%. `⌘ +` / `⌘ −` on Mac; "Each zoom increment doubles the current zoom level." — [Framer Help: Using the canvas](https://www.framer.com/help/articles/how-to-use-the-canvas/)
- Trackpad: "Pinch with two fingers to zoom in or out"; Mouse: "Hold ⌘ (Mac) or Ctrl (Windows) while scrolling." Panning: "the pan tool", or "Hold the Space key, then click and drag"; trackpad: "Click and drag to pan, or use two fingers to scroll in any direction." — [Framer Help: Using the canvas](https://www.framer.com/help/articles/how-to-use-the-canvas/)
- Secondary references give `⌘0` = fit entire canvas and `⌘2` = zoom to selection on Mac (and `Shift 1`/`Shift 2` on Windows). — [Guideflow: How to zoom in Framer](https://www.guideflow.com/tutorial/how-to-zoom-in-framer); [Framer official shortcuts page](https://www.framer.com/shortcuts) (not fetched; listed for verification)

**tldraw (SDK docs, 2026)**
- Camera defaults: `zoomSteps: [0.1, 0.25, 0.5, 1, 2, 4, 8]` — "The first value sets minimum zoom, the last sets maximum." `zoomSpeed` and `panSpeed` are "multipliers on input sensitivity". `wheelBehavior` is `'pan'` | `'zoom'` | `'none'`; "trackpad preference defaults to panning, mouse preference to zooming." `isLocked: true` "freezes the camera for fixed-viewport apps." Methods: `zoomToFit()`, `zoomToSelection()`, `zoomToBounds(bounds, {inset})`, `resetZoom()` ("Reset zoom to 100%. With constraints, toggles between the initial zoom and 100%"). — [tldraw Docs: Camera](https://tldraw.dev/sdk-features/camera)
- Editor overview page links Camera under "View". — [tldraw Docs: Editor](https://tldraw.dev/sdk-features/editor)

**Excalidraw (2026)**
- `Shift+1` zooms to fit all elements; `Shift+2` zooms to selection; `⌘0` resets zoom; `⌘+`/`⌘−` zoom in/out; Frame tool is `F`. — [csswolf Excalidraw shortcuts](https://csswolf.com/excalidraw-keyboard-shortcuts-pdf/) and [shortcutref Excalidraw](https://shortcutref.com/en/excalidraw/) (secondary); the "zoom to fit all" shortcut originated as `Shift+1` with a request for a UI button — [excalidraw issue #3831](https://github.com/excalidraw/excalidraw/issues/3831); original zoom shortcuts PR — [excalidraw PR #770](https://github.com/excalidraw/excalidraw/pull/770)
- Unreleased changelog (2026-07-03): `setViewport()` replaces `scrollToContent()`; fit modes `fit: "scale-down"` (fit at most 100%), `"contain"`, `"none"`; "the zoom-to-fit shortcuts (shift+1/2/3) now target the locked box instead of the scene elements" when a viewport lock is active. — [Excalidraw CHANGELOG](https://github.com/excalidraw/excalidraw/blob/master/packages/excalidraw/CHANGELOG.md)

**Apple Freeform (macOS; docs cover Ventura 13 through "macOS 27 Golden Gate")**
- Zoom buttons: "Click [Zoom in] or [Zoom out] in the lower-left corner of the board". View menu items: "Zoom to Selection", "Zoom to Fit Content". Grid button is in the "bottom-right corner"; "View > Snap to Grid" makes "edges and points align to the nearest dot on the grid as you resize or move an item". — [Apple Support: Change a Freeform board's appearance on Mac](https://support.apple.com/guide/freeform/frfm000074a4e/mac)
- Shortcuts/gestures: Zoom in `Command-Plus (+)`, Zoom out `Command-Minus (-)`, or "Press and hold Option-Command while you scroll", or "On a trackpad, pinch two fingers open/closed". Pan: "Click and drag the canvas while pressing the Space bar"; move: "On a trackpad, drag using two fingers". Group `Option-Command-G`, Ungroup `Option-Shift-Command-G`, `Tab` moves between items. — [Apple Support: Keyboard shortcuts and gestures in Freeform on Mac](https://support.apple.com/guide/freeform/frfm46c25187e/mac)
- Freeform's zoom range is reported as 10% to 400% (default 100%) by a secondary guide. — [XDA: Complete guide to Freeform](https://www.xda-developers.com/apple-freeform-app-guide/) (secondary; the Apple support page fetched did not state numeric limits)
- Scenes (named viewport bookmarks for navigating/presenting a board) were added with macOS 15. — [Apple Support: Navigate and present scenes in Freeform on Mac](https://support.apple.com/en-am/guide/freeform/frfm7cc55b64/mac); [AppleInsider on Scenes + Snap to Grid](https://appleinsider.com/articles/24/06/14/freeform-in-ios-18-is-enormously-easier-to-work-inside-and-navigate)

**Miro (official shortcut list)**
- Mac: "Zoom in: Cmd + +", "Zoom out: Cmd + -", "Zoom to 100%: Cmd + 0", "Zoom to fit: Opt + 1", "Zoom to selected item: Opt + 2", "Move canvas: Space + Drag", "Frame: F", "Group: Cmd + G", "Lock/Unlock: Cmd + Shift + L", "Minimap: M", "Select tool / Hand mode: V / H", "Move forward through objects top-left to bottom-right: Tab". — [Miro Shortcuts](https://miro.com/shortcuts/)
- Trackpad: pinch to zoom; two-finger slide to scroll; Miro offers a "Navigation Mode" setting (Mouse vs Trackpad vs Touchscreen) that changes how wheel/scroll input maps to pan vs zoom. — [Miro Help: Keyboard navigation while working on boards](https://help.miro.com/hc/en-us/articles/11997028019858-Keyboard-navigation-while-working-on-boards); [arclet Miro zoom guide](https://arclet.io/guides/miro/zoom-in-and-out) (secondary)

**Xcode Previews (Xcode 16)**
- The preview canvas has zoom controls (zoom out, zoom to 100%, zoom to fit "to see the whole device", zoom in) "located on the right side of the preview pane", marked with magnifying-glass icons. Multiple previews appear as tabs at the top of the canvas; "Each preview will sit inside its own tab". — [Sarunw: Xcode Previews](https://sarunw.com/posts/xcode-previews/); [AppleInsider: Xcode Previews](https://appleinsider.com/inside/xcode/tips/how-to-use-xcode-previews-to-see-how-your-app-appears-as-you-make-it)
- Developers have asked to arrange multiple device previews in a row/grid on the canvas, which indicates the canvas is not a free-form infinite canvas. — [Apple Developer Forums thread 690373](https://developer.apple.com/forums/thread/690373)

### Inferences
- A de facto cross-app "fit" convention exists: Fit-all and Fit-selection are adjacent keys `1` and `2` with a single modifier (`⌘` in Sketch, `⇧` in Figma/Excalidraw, `⌥` in Miro). For a native Mac app, Sketch's `⌘1`/`⌘2`/`⌘3` are most Mac-native, but `⇧1`/`⇧2` is what web-canvas users (Figma, Excalidraw, Framer-on-Windows) expect; supporting both is cheap.
- Zoom readout placement: web canvas tools (Figma top-right of right sidebar; Framer bottom-right of toolbar; Freeform bottom-left +/− buttons). The bottom corners are the Apple-native choice (Freeform), top-right is Figma's.
- tldraw's explicit `zoomSteps` list `[0.1, 0.25, 0.5, 1, 2, 4, 8]` and Framer's "each increment doubles" show stepped zoom (vs. continuous) for keyboard/menu zooming, with continuous zoom reserved for pinch/⌘-scroll.
- Frame labels: all canvas tools draw the frame name as a small label floating just above the frame's top-left corner, and treat clicking that label as selecting the frame (Figma's docs confirm the name is shown on canvas for top-level frames; the click-to-select-by-label behavior is widely known but not stated in the fetched doc — see Gaps).

### Gaps
- Figma's numeric min/max zoom clamps are not stated in the plugin docs page fetched; the viewport doc only defines 1.0 = 100%.
- Official Figma docs for selection outline color/thickness, and for whether clicking a frame's canvas label selects the frame, were not found in fetched pages.
- Freeform's numeric zoom range (10%–400%) is only from a secondary source.
- Xcode Previews pinch-to-zoom behavior on trackpad is not documented in sources found.
- Apple HIG "Keyboards" page could not be parsed via fetch (returned only a title), so the HIG's canonical View-menu shortcuts (`⌘0` Actual Size, `⌘+`/`⌘−`) are inferred from Sketch/Freeform/Miro usage rather than cited from the HIG directly.

---

## Key Question 2: Established trackpad/keyboard conventions on macOS for canvas apps

### Takeaway
On macOS the conventions are: `⌘0` = actual size/100%, `⌘+`/`⌘−` = zoom in/out, trackpad pinch = continuous zoom, two-finger scroll = pan, Space+drag = temporary hand tool, `H`/`V` = hand/select tools, `⌘G`/`⇧⌘G` (or Freeform's `⌥⌘G`) = group/ungroup, and ⌘-scroll (Figma/Sketch/Framer) or ⌥⌘-scroll (Freeform) = wheel zoom.

### Cited Findings
- Freeform (Apple's own canvas app): `⌘+`/`⌘−` zoom, `⌥⌘`+scroll zoom, pinch zoom, Space+drag pan, two-finger drag to move, `⌥⌘G` group, `⌥⇧⌘G` ungroup. — [Apple Support: Freeform shortcuts and gestures](https://support.apple.com/guide/freeform/frfm46c25187e/mac)
- Sketch (native Mac): `⌘0` 100%, `⌘1` fit all, `⌘2` fit selection, `⌘3` center selection, Space+drag pan, ⌘+scroll-wheel zoom, `Z` zoom tool. — [Sketch Docs: The Canvas](https://www.sketch.com/docs/canvas/)
- Figma: ⌘+scroll zoom on Mac; pinch; `⇧1`/`⇧2`/`⇧0`. — [Figma Help](https://help.figma.com/hc/en-us/articles/360041065034-Adjust-your-zoom-and-view-options)
- Framer: Space+drag, pan tool, ⌘+scroll zoom, pinch. — [Framer Help](https://www.framer.com/help/articles/how-to-use-the-canvas/)
- Miro: `V`/`H` select vs hand mode, Space+drag, `⌘0`, `⌥1`/`⌥2`, `M` minimap. — [Miro Shortcuts](https://miro.com/shortcuts/)
- tldraw: wheel behaviour is user-configurable, "trackpad preference defaults to panning, mouse preference to zooming." — [tldraw Docs: Camera](https://tldraw.dev/sdk-features/camera)
- Miro likewise exposes a Navigation Mode setting (Mouse/Trackpad/Touchscreen). — [Miro Help: Keyboard navigation](https://help.miro.com/hc/en-us/articles/11997028019858-Keyboard-navigation-while-working-on-boards)

### Inferences
- Because trackpad scroll means "pan" but mouse wheel often means "zoom," the robust pattern (tldraw, Miro) is to detect/let the user choose an input mode. On macOS, AppKit distinguishes precise (trackpad) vs. line-based (mouse) scroll deltas via `NSEvent.hasPreciseScrollingDeltas`, which makes auto-detection feasible (inference; not from a fetched source).
- Apple-native apps (Freeform, Sketch) prefer `⌘`-modified digits for fit commands and place zoom buttons in a bottom corner; a native macOS app should also expose these in a View > Zoom menu (as Freeform does with "Zoom to Fit Content"/"Zoom to Selection").

### Gaps
- Could not fetch Apple's HIG page content to cite the official View-menu shortcut table directly.
- No source documented a "smart zoom" (two-finger double-tap) behavior in any canvas app.

---

## Key Question 3: Live/interactive content inside canvas frames — disambiguating canvas interaction vs. embedded content interaction

### Takeaway
The dominant pattern is a two-state model: a frame with live content is **inert (pointer-events off) until explicitly activated**, usually by double-click/Enter (tldraw), a Play button (Figma Make embeds), or click/hover in a "view-mode" (Excalidraw); Escape or clicking outside deactivates. Lock state is used to make content usable without accidentally moving the frame. Native Mac apps mixing live `WKWebView`/terminal tiles into a zoomed canvas report hit-testing and backing-scale drift as the main engineering risks.

### Cited Findings
- tldraw embeds: "Clicking an embed selects the shape rather than interacting with the content." To interact, "double-click it (or press Enter while it's selected) to enter editing mode." In editing mode "pointer events pass through to the iframe so you can scroll, click buttons, and use the embedded application." Exit by clicking outside or pressing Escape. "`ShapeUtil.canEditWhileLocked` returns `true` for embeds ... so a locked embed can still enter editing mode and stays put while you use it." "Editing also works in readonly mode." (doc last edited Jan 31, 2026) — [tldraw Docs: Embed shape](https://tldraw.dev/sdk-features/embed-shape)
- tldraw's implementation detail (PR merged Sept 27, 2026): `isInteractive` maps directly to `isEditing` (editingShapeId === shape.id); non-edited embeds keep `pointer-events: none` "regardless of hover state." The bug fixed: "Editing one embed made every other embed on the page take pointer events, so pressing on a second embed scrolled or played it instead of selecting it." — [tldraw PR #10467](https://github.com/tldraw/tldraw/pull/10467)
- tldraw locked shapes doc (related) — [tldraw Docs: Locked shapes](https://tldraw.dev/sdk-features/locked-shapes); custom embeds example — [tldraw Docs: Custom embeds](https://tldraw.dev/examples/custom-embed)
- Excalidraw: with embeds allowed, "embeddable & iframe elements stay interactive (hover & click activates them, view-mode style)" (changelog entry dated 2026-07-05, in the `interaction` prop section). Generated iframe elements render `customData.generationData.html` as a live `srcdoc` frame and are sandboxed (no popups, downloads, autoplay, nested frames, native form submit). — [Excalidraw CHANGELOG](https://github.com/excalidraw/excalidraw/blob/master/packages/excalidraw/CHANGELOG.md); [Excalidraw PR #12191](https://github.com/excalidraw/excalidraw/pull/12191)
- Figma Make embeds in Design/FigJam/Slides: "To interact with the prototype, click the play button on the embed, then navigate through its flows. When playing, the embed supports the same interactions as the original Make file, including scrolling, clicking, and dragging." — [Figma Help: Embed a Make prototype](https://help.figma.com/hc/en-us/articles/37617790464535-Embed-a-Make-prototype-in-a-slide-deck-board-or-design-file)
- FigJam link previews come in two kinds: static previews ("like bookmarks") and interactive previews that "allow you to load websites and interact with them ... like playing music, watching videos, and pan around maps — directly from your FigJam board." — [Figma Help: Add link previews in FigJam](https://help.figma.com/hc/en-us/articles/4414079911575-Add-link-previews-in-FigJam)
- Figma Sites inline preview: a floating preview window on the canvas, opened with `Shift Space`; it has Back/Forward buttons, you can "click another webpage on the canvas" to jump to it, and you can "enter a scale percentage to increase or decrease the size of the window" to keep it open while working. — [Figma Help: Preview a webpage or site](https://help.figma.com/hc/en-us/articles/31242824747287-Preview-a-webpage-or-site)
- Figma Design does not let you scroll a scrollable frame on the canvas in design mode; users request a modifier+scroll or hover-to-scroll behavior. — [Figma forum feature request](https://forum.figma.com/suggest-a-feature-11/make-scrollable-frames-scrollable-in-design-mode-27274)
- Freeform: links added to a board become link previews (drag from Safari or paste), not live embedded web pages. — [Apple Support: Add a link to a Freeform board on Mac](https://support.apple.com/guide/freeform/frfm6285a146/mac)
- Native macOS reference ("infinite" — Ghostty terminals + WKWebView tiles on an infinite canvas): zoom is "a visual camera operation, not a real terminal resize"; the canvas uses SwiftUI `scaleEffect` rather than `NSScrollView` magnification; during pinch gestures the embedded surfaces are frozen so they do not receive size/content-scale updates; a real bug they fixed was AppKit `setFrameSize`/`viewDidChangeBackingProperties` leaking size updates causing font-metric drift, solved by keeping a separate `logicalContentSize`. Known risks: "mouse cell targeting under visual zoom", "text selection drag accuracy", "link hover/click hit-testing offset", "IME candidate window placement." Closing a web tile tears down its `WKWebView` rather than pooling. — [GitHub p1rallels/infinite](https://github.com/p1rallels/infinite)
- Figma overflow scroll (prototype-only): "To use overflow scrolling, you must have a frame (not group) with nested content 'overflowing' past the bounds"; scroll behavior is set in the Prototype panel. — [Figma Help: Prototype scroll and overflow behavior](https://help.figma.com/hc/en-us/articles/360039818734-Prototype-scroll-and-overflow-behavior); [LogRocket: Configuring scrolling in Figma](https://blog.logrocket.com/ux-design/configuring-horizontal-vertical-scrolling-figma/)

### Inferences
- A clear pattern for the target app: single click on a web viewport frame = select the frame (move/resize); double-click or Enter = "activate" and route wheel/pointer events to the WKWebView; Escape or click on empty canvas = deactivate. This is exactly tldraw's model and matches Figma Make's "press play" affordance.
- Lock as a first-class state is valuable: tldraw lets locked embeds still be activated, which is the "I'm using this, don't let me drag it" mode.
- Only the active frame should receive pointer events; tldraw's September 2026 regression shows that making all frames interactive at once breaks selection and scroll disambiguation.
- Wheel disambiguation: while a frame is active, two-finger scroll should go to the web content and ⌘/⌥⌘-scroll (or pinch) should still zoom the canvas (Figma/Freeform conventions), so the user retains a canvas escape hatch.
- For native macOS, prefer visual-only scaling (CALayer/SwiftUI scale) of live views with a separate logical size, and avoid propagating zoom as a frame resize to WKWebView; also expect to remap hit-testing when scaled (the `advanced-scrollview` README documents the NSScrollView magnification coordinate problem).

### Gaps
- No official Figma Design documentation of a "click to activate" overlay for embeds in Design files beyond the Make-embed Play button; FigJam interactive previews' activation UI is not spelled out in the help text fetched.
- No documented modifier-key pattern (e.g., hold ⌥ to scroll content) found in any official docs; the only modifier patterns found concern zoom (⌘-scroll) not content scrolling.
- Freeform offers no live web embeds, so no Apple-first-party pattern exists for this case.

---

## Key Question 4: How do welcome/home windows look in modern Mac apps (Xcode, Sketch, Pages/Keynote, Pixelmator Pro, Craft, Linear, pen.dev)?

### Takeaway
The two mature Mac patterns are (a) Xcode-style split window: left pane with 2–3 large "start" actions, right pane listing recent projects; and (b) Sketch/Pages-style document window: left sidebar of sources/categories (Recents, Templates, Projects/Teams), main area as a thumbnail grid (switchable to list) with search, sort and filter. Freeform/Keynote-style template choosers use a category sidebar with rows of large thumbnails.

### Cited Findings
- Xcode: "In the 'Welcome to Xcode' window, click 'Create a new Xcode project.'" — [Apple Xcode Help: Create a project](https://help.apple.com/xcode/mac/current/en.lproj/dev07db0e578.html). Secondary tutorials describe the layout: "The three buttons on the left are shortcuts for the most common ways to start a new project" and "shortcuts to your most recent projects will appear in the right pane so you can open them quickly." — [Kodeco: Tour of Xcode](https://www.kodeco.com/ios/paths/foundational-tools-ios/43817071-introduction-to-xcode/01-getting-to-know-xcode/04); [BuildFire Xcode tutorial](https://buildfire.com/xcode-tutorial/). Xcode 16 also has a File > Open Recent menu and users report recents issues. — [Apple Developer Forums 764267](https://developer.apple.com/forums/thread/764267)
- Sketch Workspace window: "The Workspace window pops up every time you open the Mac app. You can open it by choosing File > Open from Workspace, or pressing ⌘O." Sidebar: switch Workspaces (top-left), browse "All Documents, Shared with Me, Recent Documents, My Drafts, or Projects", Libraries, Resources, Templates. "You can browse documents in your Workspace either as a list or a grid view, and switch between these two views using the buttons next to the search bar." The window remembers the previous sidebar selection across relaunches. Templates: "click Templates in the sidebar, and double-click on any template to create a new document." — [Sketch Docs: Creating, opening & viewing documents](https://www.sketch.com/docs/getting-started/creating-opening-and-viewing-documents/); [Sketch Docs: Templates](https://www.sketch.com/docs/symbols-and-styles/templates/); [Sketch Blog: templates](https://www.sketch.com/blog/guide-to-templates/)
- Sketch's historical redesign (v58): the Welcome Window became the "Documents Window" with "a sidebar" of Teams and Projects, tabs for "recently opened documents and access templates," and was made "bigger ... so there's plenty of room for all those thumbnails." — [Sketch Blog: Smart Layout, a new Welcome Window and Projects](https://www.sketch.com/blog/smart-layout-a-new-welcome-window-and-projects-on-the-mac-and-cloud-whats-new-in-sketch/)
- Pages template chooser: "A sidebar on the left of the template chooser lists template categories you can click to filter options, with predesigned templates arranged in rows by category"; custom templates appear under "My Templates" as the last category. — [Apple Support: Use templates in Pages on Mac](https://support.apple.com/guide/pages/use-templates-tan5c52a733c/mac); [Apple Support: Create and manage Pages templates](https://support.apple.com/guide/pages/create-and-manage-custom-templates-tanb343cb739/mac)
- pen.dev (formerly Pencil): "an infinite design canvas available as a desktop app, VS Code or Cursor extension, and command-line tool"; designs are "Git-friendly .pen files"; the VS Code extension offers "pen.dev: Open Welcome File" via the Command Palette, or "Welcome" from the pen.dev sidebar. — [pen.dev docs: troubleshooting](https://docs.pencil.dev/troubleshooting); [pen.dev](https://www.pen.dev/); [The Rundown: Pencil is now pen.dev](https://www.therundown.ai/tools/pencil)
- Pixelmator Pro: user guide and release notes exist but no welcome-window documentation was found. — [Pixelmator Pro User Guide](https://support.apple.com/guide/pixelmator-pro/welcome/mac); [Pixelmator Pro release notes](https://support.apple.com/en-au/126257)

### Inferences
- For a project-based app (like the target), the Xcode split (actions left, recents right) is the lightest; for a document-centric app with many projects, Sketch's sidebar + grid/list toggle + search is the richer pattern and maps naturally to NSSplitView/NavigationSplitView with a `LazyVGrid` of thumbnail cards.
- Common card anatomy across Sketch/Keynote/Pages: large thumbnail, title underneath, secondary metadata (modified date/location), grid-vs-list toggle beside a search field, sort/filter in the toolbar.
- Remembering last sidebar selection (Sketch) and auto-opening the window on launch with ⌘O to re-summon it are both worth copying.

### Gaps
- No official or reliable screenshots/docs found for Craft's or Linear's Mac welcome/home screens (Linear is a web-first app without a classic welcome window; Craft's documents home was not located).
- Pixelmator Pro welcome window details not found.
- pen.dev's desktop-app home screen (recent projects list) is not documented in the pages found; only the VS Code "Welcome File" command is.
- Mobbin/Refero pattern-library pages for "welcome screen"/"recents" were not retrieved (they require login/search); no citations available.
- The Apple Xcode help page did not describe the welcome window layout; layout details come from secondary tutorials.

---

## Key Question 5: Open-source Swift/AppKit/SwiftUI infinite-canvas implementations on macOS (zoom/pan with embedded NSViews)

### Takeaway
Several open-source macOS projects exist. The most relevant to "live views inside a zoomable canvas" is `p1rallels/infinite` (WKWebView + Ghostty tiles with SwiftUI `scaleEffect` and frozen logical sizes); `dmytro-anokhin/advanced-scrollview` is the best reference for `NSScrollView` magnification bridged to SwiftUI, including the coordinate-translation pitfall; `namuan/open-canvas`, `1amageek/swift-flow`, `codelynx/Panorama` and `benjaminRoberts01375/SwiftUI-Infinite-Grid` are additional references.

### Cited Findings
- `dmytro-anokhin/advanced-scrollview` (MIT; iOS UIScrollView + macOS NSScrollView bridged to SwiftUI): supports "pinch to zoom at precise points, scroll with a given offset, and infinite canvas"; `Magnification` struct has `range` (e.g. `1.0...4.0`), `initialValue`, `isRelative`. Provides `onTapContentGesture` and `onDragContentGesture` because "When magnified, NSScrollView doesn't correctly translate points from its coordinate system to SwiftUI views" (UIScrollView handles it correctly). — [GitHub dmytro-anokhin/advanced-scrollview](https://github.com/dmytro-anokhin/advanced-scrollview); author write-up — [Medium: ScrollView, SwiftUI, and ShapeEdit](https://dmytro-anokhin.medium.com/scrollview-swiftui-and-shapeedit-94962e5e4245)
- `p1rallels/infinite`: "infinite canvas for infinite ghostty terminals" plus WebKit browser tiles; zoom via SwiftUI `scaleEffect` on the tile layer, zoom state in `CanvasViewModel.scale`, surfaces frozen during pinch, separate `logicalContentSize` in `TerminalSurfaceNSView.swift`; documented hit-testing risks under visual zoom. — [GitHub p1rallels/infinite](https://github.com/p1rallels/infinite)
- `namuan/open-canvas`: "a native macOS desktop application that provides an infinite, zoomable canvas where developers can create, arrange, and manage multiple OpenCode AI sessions simultaneously", with draggable nodes, real-time updates and persistent layout. — [GitHub namuan/open-canvas](https://github.com/namuan/open-canvas)
- `1amageek/swift-flow`: "A Canvas-based flow diagram library for SwiftUI (iOS / macOS)"; "Nodes are draggable, the canvas supports pan and zoom out of the box"; nodes are rendered as SwiftUI views via `resolveSymbol`. — [GitHub 1amageek/swift-flow](https://github.com/1amageek/swift-flow)
- `codelynx/Panorama`: "iOS/macOS 2D scrollable/zoomable utility code" built on Core Graphics. — [GitHub codelynx/Panorama](https://github.com/codelynx/Panorama)
- `benjaminRoberts01375/SwiftUI-Infinite-Grid`: "A SwiftUI library for creating and interacting with an infinite grid" (iOS 17+, macOS 14+). — [GitHub SwiftUI-Infinite-Grid](https://github.com/benjaminRoberts01375/SwiftUI-Infinite-Grid)
- `rroshann/voidloom`: "a canvas-first agent workspace for macOS with an infinite pan/zoom canvas." — [GitHub rroshann/voidloom](https://github.com/rroshann/voidloom)
- GitHub topic listing for Swift infinite-canvas projects — [github.com/topics/infinite-canvas?l=swift](https://github.com/topics/infinite-canvas?l=swift); `nsscrollview` topic — [github.com/topics/nsscrollview](https://github.com/topics/nsscrollview)
- Apple sample code using `NSScrollView` magnification on a canvas: Photo Editor `CanvasViewController.swift`. — [Apple Developer archive: PhotoEditor CanvasViewController.swift](https://developer.apple.com/library/archive/samplecode/PhotoEditor/Listings/Photo_Editor_CanvasViewController_swift.html)
- Article comparing two SwiftUI infinite-canvas approaches. — [Level Up Coding: SwiftUI Infinite Canvas 2 Ways](https://levelup.gitconnected.com/swiftui-infinite-canvas-2-ways-faac8a79eed4)

### Inferences
- Two viable native strategies: (1) `NSScrollView` with `allowsMagnification`/`magnification` (Apple-sanctioned, gives rubber-banding, pinch and smart zoom for free, but SwiftUI hit-testing needs correction per advanced-scrollview); (2) a custom camera (translate+scale on a container layer, as `infinite` does with `scaleEffect`) which keeps live `WKWebView`s at a fixed logical size and only visually scales them, avoiding re-layout on every zoom tick.
- The `infinite` project's experience argues for freezing live-view size during pinch and re-syncing only at gesture end; this is the key insight for live web viewports in a zoomed canvas.

### Gaps
- None of the repos found document a production-grade solution for keyboard focus/IME and scroll-event routing into a scaled `WKWebView`; `infinite` lists these as open risks.
- `voidloom` and `open-canvas` READMEs were not fetched in full; only summary descriptions are cited.
