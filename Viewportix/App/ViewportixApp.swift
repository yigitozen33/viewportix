import EngineCore
import SwiftUI

@main
struct ViewportixApp: App {
    init() {
        AppSettings.register()
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
            ProjectWindow(document: file.$document)
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

        CommandGroup(after: .newItem) {
            Button("Giriş Ekranı") { openWindow(id: HomeView.windowID) }
                .keyboardShortcut("0", modifiers: [.command, .shift])
        }

        CommandGroup(after: .saveItem) {
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
            Divider()
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
            Toggle("Senkron Açık", isOn: Binding(
                get: { workspace?.isSyncEnabled ?? false },
                set: { workspace?.isSyncEnabled = $0 }
            ))
            .keyboardShortcut("l", modifiers: [.command, .shift])
            .disabled(workspace == nil)
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
