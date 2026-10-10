import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var canvas: CanvasController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMenu()

        canvas = CanvasController()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 900),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "S1 · Canvas gestures"
        window.contentViewController = canvas
        window.setContentSize(NSSize(width: 1400, height: 900))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()

        if CommandLine.arguments.contains("--self-test") {
            Task { @MainActor in
                let passed = await SelfTest(canvas: canvas).run()
                exit(passed ? 0 : 1)
            }
        } else {
            Task { @MainActor in
                await canvas.loadAll(Fixtures.longPage)
                canvas.fit()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func makeMenu() -> NSMenu {
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit S1", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appItem = NSMenuItem()
        appItem.submenu = appMenu

        // Edit menu so ⌘C/⌘V/⌘A work inside web pages and the URL field.
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        let editItem = NSMenuItem()
        editItem.submenu = editMenu

        let menu = NSMenu()
        menu.addItem(appItem)
        menu.addItem(editItem)
        return menu
    }
}

enum Fixtures {
    /// Repo-relative fixtures, resolved at compile time so the spike needs no bundled resources.
    static let directory = URL(filePath: #filePath)
        .deletingLastPathComponent()  // Sources
        .deletingLastPathComponent()  // S1-CanvasGestures
        .deletingLastPathComponent()  // Spikes
        .deletingLastPathComponent()  // repo root
        .appending(path: "Packages/ViewportixKit/Tests/Fixtures")

    static let longPage = directory.appending(path: "long-page.html")
    static let spa = directory.appending(path: "spa.html")
}
