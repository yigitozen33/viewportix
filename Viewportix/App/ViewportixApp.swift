import AppKit
import EngineCore
import ProjectModel
import SwiftUI

@main
struct ViewportixApp: App {
    init() {
        AppSettings.register()
        // One project per window; window tabs (Show Tab Bar…) have no place here.
        NSWindow.allowsAutomaticWindowTabbing = false
        // HOME-08: drafts deleted more than 30 days ago go for good.
        ProjectFiles.drafts.purgeTrash()
        #if DEBUG
        DispatchQueue.main.async { PreviewSnapshots.runIfRequested() }
        #endif
    }

    var body: some Scene {
        Window("Viewportix", id: HomeView.windowID) {
            HomeView()
        }
        // Our own chrome (DESIGN.md §4, A): no title bar, system traffic lights stay.
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1040, height: 700)
        .defaultLaunchBehavior(.presented)

        DocumentGroup(newDocument: ProjectDocument()) { file in
            ProjectWindow(document: file.$document, fileURL: file.fileURL)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.suppressed)
        .defaultSize(width: 1440, height: 900)
        .commands {
            ViewportixCommands()
        }
    }
}

struct ViewportixCommands: Commands {
    @FocusedValue(\.workspace) private var workspace
    @FocusedValue(\.projectActions) private var projectActions
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Ayarlar…") {
                withAnimation(.easeOut(duration: 0.2)) {
                    if let workspace {
                        workspace.settingsTab = workspace.settingsTab == nil ? .general : nil
                    } else {
                        let presenter = HomeSettingsPresenter.shared
                        presenter.tab = presenter.tab == nil ? .general : nil
                    }
                }
            }
            .keyboardShortcut(",")
        }

        // New projects open as drafts on disk, not as in-memory "Untitled" documents (PLAN.md §3.5).
        CommandGroup(replacing: .newItem) {
            Button("Yeni") {
                let template = UserDefaults.standard.string(forKey: "homeTemplate").flatMap(ProjectTemplate.init(rawValue:)) ?? .default
                ProjectFiles.newDraft(Project(viewports: template.viewports))
            }
            .keyboardShortcut("n")
            Button("Aç…") { NSDocumentController.shared.openDocument(nil) }
                .keyboardShortcut("o")
            Button("Giriş Ekranı") { openWindow(id: HomeView.windowID) }
                .keyboardShortcut("0", modifiers: [.command, .shift])
        }

        // PW-06: ⌘S on a draft and ⇧⌘S Çoğalt go through our save sheet; no "Kaydedilsin mi?".
        CommandGroup(replacing: .saveItem) {
            Button("Kapat") { NSApp.keyWindow?.performClose(nil) }
                .keyboardShortcut("w")
            Button("Kaydet") { projectActions?.save() }
                .keyboardShortcut("s")
                .disabled(projectActions == nil)
            Button("Çoğalt") { projectActions?.duplicate() }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(projectActions == nil)
            Divider()
            Button("Ekran Görüntüsü Al") { capture(.visible) }
                .keyboardShortcut("s", modifiers: [.command, .option])
            Button("Tam Sayfa Ekran Görüntüsü Al") { capture(.fullPage) }
                .keyboardShortcut("s", modifiers: [.command, .option, .control])  // ⌥⇧⌘S is Save As
        }

        CommandGroup(after: .toolbar) {
            Button(workspace?.isSidebarVisible == false ? "Sidebar'ı Göster" : "Sidebar'ı Gizle") {
                withAnimation(.easeInOut(duration: 0.2)) { workspace?.isSidebarVisible.toggle() }
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
            .disabled(workspace == nil)
            Button("Senkron Kaydı") { workspace?.toggleDevPanel(.sync) }
                .keyboardShortcut("2", modifiers: [.command, .option])
                .disabled(workspace == nil)
            Button(workspace?.isRailVisible == false ? "Rayı Göster" : "Rayı Gizle") {
                withAnimation(.easeInOut(duration: 0.2)) { workspace?.isRailVisible.toggle() }
            }
            .keyboardShortcut("0", modifiers: [.command, .option])
            .disabled(workspace == nil)
            Divider()
            Button("Yakınlaştır") { workspace?.canvas?.zoomIn() }
                .keyboardShortcut("=")
            Button("Uzaklaştır") { workspace?.canvas?.zoomOut() }
                .keyboardShortcut("-")
            Button("Gerçek Boyut") { workspace?.canvas?.actualSize() }
                .keyboardShortcut("0")
            Button("Sığdır") { workspace?.canvas?.fit() }
                .keyboardShortcut("1")
            Button("Seçimi Sığdır") { workspace?.fitSelection() }
                .keyboardShortcut("2")
                .disabled(workspace?.selectedViewportID == nil)
            Divider()
            Picker("Grupla", selection: Binding(
                get: { projectActions?.grouping ?? .none },
                set: { projectActions?.setGrouping($0) }
            )) {
                Text("Yok").tag(Grouping.none)
                Text("Cihaz Türü").tag(Grouping.deviceType)
                Text("Motor").tag(Grouping.engine)
            }
            .disabled(projectActions == nil)
            Toggle("Arka Plandaki Viewport'larda Medyayı Duraklat", isOn: Binding(
                get: { workspace?.suspendsBackgroundMedia ?? false },
                set: { workspace?.suspendsBackgroundMedia = $0 }
            ))
            .disabled(workspace == nil)
            Divider()
        }

        CommandMenu("Viewport") {
            Button("Cihaz Ekle…") { workspace?.isDevicePickerOpen = true }
                .keyboardShortcut("n", modifiers: [.command, .option])
                .disabled(workspace == nil)
            // No shortcut: ⌥⌘D is the system's Dock shortcut (DESIGN.md §3.2.1).
            Button("Kartları Diz") { projectActions?.arrangeCards() }
                .disabled(projectActions == nil)
            Divider()
            // On the selected card (CARD-02); the same as its context menu and hover strip.
            Group {
                Button("Döndür") { workspace?.performOnSelection(.rotate) }
                    .keyboardShortcut("r", modifiers: [.command, .option])
                Button("Boyutu Düzenle…") { workspace?.performOnSelection(.editSize) }
                Button(workspace?.selectedViewport?.isSyncEnabled == false ? "Senkrona Kat" : "Senkrondan Çıkar") {
                    workspace?.performOnSelection(.toggleSync)
                }
                // ⌫ is handled by the canvas while no page or text field has the keyboard.
                Button("Kaldır") { workspace?.performOnSelection(.remove) }
            }
            .disabled(workspace?.selectedViewportID == nil)
            Divider()
            Toggle("Senkron Açık", isOn: Binding(
                get: { workspace?.isSyncEnabled ?? false },
                set: { workspace?.isSyncEnabled = $0 }
            ))
            .keyboardShortcut("l", modifiers: [.command, .shift])
            .disabled(workspace == nil)
            Divider()
            Group {
                Button("Sonraki Viewport") { workspace?.selectViewport(1) }
                    .keyboardShortcut(.tab, modifiers: .control)
                Button("Önceki Viewport") { workspace?.selectViewport(-1) }
                    .keyboardShortcut(.tab, modifiers: [.control, .shift])
            }
            .disabled(workspace?.viewports.isEmpty ?? true)
            // Seçimi Kaldır (Esc) is the canvas's: as a menu key it would take Esc from every field.
        }

        CommandMenu("Gezinme") {
            Button("Geri") { workspace?.goBack() }
                .keyboardShortcut("[")
            Button("İleri") { workspace?.goForward() }
                .keyboardShortcut("]")
            Button("Yenile") { workspace?.reload() }
                .keyboardShortcut("r")
            Button("Adres Çubuğu") { workspace?.focusAddress() }
                .keyboardShortcut("l")
            Divider()
            Button("Bu Sayfayı Listeye Ekle") { projectActions?.addCurrentPage() }
                .keyboardShortcut("d")
                .disabled(projectActions == nil)
            Button("Sonraki Sayfa") { projectActions?.selectPage(1) }
                .keyboardShortcut("]", modifiers: [.command, .shift])
                .disabled(projectActions == nil)
            Button("Önceki Sayfa") { projectActions?.selectPage(-1) }
                .keyboardShortcut("[", modifiers: [.command, .shift])
                .disabled(projectActions == nil)
        }
    }

    private func capture(_ area: SnapshotArea) {
        guard let workspace else { return }
        Task { await workspace.captureAll(area: area) }
    }
}
