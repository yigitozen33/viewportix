import EngineCore
import SwiftUI

@main
struct ViewportixApp: App {
    init() {
        #if DEBUG
        DispatchQueue.main.async { PreviewSnapshots.runIfRequested() }
        #endif
    }

    var body: some Scene {
        Window("Viewportix", id: HomeView.windowID) {
            HomeView()
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.presented)

        DocumentGroup(newDocument: ProjectDocument()) { file in
            ProjectWindow(document: file.$document)
        }
        .defaultLaunchBehavior(.suppressed)
        .defaultSize(width: 1440, height: 900)
        .commands {
            ViewportixCommands()
        }
    }
}

struct ViewportixCommands: Commands {
    @FocusedValue(\.workspace) private var workspace
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
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
        }
    }

    private func capture(_ area: SnapshotArea) {
        guard let workspace else { return }
        Task { await workspace.captureAll(area: area) }
    }
}
