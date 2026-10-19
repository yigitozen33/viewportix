import AppKit
import DesignSystem
import ProjectModel
import SwiftUI
import UniformTypeIdentifiers

/// Home window (DESIGN.md §3.1, `Home Window` frames): URL box + template chips, recent projects as a
/// grid or list, sidebar with Son / Taslaklar. Interactions HOME-01…18.
struct HomeView: View {
    static let windowID = "home"

    enum Section: String { case recent, drafts }
    enum Layout: String { case grid, list }

    @Environment(\.openDocument) private var openDocument
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var store: RecentProjects
    @State private var address = ""
    @State private var isAddressInvalid = false
    @State private var query = ""
    @State private var isDropTargeted = false
    @State private var settings = HomeSettingsPresenter.shared
    @State private var notices = HomeNotices.shared
    /// HOME-07: the project whose name is a field now.
    @State private var renaming: URL?
    /// HOME-08: the draft just deleted, until its capsule leaves.
    @State private var deleted: DeletedDraft?
    @Environment(\.undoManager) private var undoManager
    @AppStorage("homeTemplate") private var template = ProjectTemplate.default
    @AppStorage("homeSection") private var section = Section.recent
    @AppStorage("homeLayout") private var layout = Layout.grid

    init(store: RecentProjects = RecentProjects()) {
        _store = State(initialValue: store)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            content
        }
        .frame(minWidth: 1040, minHeight: 700)
        .background(DesignTokens.Color.canvas)
        .overlay {
            // HOME-18: dropping a .viewportix file opens it.
            if isDropTargeted {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.window)
                    .strokeBorder(DesignTokens.Color.statusLeader, lineWidth: DesignTokens.Stroke.focus)
                    .allowsHitTesting(false)
            }
        }
        .animation(.linear(duration: DesignTokens.Motion.hover), value: isDropTargeted)
        .dropDestination(for: URL.self) { urls, _ in
            let projects = urls.filter { $0.pathExtension == "viewportix" }
            projects.forEach(openProject)
            return !projects.isEmpty
        } isTargeted: { isDropTargeted = $0 }
        .overlay(alignment: .bottom) {
            if let deleted {
                UndoCapsule(text: "“\(deleted.name)” silindi", undo: { restore(deleted) }) {
                    withAnimation(Motion.curve(Motion.cardRemove)) { self.deleted = nil }
                }
                .id(deleted.id)
                .padding(.bottom, 36)
                .padding(.leading, 200)  // centred on the content, right of the sidebar
                .transition(.opacity)
            } else if let notice = notices.notice {
                ToastCapsule(notice: notice) { notices.notice = nil }
                    .id(notice.id)
                    .padding(.bottom, 36)
                    .padding(.leading, 200)
                    .transition(.opacity)
            }
        }
        .animation(Motion.curve(DesignTokens.Motion.standard), value: notices.notice)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear { store.reload() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in store.reload() }
    }

    struct DeletedDraft: Identifiable {
        let id = UUID()
        let name: String
        let restore: () -> Void
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s1) {
            sidebarRow(.recent, title: "Son", symbol: "clock.arrow.circlepath")
            sidebarRow(.drafts, title: "Taslaklar", symbol: "square.and.pencil")
            Spacer()
        }
        .padding(.top, 52)
        .padding(.horizontal, DesignTokens.Space.s3)
        .frame(width: 200)
        .trafficLights(leading: 15, centerY: 24)  // same row as the project window's sidebar
        .frame(maxHeight: .infinity)
        .background(DesignTokens.Color.surfaceBar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(DesignTokens.Color.line).frame(width: DesignTokens.Stroke.hairline)
        }
    }

    /// HOME-15: the choice is remembered.
    private func sidebarRow(_ target: Section, title: String, symbol: String) -> some View {
        let isSelected = section == target
        return Button {
            withAnimation(.linear(duration: DesignTokens.Motion.standard)) { section = target }
        } label: {
            HStack(spacing: 6) {
                ChromeSymbol(symbol, box: DesignTokens.Size.icon)
                    .foregroundStyle(isSelected ? DesignTokens.Color.inkPrimary : DesignTokens.Color.inkSecondary)
                Text(title)
                    .font(.system(size: DesignTokens.FontSize.body))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
            .background(isSelected ? DesignTokens.Color.surfaceHeader : .clear, in: .rect(cornerRadius: DesignTokens.Radius.control))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Content

    private var content: some View {
        VStack(spacing: 0) {
            topActions
                .zIndex(1)
            URLBox(text: $address, isInvalid: isAddressInvalid, onOpen: openAddress)
                .padding(.top, 89)
                .onChange(of: address) { old, new in addressChanged(from: old, to: new) }
            HStack(spacing: DesignTokens.Space.s2) {
                ForEach(ProjectTemplate.allCases, id: \.self) { item in
                    TemplateChip(template: item, isSelected: template == item) { template = item }
                        .chromeTooltip(item.isAvailable ? item.title : "Chromium ve Firefox ile gelecek")
                }
            }
            .padding(.top, DesignTokens.Space.s4)
            projectsHeader
                .padding(.top, DesignTokens.Space.s8)
            ScrollView {
                projects
                    .padding(.top, DesignTokens.Space.s6)
                    .padding(.bottom, DesignTokens.Space.s8)
            }
            .scrollIndicators(.automatic)
        }
        .padding(.horizontal, DesignTokens.Space.s8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .topTrailing) {
            // HOME-17: under the top row; the rest darkens slightly; no "Bu proje" section.
            if let tab = settings.tab {
                ZStack(alignment: .topTrailing) {
                    Color.black.opacity(0.25)
                        .onTapGesture { closeSettings() }
                    SettingsPanel(tab: Binding { tab } set: { settings.tab = $0 }, workspace: nil, close: closeSettings)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: DesignTokens.Space.s4, trailing: DesignTokens.Space.s4))
                }
                .padding(.top, 48)
                .transition(.opacity)
            }
        }
    }

    private func closeSettings() {
        withAnimation(.easeOut(duration: DesignTokens.Motion.panel)) { settings.tab = nil }
    }

    private var topActions: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            Spacer()
            ChromeButton(icon: .system("folder"), title: "Aç…") {
                NSDocumentController.shared.openDocument(nil)
            }
            .chromeTooltip("Aç…", shortcut: "⌘O", edge: .bottom)
            ChromeButton(icon: .system("plus"), title: "Yeni") {
                ProjectFiles.newDraft(Project(viewports: template.viewports))
                dismissWindow(id: Self.windowID)
            }
            .chromeTooltip("Yeni proje", shortcut: "⌘N", edge: .bottom)
            // HOME-17: ⚙ stays visible and pressed while the panel is open.
            ChromeButton(icon: .system("gearshape"), title: "Ayarlar", showsTitle: false, iconBox: DesignTokens.Size.icon,
                         insets: EdgeInsets(top: 7, leading: 7, bottom: 7, trailing: 7), isActive: settings.tab != nil) {
                withAnimation(.easeOut(duration: DesignTokens.Motion.panel)) { settings.tab = settings.tab == nil ? .general : nil }
            }
            .chromeTooltip("Ayarlar", shortcut: "⌘,", edge: .bottom)
        }
        .padding(.top, 9)
        .frame(height: 39, alignment: .top)
    }

    private var projectsHeader: some View {
        HStack(spacing: DesignTokens.Space.s3) {
            Text(section == .recent ? "SON PROJELER" : "TASLAKLAR")
                .font(.system(size: DesignTokens.FontSize.caption, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            Spacer()
            SearchField(text: $query)
            layoutToggle
        }
    }

    private var layoutToggle: some View {
        HStack(spacing: 0) {
            layoutSegment(.grid, symbol: "square.grid.2x2", label: "Izgara görünümü")
            layoutSegment(.list, symbol: "list.bullet", label: "Liste görünümü")
        }
        .background(DesignTokens.Color.surfaceCard)
        .clipShape(.rect(cornerRadius: DesignTokens.Radius.control))
    }

    /// HOME-09: grid ↔ list, remembered, 200 ms crossfade.
    private func layoutSegment(_ target: Layout, symbol: String, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: DesignTokens.Motion.panel)) { layout = target }
        } label: {
            ChromeSymbol(symbol, box: DesignTokens.Size.icon)
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .frame(width: 26, height: 27)
                .background(layout == target ? DesignTokens.Color.surfaceHeaderLeader : .clear)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .chromeTooltip(label, edge: .bottom)
        .accessibilityLabel(label)
        .accessibilityAddTraits(layout == target ? .isSelected : [])
    }

    private var listed: [ProjectSummary] {
        (section == .recent ? store.projects : store.drafts).filter { $0.matches(query) }
    }

    @ViewBuilder
    private var projects: some View {
        let all = section == .recent ? store.projects : store.drafts
        if all.isEmpty {
            EmptyProjects(section: section)
                .padding(.top, 40)
        } else if listed.isEmpty {
            NoSearchResults(query: query) { query = "" }
                .padding(.top, 40)
        } else if layout == .grid {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 236), spacing: DesignTokens.Space.s4)],
                      spacing: DesignTokens.Space.s4) {
                ForEach(listed, id: \.url) { summary in
                    ProjectCard(summary: summary, isDraft: store.isDraft(summary.url), action: { open(summary) }, menu: { menu(for: summary) },
                                isRenaming: renaming == summary.url, rename: { rename(summary, to: $0) })
                        // HOME-08: a deleted draft's card narrows in 150 ms; the grid closes up.
                        .transition(.scale(scale: 0.6, anchor: .center).combined(with: .opacity))
                }
            }
            .transition(.opacity)
        } else {
            VStack(spacing: 2) {
                ProjectListHeader().padding(.bottom, DesignTokens.Space.s2)
                ForEach(listed, id: \.url) { summary in
                    ProjectRow(summary: summary, isDraft: store.isDraft(summary.url), action: { open(summary) }, menu: { menu(for: summary) },
                               isRenaming: renaming == summary.url, rename: { rename(summary, to: $0) })
                        .transition(.opacity)
                }
            }
            .transition(.opacity)
        }
    }

    // MARK: Actions

    /// HOME-01: pasting completes the scheme; any edit clears the invalid state.
    private func addressChanged(from old: String, to new: String) {
        isAddressInvalid = false
        let pasted = old.isEmpty && new.count > 3
        if pasted, !new.contains("://"), let url = URL(addressBarInput: new) {
            address = url.absoluteString
        }
    }

    /// HOME-02: opens a project window with the chosen template; the home window closes.
    private func openAddress() {
        guard let url = URL(addressBarInput: address) else {
            isAddressInvalid = true
            return
        }
        ProjectFiles.newDraft(.new(url: url, template: template))
        dismissWindow(id: Self.windowID)
    }

    /// HOME-04, HOME-12, HOME-13.
    private func open(_ summary: ProjectSummary) {
        if summary.isMissing {
            locate(summary)
        } else if let problem = summary.problem {
            FileProblemAlert.show(problem, code: summary.errorCode, for: summary.url)
        } else {
            openProject(summary.url)
        }
    }

    private func openProject(_ url: URL) {
        Task {
            do {
                try await openDocument(at: url)
                dismissWindow(id: Self.windowID)
            } catch {
                let summary = ProjectSummary.read(url)
                FileProblemAlert.show(summary.problem ?? .unreadable, code: summary.errorCode ?? ErrorCode.reading(error), for: url)
            }
        }
    }

    /// HOME-08: the card goes at once; "“<ad>” silindi · Geri al ⌘Z" for 5 s; ⌘Z (Düzen › Geri Al) too.
    private func deleteDraft(_ summary: ProjectSummary) {
        do {
            var restore: () -> Void = {}
            try withAnimation(Motion.curve(Motion.cardRemove)) {
                restore = try store.deleteDraft(summary.url)
            }
            let deleted = DeletedDraft(name: summary.name, restore: restore)
            undoManager?.registerUndo(withTarget: store) { _ in
                MainActor.assumeIsolated { self.restore(deleted) }
            }
            undoManager?.setActionName("Taslağı Sil")
            withAnimation(Motion.curve(Motion.cardRemove)) { self.deleted = deleted }
        } catch {
            ErrorAlert.show(.draftTrashFailed, title: "“\(summary.name)” silinemedi", error: error)
        }
    }

    private func restore(_ draft: DeletedDraft) {
        guard deleted?.id == draft.id || deleted == nil else { return }
        withAnimation(.easeInOut(duration: DesignTokens.Motion.canvasPan)) { draft.restore() }
        withAnimation(Motion.curve(Motion.cardRemove)) { deleted = nil }
    }

    /// HOME-07: the package is renamed where it is; a name taken in the folder gets the file alert.
    private func rename(_ summary: ProjectSummary, to name: String?) {
        renaming = nil
        guard let name else { return }
        Task {
            do {
                _ = try await ProjectFiles.rename(summary.url, to: name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-"))
                store.reload()
            } catch {
                let code = ErrorCode.writing(error)
                ErrorAlert.show(code, title: "“\(summary.name)” yeniden adlandırılamadı",
                                message: code == .nameTaken ? "Bu klasörde “\(name)” adlı bir proje var." : error.localizedDescription,
                                buttons: [.init(title: "Tamam")])
            }
        }
    }

    /// HOME-12: "Bul…" picks the moved file; its new place replaces the old one in the list.
    private func locate(_ summary: ProjectSummary) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.viewportixProject]
        panel.directoryURL = summary.url.deletingLastPathComponent()
        panel.message = "“\(summary.name)” projesini bul"
        panel.prompt = "Seç"
        guard panel.runModal() == .OK, let found = panel.url else { return }
        store.relocate(summary.url, to: found)
    }

    /// HOME-06, HOME-08: card and row context menu (`window-home-context-menu@2x.png`); Kaldır opens
    /// its submenu with a line under each choice, so there is no confirmation dialog.
    private func menu(for summary: ProjectSummary) -> ChromeMenu {
        let url = summary.url
        if store.isDraft(url) {
            // Drafts: no submenu; "Taslağı sil" without asking, undone from the capsule or ⌘Z (K8).
            return ChromeMenu(width: 220, items: [
                .button("Aç", symbol: "folder", shortcut: "↩") { open(summary) },
                .button("Yeniden adlandır", symbol: "pencil", shortcut: "⏎") { renaming = url },
                .separator,
                .button("Taslağı sil", symbol: "trash", role: .destructive) { deleteDraft(summary) },
            ])
        }
        var items: [ChromeMenuItem] = []
        if summary.isMissing {
            items += [.button("Bul…", symbol: "magnifyingglass") { locate(summary) }, .separator]
        } else {
            items.append(.button("Aç", symbol: "folder", shortcut: "↩") { open(summary) })
        }
        items += [
            .button("Yeniden adlandır", symbol: "pencil", shortcut: "⏎", isEnabled: !summary.isMissing) { renaming = url },
            .button("Çoğalt", symbol: "doc.on.doc", shortcut: "⌘D", isEnabled: !summary.isMissing) { try? store.duplicate(url) },
            .separator,
            .button("Finder'da göster", symbol: "folder", shortcut: "⌘⇧R", isEnabled: !summary.isMissing) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            },
            .button("Dosya yolunu kopyala", symbol: "link") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.path(percentEncoded: false), forType: .string)
            },
            .separator,
        ]
        var remove: [ChromeMenuItem] = [
            .button("Listeden kaldır", subtitle: "Dosya diskte kalır", symbol: "text.badge.xmark", shortcut: "⌫") {
                store.removeFromList(url)
            },
        ]
        if !summary.isMissing {
            remove.append(.button("Çöp Sepeti'ne taşı", subtitle: "Finder'dan geri alınabilir", symbol: "trash",
                                  shortcut: "⌘⌫", role: .destructive) { try? store.moveToTrash(url) })
        }
        items.append(.submenu("Kaldır", symbol: "trash", role: .destructive, ChromeMenu(width: 260, items: remove)))
        return ChromeMenu(width: 220, items: items)
    }
}

/// Search box in the projects header (HOME-10, HOME-11: Esc clears).
private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            ChromeSymbol("magnifyingglass", box: DesignTokens.Size.icon)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
                .accessibilityHidden(true)
            TextField("", text: $text, prompt: Text("Ara").foregroundStyle(DesignTokens.Color.inkSecondary))
                .textFieldStyle(.plain)
                .font(.system(size: DesignTokens.FontSize.body))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .onKeyPress(.escape) {
                    guard !text.isEmpty else { return .ignored }
                    text = ""
                    return .handled
                }
                .accessibilityLabel("Projelerde ara")
        }
        .padding(.horizontal, 10)
        .frame(width: 200, height: 27)
        .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.control))
    }
}

/// "Henüz proje yok" with three faint ghost cards (`Home Window · Boş durum`).
private struct EmptyProjects: View {
    let section: HomeView.Section

    var body: some View {
        VStack(spacing: DesignTokens.Space.s4) {
            HStack(alignment: .top, spacing: 10) {
                ghost(width: 42, height: 67)
                ghost(width: 61, height: 71)
                ghost(width: 77, height: 46)
            }
            VStack(spacing: 6) {
                Text(section == .recent ? "Henüz proje yok" : "Henüz taslak yok")
                    .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                Text("Yukarıya bir URL yapıştır ya da bir .viewportix dosyası aç.")
                    .font(.system(size: DesignTokens.FontSize.body))
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func ghost(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(DesignTokens.Color.surfaceCard.opacity(0.5))
            .strokeBorder(DesignTokens.Color.line.opacity(0.5), lineWidth: DesignTokens.Stroke.hairline)
            .frame(width: width, height: height)
    }
}

/// HOME-10: no match for the search.
private struct NoSearchResults: View {
    let query: String
    let clear: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Space.s3) {
            ChromeSymbol("magnifyingglass", box: 24)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            Text("“\(query)” ile eşleşen proje yok")
                .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
            HStack(spacing: DesignTokens.Space.s2) {
                ChromeButton(icon: .system("xmark"), title: "Aramayı temizle", action: clear)
                Text("Esc")
                    .font(.system(size: DesignTokens.FontSize.caption))
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// HOME-13: system alert; only the text, buttons and the code line are ours (`home-file-errors@2x.png`,
/// `dialogs-save-alerts@2x.png` 2. bölüm).
@MainActor
enum FileProblemAlert {
    static func show(_ problem: ProjectSummary.ReadProblem, code: ErrorCode?, for url: URL) {
        let file = url.lastPathComponent
        switch problem {
        case .unreadable:
            var buttons: [ErrorAlert.Button] = []
            // "Son taslağı aç" when the project was saved from a draft that was kept.
            if let draft = DraftOrigins.draft(for: url) {
                buttons.append(.init(title: "Son taslağı aç") { ProjectFiles.open(draft) })
            }
            buttons += [
                .init(title: "Finder'da Göster") { NSWorkspace.shared.activateFileViewerSelecting([url]) },
                .init(title: "Vazgeç"),
            ]
            ErrorAlert.show(code ?? .readFailed, title: "“\(file)” açılamadı",
                            message: "Dosya bozuk ya da eksik. Taslaklar açıksa son taslak kurtarılabilir.", buttons: buttons)
        case .newerVersion(let version):
            // "Güncellemeleri Denetle" waits for the updater (distribution).
            ErrorAlert.show(code ?? .newerSchema, title: "“\(file)” bu sürümde açılamıyor",
                            message: "Proje Viewportix'in daha yeni bir sürümüyle kaydedilmiş (dosya sürümü \(version)). Güncelleyip tekrar dene.",
                            buttons: [.init(title: "Tamam")])
        }
    }
}
