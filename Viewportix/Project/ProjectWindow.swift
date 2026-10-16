import DesignSystem
import EngineCore
import ProjectModel
import SwiftUI

struct ProjectWindow: View {
    @Binding var document: ProjectDocument
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.undoManager) private var undoManager
    @Environment(\.openDocument) private var openDocument
    @State private var workspace: Workspace
    @State private var selectedPageID: Page.ID?
    /// CARD-06: the "Boyutu düzenle" popover under a card header.
    @State private var editingSize: ViewportSizeEditor?
    @State private var isBarMenuOpen = false
    @State private var isTooltipShown = false
    @State private var canvasWidth: CGFloat = 1000

    init(document: Binding<ProjectDocument>, sidebarVisible: Bool = true, railVisible: Bool? = nil, devicePickerOpen: Bool = false, settingsTab: SettingsTab? = nil) {
        _document = document
        _selectedPageID = State(initialValue: document.wrappedValue.project.selectedPageID)
        let workspace = Workspace()
        workspace.isSidebarVisible = sidebarVisible
        if let railVisible { workspace.isRailVisible = railVisible }
        workspace.isDevicePickerOpen = devicePickerOpen
        workspace.settingsTab = settingsTab
        _workspace = State(initialValue: workspace)
    }

    /// Sidebar · canvas · rail; no title bar (DESIGN.md §4 A, PLAN.md §3.8). Floating chrome sits on
    /// the canvas: device strip on top, collapsed header top left, bottom bar, rail handle.
    var body: some View {
        HStack(spacing: 0) {
            if workspace.isSidebarVisible {
                ProjectSidebar(
                    workspace: workspace,
                    pages: $document.project.pages,
                    selection: $selectedPageID,
                    addCurrentPage: addCurrentPage
                )
                .transition(.move(edge: .leading))
            }
            canvas
            if workspace.isRailVisible {
                InspectorRail(workspace: workspace)
                    .transition(.move(edge: .trailing))
            }
        }
        .onFullScreenChange { workspace.isFullScreen = $0 }
        .frame(minWidth: 1024, minHeight: 640)  // DESIGN.md §5.20 a
        .background(DesignTokens.Color.canvas)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .focusedSceneValue(\.workspace, workspace)
        .focusedSceneValue(\.projectActions, ProjectActions(addCurrentPage: addCurrentPage, selectPage: selectPage, arrangeCards: arrangeCards,
                                                         grouping: document.project.canvas.grouping, setGrouping: setGrouping))
        .onAppear {
            // Opening a project from Finder or Open Recent should not leave the home window behind.
            dismissWindow(id: HomeView.windowID)
            workspace.performCommand = { handle($0, $1) }
            workspace.reconcile(with: document.project.viewports)
            if let page = document.project.selectedPage {
                workspace.navigate(to: page.url)
            }
            #if DEBUG
            if PerfProbe.isRequested {
                Task { await PerfProbe.run(workspace) }
            } else if PerfProbe.isCaptureRequested {
                Task { await PerfProbe.runCapture(workspace) }
            }
            #endif
        }
        .onChange(of: document.project.viewports) { _, viewports in
            workspace.reconcile(with: viewports)
        }
        .onChange(of: selectedPageID) { _, id in
            document.project.selectedPageID = id
            guard let page = document.project.pages.first(where: { $0.id == id }),
                  workspace.currentURL.map({ !page.url.isSamePage(as: $0) }) ?? true else { return }
            workspace.navigate(to: page.url)
        }
    }
}

private extension ProjectWindow {
    var canvas: some View {
        CanvasView(workspace: workspace, grouping: document.project.canvas.grouping, collapsedGroups: document.project.canvas.collapsedGroups)
            .overlay {
                CardChromeLayer(workspace: workspace, command: handle, savePositions: savePositions,
                                toggleGroup: toggleGroup, closeGroup: closeGroup, saveSize: save, editingSize: $editingSize)
            }
            .overlay(alignment: .bottom) {
                // 28 pt gap measured in window-project-dark@2x.png; no spec value yet.
                VStack(spacing: 28) {
                    // The notice sits above the bottom bar and hides while a bar menu or tooltip is open.
                    if let notice = workspace.notice, !isBarMenuOpen, !isTooltipShown {
                        ToastCapsule(notice: notice, dismiss: workspace.dismissNotice)
                            .transition(.opacity)
                            .id(notice.id)
                    }
                    BottomBar(workspace: workspace, isMenuOpen: $isBarMenuOpen)
                        .onPreferenceChange(ChromeTooltipVisibleKey.self) { isTooltipShown = $0 }
                }
                .padding(.bottom, BottomBar.bottomInset)
            }
            .animation(.easeInOut(duration: DesignTokens.Motion.standard), value: workspace.notice)
            .overlay {
                if document.project.viewports.isEmpty {
                    ContentUnavailableView("Viewport yok", systemImage: "rectangle.dashed", description: Text("+ Cihaz ile ekle."))
                }
            }
            .overlay(alignment: .top) {
                DeviceStrip(workspace: workspace, maxWidth: stripMaxWidth, remove: removeViewport,
                            add: { addViewport(ViewportConfig(preset: $0)) },
                            addCustom: { addViewport(ViewportConfig(name: "Özel", size: $0)) },
                            collapsedGroups: document.project.canvas.collapsedGroups,
                            openGroup: openGroup)
                .padding(.top, DesignTokens.Space.s4)
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { canvasWidth = $0 }
            .onDrop(of: [.url, .fileURL], delegate: LinkDropDelegate(workspace: workspace, openDocument: openDocument))
            .overlay {
                // §5.20 g: a dragged link shows where it will open; dropping opens it in every viewport.
                if let address = workspace.droppingAddress {
                    ZStack {
                        Rectangle()
                            .strokeBorder(DesignTokens.Color.statusLeader, lineWidth: DesignTokens.Stroke.focus)
                        HStack(spacing: 10) {
                            ChromeSymbol("link", box: DesignTokens.Size.icon).foregroundStyle(DesignTokens.Color.statusLeader)
                            Text("Bu adresi aç")
                                .font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                                .foregroundStyle(DesignTokens.Color.inkPrimary)
                            Text(address)
                                .font(.system(size: DesignTokens.FontSize.label))
                                .foregroundStyle(DesignTokens.Color.inkSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .background(DesignTokens.Color.surfaceHeader, in: .capsule)
                        .overlay { Capsule().strokeBorder(DesignTokens.Color.statusLeader, lineWidth: DesignTokens.Stroke.hairline) }
                        .frame(maxWidth: 420)
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
            .animation(.linear(duration: DesignTokens.Motion.hover), value: workspace.droppingAddress)
            .overlay(alignment: .topLeading) {
                if !workspace.isSidebarVisible {
                    CollapsedSidebarHeader(workspace: workspace)
                        .padding(DesignTokens.Space.s4)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .trailing) {
                // RAIL-01: the settings panel slides over the canvas; the canvas stays put.
                if let tab = workspace.settingsTab {
                    SettingsPanel(
                        tab: Binding { tab } set: { workspace.settingsTab = $0 },
                        workspace: workspace,
                        close: { withAnimation(.easeOut(duration: DesignTokens.Motion.panel)) { workspace.settingsTab = nil } }
                    )
                    .padding(DesignTokens.Space.s4)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .overlay(alignment: .topTrailing) {
                if !workspace.isRailVisible {
                    RailHandle(workspace: workspace)
                        .padding(.top, DesignTokens.Space.s4)
                        .transition(.opacity)
                }
            }
    }

    /// The strip stays centred on the canvas and clear of the collapsed header capsule (16 + 396 + 16).
    var stripMaxWidth: CGFloat {
        let side: CGFloat = workspace.isSidebarVisible ? 32 : 428
        return max(canvasWidth - 2 * side, 200)
    }

    /// STRIP-08: the device joins the end of the canvas; the canvas fits (⌘1) once it is laid out.
    func addViewport(_ config: ViewportConfig) {
        withAnimation(.easeOut(duration: DesignTokens.Motion.panel)) { document.project.viewports.append(config) }
        DispatchQueue.main.async {
            workspace.canvas?.fit()
            workspace.selectedViewportID = config.id
        }
    }

    /// STRIP-02 / STRIP-06: the viewport closes; the others slide over. "iPad kapatıldı · Geri al"
    /// for 5 s, ⌘Z too (DESIGN.md §5.20 f).
    func removeViewport(_ id: ViewportID) {
        guard let index = document.project.viewports.firstIndex(where: { $0.id == id }) else { return }
        let removed = document.project.viewports[index]
        withAnimation(.easeOut(duration: DesignTokens.Motion.standard)) {
            _ = document.project.viewports.remove(at: index)
        }
        let restore = { [binding = $document] in
            guard !binding.wrappedValue.project.viewports.contains(where: { $0.id == removed.id }) else { return }
            let position = min(index, binding.wrappedValue.project.viewports.count)
            withAnimation(.easeOut(duration: DesignTokens.Motion.standard)) {
                binding.wrappedValue.project.viewports.insert(removed, at: position)
            }
        }
        undoManager?.registerUndo(withTarget: workspace) { _ in MainActor.assumeIsolated { restore() } }
        undoManager?.setActionName("\(removed.name) Kapat")
        workspace.show(Workspace.Notice(kind: .undo, text: "\(removed.name) kapatıldı", action: .init(title: "Geri al") {
            restore()
        }))
    }

    /// SIDEBAR-05 / ⌘D: the open address joins the page list, named after the page title.
    func addCurrentPage() {
        guard let url = workspace.currentURL else {
            workspace.focusAddress()
            return
        }
        if let existing = document.project.pages.first(where: { $0.url.isSamePage(as: url) }) {
            selectedPageID = existing.id
            return
        }
        let title = workspace.currentTitle.trimmingCharacters(in: .whitespaces)
        let page = Page(name: title.isEmpty ? (url.host() ?? url.absoluteString) : title, url: url)
        withAnimation(.easeOut(duration: DesignTokens.Motion.standard)) { document.project.pages.append(page) }
        selectedPageID = page.id
    }

    /// CARD-08: positions are written to the project, so the layout survives reopening.
    func savePositions(_ positions: [ViewportID: CanvasPoint]) {
        for index in document.project.viewports.indices {
            if let position = positions[document.project.viewports[index].id] {
                document.project.viewports[index].position = position
            }
        }
    }

    /// PW-02 Görünüm › Grupla.
    func setGrouping(_ grouping: Grouping) {
        withAnimation(.easeInOut(duration: DesignTokens.Motion.canvasPan)) {
            document.project.canvas.grouping = grouping
            document.project.canvas.collapsedGroups = []
        }
        DispatchQueue.main.async { workspace.canvas?.fit() }
    }

    /// PW-03: fold or open a group from its header.
    func toggleGroup(_ key: String) {
        withAnimation(.easeInOut(duration: DesignTokens.Motion.panel)) {
            if document.project.canvas.collapsedGroups.contains(key) {
                document.project.canvas.collapsedGroups.remove(key)
            } else {
                document.project.canvas.collapsedGroups.insert(key)
            }
        }
    }

    /// STRIP-12: the strip's folded-group chip opens the group and pans to it.
    func openGroup(_ key: String) {
        document.project.canvas.collapsedGroups.remove(key)
        DispatchQueue.main.async { workspace.canvas?.fitGroup(key) }
    }

    func closeGroup(_ key: String) {
        guard let group = workspace.groups.first(where: { $0.key == key }) else { return }
        withAnimation(.easeOut(duration: DesignTokens.Motion.standard)) {
            document.project.viewports.removeAll { group.members.contains($0.id) }
            document.project.canvas.collapsedGroups.remove(key)
        }
    }

    /// PW-01 Viewport › Kartları Diz: back to the automatic row.
    func arrangeCards() {
        for index in document.project.viewports.indices {
            document.project.viewports[index].position = nil
        }
    }

    /// ⇧⌘] / ⇧⌘[: next or previous page in the list.
    func selectPage(offset: Int) {
        let pages = document.project.pages
        guard !pages.isEmpty else { return }
        let current = pages.firstIndex { $0.id == selectedPageID } ?? (offset > 0 ? -1 : pages.count)
        selectedPageID = pages[min(max(current + offset, 0), pages.count - 1)].id
    }

    func handle(_ id: ViewportID, _ command: ViewportCommand) {
        guard let index = document.project.viewports.firstIndex(where: { $0.id == id }) else { return }
        switch command {
        case .remove:
            removeViewport(id)
        case .rotate:
            document.project.viewports[index].rotate()
        case .editSize:
            editingSize = ViewportSizeEditor(editing: document.project.viewports[index])
        case .toggleSync:
            document.project.viewports[index].isSyncEnabled.toggle()
        case .capture(let area):
            Task { await workspace.capture([id], area: area) }
        }
    }

    func save(_ editor: ViewportSizeEditor) {
        let size = ViewportSize(width: editor.width, height: editor.height)
        let name = editor.name.trimmingCharacters(in: .whitespaces)
        guard let id = editor.viewportID, let index = document.project.viewports.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: DesignTokens.Motion.panel)) {
            document.project.viewports[index].size = size
            if !name.isEmpty { document.project.viewports[index].name = name }
        }
    }
}

/// Project window actions the menu bar needs that change the document.
struct ProjectActions {
    let addCurrentPage: () -> Void
    let selectPage: (_ offset: Int) -> Void
    let arrangeCards: () -> Void
    let grouping: Grouping
    let setGrouping: (Grouping) -> Void
}

extension FocusedValues {
    @Entry var workspace: Workspace?
    @Entry var projectActions: ProjectActions?
}

/// Links dropped on the canvas open in every viewport (not added to the page list; ⌘D adds);
/// `.viewportix` files open as projects.
struct LinkDropDelegate: DropDelegate {
    let workspace: Workspace
    let openDocument: OpenDocumentAction

    func dropEntered(info: DropInfo) {
        workspace.droppingAddress = ""
        guard let provider = info.itemProviders(for: [.url, .fileURL]).first else { return }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            let text = url.map { $0.isFileURL ? $0.lastPathComponent : URLHistory.display($0) }
            Task { @MainActor in
                if workspace.droppingAddress != nil { workspace.droppingAddress = text ?? "" }
            }
        }
    }

    func dropExited(info: DropInfo) {
        workspace.droppingAddress = nil
    }

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.url, .fileURL])
    }

    func performDrop(info: DropInfo) -> Bool {
        workspace.droppingAddress = nil
        guard let provider = info.itemProviders(for: [.url, .fileURL]).first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            Task { @MainActor in
                if url.isFileURL, url.pathExtension == "viewportix" {
                    try? await openDocument(at: url)
                } else if url.scheme == "http" || url.scheme == "https" || url.isFileURL {
                    workspace.navigate(to: url)
                }
            }
        }
        return true
    }
}
