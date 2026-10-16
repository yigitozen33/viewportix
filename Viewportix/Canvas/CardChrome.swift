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
    let saveSize: (ViewportSizeEditor) -> Void
    @Binding var editingSize: ViewportSizeEditor?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.allowsHitTesting(false)
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
                        editor: editorBinding(for: config.id),
                        saveSize: saveSize
                    )
                    .offset(x: frame.minX, y: frame.minY - ViewportCardChrome.headerHeight)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
    }

    private func state(of config: ViewportConfig) -> ViewportCardChrome.CardState {
        .init(
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
    @Binding var editor: ViewportSizeEditor?
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
                .overlay(alignment: .top) {
                    if state.isLoading { ProgressLine().allowsHitTesting(false) }
                }
            if state.isMissed {
                warningNote
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .strokeBorder(state.isLeader ? DesignTokens.Color.statusLeader : DesignTokens.Color.line,
                              lineWidth: state.isLeader ? DesignTokens.Stroke.leader : DesignTokens.Stroke.hairline)
                .allowsHitTesting(false)
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
        .overlay(alignment: .topTrailing) {
            if (state.isHovered || isStripHovered) && editor == nil {
                ViewportHoverStrip(isSyncEnabled: state.isSyncEnabled, command: command)
                    .onHover { isStripHovered = $0; hover($0) }
                    .alignmentGuide(.top) { $0[.bottom] + DesignTokens.Space.s2 }
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
                .offset(x: 0, y: Self.headerHeight + DesignTokens.Space.s2)
                .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .animation(.linear(duration: DesignTokens.Motion.hover), value: state)
        .animation(.easeOut(duration: DesignTokens.Motion.fast), value: editor?.id)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            ViewThatFits(in: .horizontal) {
                title(showsSize: true)
                title(showsSize: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ChromeSymbol(asset: config.engine.glyph, box: DesignTokens.Size.iconSm)
                .foregroundStyle(state.isLeader || state.isSelected ? DesignTokens.Color.statusLeader : DesignTokens.Color.inkSecondary)
                .chromeTooltip(engineTitle, shortcut: osTitle)
                .accessibilityLabel("Motor")
                .accessibilityValue("\(engineTitle) · \(osTitle)")
            camera
        }
        .padding(.horizontal, DesignTokens.Space.s3)
        .frame(width: pageSize.width, height: Self.headerHeight)
        .background(state.isLeader ? DesignTokens.Color.surfaceHeaderLeader : DesignTokens.Color.surfaceHeader,
                    in: UnevenRoundedRectangle(topLeadingRadius: DesignTokens.Radius.card, topTrailingRadius: DesignTokens.Radius.card))
        .contentShape(.rect)
        .onTapGesture(perform: select)
        .onHover(perform: hover)
        .chromeContextMenu(isOpen: $isMenuOpen, menu: contextMenu)
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
            if state.isMissed {
                ChromeSymbol("exclamationmark.triangle", box: DesignTokens.Size.iconSm)
                    .foregroundStyle(DesignTokens.Color.statusWarning)
                    .chromeTooltip("Element bu viewport'ta bulunamadı")
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
                DispatchQueue.main.async {
                    cameraAnchor.popUpBelow(cameraMenu(), gap: 10)
                    isCameraOpen = false
                }
            } label: {
                ChromeSymbol("camera", box: DesignTokens.Size.icon)
                    .foregroundStyle(cameraColor)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .background(alignment: .bottomLeading) { MenuAnchorView(anchor: cameraAnchor).frame(width: 0, height: 0) }
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

    /// CARD-04: same chooser as the bottom bar, for this viewport only, under the camera.
    private func cameraMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(.sectionHeader(title: "EKRAN GÖRÜNTÜSÜ · \(config.name)"))
        menu.addItem(ActionMenuItem("Görünen alan", symbol: "viewfinder") { command(.capture(.visible)) })
        menu.addItem(ActionMenuItem("Tam sayfa", symbol: "arrow.down.document") { command(.capture(.fullPage)) })
        return menu
    }

    /// CARD-05: Döndür ⌥⌘R · Boyutu düzenle… · Senkrondan çıkar · — · Motor › · — · Kaldır ⌫.
    private func contextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(ActionMenuItem("Döndür", key: "r", modifiers: [.command, .option], symbol: "rectangle.portrait.rotate") { command(.rotate) })
        menu.addItem(ActionMenuItem("Boyutu düzenle…") { command(.editSize) })
        menu.addItem(ActionMenuItem(config.isSyncEnabled ? "Senkrondan çıkar" : "Senkrona kat") { command(.toggleSync) })
        menu.addItem(.separator())
        let engine = NSMenuItem(title: "Motor", action: nil, keyEquivalent: "")
        let engines = NSMenu()
        engines.autoenablesItems = false
        engines.addItem(ActionMenuItem(engineTitle, isChecked: true, isEnabled: false) {})
        engine.submenu = engines
        engine.isEnabled = false  // engine switching arrives with Chromium (M4)
        menu.addItem(engine)
        menu.addItem(.separator())
        let remove = ActionMenuItem("Kaldır", key: "\u{8}", modifiers: []) { command(.remove) }
        remove.attributedTitle = NSAttributedString(string: "Kaldır", attributes: [.foregroundColor: NSColor(DesignTokens.Color.statusWarning)])
        menu.addItem(remove)
        return menu
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
                field("Genişlik", invalid: !ViewportSize.widthRange.contains(editor.width)) {
                    TextField("", value: $editor.width, format: .number.grouping(.never)).focused($focused, equals: .width)
                }
                Button {
                    (editor.width, editor.height) = (editor.height, editor.width)
                } label: {
                    ChromeSymbol("arrow.left.arrow.right", box: DesignTokens.Size.iconSm)
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                        .frame(width: 26, height: 28)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .chromeTooltip("En ↔ boy")
                field("Yükseklik", invalid: !ViewportSize.heightRange.contains(editor.height)) {
                    TextField("", value: $editor.height, format: .number.grouping(.never)).focused($focused, equals: .height)
                }
            }
            Text("\(ViewportSize.widthRange.lowerBound)–\(ViewportSize.widthRange.upperBound) × \(ViewportSize.heightRange.lowerBound)–\(ViewportSize.heightRange.upperBound) px")
                .font(.system(size: DesignTokens.FontSize.caption))
                .foregroundStyle(editor.isValid ? DesignTokens.Color.inkSecondary : DesignTokens.Color.statusWarning)
            HStack(spacing: DesignTokens.Space.s2) {
                Spacer()
                ChromeButton(icon: .system("xmark"), title: "İptal", action: cancel)
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
        .background(DesignTokens.Color.surfaceHeader, in: .rect(cornerRadius: DesignTokens.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card).strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
        }
        .shadow(color: .black.opacity(0.4), radius: 12, y: 8)
        .onAppear { focused = .width }
        .onKeyPress(.escape) { cancel(); return .handled }
    }

    private func field(_ label: String, invalid: Bool = false, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s1) {
            Text(label)
                .font(.system(size: DesignTokens.FontSize.caption))
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            content()
                .textFieldStyle(.plain)
                .font(.system(size: DesignTokens.FontSize.body).monospacedDigit())
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
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
