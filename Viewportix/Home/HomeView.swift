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

    @Environment(\.newDocument) private var newDocument
    @Environment(\.openDocument) private var openDocument
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var store: RecentProjects
    @State private var address = ""
    @State private var isAddressInvalid = false
    @State private var query = ""
    @State private var isDropTargeted = false
    @State private var settings = HomeSettingsPresenter.shared
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
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear { store.reload() }
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
                newDocument(ProjectDocument(project: Project(viewports: template.viewports)))
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
                    ProjectCard(summary: summary, isDraft: section == .drafts, action: { open(summary) }, menu: { menu(for: summary) })
                }
            }
            .transition(.opacity)
        } else {
            VStack(spacing: 2) {
                ProjectListHeader().padding(.bottom, DesignTokens.Space.s2)
                ForEach(listed, id: \.url) { summary in
                    ProjectRow(summary: summary, isDraft: section == .drafts, action: { open(summary) }, menu: { menu(for: summary) })
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
        newDocument(ProjectDocument(project: .new(url: url, template: template)))
        dismissWindow(id: Self.windowID)
    }

    /// HOME-04, HOME-12, HOME-13.
    private func open(_ summary: ProjectSummary) {
        if summary.isMissing {
            locate(summary)
        } else if let problem = summary.problem {
            FileProblemAlert.show(problem, for: summary.url)
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
                FileProblemAlert.show(ProjectSummary.read(url).problem ?? .unreadable, for: url)
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

    /// HOME-06, HOME-08: card and row context menu (also the ⋯ target).
    private func menu(for summary: ProjectSummary) -> NSMenu {
        let url = summary.url
        let menu = NSMenu()
        menu.autoenablesItems = false
        if summary.isMissing {
            menu.addItem(ActionMenuItem("Bul…") { locate(summary) })
            menu.addItem(.separator())
        } else {
            menu.addItem(ActionMenuItem("Aç", key: "\r", modifiers: []) { open(summary) })
        }
        // HOME-07 (in-place rename) is not built yet.
        menu.addItem(ActionMenuItem("Yeniden adlandır", isEnabled: false) {})
        menu.addItem(ActionMenuItem("Çoğalt", key: "d", isEnabled: !summary.isMissing) { try? store.duplicate(url) })
        menu.addItem(.separator())
        menu.addItem(ActionMenuItem("Finder'da göster", key: "r", modifiers: [.command, .shift], isEnabled: !summary.isMissing) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        })
        menu.addItem(ActionMenuItem("Dosya yolunu kopyala") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.path(percentEncoded: false), forType: .string)
        })
        menu.addItem(.separator())

        let remove = NSMenuItem(title: "Kaldır", action: nil, keyEquivalent: "")
        remove.attributedTitle = NSAttributedString(string: "Kaldır", attributes: [.foregroundColor: NSColor(DesignTokens.Color.statusWarning)])
        let submenu = NSMenu()
        let fromList = ActionMenuItem("Listeden kaldır", key: "\u{8}", modifiers: []) { store.removeFromList(url) }
        fromList.subtitle = "Dosya diskte kalır"
        submenu.addItem(fromList)
        if !summary.isMissing {
            let trash = ActionMenuItem("Çöp Sepeti'ne taşı", key: "\u{8}") { try? store.moveToTrash(url) }
            trash.subtitle = "Finder'dan geri alınabilir"
            submenu.addItem(trash)
        }
        remove.submenu = submenu
        menu.addItem(remove)
        return menu
    }
}

/// Search box in the projects header (HOME-10, HOME-11: Esc clears).
private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            ChromeSymbol("magnifyingglass", box: DesignTokens.Size.icon)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
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

/// HOME-13: system alert; only the text and buttons are ours (`home-file-errors@2x.png`).
@MainActor
enum FileProblemAlert {
    static func show(_ problem: ProjectSummary.ReadProblem, for url: URL) {
        let alert = NSAlert()
        let file = url.lastPathComponent
        switch problem {
        case .unreadable:
            alert.messageText = "“\(file)” açılamadı"
            // No drafts yet, so "Son taslağı aç" is not offered and "Tamam" is the default.
            alert.informativeText = "Dosya bozuk ya da eksik. Taslaklar açıksa son taslak kurtarılabilir."
            alert.addButton(withTitle: "Tamam")
            alert.addButton(withTitle: "Finder'da Göster")
            if alert.runModal() == .alertSecondButtonReturn {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        case .newerVersion(let version):
            alert.messageText = "“\(file)” bu sürümde açılamıyor"
            alert.informativeText = "Proje Viewportix'in daha yeni bir sürümüyle kaydedilmiş (dosya sürümü \(version)). Güncelleyip tekrar dene."
            // "Güncellemeleri Denetle" waits for the updater (distribution).
            alert.addButton(withTitle: "Tamam")
            alert.runModal()
        }
    }
}
