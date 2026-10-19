import DesignSystem
import EngineCore
import ProjectModel
import SwiftUI
import UniformTypeIdentifiers

struct ProjectWindow: View {
    @Binding var document: ProjectDocument
    /// The package on disk; in the drafts folder until the project is saved (PLAN.md §3.5).
    var fileURL: URL?
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
    /// PW-06: our save sheet (⌘S on a draft, ⇧⌘S Çoğalt).
    @State private var saveRequest: SaveRequest?
    @State private var windowAnchor = WindowAnchor()
    @State private var thumbnailTask: Task<Void, Never>?
    @State private var thumbnailDate = Date.distantPast
    /// PW-07: the file changed elsewhere while this window has unsaved changes.
    @State private var isDiskConflict = false

    init(document: Binding<ProjectDocument>, fileURL: URL? = nil, sidebarVisible: Bool = true, railVisible: Bool? = nil, devicePickerOpen: Bool = false, settingsTab: SettingsTab? = nil) {
        _document = document
        self.fileURL = fileURL
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
            VStack(spacing: 0) {
                if isDiskConflict {
                    DiskChangeStrip(openDisk: revertToDisk, keepMine: keepMine)
                        .transition(.move(edge: .top))
                }
                canvas
            }
            .clipped()
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
                                                         grouping: document.project.canvas.grouping, setGrouping: setGrouping,
                                                         save: requestSave, duplicate: requestDuplicate))
        .background(WindowAnchorView(anchor: windowAnchor))
        .chromeSheet(item: $saveRequest, width: SaveProjectSheet.width) { request in
            SaveProjectSheet(request: request) { try await performSave(request, $0) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { note in
            guard let window = note.object as? NSWindow, window === windowAnchor.window else { return }
            checkDisk()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Coming back to the app leaves the key window key: no notification above.
            if windowAnchor.window?.isKeyWindow == true { checkDisk() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { note in
            guard let window = note.object as? NSWindow, window === windowAnchor.window else { return }
            ProjectFiles.discardIfDraftsAreNotKept(fileURL)
        }
        .onChange(of: workspace.isLoading) { _, loading in
            if !loading { scheduleThumbnail() }
        }
        .onChange(of: document.project.viewports) { scheduleThumbnail() }
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
                // Centred on the canvas while it fits; past the collapsed header capsule it moves
                // right instead of overflowing early (found in the live app: "+6" with room to spare).
                HStack(spacing: 0) {
                    Spacer(minLength: stripLeadingRoom)
                    DeviceStrip(workspace: workspace, maxWidth: stripMaxWidth, remove: removeViewport,
                                add: { addViewport(ViewportConfig(preset: $0)) },
                                addCustom: { addViewport(ViewportConfig(name: "Özel", size: $0)) },
                                collapsedGroups: document.project.canvas.collapsedGroups,
                                openGroup: openGroup)
                    Spacer(minLength: Self.stripTrailingRoom)
                }
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
    /// Room left of the strip: the collapsed header capsule takes the canvas's top left.
    var stripLeadingRoom: CGFloat { workspace.isSidebarVisible ? Self.stripTrailingRoom : 428 }
    static let stripTrailingRoom: CGFloat = 32

    var stripMaxWidth: CGFloat {
        max(canvasWidth - stripLeadingRoom - Self.stripTrailingRoom, 200)
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

    // MARK: Saving (PW-06, PW-09)

    var isDraft: Bool { fileURL.map(ProjectFiles.drafts.isDraft) ?? true }

    /// The page title ("Keten Gömlek"), else the host; what the save sheet suggests.
    var suggestedName: String {
        let title = workspace.currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = title.isEmpty ? (workspace.currentURL?.host() ?? document.project.selectedPage?.name ?? "Adsız") : title
        return String(name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-").prefix(80))
    }

    /// ⌘S: a draft gets our save sheet; a saved project just saves.
    func requestSave() {
        if isDraft {
            saveRequest = SaveRequest(mode: .save, name: suggestedName)
            return
        }
        guard let nsDocument = ProjectFiles.document(for: windowAnchor.window), let url = nsDocument.fileURL else { return }
        Task {
            await refreshThumbnail()
            do {
                try await nsDocument.save(to: url, ofType: nsDocument.fileType ?? UTType.viewportixProject.identifier, for: .saveOperation)
            } catch {
                showSaveError(error, name: url.deletingPathExtension().lastPathComponent)
            }
        }
    }

    /// ⇧⌘S Çoğalt: "<ad> kopya" in our sheet, written next to nothing yet, opened in its own window.
    func requestDuplicate() {
        let name = isDraft ? suggestedName : (fileURL?.deletingPathExtension().lastPathComponent ?? suggestedName)
        saveRequest = SaveRequest(mode: .duplicate, isDraft: isDraft, name: "\(name) kopya")
    }

    func performSave(_ request: SaveRequest, _ options: ProjectFiles.SaveOptions) async throws {
        await refreshThumbnail()
        do {
            switch request.mode {
            case .duplicate:
                try ProjectFiles.duplicate(document.project, thumbnail: document.thumbnail, options: options)
            case .save:
                guard let nsDocument = ProjectFiles.document(for: windowAnchor.window) else { return }
                document.project.includesThumbnail = options.includesThumbnail
                // The binding reaches the system document on the next turn of the run loop.
                try await Task.sleep(for: .milliseconds(50))
                try await ProjectFiles.save(nsDocument, options: options)
            }
        } catch {
            showSaveError(error, name: options.name, duplicating: request.mode == .duplicate)
            throw error
        }
    }

    /// PW-09: "“<ad>” kaydedilemedi" with our texts; disk full → Yeniden Dene, no permission →
    /// Farklı Yere Kaydet….
    func showSaveError(_ error: Error, name: String, duplicating: Bool = false) {
        let code = duplicating && ErrorCode.writing(error) == .writeFailed ? .duplicateFailed : ErrorCode.writing(error)
        let kept = isDraft ? "değişiklikler taslakta duruyor" : "değişiklikler pencerede duruyor"
        let window = windowAnchor.window
        switch code {
        case .diskFull:
            ErrorAlert.show(code, title: "“\(name)” kaydedilemedi", message: "Diskte yer kalmadı. Yer açıp yeniden deneyin; \(kept).",
                            buttons: [.init(title: "Yeniden Dene") { duplicating ? requestDuplicate() : requestSave() }, .init(title: "Vazgeç")],
                            in: window)
        case .writePermission:
            ErrorAlert.show(code, title: "“\(name)” kaydedilemedi", message: "Bu klasöre yazma izni yok; \(kept).",
                            buttons: [.init(title: "Farklı Yere Kaydet…") {
                                saveRequest = SaveRequest(mode: duplicating ? .duplicate : .save, isDraft: isDraft, name: name)
                            }, .init(title: "Vazgeç")], in: window)
        default:
            ErrorAlert.show(code, title: "“\(name)” kaydedilemedi", message: "\(error.localizedDescription) Değişiklikler kaybolmadı; \(kept).",
                            buttons: [.init(title: "Tamam")], in: window)
        }
    }

    // MARK: File changed on disk (PW-07)

    /// When the window comes forward: a newer file on disk reloads quietly, unless this window has
    /// changes of its own; then the strip asks which one stays.
    func checkDisk() {
        guard let nsDocument = ProjectFiles.document(for: windowAnchor.window), let url = nsDocument.fileURL,
              let known = nsDocument.fileModificationDate,
              let onDisk = ProjectFiles.lastModified(url), onDisk.timeIntervalSince(known) > 1 else { return }
        // Leaving the app autosaves, so changes not yet written are the only ones the disk can beat.
        if nsDocument.hasUnautosavedChanges {
            withAnimation(Motion.curve(Motion.strip)) { isDiskConflict = true }
        } else {
            revertToDisk()
        }
    }

    /// "Diskteki sürümü aç": this window's changes go, the file's version comes in.
    func revertToDisk() {
        guard let nsDocument = ProjectFiles.document(for: windowAnchor.window), let url = nsDocument.fileURL else { return }
        do {
            try nsDocument.revert(toContentsOf: url, ofType: nsDocument.fileType ?? UTType.viewportixProject.identifier)
            withAnimation(Motion.curve(Motion.strip)) { isDiskConflict = false }
        } catch {
            ErrorAlert.show(ErrorCode.reading(error), title: "“\(url.deletingPathExtension().lastPathComponent)” yeniden yüklenemedi",
                            error: error, in: windowAnchor.window)
        }
    }

    /// "Benimkini tut": this window's version is written over the file.
    func keepMine() {
        guard let nsDocument = ProjectFiles.document(for: windowAnchor.window), let url = nsDocument.fileURL else { return }
        // The system refuses to save over a file changed elsewhere; take the package's date as seen.
        nsDocument.fileModificationDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        withAnimation(Motion.curve(Motion.strip)) { isDiskConflict = false }
        Task {
            do {
                try await nsDocument.save(to: url, ofType: nsDocument.fileType ?? UTType.viewportixProject.identifier, for: .saveOperation)
            } catch {
                showSaveError(error, name: url.deletingPathExtension().lastPathComponent)
            }
        }
    }

    // MARK: Thumbnail

    /// After pages finish loading or the device set changes, at most every 20 s.
    func scheduleThumbnail() {
        thumbnailTask?.cancel()
        thumbnailTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled, !workspace.isLoading, Date.now.timeIntervalSince(thumbnailDate) > 20 else { return }
            await refreshThumbnail()
        }
    }

    func refreshThumbnail() async {
        guard !document.project.viewports.isEmpty, let png = await workspace.thumbnail(for: document.project) else { return }
        thumbnailDate = .now
        guard png != document.thumbnail else { return }
        document.thumbnail = png
        // A thumbnail-only change doesn't count as an edit for SwiftUI's document; without this the
        // draft would keep its old picture until the next real change.
        ProjectFiles.document(for: windowAnchor.window)?.updateChangeCount(.changeDone)
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

/// PW-07 (`dialogs-save-alerts@2x.png` 4. bölüm, pen `Disk Change Strip`): 40 pt over the canvas,
/// `surface/header` with a bottom hairline, caption 500, both choices grey and without keys (which
/// is right isn't known); drops in 200 ms.
struct DiskChangeStrip: View {
    let openDisk: () -> Void
    let keepMine: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Dosya başka yerde değişti")
                .font(.system(size: DesignTokens.FontSize.caption, weight: .medium))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
            Spacer(minLength: 0)
            ActionButton("Diskteki sürümü aç", action: openDisk)
            ActionButton("Benimkini tut", action: keepMine)
        }
        .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 10))
        .frame(height: 40)
        .background(DesignTokens.Color.surfaceHeader)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.Color.line).frame(height: DesignTokens.Stroke.hairline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Dosya başka yerde değişti")
    }
}

/// Project window actions the menu bar needs that change the document.
struct ProjectActions {
    let addCurrentPage: () -> Void
    let selectPage: (_ offset: Int) -> Void
    let arrangeCards: () -> Void
    let grouping: Grouping
    let setGrouping: (Grouping) -> Void
    /// Dosya › Kaydet (⌘S), Çoğalt (⇧⌘S).
    let save: () -> Void
    let duplicate: () -> Void
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
