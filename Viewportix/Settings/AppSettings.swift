import DeviceCatalog
import Foundation
import Observation

/// App-wide preferences (Ayarlar › Genel); applied at once, no save (SETTINGS-01).
enum AppSettings {
    static let syncOnStart = "syncOnStart"
    static let keepDrafts = "keepDrafts"
    static let screenshotFolder = "screenshotFolder"
    static let copyScreenshot = "copyScreenshot"
    static let screenshotScale = "screenshotScale"

    static func register() {
        UserDefaults.standard.register(defaults: [
            syncOnStart: true,
            keepDrafts: true,
            copyScreenshot: true,
            screenshotScale: 2,
            // DESIGN.md §4 / KOD-OTURUMU-ISLERI §10: on by default, so sounds don't overlap.
            Workspace.suspendMediaKey: true,
        ])
    }

    static var screenshotFolderURL: URL {
        UserDefaults.standard.string(forKey: screenshotFolder).map { URL(filePath: $0, directoryHint: .isDirectory) }
            ?? URL.picturesDirectory.appending(path: "Viewportix")
    }
}

/// The user's devices (`DeviceLibrary`), kept with the app and shared by every window.
@MainActor
@Observable
final class DeviceLibraryStore {
    static let shared = DeviceLibraryStore()

    var library: DeviceLibrary {
        didSet { UserDefaults.standard.set(try? JSONEncoder().encode(library), forKey: Self.key) }
    }

    private static let key = "deviceLibrary"

    private init() {
        library = UserDefaults.standard.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(DeviceLibrary.self, from: $0) } ?? DeviceLibrary()
    }
}

/// The home window's settings panel (⚙ / ⌘, with no project window in front; HOME-17).
@MainActor
@Observable
final class HomeSettingsPresenter {
    static let shared = HomeSettingsPresenter()
    var tab: SettingsTab?
}

/// A capsule for the home window from elsewhere: "İçe aktar…" in its settings panel, or a project
/// window that closed during a disk conflict (PW-07). Shown 5 s, or until replaced.
@MainActor
@Observable
final class HomeNotices {
    static let shared = HomeNotices()
    var notice: Workspace.Notice?

    func show(_ notice: Workspace.Notice) {
        self.notice = notice
        Task {
            try? await Task.sleep(for: .seconds(5))
            if self.notice?.id == notice.id { self.notice = nil }
        }
    }
}
