import AppKit
import DesignSystem
import EngineCore
import ProjectModel
import SwiftUI

/// The constant-size parts of every `ViewportCard`, drawn above the canvas at the cards' screen
/// frames (`Workspace.cardFrames`): the page itself scales with zoom, the chrome does not
/// (DESIGN.md §3.2; specs/ViewportCard.json, ViewportHoverStrip.json).
struct CardChromeLayer: View {
    @Bindable var workspace: Workspace
    let command: (ViewportID, ViewportCommand) -> Void
    /// Saves card positions after a drag (the whole layout is pinned once a card was moved).
    let savePositions: ([ViewportID: CanvasPoint]) -> Void
    /// Folds or opens a group (PW-03).
    var toggleGroup: (String) -> Void = { _ in }
    /// Closes every viewport in a group (group menu).
    var closeGroup: (String) -> Void = { _ in }
    let saveSize: (ViewportSizeEditor) -> Void
    @Binding var editingSize: ViewportSizeEditor?

    var body: some View {
        // The cards hang off a clear view of the canvas's size: a ZStack of them grows with cards
        // larger than the window (high zoom) and was then centred, shifting every header and ring
        // up and left (found in the live app at %118 after ⌘2).
        Color.clear
            .overlay(alignment: .topLeading) { cards }
            .overlay {
                // CARD-08: sky alignment guides while dragging.
                Canvas { context, _ in
                    for guide in workspace.dragGuides {
                        var path = Path()
                        path.move(to: guide.from)
                        path.addLine(to: guide.to)
                        context.stroke(path, with: .color(DesignTokens.Color.statusLeader), lineWidth: 1)
                    }
                }
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .clipped()
    }

    private var cards: some View {
        ZStack(alignment: .topLeading) {
            ForEach(workspace.groups, id: \.key) { group in
                if let frame = workspace.groupFrames[group.key] {
                    let isCollapsed = frame.isEmpty
                    let pad = CanvasController.groupPadding
                    GroupHeader(
                        group: group,
                        isCollapsed: isCollapsed,
                        width: isCollapsed ? nil : frame.width + pad.left + pad.right,
                        toggle: { toggleGroup(group.key) },
                        fit: { workspace.canvas?.fitGroup(group.key) },
                        close: { closeGroup(group.key) }
                    )
                    .offset(x: frame.minX - (isCollapsed ? 0 : pad.left), y: frame.minY - pad.top)
                }
            }
            ForEach(workspace.viewports) { config in
                if let frame = workspace.cardFrames[config.id] {
                    ViewportCardChrome(
                        config: config,
                        pageSize: frame.size,
                        engineVersion: workspace.session(for: config.id)?.engineVersion ?? "WebKit",
                        state: state(of: config),
                        hover: { workspace.cardHovered(config.id, $0) },
                        select: { workspace.selectedViewportID = config.id },
                        command: { command(config.id, $0) },
                        failureAction: { handle($0, for: config.id) },
                        drag: { dragged(config.id, $0) },
                        editor: editorBinding(for: config.id),
                        saveSize: saveSize
                    )
                    .offset(x: frame.minX, y: frame.minY - ViewportCardChrome.headerHeight)
                    // Overlapping cards: the one last dragged is in front, chrome and page alike; a card
                    // with its size popover open is above every other card's chrome.
                    .zIndex(editingSize?.viewportID == config.id ? 2 : workspace.frontCardID == config.id ? 1 : 0)
                }
            }
        }
    }

    /// Drag phases from a card header; nil translation ends the drag. Grouped canvases lay out
    /// automatically, so cards are not dragged there.
    private func dragged(_ id: ViewportID, _ translation: CGSize?) {
        guard let canvas = workspace.canvas, workspace.groups.isEmpty else { return }
        guard let translation else {
            let positions = canvas.endDrag()
            workspace.draggingID = nil
            workspace.dragGuides = []
            savePositions(positions)
            return
        }
        if workspace.draggingID != id {
            workspace.draggingID = id
            workspace.frontCardID = id
            workspace.selectedViewportID = id
            canvas.beginDrag(id)
        }
        // CARD-09: ⌥ turns alignment and snapping off.
        let snapping = !NSEvent.modifierFlags.contains(.option)
        workspace.dragGuides = canvas.dragCard(by: translation, snapping: snapping).map(canvas.screenGuide)
    }

    private func handle(_ action: ViewportCardChrome.FailureAction, for id: ViewportID) {
        switch action {
        case .retry: workspace.retryLoad(id)
        case .trust: if let failure = workspace.loadFailures[id] { workspace.trustCertificate(for: failure) }
        case .goBack: workspace.goBack(in: id)
        case .editAddress: workspace.focusAddress()
        }
    }

    private func state(of config: ViewportConfig) -> ViewportCardChrome.CardState {
        .init(
            failure: workspace.loadFailures[config.id],
            isDragging: workspace.draggingID == config.id,
            isLeader: workspace.leaderID == config.id,
            isSelected: workspace.selectedViewportID == config.id,
            isMissed: workspace.missedIDs.contains(config.id),
            isLoading: workspace.loadingIDs.contains(config.id),
            isSyncEnabled: config.isSyncEnabled,
            isHovered: workspace.hoveredViewportID == config.id
        )
    }

    private func editorBinding(for id: ViewportID) -> Binding<ViewportSizeEditor?> {
        Binding {
            editingSize?.viewportID == id ? editingSize : nil
        } set: {
            editingSize = $0
        }
    }
}

/// One card's chrome: header above the page, borders and rings around it, the warning note below,
/// the hover strip above the header's right end.
struct ViewportCardChrome: View {
    struct CardState: Equatable {
        var failure: LoadFailure?
        var isDragging = false
        var isLeader = false
        var isSelected = false
        var isMissed = false
        var isLoading = false
        var isSyncEnabled = true
        var isHovered = false
    }

    static let headerHeight = DesignTokens.Size.cardHeader

    let config: ViewportConfig
    let pageSize: CGSize
    let engineVersion: String
    let state: CardState
    let hover: (Bool) -> Void
    let select: () -> Void
    let command: (ViewportCommand) -> Void
    let failureAction: (FailureAction) -> Void
    /// Header drag: translation in screen points while moving, nil when released.
    let drag: (CGSize?) -> Void
    @Binding var editor: ViewportSizeEditor?

    enum FailureAction { case retry, trust, goBack, editAddress }
    let saveSize: (ViewportSizeEditor) -> Void

    @State private var isMenuOpen = false
    @State private var isCameraOpen = false
    @State private var isStripHovered = false
    @State private var cameraAnchor = MenuAnchor()

    var body: some View {
        VStack(spacing: 0) {
            header
            Color.clear
                .frame(width: pageSize.width, height: pageSize.height)
                .allowsHitTesting(false)
                .overlay {
                    if let failure = state.failure {
                        LoadFailureView(failure: failure, action: failureAction)
                            .clipped()
                            .transition(.opacity)
                    }
                }
                .overlay(alignment: .top) {
                    if state.isLoading { ProgressLine().allowsHitTesting(false) }
                }
            if state.isMissed {
                warningNote
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .strokeBorder(state.isLeader || state.isDragging ? DesignTokens.Color.statusLeader : DesignTokens.Color.line,
                              lineWidth: state.isLeader || state.isDragging ? DesignTokens.Stroke.leader : DesignTokens.Stroke.hairline)
                .allowsHitTesting(false)
        }
        .background {
            // Lifted while dragged (`window-project-dragging@2x.png`: #000000AA, y 18, blur 40).
            if state.isDragging {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .fill(.black.opacity(0.01))
                    .shadow(color: .black.opacity(0.67), radius: 20, y: 18)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            // CARD-02: 1.5 pt cream ring 3 pt outside the card, independent of the leader line.
            if state.isSelected {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card + DesignTokens.Stroke.selectionGap)
                    .strokeBorder(DesignTokens.Color.inkPrimary, lineWidth: DesignTokens.Stroke.selectionRing)
                    .padding(-(DesignTokens.Stroke.selectionGap + DesignTokens.Stroke.selectionRing))
                    .allowsHitTesting(false)
            }
        }
        .outside(.top, alignment: .trailing, gap: DesignTokens.Space.s2) {
            if (state.isHovered || isStripHovered) && editor == nil && !state.isDragging {
                ViewportHoverStrip(isSyncEnabled: state.isSyncEnabled, command: command)
                    .onHover { isStripHovered = $0; hover($0) }
                    .padding(.trailing, DesignTokens.Space.s1)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .topLeading) {
            if let editor {
                SizeEditorPopover(editor: editor) { saved in
                    saveSize(saved)
                    self.editor = nil
                } cancel: {
                    self.editor = nil
                }
                // `Size Popover`: 20 pt in from the card's left, 8 pt under its header.
                .offset(x: 20, y: Self.headerHeight + DesignTokens.Space.s2)
                .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .animation(.linear(duration: DesignTokens.Motion.hover), value: state)
        .animation(.easeOut(duration: DesignTokens.Motion.fast), value: editor?.id)
    }

    // MARK: Header

    /// Narrowing order (DESIGN.md §3.2): size goes first, then the name shortens in the middle.
    /// Below that (zoomed far out) the engine glyph, then the camera give way so the name stays
    /// readable — a deviation from "motor ve kamera asla gizlenmez", raised with the design side.
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            headerRow(showsSize: true, showsEngine: true, showsCamera: true)
            headerRow(showsSize: false, showsEngine: true, showsCamera: true, minimumName: 56)
            headerRow(showsSize: false, showsEngine: false, showsCamera: true, minimumName: 40)
            headerRow(showsSize: false, showsEngine: false, showsCamera: false)
        }
        .frame(width: pageSize.width, height: Self.headerHeight)
        .background(MenuAnchorView(anchor: cameraAnchor))
        .background(state.isLeader ? DesignTokens.Color.surfaceHeaderLeader : DesignTokens.Color.surfaceHeader,
                    in: UnevenRoundedRectangle(topLeadingRadius: DesignTokens.Radius.card, topTrailingRadius: DesignTokens.Radius.card))
        .contentShape(.rect)
        .onTapGesture(perform: select)
        .gesture(
            DragGesture(minimumDistance: 3, coordinateSpace: .global)
                .onChanged { drag($0.translation) }
                .onEnded { _ in drag(nil) }
        )
        .pointerStyle(state.isDragging ? .grabActive : .grabIdle)
        .onHover(perform: hover)
        .chromeContextMenu(isOpen: $isMenuOpen, menu: contextMenu)
    }

    private func headerRow(showsSize: Bool, showsEngine: Bool, showsCamera: Bool, minimumName: CGFloat = 0) -> some View {
        let padding = showsCamera ? DesignTokens.Space.s3 : DesignTokens.Space.s2
        return HStack(spacing: DesignTokens.Space.s2) {
            // ViewThatFits measures ideal widths: a row fits when at least `minimumName` of the name
            // shows next to its icons (0: the whole name).
            title(showsSize: showsSize)
                .frame(idealWidth: minimumName > 0 ? minimumName : nil, maxWidth: .infinity, alignment: .leading)
            if showsEngine {
                ChromeSymbol(asset: config.engine.glyph, box: DesignTokens.Size.iconSm)
                    .foregroundStyle(state.isLeader || state.isSelected ? DesignTokens.Color.statusLeader : DesignTokens.Color.inkSecondary)
                    .chromeTooltip(engineTitle, shortcut: osTitle)
                    .accessibilityLabel("Motor")
                    .accessibilityValue("\(engineTitle) · \(osTitle)")
            }
            if showsCamera { camera }
        }
        .padding(.horizontal, padding)
    }

    private func title(showsSize: Bool) -> some View {
        HStack(spacing: 6) {
            Text(config.name)
                .font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            if showsSize {
                Text(verbatim: "\(config.size.width)×\(config.size.height)")
                    .font(.system(size: DesignTokens.FontSize.caption).monospacedDigit())
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                    .lineLimit(1)
                    .fixedSize()
            }
            if !config.isSyncEnabled {
                ChromeSymbol("pause", box: DesignTokens.Size.iconSm)
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                    .chromeTooltip("Bu viewport için senkron kapalı")
            }
            if state.isMissed || state.failure != nil {
                ChromeSymbol("exclamationmark.triangle", box: DesignTokens.Size.iconSm)
                    .foregroundStyle(DesignTokens.Color.statusWarning)
                    .chromeTooltip(state.failure == nil ? "Element bu viewport'ta bulunamadı" : "Sayfa yüklenemedi")
            }
        }
    }

    @ViewBuilder
    private var camera: some View {
        if state.isLoading {
            ProgressView().controlSize(.small).frame(width: 16, height: 16)
        } else {
            Button {
                isCameraOpen = true
                // `Card Screenshot Chooser`: centred on the card, 6 pt under its header.
                cameraAnchor.show(cameraMenu(), edge: .bottom, alignment: .center, gap: 6) { isCameraOpen = false }
            } label: {
                ChromeSymbol("camera", box: DesignTokens.Size.icon)
                    .foregroundStyle(cameraColor)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .chromeTooltip("Ekran görüntüsü")
            .accessibilityLabel("Ekran görüntüsü al")
            .accessibilityHint("bu viewport")
        }
    }

    private var cameraColor: Color {
        if isCameraOpen { return DesignTokens.Color.inkPrimary }
        return state.isLeader ? DesignTokens.Color.statusLeader : DesignTokens.Color.inkSecondary
    }

    private var warningNote: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            ChromeSymbol("exclamationmark.triangle", box: DesignTokens.Size.iconSm)
            Text("Element bu viewport'ta bulunamadı")
                .font(.system(size: DesignTokens.FontSize.caption))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .foregroundStyle(DesignTokens.Color.statusWarning)
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        .frame(width: pageSize.width)
        .background(DesignTokens.Color.statusWarningBg,
                    in: UnevenRoundedRectangle(bottomLeadingRadius: DesignTokens.Radius.card, bottomTrailingRadius: DesignTokens.Radius.card))
        .transition(.opacity)
    }

    // MARK: Menus

    /// CARD-04: the bottom bar's chooser for this viewport only (`Card Screenshot Chooser`).
    private func cameraMenu() -> ChromeMenu {
        ChromeMenu(style: .chooser, width: 250, items: [
            .header("EKRAN GÖRÜNTÜSÜ · \(config.name)"),
            .button("Görünen alan", subtitle: "Ekrandaki kısım", symbol: "viewfinder") { command(.capture(.visible)) },
            .button("Tam sayfa", subtitle: "Sayfanın tamamı", symbol: "arrow.down.document") { command(.capture(.fullPage)) },
        ])
    }

    /// CARD-05 (`Card Context Menu`): Döndür ⌥⌘R · Boyutu düzenle… · Senkrondan çıkar · — · Motor ·
    /// — · Kaldır ⌫. Motor only shows the engine until switching arrives with Chromium (M4).
    private func contextMenu() -> ChromeMenu {
        ChromeMenu(width: 240, items: [
            .button("Döndür", shortcut: "⌥⌘R") { command(.rotate) },
            .button("Boyutu düzenle…") { command(.editSize) },
            .button(config.isSyncEnabled ? "Senkrondan çıkar" : "Senkrona kat") { command(.toggleSync) },
            .separator,
            .info("Motor", value: "\(engineTitle) ›"),
            .separator,
            .button("Kaldır", shortcut: "⌫", role: .destructive) { command(.remove) },
        ])
    }

    /// "WebKit 26.6" from "WebKit · Safari 26.6" (CARD-03).
    private var engineTitle: String {
        guard let version = engineVersion.split(separator: " ").last, version.first?.isNumber == true else {
            return config.engine.displayName
        }
        return "\(config.engine.displayName) \(version)"
    }

    private var osTitle: String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(os.majorVersion).\(os.minorVersion)"
    }
}

/// `Viewport/HoverStrip`: Senkrondan çıkar / Senkrona kat · Döndür · Kapat, above the card on hover.
struct ViewportHoverStrip: View {
    let isSyncEnabled: Bool
    let command: (ViewportCommand) -> Void

    var body: some View {
        HStack(spacing: 10) {
            StripButton(source: isSyncEnabled ? .asset("link.slash") : .system("link"),
                        label: isSyncEnabled ? "Senkrondan çıkar" : "Senkrona kat",
                        tint: isSyncEnabled ? DesignTokens.Color.inkSecondary : DesignTokens.Color.inkPrimary) { command(.toggleSync) }
            StripButton(source: .system("rectangle.portrait.rotate"), label: "Döndür", shortcut: "⌥⌘R") { command(.rotate) }
            StripButton(source: .system("xmark"), label: "Kapat", shortcut: "⌫") { command(.remove) }
        }
        .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
        .background(DesignTokens.Color.surfaceHeaderLeader, in: .capsule)
        .overlay { Capsule().strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline) }
    }

    private struct StripButton: View {
        let source: ChromeSymbol.Source
        let label: String
        var shortcut: String?
        var tint = DesignTokens.Color.inkSecondary
        let action: () -> Void
        @State private var isHovered = false

        var body: some View {
            Button(action: action) {
                ChromeSymbol(source, box: DesignTokens.Size.icon)
                    .foregroundStyle(isHovered ? DesignTokens.Color.inkPrimary : tint)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
            .chromeTooltip(label, shortcut: shortcut)
            .accessibilityLabel(label)
        }
    }
}

/// Loading: 3 pt `line` track under the header with an `ink/primary` segment sweeping across.
private struct ProgressLine: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle().fill(DesignTokens.Color.line)
                Rectangle()
                    .fill(DesignTokens.Color.inkPrimary)
                    .frame(width: min(120, proxy.size.width / 2))
                    .offset(x: phase * (proxy.size.width + 120) - 120)
            }
        }
        .frame(height: 3)
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { phase = 1 }
        }
    }
}

/// CARD-06 "Boyutu düzenle" popover under the header: Ad, Genişlik ⇄ Yükseklik, limits hint,
/// İptal / Kaydet. Out of limits: coral field border, Kaydet disabled.
struct SizeEditorPopover: View {
    @State var editor: ViewportSizeEditor
    let save: (ViewportSizeEditor) -> Void
    let cancel: () -> Void

    @FocusState private var focused: Field?
    private enum Field { case name, width, height }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s3) {
            field("Ad") {
                TextField("", text: $editor.name).focused($focused, equals: .name)
            }
            HStack(alignment: .bottom, spacing: DesignTokens.Space.s2) {
                field("Genişlik", invalid: !ViewportSize.widthRange.contains(editor.width), isNumber: true) {
                    TextField("", value: $editor.width, format: .number.grouping(.never)).focused($focused, equals: .width)
                }
                .frame(width: 90)
                Button {
                    (editor.width, editor.height) = (editor.height, editor.width)
                } label: {
                    // `Swap`: 13 pt icon on `surface/card`, 7 pt around.
                    ChromeSymbol("arrow.left.arrow.right", box: 13)
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                        .padding(7)
                        .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.badge))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .chromeTooltip("En ↔ boy")
                field("Yükseklik", invalid: !ViewportSize.heightRange.contains(editor.height), isNumber: true) {
                    TextField("", value: $editor.height, format: .number.grouping(.never)).focused($focused, equals: .height)
                }
                .frame(width: 90)
            }
            Text(verbatim: "\(ViewportSize.widthRange.lowerBound)–\(ViewportSize.widthRange.upperBound) × \(ViewportSize.heightRange.lowerBound)–\(ViewportSize.heightRange.upperBound) px")
                .font(.system(size: DesignTokens.FontSize.micro, design: .monospaced))
                .foregroundStyle(editor.isValid ? DesignTokens.Color.inkSecondary : DesignTokens.Color.statusWarning)
            HStack(spacing: DesignTokens.Space.s2) {
                Spacer()
                Button("İptal", action: cancel)
                    .buttonStyle(.plain)
                    .font(.system(size: DesignTokens.FontSize.label))
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                    .keyboardShortcut(.cancelAction)
                Button { save(editor) } label: {
                    Text("Kaydet")
                        .font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                        .foregroundStyle(DesignTokens.Color.accentInk)
                        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .background(DesignTokens.Color.accent, in: .rect(cornerRadius: DesignTokens.Radius.control))
                        .opacity(editor.isValid ? 1 : 0.4)
                }
                .buttonStyle(.plain)
                .disabled(!editor.isValid)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(14)
        .frame(width: 270)
        .chromeSurface(shadowOpacity: 0.4, shadowRadius: 12)
        .onAppear { focused = .width }
        .onKeyPress(.escape) { cancel(); return .handled }
    }

    /// `Field`: 10 pt label, 4 pt above a `surface/card` box (6 pt corners, 6/8 padding, 12 pt text;
    /// numbers in mono).
    private func field(_ label: String, invalid: Bool = false, isNumber: Bool = false, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s1) {
            Text(label)
                .font(.system(size: DesignTokens.FontSize.micro))
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            content()
                .textFieldStyle(.plain)
                .font(.system(size: DesignTokens.FontSize.label, design: isNumber ? .monospaced : .default))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.badge))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.badge)
                        .strokeBorder(invalid ? DesignTokens.Color.statusWarning : DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
                }
        }
    }
}

extension EngineKind {
    /// Custom symbols in Assets.xcassets (design/handoff/symbols/).
    var glyph: String {
        switch self {
        case .webKit: "engine.webkit"
        case .chromium: "engine.chromium"
        case .firefox: "engine.firefox"
        }
    }
}

/// "Sayfa yüklenemedi" in place of the page (`card-load-errors@2x.png`; CARD-10…12): icon, title,
/// message, mono code, action. The page's own 404/500 is not this; it shows as it is.
struct LoadFailureView: View {
    let failure: LoadFailure
    let action: (ViewportCardChrome.FailureAction) -> Void

    /// Full layout in a roomy card; zoomed far out the page area can be a few dozen points, so the
    /// view steps down (title + action, then icon + action, then icon) and never leaves the card.
    var body: some View {
        ViewThatFits {
            full
            compact(showsTitle: true)
            compact(showsTitle: false)
            icon
        }
        .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Color.surfaceCard)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: DesignTokens.Radius.card, bottomTrailingRadius: DesignTokens.Radius.card))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(message)")
    }

    private var full: some View {
        VStack(spacing: DesignTokens.Space.s2) {
            icon
                .padding(.bottom, DesignTokens.Space.s1)
            Text(title)
                .font(.system(size: DesignTokens.FontSize.title, weight: .semibold))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.system(size: DesignTokens.FontSize.body))
                .foregroundStyle(DesignTokens.Color.inkSecondary)
                .multilineTextAlignment(.center)
            Text(failure.code)
                .font(DesignTokens.Font.mono(DesignTokens.FontSize.caption))
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            buttons
                .padding(.top, DesignTokens.Space.s2)
            if failure.kind == .serverDown {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.mini)
                    Text("2 sn'de bir deneniyor…")
                        .font(.system(size: DesignTokens.FontSize.caption))
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                }
                .padding(.top, DesignTokens.Space.s1)
            }
        }
        .padding(EdgeInsets(top: 16, leading: 10, bottom: 4, trailing: 10))
        // ViewThatFits compares ideal sizes: chosen from ~180 pt up, where lines wrap by words.
        .frame(idealWidth: 180)
    }

    private func compact(showsTitle: Bool) -> some View {
        VStack(spacing: DesignTokens.Space.s2) {
            icon
            if showsTitle {
                Text(title)
                    .font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            ChromeIconButton(symbol: "arrow.clockwise", label: retryLabel, action: compactAction)
        }
        .frame(idealWidth: showsTitle ? 120 : 24)
    }

    private var retryLabel: String {
        switch failure.kind {
        case .certificate: "Bu oturumda güven"
        case .notFound: "Adresi düzenle"
        case .serverDown: "Şimdi dene"
        case .network, .other: "Yeniden dene"
        }
    }

    private func compactAction() {
        switch failure.kind {
        case .certificate: action(.trust)
        case .notFound: action(.editAddress)
        case .serverDown, .network, .other: action(.retry)
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch failure.kind {
        case .certificate:
            ChromeSymbol("exclamationmark.shield", box: 24).foregroundStyle(DesignTokens.Color.statusWarning)
        case .serverDown:
            ChromeSymbol("server.rack", box: 24).foregroundStyle(DesignTokens.Color.inkSecondary)
        case .notFound:
            ChromeSymbol(asset: "link.slash", box: 24).foregroundStyle(DesignTokens.Color.inkSecondary)
        case .network, .other:
            ChromeSymbol("wifi.slash", box: 24).foregroundStyle(DesignTokens.Color.inkSecondary)
        }
    }

    private var title: String {
        switch failure.kind {
        case .certificate: "Bağlantı güvenli değil"
        case .serverDown: "\(failure.hostLabel) yanıt vermiyor"
        case .notFound: "Adres bulunamadı"
        case .network, .other: "Sayfa açılamadı"
        }
    }

    private var message: String {
        switch failure.kind {
        case .certificate: "\(failure.hostLabel) sertifikası doğrulanamadı."
        case .serverDown: "Geliştirme sunucun çalışıyor mu?"
        case .notFound: "“\(failure.url.host() ?? failure.hostLabel)” adında bir site yok."
        case .network, .other: "İnternet bağlantısı yok ya da sunucu yanıt vermiyor."
        }
    }

    @ViewBuilder
    private var buttons: some View {
        switch failure.kind {
        case .certificate:
            HStack(spacing: DesignTokens.Space.s2) {
                secondaryButton("Geri dön") { action(.goBack) }
                secondaryButton("Bu oturumda güven") { action(.trust) }
            }
        case .serverDown:
            yellowButton("Şimdi dene") { action(.retry) }
        case .notFound:
            secondaryButton("Adresi düzenle") { action(.editAddress) }
        case .network, .other:
            yellowButton("Yeniden dene") { action(.retry) }
        }
    }

    private func secondaryButton(_ title: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Text(title)
                .font(.system(size: DesignTokens.FontSize.label))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .lineLimit(1)
                .fixedSize()
                .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .background(DesignTokens.Color.surfaceHeader, in: .rect(cornerRadius: DesignTokens.Radius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.control).strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
                }
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
    }

    private func yellowButton(_ title: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Text(title)
                .font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                .foregroundStyle(DesignTokens.Color.accentInk)
                .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .background(DesignTokens.Color.accent, in: .rect(cornerRadius: DesignTokens.Radius.control))
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
    }
}

/// A group's header on the canvas: "⌄ TELEFON 2" at the area's top left, ⋯ on hover (and right
/// click): Katla · Grubu sığdır · — · Gruptakileri kapat (DESIGN.md §5.20 i). Folded: a chip
/// "› TELEFON 2" (`window-project-groups-collapsed@2x.png`).
struct GroupHeader: View {
    let group: ViewportGroup
    let isCollapsed: Bool
    /// The open area's width (header row spans it); nil for the folded chip.
    let width: CGFloat?
    let toggle: () -> Void
    let fit: () -> Void
    let close: () -> Void

    @State private var isHovered = false
    @State private var isMenuOpen = false
    @State private var anchor = MenuAnchor()

    var body: some View {
        HStack(spacing: 6) {
            Button(action: toggle) {
                HStack(spacing: 6) {
                    ChromeSymbol(isCollapsed ? "chevron.right" : "chevron.down", box: 12)
                    Text(group.title.uppercased(with: Locale(identifier: "tr_TR")))
                        .font(.system(size: DesignTokens.FontSize.micro, weight: .semibold))
                        .tracking(0.8)
                    Text("\(group.members.count)")
                        .font(.system(size: DesignTokens.FontSize.micro))
                }
                .foregroundStyle(DesignTokens.Color.inkSecondary)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .chromeFocusRing(cornerRadius: 4)
            .accessibilityLabel("\(group.title) grubu")
            .accessibilityValue("\(group.members.count) cihaz; \(isCollapsed ? "katlı" : "açık")")
            if width != nil { Spacer(minLength: 0) }
            if isHovered || isMenuOpen {
                ChromeIconButton(symbol: "ellipsis", label: "Grup", box: 14) {
                    isMenuOpen = true
                    anchor.show(menu(), edge: .bottom, gap: 4) { isMenuOpen = false }
                }
                .background(MenuAnchorView(anchor: anchor))
            }
        }
        .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
        .frame(width: width, alignment: .leading)
        .background {
            if isCollapsed {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.window)
                    .fill(DesignTokens.Color.surfaceGroup)
                    .strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
            }
        }
        .contentShape(.rect)
        .onHover { isHovered = $0 }
        .chromeContextMenu(isOpen: $isMenuOpen, menu: menu)
    }

    /// Group menu (`Menu` beside the group header): Katla · Grubu sığdır · — · Gruptakileri kapat.
    private func menu() -> ChromeMenu {
        ChromeMenu(width: 200, items: [
            .button(isCollapsed ? "Aç" : "Katla", action: toggle),
            .button("Grubu sığdır", action: fit),
            .separator,
            .button("Gruptakileri kapat", role: .destructive, action: close),
        ])
    }
}
