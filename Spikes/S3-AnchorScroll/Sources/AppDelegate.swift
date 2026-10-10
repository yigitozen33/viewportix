import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var sync: SyncController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit S3", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        NSApp.mainMenu = NSMenu()
        NSApp.mainMenu?.addItem(appItem)

        sync = SyncController()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 820),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "S3 · Anchor scroll sync"
        window.contentViewController = sync
        window.setContentSize(NSSize(width: 1400, height: 820))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()

        if CommandLine.arguments.contains("--self-test") {
            Task { @MainActor in
                let passed = await SelfTest(sync: sync).run()
                exit(passed ? 0 : 1)
            }
        } else {
            Task { @MainActor in await sync.loadAll(Paths.fixture("long-page.html")) }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

enum Paths {
    private static let sources = URL(filePath: #filePath).deletingLastPathComponent()

    static let agent = sources.appending(path: "sync-agent.js")

    static func fixture(_ name: String) -> URL {
        sources
            .deletingLastPathComponent()  // S3-AnchorScroll
            .deletingLastPathComponent()  // Spikes
            .deletingLastPathComponent()  // repo root
            .appending(path: "Packages/ViewportixKit/Tests/Fixtures/\(name)")
    }
}
