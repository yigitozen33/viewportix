import AppKit
import Capture
import DeviceCatalog
import EngineCore
import Foundation
import Observation
import ProjectModel
import SyncCore
import WebKitEngine

/// Live state of one project window: engine sessions, sync, address bar and per-viewport indicators.
/// The document owns what is saved; the workspace owns what runs.
@MainActor
@Observable
final class Workspace {
    private(set) var viewports: [ViewportConfig] = []
    private(set) var leaderID: ViewportID?
    /// Viewports where the last mirrored click found no target; cleared after a few seconds.
    private(set) var missedIDs: Set<ViewportID> = []
    private(set) var currentURL: URL?
    private(set) var currentTitle = ""
    private(set) var isLoading = false
    /// Viewports whose page is loading (tab and card spinners).
    private(set) var loadingIDs: Set<ViewportID> = []
    /// The selected card (CARD-02): target of tab clicks and per-viewport shortcuts.
    var selectedViewportID: ViewportID?
    var addressText = ""
    var zoom: Double = 1
    var isSyncEnabled = true {
        didSet { coordinator.isEnabled = isSyncEnabled }
    }
    /// App-wide preference: media plays only in the viewport under the pointer. Off by default: on
    /// apple.com it made no measurable CPU difference (video decoding is hardware-accelerated) while it
    /// changes what follower viewports show (PLAN.md M2 "Performans").
    var suspendsBackgroundMedia: Bool {
        didSet {
            UserDefaults.standard.set(suspendsBackgroundMedia, forKey: Self.suspendMediaKey)
            coordinator.suspendsFollowerMedia = suspendsBackgroundMedia
        }
    }
    static let suspendMediaKey = "suspendBackgroundMedia"
    /// Transient status shown at the bottom of the window (screenshot progress and results).
    private(set) var notice: Notice?

    // MARK: Window chrome

    /// Sidebar shown; when hidden its header moves to the capsule at the canvas's top left (SIDEBAR-06).
    var isSidebarVisible = true
    /// App-wide preference (SIDEBAR-08): 200–360, default 240.
    var sidebarWidth: CGFloat {
        didSet { UserDefaults.standard.set(Double(sidebarWidth), forKey: Self.sidebarWidthKey) }
    }
    static let sidebarWidthRange: ClosedRange<CGFloat> = 200...360
    /// App-wide preference (RAIL-03); default shown.
    var isRailVisible: Bool {
        didSet { UserDefaults.standard.set(isRailVisible, forKey: Self.railVisibleKey) }
    }
    /// Incremented by ⌘L; the visible address field takes focus.
    private(set) var addressFocusRequest = 0
    /// Addresses opened in any project (app-wide), for the address field's SON menu.
    @ObservationIgnored let history = URLHistoryStore.shared

    func focusAddress() { addressFocusRequest += 1 }

    private static let sidebarWidthKey = "sidebarWidth"
    private static let railVisibleKey = "railVisible"

    @ObservationIgnored weak var canvas: CanvasController?
    @ObservationIgnored private let coordinator = SyncCoordinator()
    @ObservationIgnored private var sessions: [ViewportID: any EngineSession] = [:]

    init() {
        let width = UserDefaults.standard.object(forKey: Self.sidebarWidthKey) as? Double ?? 240
        sidebarWidth = min(max(CGFloat(width), Self.sidebarWidthRange.lowerBound), Self.sidebarWidthRange.upperBound)
        isRailVisible = UserDefaults.standard.object(forKey: Self.railVisibleKey) as? Bool ?? true
        suspendsBackgroundMedia = UserDefaults.standard.object(forKey: Self.suspendMediaKey) as? Bool ?? false
        coordinator.suspendsFollowerMedia = suspendsBackgroundMedia
        coordinator.onEvent = { [weak self] id, event in self?.handle(event, from: id) }
        coordinator.onResult = { [weak self] id, _, result in
            if result == .missed { self?.flagMissed(id) }
        }
    }

    func session(for id: ViewportID) -> (any EngineSession)? {
        sessions[id]
    }

    /// STRIP-01, STRIP-04, STRIP-05: select the viewport and pan the canvas to its card.
    func reveal(_ id: ViewportID) {
        selectedViewportID = id
        canvas?.reveal(id)
    }

    var syncStats: SyncStats { coordinator.stats }

    func resetSyncStats() {
        coordinator.stats = SyncStats()
    }

    /// Creates, removes and resizes sessions so they match the document's viewport list.
    func reconcile(with configs: [ViewportConfig]) {
        let wanted = Set(configs.map(\.id))
        for id in sessions.keys where !wanted.contains(id) {
            coordinator.remove(id)
            sessions[id] = nil
            loadingIDs.remove(id)
        }
        for config in configs {
            if let session = sessions[config.id] {
                session.resize(to: config.size)
                continue
            }
            let session = EngineFactory.makeSession(for: config)
            sessions[config.id] = session
            coordinator.add(session)
            if let currentURL { session.load(currentURL) }
        }
        coordinator.excludedIDs = Set(configs.filter { !$0.isSyncEnabled }.map(\.id))
        viewports = configs
        if let leaderID, !wanted.contains(leaderID) { setLeader(nil) }
        if let selectedViewportID, !wanted.contains(selectedViewportID) { self.selectedViewportID = nil }
    }

    func navigate(to url: URL) {
        currentURL = url
        addressText = url.absoluteString
        history.record(url)
        coordinator.loadAll(url)
    }

    /// Esc in the address field: back to the page's address.
    func revertAddress() {
        addressText = currentURL?.absoluteString ?? ""
    }

    func submitAddress() {
        guard let url = URL(addressBarInput: addressText) else { return }
        navigate(to: url)
    }

    func goBack() { coordinator.goBackAll() }
    func goForward() { coordinator.goForwardAll() }
    func reload() { coordinator.reloadAll() }

    /// The viewport under the pointer leads; only its interactions are mirrored.
    func setLeader(_ id: ViewportID?) {
        guard leaderID != id else { return }
        leaderID = id
        coordinator.leaderID = id
    }

    private func handle(_ event: EngineEvent, from id: ViewportID) {
        // The address bar follows the leader, or the first viewport when nobody leads yet.
        let speaksForWindow = id == (leaderID ?? viewports.first?.id)
        switch event {
        case .urlChanged(let url):
            if speaksForWindow {
                currentURL = url
                addressText = url.absoluteString
                history.record(url)
            }
        case .titleChanged(let title):
            if speaksForWindow { currentTitle = title }
        case .loadingChanged(let loading):
            if loading { loadingIDs.insert(id) } else { loadingIDs.remove(id) }
            isLoading = !loadingIDs.isEmpty
        case .interaction:
            break
        }
    }

    // MARK: Screenshots

    /// The notice capsule's content (`ToastCapsule`, DESIGN.md §3.2 "Bildirim kapsülü halleri").
    struct Notice: Identifiable, Equatable {
        enum Kind {
            case progress, success, partialFailure, failure, info, undo
        }

        struct Action {
            let title: String
            let perform: @MainActor () -> Void
        }

        let id = UUID()
        let kind: Kind
        let text: String
        var action: Action?
        /// The saved screenshot, for "Finder'da Göster".
        var fileURL: URL?

        var isProgress: Bool { kind == .progress }
        /// Errors stay until dismissed and are not replaced by a success (DESIGN.md §5.20 e).
        var isError: Bool { kind == .partialFailure || kind == .failure }

        static func == (lhs: Notice, rhs: Notice) -> Bool { lhs.id == rhs.id && lhs.text == rhs.text }
    }

    static let screenshotFolder = URL.picturesDirectory.appending(path: "Viewportix")

    /// Captures the given viewports (canvas order), saves one PNG and copies it to the clipboard.
    /// Several viewports are laid out side by side under their names. Viewports that fail are left
    /// out and reported with a retry (partial failure); if all fail, nothing is saved.
    func capture(_ ids: [ViewportID], area: SnapshotArea) async {
        let targets = viewports.filter { ids.contains($0.id) }
        guard !targets.isEmpty else { return }

        var items: [ScreenshotComposer.Item] = []
        var captured: [ViewportConfig] = []
        var failed: [ViewportConfig] = []
        for (index, config) in targets.enumerated() {
            let progress = targets.count > 1 ? " \(index + 1) / \(targets.count)" : ""
            show(Notice(kind: .progress, text: "Ekran görüntüsü alınıyor…\(progress)"))
            guard let session = sessions[config.id] else { continue }
            do {
                let image = try await session.snapshot(area)
                items.append(.init(title: "\(config.name) · \(config.size.width)×\(config.size.height)", image: image))
                captured.append(config)
            } catch {
                failed.append(config)
            }
        }
        let retry = Notice.Action(title: "Yeniden dene") { [weak self] in
            Task { await self?.capture(failed.map(\.id), area: area) }
        }
        guard !items.isEmpty else {
            let text = failed.count == 1 ? "\(failed[0].name) yakalanamadı" : "\(failed.count) viewport yakalanamadı"
            show(Notice(kind: .failure, text: text, action: retry))
            return
        }

        // Screenshots are at the display's pixel density; titles and spacing follow it.
        let scale = CGFloat(items[0].image.width) / CGFloat(captured[0].size.width)
        let subject = currentTitle.isEmpty ? (currentURL?.host() ?? "") : currentTitle
        let name = ScreenshotNaming.fileName(subject: subject, detail: captured.count == 1 ? captured[0].name : nil, date: .now)
        let png = await Task.detached {
            let image = items.count == 1 ? items[0].image : ScreenshotComposer.compose(items, scale: scale)
            return image.flatMap(ScreenshotComposer.pngData)
        }.value

        guard let png else {
            show(Notice(kind: .failure, text: "Ekran görüntüsü oluşturulamadı"))
            return
        }
        do {
            try FileManager.default.createDirectory(at: Self.screenshotFolder, withIntermediateDirectories: true)
            let url = Self.screenshotFolder.appending(path: name)
            try png.write(to: url)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setData(png, forType: .png)
            if failed.isEmpty {
                show(Notice(kind: .success, text: "Kaydedildi ve kopyalandı", action: .init(title: "Finder'da Göster") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }, fileURL: url))
            } else {
                let names = failed.map(\.name).joined(separator: ", ")
                show(Notice(kind: .partialFailure, text: "\(names) yakalanamadı", action: retry, fileURL: url))
            }
        } catch {
            let message = error.localizedDescription
            show(Notice(kind: .failure, text: "Kaydedilemedi", action: .init(title: "Ayrıntılar") {
                let alert = NSAlert()
                alert.messageText = "Ekran görüntüsü kaydedilemedi"
                alert.informativeText = message
                alert.runModal()
            }))
        }
    }

    func captureAll(area: SnapshotArea) async {
        await capture(viewports.map(\.id), area: area)
    }

    func dismissNotice() {
        notice = nil
        if let waiting = waitingNotice {
            waitingNotice = nil
            show(waiting)
        }
    }

    /// One capsule at a time (DESIGN.md §5.20 e): a new one replaces the old, except that an open
    /// error is not covered by a success, which waits until the error is closed. Success, undo and
    /// info leave after 5 s; progress until replaced; errors until dismissed.
    func show(_ notice: Notice) {
        if let current = self.notice, current.isError, !notice.isError, !notice.isProgress {
            waitingNotice = notice
            return
        }
        self.notice = notice
        guard !notice.isError, !notice.isProgress else { return }
        Task {
            try? await Task.sleep(for: .seconds(5))
            if self.notice?.id == notice.id { self.notice = nil }
        }
    }

    @ObservationIgnored private var waitingNotice: Notice?

    private func flagMissed(_ id: ViewportID) {
        missedIDs.insert(id)
        Task {
            try? await Task.sleep(for: .seconds(3))
            missedIDs.remove(id)
        }
    }
}

/// The one place that knows concrete engines. Everything else sees `EngineSession`.
@MainActor
enum EngineFactory {
    static func makeSession(for config: ViewportConfig) -> any EngineSession {
        switch config.engine {
        case .webKit, .chromium, .firefox:  // Chromium (M4) and Firefox (M6) fall back to WebKit for now.
            WebKitSession(id: config.id, size: config.size, mobileUserAgent: usesMobileUserAgent(config))
        }
    }

    /// Phones get an iPhone user agent; iPadOS Safari sends a desktop one, so tablets do too.
    private static func usesMobileUserAgent(_ config: ViewportConfig) -> Bool {
        if let category = config.presetID.flatMap(DeviceCatalog.preset(id:))?.category {
            return category == .phone
        }
        return config.size.width < 600
    }
}
