import AppKit
import Foundation

/// The one headless Chrome all Chromium viewports share (PLAN.md §5.2): started with the first of
/// them, from the installed Chrome (or Chromium, Edge, Brave), with a lasting profile so logins stay.
@MainActor
public final class ChromeBrowser {
    public static let shared = ChromeBrowser()

    /// Where Chrome's profile lives; tests use a temporary one.
    public var profileFolder = URL.applicationSupportDirectory.appending(path: "Viewportix/Chromium", directoryHint: .isDirectory)

    nonisolated static let candidates = [
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Chromium.app/Contents/MacOS/Chromium",
        "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
        "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
    ]

    /// The browser to start, or nil: the viewport shows "Chrome bulunamadı".
    nonisolated public static var executable: URL? {
        let home = URL.homeDirectory.path(percentEncoded: false)
        return (candidates + candidates.map { home + $0 })
            .first(where: FileManager.default.isExecutableFile(atPath:))
            .map { URL(filePath: $0) }
    }

    nonisolated public static var isAvailable: Bool { executable != nil }

    private var pid: pid_t = 0
    private var connection: CDPConnection?
    private var starting: Task<CDPConnection, Error>?
    /// "Chrome 141.0.7390.65", once started.
    public private(set) var version = "Chromium"

    private init() {
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { ChromeBrowser.shared.stop() }
        }
    }

    /// The browser connection, starting Chrome the first time.
    func connect() async throws -> CDPConnection {
        if let connection, !connection.isClosed { return connection }
        if let starting { return try await starting.value }
        let task = Task { try await start() }
        starting = task
        defer { starting = nil }
        let connection = try await task.value
        self.connection = connection
        return connection
    }

    private func start() async throws -> CDPConnection {
        guard let executable = Self.executable else { throw CDPConnection.Failure(description: "Chrome bulunamadı") }
        try FileManager.default.createDirectory(at: profileFolder, withIntermediateDirectories: true)
        stopLeftover()
        let portFile = profileFolder.appending(path: "DevToolsActivePort")
        try? FileManager.default.removeItem(at: portFile)

        // S5: one window per viewport needs nothing special here; the flags keep background windows
        // painting, give retina frames, and keep Chrome's updater from asking macOS to modify apps.
        let arguments = [
            "--headless=new", "--remote-debugging-port=0", "--user-data-dir=\(profileFolder.path(percentEncoded: false))",
            "--no-first-run", "--no-default-browser-check", "--disable-extensions", "--hide-scrollbars", "--mute-audio",
            "--force-device-scale-factor=2", "--disable-background-networking", "--disable-component-update",
            "--disable-background-timer-throttling", "--disable-renderer-backgrounding",
            "--disable-backgrounding-occluded-windows", "--disable-features=Translate,MediaRouter",
            "about:blank",
        ]
        pid = try Self.spawnDisclaimed(executable, arguments: arguments)

        for _ in 0..<400 {
            if let text = try? String(contentsOf: portFile, encoding: .utf8) {
                let lines = text.split(separator: "\n")
                if lines.count >= 2, let url = URL(string: "ws://127.0.0.1:\(lines[0])\(lines[1])") {
                    let connection = CDPConnection(url: url)
                    if let info = try? await connection.send("Browser.getVersion"),
                       let product = info["product"]?.stringValue {
                        // "HeadlessChrome/141.0.7390.65" → "Chrome 141.0.7390.65".
                        version = product.replacingOccurrences(of: "Headless", with: "").replacingOccurrences(of: "/", with: " ")
                    }
                    try await connection.send("Target.setDiscoverTargets", ["discover": true])
                    return connection
                }
            }
            try await Task.sleep(for: .milliseconds(25))
        }
        stop()
        throw CDPConnection.Failure(description: "Chrome başlamadı")
    }

    /// A Chrome left running by an earlier run of the app (crash, force quit) holds the profile;
    /// its pid is in the profile's SingletonLock link ("host-pid").
    private func stopLeftover() {
        let lock = profileFolder.appending(path: "SingletonLock").path(percentEncoded: false)
        guard let target = try? FileManager.default.destinationOfSymbolicLink(atPath: lock),
              let pid = target.split(separator: "-").last.flatMap({ Int32($0) }), pid > 0 else { return }
        kill(pid, SIGTERM)
        try? FileManager.default.removeItem(atPath: lock)
    }

    public func stop() {
        connection?.close()
        connection = nil
        if pid > 0 { kill(pid, SIGTERM) }
        pid = 0
    }

    /// Starts Chrome as its own "responsible process". Launched like a plain child, macOS charges
    /// what Chrome does to Viewportix: after a Chrome update, Chrome tidies its own app bundle and
    /// the user saw "Viewportix … uygulamaları değiştirmesi engellendi" (App Management, found
    /// live 2026-10-19). Terminal and editors launch tools the same way.
    private static func spawnDisclaimed(_ executable: URL, arguments: [String]) throws -> pid_t {
        var attributes: posix_spawnattr_t?
        posix_spawnattr_init(&attributes)
        defer { posix_spawnattr_destroy(&attributes) }
        posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSIGDEF | POSIX_SPAWN_SETSIGMASK))
        typealias Disclaim = @convention(c) (UnsafeMutablePointer<posix_spawnattr_t?>, Int32) -> Int32
        if let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "responsibility_spawnattrs_setdisclaim") {
            _ = unsafeBitCast(symbol, to: Disclaim.self)(&attributes, 1)
        }
        var files: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&files)
        defer { posix_spawn_file_actions_destroy(&files) }
        posix_spawn_file_actions_addopen(&files, 0, "/dev/null", O_RDONLY, 0)
        posix_spawn_file_actions_addopen(&files, 1, "/dev/null", O_WRONLY, 0)
        posix_spawn_file_actions_addopen(&files, 2, "/dev/null", O_WRONLY, 0)

        let path = executable.path(percentEncoded: false)
        let argv = ([path] + arguments).map { strdup($0) } + [nil]
        defer { argv.forEach { free($0) } }
        var pid: pid_t = 0
        let result = posix_spawn(&pid, path, &files, &attributes, argv, environ)
        guard result == 0 else { throw CDPConnection.Failure(description: "Chrome başlatılamadı (\(result))") }
        // Reap it when it exits, so no zombie stays behind.
        DispatchQueue.global(qos: .utility).async { var status: Int32 = 0; waitpid(pid, &status, 0) }
        return pid
    }
}
