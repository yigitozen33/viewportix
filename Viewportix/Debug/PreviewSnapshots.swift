#if DEBUG
import AppKit
import DesignSystem
import DeviceCatalog
import EngineCore
import ProjectModel
import SwiftUI

/// `--snapshots <folder>`: renders chrome previews to @2x PNGs and quits (Scripts/snapshots.sh).
/// Stands in for Xcode's preview canvas, which can't build the signed app target here ("No Accounts");
/// used for parity rounds (`docs/parity/`, design/handoff/PLAN.md stage 8). Views are drawn in an
/// off-screen window, so AppKit-backed parts (text fields, menu anchors) render as in the app.
@MainActor
enum PreviewSnapshots {
    static var folder: URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--snapshots"),
              CommandLine.arguments.indices.contains(index + 1) else { return nil }
        return URL(filePath: CommandLine.arguments[index + 1], directoryHint: .isDirectory)
    }

    private struct Entry {
        let name: String
        let size: CGSize?
        let defaults: [String: String]
        let view: AnyView

        init(_ name: String, size: CGSize? = nil, defaults: [String: String] = [:], _ view: some View) {
            self.name = name
            self.size = size
            self.defaults = defaults
            self.view = AnyView(view)
        }
    }

    private static let homeSize = CGSize(width: 1040, height: 700)
    private static let projectSize = CGSize(width: 1440, height: 900)

    /// Same four states as design/exports/card-load-errors@2x.png.
    private static var loadErrors: some View {
        let failures = [
            LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, url: URL(string: "https://marka.com")!),
            LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateHasBadDate, url: URL(string: "https://marka.test")!),
            LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, url: URL(string: "http://localhost:3000")!),
            LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost, url: URL(string: "https://marka.comm")!),
        ].compactMap(\.self)
        return VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 24) {
                ForEach(failures, id: \.self) { failure in
                    LoadFailureView(failure: failure) { _ in }
                        .frame(width: 218, height: 246)
                        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(DesignTokens.Color.line) }
                }
            }
            // Zoomed far out: the same failures in small page areas.
            HStack(alignment: .top, spacing: 24) {
                ForEach([CGSize(width: 56, height: 120), CGSize(width: 120, height: 160), CGSize(width: 160, height: 90)], id: \.width) { size in
                    LoadFailureView(failure: failures[0]) { _ in }
                        .frame(width: size.width, height: size.height)
                        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(DesignTokens.Color.line) }
                }
            }
        }
    }

    /// Cards placed by hand: the desktop under the phone, the tablet to the right.
    private static var positioned: Project {
        var project = sampleProject
        project.viewports[0].position = CanvasPoint(x: 64, y: 64)
        project.viewports[1].position = CanvasPoint(x: 1600, y: 64)
        project.viewports[2].position = CanvasPoint(x: 64, y: 1100)
        return project
    }

    /// The design's grouping sample: iPhone SE, iPhone 16 · iPad · Masaüstü.
    private static func grouped(collapsed: Set<String>) -> Project {
        var project = sampleProject
        project.viewports = ["iphone-se", "iphone-16", "ipad-air-11", "desktop"].compactMap(DeviceCatalog.preset(id:)).map { ViewportConfig(preset: $0) }
        project.canvas.grouping = .deviceType
        project.canvas.collapsedGroups = collapsed
        return project
    }

    private static var manyDevices: Project {
        var project = sampleProject
        project.viewports = ProjectTemplate.fullMatrix.viewports
        return project
    }

    /// The design's sample: Ana sayfa · Ürün (open) · Sepet · Ödeme on the fixture product page.
    private static var sampleProject: Project {
        let fixture = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Packages/ViewportixKit/Tests/Fixtures/sample-product.html")
        let base = URL(string: "https://marka.com")!
        let pages = [
            Page(name: "Ana sayfa", url: base.appending(path: "/")),
            Page(name: "Ürün", url: fixture),
            Page(name: "Sepet", url: base.appending(path: "sepet")),
            Page(name: "Ödeme", url: base.appending(path: "odeme")),
        ]
        let viewports = ["iphone-16", "ipad-air-11", "desktop"].compactMap(DeviceCatalog.preset(id:)).map { ViewportConfig(preset: $0) }
        return Project(pages: pages, selectedPageID: pages[1].id, viewports: viewports)
    }

    private static var entries: [Entry] {
        [
            Entry("BottomBar-syncOn", padded(bottomBar(syncOn: true))),
            Entry("BottomBar-syncOff", padded(bottomBar(syncOn: false))),
            Entry("BottomBar-zoom25", padded(bottomBar(syncOn: true, zoom: 0.25))),
            Entry("BottomBar-tooltip", padded(ChromeTooltip(title: "Sığdır", shortcut: "⌘1"))),
            Entry("toast-states", padded(toastStates)),
            Entry("action-buttons", padded(actionButtons)),
            Entry("window-home-dark", size: homeSize, defaults: ["homeLayout": "grid"], HomeView(store: RecentProjects(fixed: samples))),
            Entry("window-home-list", size: homeSize, defaults: ["homeLayout": "list"], HomeView(store: RecentProjects(fixed: samples + [missing]))),
            Entry("window-home-empty", size: homeSize, defaults: ["homeLayout": "grid"], HomeView(store: RecentProjects(fixed: []))),
            Entry("home-states", homeStates),
            Entry("window-project-dark", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: sampleProject)), railVisible: true)),
            Entry("window-project-sidebar-collapsed", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: sampleProject)), sidebarVisible: false, railVisible: true)),
            Entry("window-project-rail-hidden", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: sampleProject)), railVisible: false)),
            Entry("window-project-device-picker", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: sampleProject)), railVisible: true, devicePickerOpen: true)),
            Entry("window-project-settings-panel", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: sampleProject)), railVisible: true, settingsTab: .general)),
            Entry("window-project-settings-devices", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: sampleProject)), railVisible: true, settingsTab: .devices)),
            Entry("window-project-settings-account", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: sampleProject)), railVisible: true, settingsTab: .account)),
            Entry("card-load-errors", padded(loadErrors)),
            Entry("menus", padded(menus)),
            Entry("window-project-positioned", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: positioned)), railVisible: true)),
            Entry("window-project-groups", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: grouped(collapsed: []))), railVisible: true)),
            Entry("window-project-groups-collapsed", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: grouped(collapsed: ["phone"]))), railVisible: true)),
            Entry("window-project-many-devices", size: projectSize, ProjectWindow(document: .constant(ProjectDocument(project: manyDevices)), sidebarVisible: false, railVisible: true)),
        ]
    }

    /// The menus as in the design frames, one row highlighted as the pointer would (sample rows; the
    /// live menus are built where they open).
    private static var menus: some View {
        func menu(_ menu: ChromeMenu, highlighted: Int? = nil) -> some View {
            let state = ChromeMenuState(menu: menu)
            if let highlighted { state.highlighted = highlighted }
            return ChromeMenuView(state: state)
        }
        let action: () -> Void = {}
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                menu(ChromeMenu(style: .list, width: 220, items: [
                    .button("Aç", shortcut: "⏎", action: action), .button("Yeniden adlandır", shortcut: "Çift tık", action: action),
                    .button("URL'yi kopyala", shortcut: "⇧⌘C", action: action), .separator,
                    .button("Yukarı taşı", shortcut: "⌥⌘↑", action: action), .button("Aşağı taşı", shortcut: "⌥⌘↓", action: action), .separator,
                    .button("Kaldır", shortcut: "⌫", role: .destructive, action: action),
                ]))
                menu(ChromeMenu(width: 240, items: [
                    .button("Döndür", shortcut: "⌥⌘R", action: action), .button("Boyutu düzenle…", action: action),
                    .button("Senkrondan çıkar", action: action), .separator, .info("Motor", value: "WebKit 26.6 ›"), .separator,
                    .button("Kaldır", shortcut: "⌫", role: .destructive, action: action),
                ]), highlighted: 1)
                menu(ChromeMenu(width: 220, items: [
                    .button("Aç", symbol: "folder", shortcut: "↩", action: action),
                    .button("Yeniden adlandır", symbol: "pencil", shortcut: "⏎", action: action),
                    .button("Çoğalt", symbol: "doc.on.doc", shortcut: "⌘D", action: action), .separator,
                    .button("Finder'da göster", symbol: "folder", shortcut: "⌘⇧R", action: action),
                    .button("Dosya yolunu kopyala", symbol: "link", action: action), .separator,
                    .submenu("Kaldır", symbol: "trash", role: .destructive, ChromeMenu(items: [])),
                ]), highlighted: 7)
                menu(ChromeMenu(width: 260, items: [
                    .button("Listeden kaldır", subtitle: "Dosya diskte kalır", symbol: "text.badge.xmark", shortcut: "⌫", action: action),
                    .button("Çöp Sepeti'ne taşı", subtitle: "Finder'dan geri alınabilir", symbol: "trash", shortcut: "⌘⌫",
                            role: .destructive, action: action),
                ]))
            }
            HStack(alignment: .top, spacing: 0) {
                menu(ChromeMenu(width: 240, showsChecks: true, items: [
                    .button("Sığdır", shortcut: "⌘1", action: action), .button("Seçimi sığdır", shortcut: "⌘2", action: action), .separator,
                    .button("%25", action: action), .button("%50", action: action), .button("%100", isChecked: true, action: action),
                    .button("%200", action: action), .separator,
                    .button("Gerçek boyut", shortcut: "⌘0", action: action), .button("Yakınlaştır", shortcut: "⌘+", action: action),
                    .button("Uzaklaştır", shortcut: "⌘−", action: action),
                ]))
                menu(ChromeMenu(style: .chooser, width: 300, items: [
                    .header("EKRAN GÖRÜNTÜSÜ · 3 VIEWPORT"),
                    .button("Görünen alan", subtitle: "Her viewport'un şu an ekranda olan kısmı", symbol: "viewfinder", shortcut: "⌥⌘S", action: action),
                    .button("Tam sayfa", subtitle: "Her viewport'un sayfanın tamamı", symbol: "arrow.down.document", shortcut: "⌃⌥⌘S", action: action),
                    .separator, .footer("Panoya kopyala ✓ · 2× · ~/Pictures/Viewportix — Ayarlar'da", action: action),
                ]))
                menu(ChromeMenu(style: .chooser, width: 250, items: [
                    .header("EKRAN GÖRÜNTÜSÜ · iPhone 16"),
                    .button("Görünen alan", subtitle: "Ekrandaki kısım", symbol: "viewfinder", action: action),
                    .button("Tam sayfa", subtitle: "Sayfanın tamamı", symbol: "arrow.down.document", action: action),
                ]))
                menu(ChromeMenu(width: 200, items: [
                    .button("Katla", action: action), .button("Grubu sığdır", action: action), .separator,
                    .button("Gruptakileri kapat", role: .destructive, action: action),
                ]), highlighted: 0)
            }
        }
    }

    private static func padded(_ view: some View) -> some View {
        view.padding(24).background(DesignTokens.Color.canvas)
    }

    static func bottomBar(syncOn: Bool, zoom: Double = 1) -> some View {
        let workspace = Workspace()
        workspace.isSyncEnabled = syncOn
        workspace.zoom = zoom
        return BottomBar(workspace: workspace, isMenuOpen: .constant(false))
    }

    /// Same states as design/exports/toast-states@2x.png.
    private static var toastStates: some View {
        let notices: [Workspace.Notice] = [
            .init(kind: .progress, text: "Ekran görüntüsü alınıyor… 2 / 3"),
            .init(kind: .success, text: "Kaydedildi ve kopyalandı", action: .init(title: "Finder'da Göster") {}),
            .init(kind: .partialFailure, text: "Masaüstü yakalanamadı", action: .init(title: "Yeniden dene") {}),
            .init(kind: .failure, text: "Kaydedilemedi: disk dolu", action: .init(title: "Ayrıntılar") {}),
            .init(kind: .undo, text: "iPad kapatıldı", action: .init(title: "Geri al") {}),
            .init(kind: .info, text: "Bu sayfada senkron çalışmıyor", action: .init(title: "Neden?") {}),
        ]
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(notices) { ToastCapsule(notice: $0, dismiss: {}) }
        }
    }

    /// `Action/Primary`, `Action/Secondary` in their five states and `AI/Glyph` (motion-spec 1. bölüm).
    private static var actionButtons: some View {
        let states: [(String, ActionButtonPreviewState?, Bool)] = [
            ("normal", nil, true), ("üzerinde", .hovered, true), ("basılı", .pressed, true), ("odak", .focused, true), ("pasif", nil, false),
        ]
        func label(_ text: String) -> some View {
            Text(text).font(.system(size: DesignTokens.FontSize.micro)).foregroundStyle(DesignTokens.Color.inkSecondary)
        }
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(states, id: \.0) { name, state, enabled in
                HStack(spacing: 6) {
                    label(name).frame(width: 60, alignment: .leading)
                    ActionButton("Kabul", kind: .primary, key: "A") {}
                    ActionButton("Yoksay", key: "I") {}
                    ActionButton("Takip et", key: "T") {}
                    ActionButton("Göster", key: "⏎") {}
                    ActionButton("Kaydet", kind: .primary, key: "⏎", showsKey: false) {}
                    ActionButton("Diskteki sürümü aç") {}
                }
                .environment(\.actionButtonPreviewState, state)
                .disabled(!enabled)
            }
            HStack(spacing: 24) {
                ForEach([("çalışıyor", AIActivityGlyph.Phase.running), ("onay bekliyor", .paused), ("bitti", .done)], id: \.0) { name, phase in
                    VStack(spacing: 6) {
                        AIActivityGlyph(phase: phase).scaleEffect(3).frame(width: 36, height: 36)
                        AIActivityGlyph(phase: phase)
                        label(name)
                    }
                }
            }
        }
    }

    // MARK: Home samples (names and metas as in the design frames)

    private static func sample(_ name: String, hoursAgo: Double, presets: [String], pages: Int = 1) -> ProjectSummary {
        let url = URL(string: "https://marka.com")!
        let project = Project(
            pages: (0..<pages).map { Page(name: "Sayfa \($0 + 1)", url: url) },
            viewports: presets.compactMap(DeviceCatalog.preset(id:)).map { ViewportConfig(preset: $0) }
        )
        return ProjectSummary(url: URL(filePath: "/tmp/\(name).viewportix"), name: name,
                              modified: .now.addingTimeInterval(-hoursAgo * 3600), project: project, isMissing: false)
    }

    private static var samples: [ProjectSummary] {
        [
            sample("Marka A", hoursAgo: 2, presets: ["iphone-16", "ipad-air-11", "desktop"], pages: 4),
            sample("Marka B", hoursAgo: 26, presets: ["iphone-se", "iphone-16", "ipad-mini", "desktop", "laptop"], pages: 6),
        ]
    }

    private static var missing: ProjectSummary {
        ProjectSummary(url: URL(filePath: "/tmp/Marka C.viewportix"), name: "Marka C", modified: nil, project: nil, isMissing: true)
    }

    /// Same layout as design/exports/home-states@2x.png.
    private static var homeStates: some View {
        let card = samples[0]
        let draft = sample("Untitled", hoursAgo: 0.09, presets: ["iphone-16", "ipad-air-11", "desktop"])
        return VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 24) {
                URLBox(text: .constant(""), isInvalid: false) {}
                URLBox(text: .constant("https://marka.com/urun/keten-gomlek"), isInvalid: false) {}
            }
            URLBox(text: .constant("marka com/urun"), isInvalid: true) {}
            HStack(alignment: .top, spacing: 24) {
                ProjectCard(summary: card, action: {}, menu: { ChromeMenu(items: []) }).frame(width: 196)
                ProjectCard(summary: card, action: {}, menu: { ChromeMenu(items: []) }, forcesHover: true).frame(width: 196)
                ProjectCard(summary: draft, isDraft: true, action: {}, menu: { ChromeMenu(items: []) }).frame(width: 196)
                ProjectCard(summary: card, action: {}, menu: { ChromeMenu(items: []) }, forcesMenuOpen: true).frame(width: 196)
                ProjectCard(summary: missing, action: {}, menu: { ChromeMenu(items: []) }).frame(width: 196)
            }
            HStack(spacing: 24) {
                TemplateChip(template: .mobileFocused, isSelected: false) {}
                TemplateChip(template: .mobileFocused, isSelected: true) {}
                TemplateChip(template: .engineComparison, isSelected: false) {}
            }
        }
        .padding(24)
        .background(DesignTokens.Color.canvas)
        .preferredColorScheme(.dark)
    }

    // MARK: Rendering

    static func runIfRequested() {
        guard let folder else { return }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let defaults = UserDefaults(suiteName: "com.viewportix.snapshots")!
        // Sample windows write app preferences (rail, sidebar width, history); put the user's back after.
        let touched = ["railVisible", "sidebarWidth", "urlHistory"]
        let saved = touched.map { ($0, UserDefaults.standard.object(forKey: $0)) }
        for entry in entries {
            for (key, value) in entry.defaults { defaults.set(value, forKey: key) }
            let view = entry.view.defaultAppStorage(defaults).environment(\.colorScheme, .dark)
            guard let rep = render(view, size: entry.size) else {
                print("SNAPSHOT \(entry.name) failed")
                continue
            }
            let url = folder.appending(path: "\(entry.name)@2x.png")
            try? rep.representation(using: .png, properties: [:])?.write(to: url)
            print("SNAPSHOT \(entry.name) \(rep.pixelsWide)x\(rep.pixelsHigh) → \(url.path)")
        }
        for (key, value) in saved { UserDefaults.standard.set(value, forKey: key) }
        UserDefaults.standard.synchronize()
        exit(0)
    }

    private static func render(_ view: some View, size: CGSize?) -> NSBitmapImageRep? {
        let host = NSHostingView(rootView: view)
        let frame = CGRect(origin: .zero, size: size ?? host.fittingSize)
        host.frame = frame
        let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = host
        window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        window.orderFrontRegardless()
        // Let SwiftUI lay out, run onAppear and draw.
        RunLoop.main.run(until: Date().addingTimeInterval(size.map { $0.width > 1200 } == true ? 3 : 0.5))
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return nil }
        host.cacheDisplay(in: host.bounds, to: rep)
        window.orderOut(nil)
        // The window draws in the display's colour space; design exports are sRGB.
        return rep.converting(to: .sRGB, renderingIntent: .default) ?? rep
    }
}
#endif
