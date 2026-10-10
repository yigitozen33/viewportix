# macOS 26 / Liquid Glass-era UI kits, templates and design resources for a native canvas-style Mac app (as of 2026-10-06)

Scope note: the target app has a toolbar, a sidebar, an infinite canvas, an inspector/side panel, and a welcome/home window with recent documents. Resources are tagged **[Free]** / **[Paid]** and **[Current: macOS 26/27, Liquid Glass]** / **[Older]**. Important context discovered during research: by October 2026 Apple has already moved its official design-resources page to **macOS 27** kits (same Liquid Glass design language); the macOS 26 kits remain downloadable on Figma Community.

## Key Question 1: What official Apple design resources exist for macOS 26 (Figma/Sketch kits, SF Symbols, Liquid Glass guidance), and what components do they include?

### Takeaway
Apple publishes free, official macOS UI kits for Figma and Sketch (macOS 26 "Tahoe" kit, and since Sept 2026 a macOS 27 kit) that cover window chrome, toolbars, sidebars, menus, tables, alerts/sheets/popovers, system colors, materials and text styles in light and dark mode; there is no dedicated "inspector" or "canvas" component, so inspectors must be composed from the kit's sidebar/table/form controls. Liquid Glass guidance lives in the HIG "Materials" page plus the updated Toolbars/Sidebars pages, and SF Symbols 27 and Icon Composer round out the toolset.

### Cited Findings
- Apple's Design Resources page (Oct 2026) lists for macOS only the **macOS 27 UI Kit**: Figma https://www.figma.com/community/file/1651309434229735362/macos-27 and Sketch https://sketch.com/s/57153a31-3379-4737-8ac6-dbfd6525f052; it also lists iOS/iPadOS 27, watchOS 26, visionOS 26 kits, SF Symbols 27, Icon Composer, fonts (SF Pro, SF Compact, SF Mono, New York) and product bezels — [Apple Design Resources](https://developer.apple.com/design/resources/)
- The **macOS 27 Figma kit** is published by Apple (@apple), description: "Comprehensive set of macOS UI components including sidebar, toolbar, tables, buttons, menus, pointers and more; full dark mode and window state support; views and system components including windows, alerts, popovers, sheets, and dialogs; desktop templates including menubar, dock, notifications and wallpapers"; page metadata shows 646 likes and 12,987 uses, "Updated July 24, 2026", and a created date of 2026-09-23 in the page JSON — [Figma Community: macOS 27 (Apple)](https://www.figma.com/community/file/1651309434229735362/macos-27)
- A third-party mirror describes the same macOS 27 kit as also including "system colors, materials, text styles, and vibrancy effects" and being an editable Figma source file, free — [TitanUI: macOS 27 Figma UI kit](https://www.titanui.com/130424-free-macos-27-figma-ui-kit/)
- The **macOS 26 Figma kit** (Apple official) is still on Figma Community: "Apple's official macOS 26 UI kit for Figma contains a comprehensive set of components, text styles, color styles, and materials... Updated July 24, 2026"; key features listed: sidebar, toolbar, tables, buttons, menus, cursors; windows, alerts, popovers, sheets, save dialogs; desktop templates (menubar, dock, notifications, wallpapers); system colors, materials, text styles — [Figma Community: macOS 26 (Apple)](https://www.figma.com/community/file/1543337041090580818/macos-26); mirrored description at [TitanUI macOS 26 Tahoe kit](https://titanui.com/128692-official-apple-macos-26-tahoe-figma-ui-kit/)
- Apple's **macOS Tahoe 26 Sketch Library** was released after WWDC25 (June 2025) and includes Arrow Buttons, Checkboxes, Color Wells, Combo Boxes, Dials, Disclosure Buttons, Group Boxes, Image Wells, Pop-Up Buttons, Progress Indicators, Pull-Down Buttons, Push Buttons, Radio Buttons, Scrollbars, Search Fields, Segmented Controls, Sidebars, Sliders, Steppers, Text Fields, Toggles, Tooltips, App icons, Alerts, Cursors; also menus, dialogs, menubars, desktop elements, titlebars, dock, notifications, wallpapers and system forms — [9to5Mac](https://9to5mac.com/2025/06/10/apple-updates-design-resources-for-ios-26-ipados-26-and-macos-tahoe-26/); [AppleInsider](https://appleinsider.com/articles/25/06/11/apple-design-resources-update-helps-developer-make-liquid-glass-apps-for-ios-26-macos-tahoe)
- Apple's verified Figma profile hosts all official kits (iOS/iPadOS 27, macOS 27, watchOS 26, visionOS 26, App Icon templates, technology templates) — [Figma @apple](https://www.figma.com/@apple)
- **SF Symbols 27**: 7,000+ symbols, 9 weights, 3 scales, multi-layer drawings for motion, requires macOS Sonoma or later — [Apple Design Resources](https://developer.apple.com/design/resources/)
- **Icon Composer**: creates layered Liquid Glass app icons for iPhone, iPad, Mac and Apple Watch; requires macOS Sequoia or later — [Apple Design Resources](https://developer.apple.com/design/resources/)
- Apple's "iOS and iPadOS 26 design kits are here" news post announced the Figma/Sketch kits for the 26 generation — [Apple Developer News](https://developer.apple.com/news/?id=pnfbj8je)
- A community GitHub catalog (mjmirza/apple-design-system) mirrors the official resource list, including the macOS 27 Sketch cloud link, Icon Composer, SF Symbols 8 beta/7, fonts, bezels and technology templates, with a fetch script — [GitHub mjmirza/apple-design-system](https://github.com/mjmirza/apple-design-system/blob/master/catalog/10-resources-downloads.md)
- Apple's Sketch libraries for tvOS/visionOS 2 use the `sketch://add-library?url=...rss` auto-updating library mechanism; the 26/27 kits are instead shared as Sketch Cloud documents (sketch.com/s/...) — [Apple Design Resources](https://developer.apple.com/design/resources/)
- Uithings maintains a guide to all official Apple design resources (2025) — [uithings.com](https://uithings.com/apple-design-resources)

### Inferences
- For a macOS 26-era app, the best starting file is Apple's official macOS 26 or macOS 27 Figma kit (both Liquid Glass; the 27 kit is the one Apple now promotes). The component list covers toolbar, sidebar, window chrome, menus, tables, alerts/sheets, dark mode, and materials; it does not ship an "inspector" or "canvas" template, so the inspector must be assembled from sidebar/table/form controls and the canvas drawn as a content-layer region.
- Because the two kits share the same descriptions and update dates, a designer can expect near-identical component coverage; pick 27 if targeting the forward-looking look, 26 if matching a shipped macOS 26 app precisely.

### Gaps
- Figma Community pages block automated fetching (HTTP 403/202), so the full change log, page/variable structure, and license text of the Apple kits could not be read directly; Apple kits are free on Figma Community but the exact license wording was not verified.
- The exact list of new/changed components between the macOS 26 and macOS 27 kits was not found.

## Key Question 2: Best community Figma/Sketch kits for macOS apps and how current are they?

### Takeaway
Community kits that are genuinely macOS 26-current are mostly narrow (Liquid Glass effect files, cursors, icon templates, Control Center/Safari mockups); the broad community macOS design systems (Apple macOS 12 Design System, alexkaessner's Sketch macOS UI Kit, macOS Browsers kit) predate Liquid Glass and are useful mainly for layout reference.

### Cited Findings
- **Apple macOS 26 Cursors** (Figma Community file) — [Figma](https://www.figma.com/community/file/1517119747499682321/apple-macos-26-cursors) [Current]
- **"macOS 26 - Liquid Glass Effect"** community file demonstrating the glass effect in Figma — [Figma](https://www.figma.com/community/file/1514239434132644410/macos-26-liquid-glass-effect) [Current]
- **Liquid Glass UI** Figma plugin — [Figma plugin](https://www.figma.com/community/plugin/1514769156504171663/liquid-glass-ui) [Current]
- **Apple Liquid Glass UI – Control Center – macOS 26 (WWDC 2025)** recreation; the author created the macOS Control Center "to explore how this beautiful effect could be achieved in Figma" — [Figma](https://www.figma.com/community/file/1515113236376349942/apple-liquid-glass-ui-control-center-macos-26-apple-wwdc-2025) [Current]
- **Liquid Glass** by fuwad.design — [Figma](https://www.figma.com/community/file/1514868873901345845/liquid-glass-apple-fuwad-design) [Current]
- **Safari Browser Mockups Liquid Glass – macOS 26 Tahoe** — [Figma](https://www.figma.com/community/file/1549609148392437055/safari-browser-mockups-liquid-glass-macos-26-tahoe) [Current]
- **macOS icon template (Updated for macOS 26 & Liquid Glass)** — [Figma](https://www.figma.com/community/file/930870327989917713/macos-icon-template-updated-for-macos-26-liquid-glass) [Current]; **MacOS26 (Liquid Glass) Icon** — [Figma](https://www.figma.com/community/file/1521194518354696931/macos26-liquid-glass-icon)
- **Apple macOS 26 (Tahoe) File Template (Vector)** — [Figma](https://www.figma.com/community/file/1604888746533816403/apple-macos-26-tahoe-file-template-vector)
- **Code prism Liquid Glass UI Kit** (generic Liquid Glass component kit) — [Figma](https://www.figma.com/community/file/1541734372393810634/code-prism-liquid-glass-ui-kit)
- **"Apple macOS 26 Library"** community file: despite its name, its own description says "Apple iOS 26 / iPad26 UI Library kit imported from Sketch" with color and typography variables added (updates 01/02) — [Figma](https://www.figma.com/community/file/1514327883026186935/apple-macos-26-library) (naming is misleading; treat as iOS-derived)
- **Apple MacOS 12 Design System for Figma** — [Figma](https://www.figma.com/community/file/1143831050419793062/apple-macos-12-design-system-for-figma) [Older: Monterey era]
- **macOS Browsers UI kit – Fully Responsive** — [Figma](https://www.figma.com/community/file/1139199487938959092/macos-browsers-ui-kit-fully-responsive) [Older]
- **Macbook Tool Kit** — [Figma](https://www.figma.com/community/file/1556862814110764483/macbook-tool-kit) (device/mockup oriented)
- **alexkaessner/macOS-UI-Kit** (Sketch): "the most detailed and accurate macOS UI Kit for Sketch", Sketch 101+, 750+ symbols, 270+ text styles, light/dark, Touch Bar, cursors, SF Symbol support, MIT license, free; targets Big Sur-era macOS — [GitHub](https://github.com/alexkaessner/macOS-UI-Kit) [Older]
- **macOS UI Library Sketch freebie** on Sketch App Sources — [sketchappsources.com](https://www.sketchappsources.com/free-source/3187-macos-ui-library-sketch-freebie-resource.html) [Older, undated]
- **MockFlow "Wireframe UI kit for macOS 26 Tahoe"**: updated windows, toolbars, modals and preference panels for MockFlow WireframePro; free to import — [MockFlow](https://mockflow.com/uikits/wireframe/macos-26-tahoe) (wireframe fidelity only)
- **Sketch app itself** (paid tool): the Barcelona update (2025.2.1) added a Liquid Glass-style glass effect with blur, distortion, depth, chromatic aberration, brightness, saturation and specular highlight controls, plus an updated Apple UI library with macOS 26 and iOS 26 assets; requires macOS Sonoma 14.0+ — [9to5Mac](https://9to5mac.com/2025/08/20/sketch-update-brings-liquid-glass-effects-macos-26-and-ios-26-libraries-more/); Sketch's 2025 recap confirms Stacks/Frames, Glass effects and a macOS Tahoe redesign — [Sketch blog](https://www.sketch.com/blog/sketch-in-2025/)
- Figma's uwarp index lists "Apple Design Resources – macOS" as a Figma UI kit entry — [figma.uwarp.design](https://figma.uwarp.design/resources/ui-kits/74943c99-4036-43e8-bca0-c18495b84e13)

### Inferences
- No community kit was found that is both broad (full macOS app chrome) and macOS 26/27-current; Apple's official kits are the only full-coverage Liquid Glass option. Community files are best used as add-ons (cursors, glass effect recipes, icon templates).
- If the team uses Sketch, the native glass effect (Barcelona 2025.2.1+) plus Apple's Sketch library is the most faithful route to Liquid Glass renderings; Figma needs plugin/effect-file workarounds.

### Gaps
- Like/duplicate counts, last-updated dates and licenses for most community files could not be retrieved (Figma blocked scraping); figures above are only available for Apple's macOS 27 kit.
- No paid macOS 26 UI kit marketplaces (e.g., UI8, Setproduct) were confirmed; searches did not surface a Liquid Glass macOS kit from those vendors.

## Key Question 3: What does the HIG say about toolbars, sidebars, inspectors, the welcome-window/document pattern, and canvas-style content areas?

### Takeaway
The HIG (Toolbars updated Dec 16, 2025; Sidebars updated June 8, 2026) frames toolbars and sidebars as Liquid Glass elements floating above a content layer that should scroll/extend beneath them; inspectors are covered under Panels (trailing split-view pane or floating panel with simple controls); there is no HIG page for a "welcome window" — the closest guidance is File Management (menus, Add (+) button, "open recent") and the iOS document launcher pattern.

### Cited Findings
**Toolbars** — [HIG Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- Three item locations: leading edge (back/sidebar toggle, then title, optional document menu; not customizable), center (common controls; customizable in macOS/iPadOS; collapse into system overflow menu), trailing edge (important items, "buttons that open nearby inspectors", optional search field, More menu, primary action like Done; always visible).
- "Minimize the number of groups... aim for a maximum of three"; keep title under 15 characters; don't title windows with the app name.
- "Reduce the use of toolbar backgrounds and tinted controls" — custom backgrounds can interfere with system (Liquid Glass) effects; use the content layer to inform toolbar appearance; prefer the default monochromatic appearance when content is colorful.
- "Prefer system-provided symbols without borders" (no outlined-circle symbols); use `.prominent` style for one primary action, on the trailing side.
- Standard components have corner radii "concentric with bar corners"; custom components should match.
- Do not add an overflow menu manually; the system adds one in macOS/iPadOS when items don't fit. Consider letting people customize the toolbar in long-session apps; consider temporarily hiding toolbars for distraction-free mode.
- macOS: toolbar "resides in the frame at the top of a window, either below or integrated with the title bar"; titles can display inline with controls; items have no bezel; "make every toolbar item available as a command in the menu bar".
- Change log: "December 16, 2025 Updated guidance for Liquid Glass. June 9, 2025 Added guidance for grouping bar items..."

**Sidebars** — [HIG Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars)
- "Extend visually rich content beneath the sidebar": in iOS/iPadOS/macOS sidebars "float above content in the Liquid Glass layer"; extend content under it by horizontal scrolling or a "background extension effect" that mirrors adjacent content.
- Let people customize and hide the sidebar (macOS: show/hide button and View menu commands); avoid hiding by default; show no more than two levels of hierarchy, otherwise use a split view with a content list; use disclosure controls for deep hierarchies; use SF Symbols; sidebar icons use the app accent color and must follow the user's system accent color.
- macOS: row height, text and glyph size depend on sidebar size (small/medium/large; user-changeable in General settings); consider auto-collapsing the sidebar when the window shrinks; avoid critical actions at the bottom of a sidebar.
- Change log: June 8, 2026 (icon colors, adaptable sidebar style); June 9, 2025 (content beneath sidebar).

**Inspectors / Panels** — [HIG Panels](https://developer.apple.com/design/human-interface-guidelines/panels)
- "An inspector displays the details of the currently selected item, automatically updating its contents when the item changes"; present it as a panel or "a split view pane"; an Info window with fixed contents should be a regular window, not a panel.
- Prefer simple adjustment controls (sliders, steppers) over typing; give panels a brief noun title ("Inspector", "Fonts", "Colors"); menu commands read "Show Inspector"; bring panels forward when the app activates and hide them when inactive; generally no minimize button; don't list panels in the Window menu.
- HUD-style (dark translucent) panels only for media-oriented apps, when a standard panel would obscure content, or when few controls are needed; keep HUDs small.
- Windows page: a bottom bar "is small, so if you have more information to display, consider using an inspector, which typically presents information on the trailing side of a split view" — [HIG Windows](https://developer.apple.com/design/human-interface-guidelines/windows)

**Split views (sidebar + canvas + inspector layout)** — [HIG Split Views](https://developer.apple.com/design/human-interface-guidelines/split-views)
- "Keynote in macOS uses split view panes to present the slide navigator, the presenter notes, and the inspector pane in areas that surround the main slide canvas."
- macOS: panes can be vertical, horizontal or both; set reasonable min/max pane sizes so dividers stay visible; "Prefer the thin divider style. The thin divider measures one point in width"; let people hide panes to make room for an editing area; provide multiple ways (toolbar button, menu command, shortcut) to reveal hidden panes; persistently highlight the current selection; consider drag and drop between panes.

**Windows / window chrome** — [HIG Windows](https://developer.apple.com/design/human-interface-guidelines/windows)
- macOS window anatomy: a frame (title bar, window controls, optional toolbar, rare bottom bar) and a body area; window states main / key / inactive, with inactive windows losing vibrancy; "Avoid creating custom window UI"; use the term "window" in user-facing text; choose carefully when to open new windows.

**Materials / Liquid Glass** — [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- "Liquid Glass forms a distinct functional layer for controls and navigation elements — like tab bars and sidebars — that floats above the content layer"; "Don't use Liquid Glass in the content layer" (use standard materials for app backgrounds); "Use Liquid Glass effects sparingly"; two variants: regular (blurs/adjusts luminosity; used by sidebars, alerts, popovers) and clear (highly translucent, for media backgrounds; add a 35%-opacity dark dimming layer over bright content); macOS keeps standard materials, vibrant system colors and "behind window / within window" blending modes.
- Apple announced Liquid Glass on June 9, 2025 at WWDC25 — [Apple Newsroom](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)

**Welcome window / recent documents** — [HIG File Management](https://developer.apple.com/design/human-interface-guidelines/file-management)
- macOS/iPadOS: people expect New/Open via menu commands and keyboard shortcuts; "include an Add (+) button to help people create a new document"; people "might appreciate an 'open recent' action in addition to the simple 'open' action"; custom file browsers may filter or multi-select; new documents are titled "Untitled"; show unsaved-changes dot on the close button when autosave is off; "Edited" suffix allowed in the title bar.
- iOS/iPadOS 18+ "document launcher": a title card with app title and two app-specific buttons (e.g., primary "Start Writing", secondary "Choose a Template"), a background image with accessories, and a sheet with a file browser — the closest Apple-documented pattern to a welcome/home window, but macOS has no equivalent section.
- Launching / onboarding: "macOS, visionOS, and watchOS don't require launch screens"; restore windows "in the same state and location in which people left them" — [HIG Launching](https://developer.apple.com/design/human-interface-guidelines/launching); [HIG Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)

**macOS platform fundamentals** — [HIG Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos)
- Leverage large displays for more content in fewer nested levels; let people resize/hide/show/move windows and support full screen; use the menu bar for all commands; support high-precision input and keyboard shortcuts; support personalization (customizable toolbars, window views).

**Developer-side references for window styling**
- WWDC24 "Tailor macOS windows with SwiftUI" covers styling window toolbars/backgrounds, placement, restoration and minimization — [Apple Developer Videos](https://developer.apple.com/videos/play/wwdc2024/10148/)

### Inferences
- For a canvas app, the HIG-compliant layout is a three-pane split view (sidebar | canvas | inspector) with a unified/integrated toolbar; the canvas is content-layer (standard materials, no glass) and should visibly extend beneath the floating sidebar and toolbar (edge-to-edge scrolling or background-extension effect).
- Inspector controls should favor sliders/steppers/segmented controls, live on the trailing side, and have a toolbar toggle on the trailing edge plus View-menu commands and shortcuts.
- The "Xcode-style" welcome window with a recent-documents list is a de-facto convention (Xcode, CodeEdit) rather than a HIG-specified pattern; the HIG only mandates New/Open/Open Recent commands and an Add (+) affordance.

### Gaps
- The HIG does not publish numeric sidebar widths, toolbar heights, or inspector widths; the only numeric values found are the 1 pt thin divider, 15-character title limit, max three toolbar groups, and 35% dimming layer.
- No HIG page covers "canvas" or "infinite canvas" content areas explicitly; guidance was inferred from Split Views (Keynote canvas example), Materials and Sidebars.
- The HIG "Liquid Glass" standalone page and "Inspectors" slug returned errors via the data API; Liquid Glass guidance here comes from Materials/Toolbars/Sidebars.

## Key Question 4: Figma design systems or kits with infinite-canvas / artboard UI (frames, zoom controls, "fit" buttons) that could be adapted?

### Takeaway
No ready-made Figma kit specifically for designing an infinite-canvas desktop tool (zoom widget, fit-to-screen, rulers, minimap) was found; the closest adaptable sources are Figma's own UI3 interface conventions (fixed side panels, floating bottom toolbar, minimize-UI mode), the Figma Plugin UI Kit (UI3 components), a "Figma Toolbar UI Kit" community file, and Sketch's Copenhagen redesign, which is itself a native macOS canvas app built for Tahoe.

### Cited Findings
- Figma UI3 (rolled out to everyone Oct 10, 2024): the team first shipped floating panels above the canvas, then reverted to fixed, docked, resizable panels because "they slowed people down"; floating toolbars stay at the bottom across Figma products; a "Minimize UI" mode collapses side panels; the navigation panel lists file, branch, project, then pages and layers — [Figma blog: Our approach to designing UI3](https://www.figma.com/blog/our-approach-to-designing-ui3/); [Figma blog: Making the move to UI3](https://www.figma.com/blog/making-the-move-to-ui3-a-guide-to-figmas-next-chapter/)
- Figma's interface is built from a canvas, a left navigation panel (Layers/Assets), a bottom toolbar and a right properties panel that updates with selection — [Figma Help: right sidebar](https://help.figma.com/hc/en-us/articles/360039832014-Design-prototype-and-explore-layer-properties-in-the-right-sidebar); zoom/view options (zoom to fit, zoom to selection, etc.) are documented at [Figma Help: Adjust your zoom and view options](https://help.figma.com/hc/en-us/articles/360041065034-Adjust-your-zoom-and-view-options)
- **Figma Plugin UI Kit** (FigLint) "includes most UI3 components and over 300 icons" — [Medium: FigLint UI3 icons update](https://medium.com/@marcinukleja/figlint-ui3-icons-update-part-1-3-figma-plugin-ui-kit-67eb92a0c9f7)
- **Figma Toolbar UI Kit** community file (toolbar recreation) — [Figma](https://www.figma.com/community/file/1084574845576659209/figma-toolbar-ui-kit) (contents/date unverified)
- **"UI KIT"** community file surfaced for a UI3 query — [Figma](https://www.figma.com/community/file/1094903221888025808/ui-kit) (contents unverified)
- **Artboard** FigJam/Figma widget: "virtual whiteboard... Excalidraw-like diagramming... infinite whiteboards right inside Figma or FigJam" with zoom and panning — [Figma widget](https://www.figma.com/community/widget/1430445084141708060/artboard) (a tool, not a UI kit)
- **Canvas Design System** by Airdev is a web-app UI kit (blocks/page templates), not a canvas-tool UI — [Figma](https://www.figma.com/community/file/1387894540487619534/canvas-design-system); similarly **Canvas – Free UI Kit (Recreated)** — [Figma](https://www.figma.com/community/file/1324307019151602571/canvas-free-ui-kit-recreated) (name collision; not relevant)
- **fancy-artboard** (GitHub): "Figma-style design canvas... pan/zoom ArtBoard of ArtPieces (image, HTML, or JSX)" — a web component, useful as an interaction reference — [GitHub](https://github.com/Particle-Academy/fancy-artboard)
- **Sketch Copenhagen** (released Nov 19, 2025): native Mac canvas app redesigned for macOS Tahoe — "went custom here, with fixed sidebars" instead of Tahoe's floating defaults; document tabs moved into the sidebar; a context-aware toolbar that changes with tool/layer plus a Command Bar (press S); the inspector turned most popovers into detached panels that persist across selections; layer-list focus mode; 700+ new icons; redesigned selection overlays, handles, cursors; Liquid Glass used in the toolbar, minimap and bottom-of-canvas notifications — [Sketch blog: A guided tour of Copenhagen](https://www.sketch.com/blog/a-tour-of-copenhagen/); [CSS-Tricks coverage](https://css-tricks.com/sketch-a-guided-tour-of-copenhagen/)
- Jitter (web motion tool) added an infinite canvas in Feb 2025 — [Jitter changelog](https://jitter.video/changelog/2025-02-04-infinite-canvas/) (reference only)

### Inferences
- Practical path: take Apple's macOS 27/26 kit for window chrome, sidebar and inspector controls, then draw canvas-specific widgets (zoom percentage pop-up, fit/100% buttons, minimap, rulers) by hand, using Figma UI3 and Sketch Copenhagen screenshots as behavioral references. Sketch's choice of fixed (non-floating) sidebars for a canvas app is a notable precedent that departs from Tahoe defaults.
- A floating bottom toolbar (Figma UI3 style) over the canvas is a Liquid Glass-compatible pattern (controls floating above content), but HIG says to keep glass out of the content layer, so the canvas itself must stay opaque/standard-material.

### Gaps
- No Figma Community file was found that packages infinite-canvas chrome (zoom widget, fit button, rulers, minimap) as reusable components; Figma's own UI3 design system is not published as a community file per the blog post read.
- Contents and currency of "Figma Toolbar UI Kit" and "UI KIT" could not be verified (page scraping blocked).

## Key Question 5: Open-source native macOS apps (canvas/diagramming/design tools) with public design or screenshots as references?

### Takeaway
Several small open-source SwiftUI macOS infinite-canvas apps and libraries exist (OpenCanvas, Napkin, VoidLoom, Infinite, CleanCocoa InfiniteCanvas, SwiftUI-Infinite-Grid, swiftui-infinite-canvas) and CodeEdit's WelcomeWindow package is a drop-in, MIT-licensed Xcode-style welcome window with recent documents; none publishes Figma design files, so they serve as screenshot/behavior references only.

### Cited Findings
- **namuan/open-canvas** — "A native macOS desktop application that provides an infinite, zoomable canvas where developers can create, arrange, and manage multiple OpenCode AI sessions" — [GitHub](https://github.com/namuan/open-canvas)
- **alex-k03/napkin** — "Simple, native, macOS whiteboard" — [GitHub](https://github.com/alex-k03/napkin)
- **rroshann/voidloom** — "canvas-first agent workspace for macOS — an infinite pan/zoom canvas of draggable cards with native SwiftUI" — [GitHub](https://github.com/rroshann/voidloom)
- **p1rallels/infinite** — "experimental macOS infinite canvas for Ghostty-backed terminals and WebKit-backed browser tiles" — [GitHub](https://github.com/p1rallels/infinite)
- **CleanCocoa/InfiniteCanvas** — "proof-of-concept Mac drawing app with an infinite 3D canvas for unrestricted vector drawing" — [GitHub](https://github.com/CleanCocoa/InfiniteCanvas); also listed at [open-awesome.com](https://open-awesome.com/projects/infinitecanvas)
- **benjaminRoberts01375/SwiftUI-Infinite-Grid** — SwiftUI infinite grid library, iOS 17+/macOS 14+ — [GitHub](https://github.com/benjaminRoberts01375/SwiftUI-Infinite-Grid); **chrisrecalis/swiftui-infinite-canvas** — reusable SwiftUI infinite canvas — [GitHub](https://github.com/chrisrecalis/swiftui-infinite-canvas); GitHub topic listing for Swift infinite-canvas projects — [GitHub topics](https://github.com/topics/infinite-canvas?l=swift)
- **CodeEditApp/WelcomeWindow** — "a welcome window built for macOS applications": recent-documents list, new/open action buttons, drag-and-drop to open, NSDocument support, ability to override the recent list; SwiftUI + AppKit; MIT; used by CodeEdit and CircuitPro; 44 stars — [GitHub](https://github.com/CodeEditApp/WelcomeWindow); docs at codeeditapp.github.io/WelcomeWindow
- **JUSTINMKAUFMAN/WelcomeWindow** — SwiftUI welcome screen "modeled after the 'Welcome to Xcode' window" — [Swift Package Registry](https://swiftpackageregistry.com/JUSTINMKAUFMAN/WelcomeWindow)
- **simonweniger/swift-macos-template** — starter template for macOS apps — [GitHub](https://github.com/simonweniger/swift-macos-template)
- Agent "skills" encoding macOS design guidelines exist (useful as checklists for AI-assisted design): [lobehub macos-design-guidelines](https://lobehub.com/skills/andresilvagomez-wisper-macos-design-guidelines); [ehmo/platform-design-skills](https://agentskills.so/skills/ehmo-platform-design-skills-macos-design-guidelines)
- A curated list of open-source Swift macOS apps exists but contains no canvas/diagramming/design tools — [Awesome Swift macOS Apps](https://wangchujiang.com/awesome-swift-macos-apps/)
- Commercial native references adopting Liquid Glass: Sketch Copenhagen (see Q4) and Paste 6 (Liquid Glass redesign, Oct 2025) — [AlternativeTo news](https://alternativeto.net/news/2025/10/paste-6-launches-liquid-glass-redesign-for-macos-ios-and-ipados/); Merlin Project published macOS 26/iOS 26 tips — [ProjectWizards blog](https://www.projectwizards.net/en/blog/2025/09/macos26-ios26-tips)

### Inferences
- CodeEdit (and its WelcomeWindow package) is the most directly reusable reference for the welcome/home window with recent documents; CircuitPro (which uses it) is a canvas-based open-source app worth screenshotting, though its repo was not fetched here.
- The SwiftUI infinite-canvas repos are implementation references (pan/zoom, grid) rather than polished UI references; for visual chrome, Sketch Copenhagen and Figma UI3 are stronger.

### Gaps
- No open-source macOS canvas app was found that publishes its Figma/Sketch design source files.
- CircuitPro's repository, license and screenshots were not verified (only referenced via WelcomeWindow's README).

## Key Question 6: Does pen.dev offer a macOS or desktop-app design system/template?

### Takeaway
pen.dev (Pencil) runs natively on macOS and can import Figma files, but no source mentions a macOS/desktop-app design system or template shipped with it; its built-in libraries are unnamed "default libraries" plus icon sets, so Apple's Figma kit would have to be imported via .fig.

### Cited Findings
- pen.dev is "an agentic canvas" that saves designs as `.pen` files next to code, connects to Claude Code, Codex, Cursor and others over MCP; "Import .fig files with layouts, styles and images. Or just copy/paste from Figma directly"; mentions "built-in industry standard design skills" without naming systems — [pen.dev](https://www.pen.dev/)
- Desktop apps for macOS (Apple Silicon and Intel), Windows, Linux; VS Code/Cursor extension; CLI requiring Node.js 22.19+ — [pen.dev docs: installation](https://docs.pen.dev/getting-started/installation); [pen.dev downloads](https://www.pen.dev/downloads)
- Design libraries: reusable `.lib.pen` component/variable collections imported via a Libraries tab; users "can also choose from the default libraries" (not named); no mention of Apple/macOS/iOS kits or desktop templates — [pen.dev docs: design libraries](https://docs.pen.dev/core-concepts/design-libraries); related doc "Build a small design system" — [docs.pen.dev/core-concepts/build-a-design-system](https://docs.pen.dev/core-concepts/build-a-design-system)
- Import/export: full Figma files via toolbar/File menu (desktop), individual Figma layers by copy/paste, PNG/JPEG/SVG, web pages via built-in browser (desktop only), built-in icon libraries (Material Symbols, Lucide, Feather, Phosphor); export HTML+Tailwind or HTML+CSS, PNG/JPEG/WEBP/PDF at 1x–3x, batch ZIP; Sketch import not mentioned — [pen.dev docs: import and export](https://docs.pen.dev/core-concepts/import-and-export)
- The `.pen` format "is just a JSON file" so agents can work with it natively — [pen.dev docs: AI integration](https://docs.pencil.dev/getting-started/ai-integration)
- A third-party review claims pen.dev "out of the box knows about popular component libraries like Shadcn/UI and Lunarus" (secondary source; not confirmed in official docs) — [uxmagic.ai review](https://uxmagic.ai/blog/pencil-dev-review)
- Workflow write-up combining Pencil.dev with Claude Code (Feb 2026) — [atalupadhyay.wordpress.com](https://atalupadhyay.wordpress.com/2026/02/25/pencil-dev-claude-code-workflow-from-design-to-production-code-in-minutes/)

### Inferences
- Realistic pen.dev workflow for this project: duplicate Apple's macOS 27 (or 26) Figma kit, export/download it as .fig, import into pen.dev, then save the needed components (toolbar, sidebar, inspector controls, window chrome) as a `.lib.pen` library for agent-driven design. Liquid Glass blur/refraction fidelity after import is unverified.

### Gaps
- pen.dev pricing tiers were not visible on the fetched pages (a Pricing link exists but content was not retrieved).
- The names of pen.dev's "default libraries" could not be confirmed from official docs; the Shadcn/Lunarus claim comes from a review site.
- Whether .fig import preserves Figma variables, component properties and glass effects from Apple's kit was not tested or documented.
