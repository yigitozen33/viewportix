import AppKit
import Capture
import DesignSystem
import DeviceCatalog
import EngineCore
import Foundation
import Observation
import ProjectModel
import SwiftUI
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
    /// Viewports whose page failed to load; the card shows the error in place of the page.
    private(set) var loadFailures: [ViewportID: LoadFailure] = [:]
    /// Viewports whose page takes no sync agent (PDF, image, about:blank): §5.20 h.
    private(set) var syncBlockedIDs: Set<ViewportID> = []
    /// "Bu sayfada senkron çalışmıyor · Neden?" only the first time in a run of the app.
    @ObservationIgnored private static var hasExplainedSyncBlock = false
    @ObservationIgnored private var retryTasks: [ViewportID: Task<Void, Never>] = [:]
    @ObservationIgnored private var allFailedNoticeID: UUID?
    /// Device picker popover under "+ Cihaz" (STRIP-07, ⌥⌘N).
    var isDevicePickerOpen = false
    /// The settings panel over the canvas and its tab; nil when closed (RAIL-01, ⌘,).
    var settingsTab: SettingsTab?
    /// The developer panel docked left of the rail (DESIGN.md §3.4); it pushes the canvas.
    var devPanel: DevPanel?
    /// The Senkron panel's rows, mirrored from the coordinator (newest first).
    private(set) var syncLog: [SyncLog.Entry] = []
    /// "Canlı" / "Duraklatıldı": while paused nothing new is recorded; sync itself goes on.
    var isSyncLogLive = true {
        didSet { coordinator.isLogging = isSyncLogLive }
    }
    /// Times in the log count from here (mm:ss).
    @ObservationIgnored let logStart = Date.now

    enum DevPanel { case diffs, sync }
    /// The selected card (CARD-02): target of tab clicks and per-viewport shortcuts.
    var selectedViewportID: ViewportID?
    /// Groups on the canvas (Görünüm › Grupla) and their screen frames: open groups' page-area union,
    /// folded groups' chip anchor (zero size).
    var groups: [ViewportGroup] = []
    var groupFrames: [String: CGRect] = [:]
    /// The card being dragged by its header (CARD-08) and the alignment guides to draw (screen points).
    var draggingID: ViewportID?
    /// Drawn above the other cards where they overlap (the last one dragged).
    var frontCardID: ViewportID?
    var dragGuides: [(from: CGPoint, to: CGPoint)] = []
    /// CARD-08: equal-spacing runs and their length in CSS px, in screen points.
    var dragGaps: [DragGap] = []
    /// Where the pointer is while dragging, for the "⌥ basılıyken hizalama kapalı" hint.
    var dragPointer: CGPoint?

    struct DragGap: Hashable {
        let from: CGPoint
        let to: CGPoint
        let label: String
    }
    /// Card under the pointer (page, header or hover strip): shows its hover strip.
    private(set) var hoveredViewportID: ViewportID?
    /// Page areas of the cards on screen (canvas coordinates, top-left origin), from the canvas.
    var cardFrames: [ViewportID: CGRect] = [:]
    @ObservationIgnored private var hoverEnd: Task<Void, Never>?

    /// CARD-01: the card under the pointer leads; leaving lets the hover strip linger briefly so the
    /// pointer can reach it.
    func cardHovered(_ id: ViewportID, _ inside: Bool) {
        hoverEnd?.cancel()
        if inside {
            hoveredViewportID = id
            setLeader(id)
        } else if hoveredViewportID == id {
            hoverEnd = Task {
                try? await Task.sleep(for: .milliseconds(250))
                if !Task.isCancelled, hoveredViewportID == id { hoveredViewportID = nil }
            }
        }
    }
    var addressText = ""
    /// While the address field has focus, page events don't overwrite what is being typed (found in
    /// the live app: a page finishing its load replaced the half-typed address after ⌘L).
    @ObservationIgnored var isEditingAddress = false
    var zoom: Double = 1
    var isSyncEnabled = true {
        didSet { coordinator.isEnabled = isSyncEnabled }
    }
    /// App-wide preference: media plays only in the viewport under the pointer. On by default so
    /// sounds from several viewports don't overlap (DESIGN.md §4; the CPU gain measured none,
    /// PLAN.md M2 "Performans").
    var suspendsBackgroundMedia: Bool {
        didSet {
            UserDefaults.standard.set(suspendsBackgroundMedia, forKey: Self.suspendMediaKey)
            coordinator.suspendsFollowerMedia = suspendsBackgroundMedia
        }
    }
    nonisolated static let suspendMediaKey = "suspendBackgroundMedia"
    /// Transient status shown at the bottom of the window (screenshot progress and results).
    private(set) var notice: Notice?

    // MARK: Window chrome

    var isFullScreen = false
    /// A link dragged over the window (§5.20 g): the address it would open, shown in a capsule.
    var droppingAddress: String?
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
        suspendsBackgroundMedia = UserDefaults.standard.bool(forKey: Self.suspendMediaKey)
        isSyncEnabled = UserDefaults.standard.bool(forKey: AppSettings.syncOnStart)
        coordinator.suspendsFollowerMedia = suspendsBackgroundMedia
        coordinator.isEnabled = isSyncEnabled
        coordinator.onEvent = { [weak self] id, event in self?.handle(event, from: id) }
        coordinator.onResult = { [weak self] id, _, result in
            if result == .missed { self?.flagMissed(id) }
        }
        coordinator.onLogChange = { [weak self] in
            guard let self else { return }
            syncLog = coordinator.log.entries
        }
    }

    // MARK: Senkron panel

    /// The rail item or ⌥⌘1 / ⌥⌘2: opens that panel, or closes it when it is already open.
    func toggleDevPanel(_ panel: DevPanel) {
        withAnimation(Motion.curve(DesignTokens.Motion.panel)) { devPanel = devPanel == panel ? nil : panel }
    }

    /// DEV-06 "Yeniden dene": the event again, only where it was missed.
    func retrySync(_ entry: SyncLog.Entry) {
        for id in entry.missedIDs { coordinator.retry(entry.id, in: id) }
    }

    func clearSyncLog() {
        coordinator.clearLog()
    }

    /// "Dışa aktar (JSON)".
    func exportSyncLog() throws -> Data {
        try coordinator.log.exportJSON(names: Dictionary(uniqueKeysWithValues: viewports.map { ($0.id, $0.name) }))
    }

    func viewportName(_ id: ViewportID) -> String {
        viewports.first { $0.id == id }?.name ?? "Viewport"
    }

    func session(for id: ViewportID) -> (any EngineSession)? {
        sessions[id]
    }

    /// Set by the project window, which owns the document: rotate, resize, remove…
    @ObservationIgnored var performCommand: ((ViewportID, ViewportCommand) -> Void)?

    /// Viewport menu and ⌫: the command on the selected card.
    func performOnSelection(_ command: ViewportCommand) {
        guard let selectedViewportID else { return }
        performCommand?(selectedViewportID, command)
    }

    var selectedViewport: ViewportConfig? {
        viewports.first { $0.id == selectedViewportID }
    }

    /// Sonraki / Önceki Viewport (⌃⇥, ⌃⇧⇥): selects the next card in strip order and pans to it.
    func selectViewport(_ offset: Int) {
        let ids = viewports.map(\.id)
        guard !ids.isEmpty else { return }
        let index = selectedViewportID.flatMap(ids.firstIndex(of:)).map { ($0 + offset % ids.count + ids.count) % ids.count }
            ?? (offset > 0 ? 0 : ids.count - 1)
        reveal(ids[index])
    }

    /// "Seçimi Sığdır" (⌘2).
    func fitSelection() {
        guard let selectedViewportID else { return }
        canvas?.fitCard(selectedViewportID)
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
            loadFailures[id] = nil
            retryTasks.removeValue(forKey: id)?.cancel()
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
                if !isEditingAddress { addressText = url.absoluteString }
                history.record(url)
            }
        case .titleChanged(let title):
            if speaksForWindow { currentTitle = title }
        case .loadingChanged(let loading):
            if loading { loadingIDs.insert(id) } else { loadingIDs.remove(id) }
            isLoading = !loadingIDs.isEmpty
        case .loadFailure(let failure):
            setLoadFailure(failure, for: id)
        case .syncAvailable(let available):
            if available {
                syncBlockedIDs.remove(id)
            } else {
                syncBlockedIDs.insert(id)
                explainSyncBlock()
            }
        case .interaction:
            break
        }
    }

    private func explainSyncBlock() {
        guard !Self.hasExplainedSyncBlock else { return }
        Self.hasExplainedSyncBlock = true
        show(Notice(kind: .info, text: "Bu sayfada senkron çalışmıyor", action: .init(title: "Neden?") { [weak self] in
            self?.show(Notice(kind: .info, text: "Sayfa betik çalıştırmıyor (PDF, görsel ya da boş sayfa); bu viewport kaydırma ve tıklamaları izlemez"))
        }))
    }

    // MARK: Load failures

    private func setLoadFailure(_ failure: LoadFailure?, for id: ViewportID) {
        loadFailures[id] = failure
        retryTasks[id]?.cancel()
        retryTasks[id] = nil
        // CARD-11: a local development server that is down is tried again every 2 s.
        if let failure, failure.kind == .serverDown {
            retryTasks[id] = Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled, let self, self.loadFailures[id] == failure else { return }
                self.sessions[id]?.load(failure.url)
            }
        }
        updateAllFailedNotice()
    }

    /// PW-04: when the page failed everywhere, one capsule offers to retry them all.
    private func updateAllFailedNotice() {
        let allFailed = viewports.count > 1 && viewports.allSatisfy { loadFailures[$0.id] != nil }
        if allFailed, allFailedNoticeID == nil {
            let notice = Notice(kind: .partialFailure, text: "Sayfa \(viewports.count) viewport'ta açılamadı",
                                action: .init(title: "Hepsini dene") { [weak self] in self?.retryAllFailed() })
            allFailedNoticeID = notice.id
            show(notice)
        } else if !allFailed, let id = allFailedNoticeID {
            allFailedNoticeID = nil
            if notice?.id == id { dismissNotice() }
        }
    }

    /// CARD-10: only this viewport loads again (⌘R reloads all).
    func retryLoad(_ id: ViewportID) {
        guard let failure = loadFailures[id] else { sessions[id]?.reload(); return }
        sessions[id]?.load(failure.url)
    }

    func retryAllFailed() {
        allFailedNoticeID = nil
        for id in loadFailures.keys { retryLoad(id) }
    }

    /// CARD-12: trust the host until the app quits; every viewport loads again.
    func trustCertificate(for failure: LoadFailure) {
        guard let host = failure.url.host() else { return }
        sessions.values.first?.trustCertificates(forHost: host)
        for (id, other) in loadFailures where other.kind == .certificate && other.url.host() == host {
            sessions[id]?.load(other.url)
        }
    }

    func goBack(in id: ViewportID) {
        sessions[id]?.goBack()
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

    /// Ayarlar › Ekran görüntüsü › Klasör.
    static var screenshotFolder: URL { AppSettings.screenshotFolderURL }

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
        // Ayarlar › Ölçek: 2× keeps the display density, 1× resamples to CSS pixels.
        let outputScale = CGFloat(UserDefaults.standard.integer(forKey: AppSettings.screenshotScale))
        let factor = outputScale >= scale ? 1 : outputScale / scale
        let png = await Task.detached {
            let image = items.count == 1 ? items[0].image : ScreenshotComposer.compose(items, scale: scale)
            return image.flatMap { ScreenshotComposer.scaled($0, by: factor) }.flatMap(ScreenshotComposer.pngData)
        }.value

        guard let png else {
            show(Notice(kind: .failure, text: "Ekran görüntüsü oluşturulamadı"))
            return
        }
        do {
            try FileManager.default.createDirectory(at: Self.screenshotFolder, withIntermediateDirectories: true)
            let url = Self.screenshotFolder.appending(path: name)
            try png.write(to: url)
            let copies = UserDefaults.standard.bool(forKey: AppSettings.copyScreenshot)
            if copies {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setData(png, forType: .png)
            }
            if failed.isEmpty {
                show(Notice(kind: .success, text: copies ? "Kaydedildi ve kopyalandı" : "Kaydedildi", action: .init(title: "Finder'da Göster") {
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

    /// `thumbnail.png` (PLAN.md §3.5): the cards where the canvas lays them out, each page from what
    /// its viewport shows now.
    func thumbnail(for project: Project) async -> Data? {
        let groups = project.canvas.grouping.groups(of: project.viewports)
        let frames = groups.isEmpty ? CanvasLayout.frames(for: project.viewports)
            : CanvasLayout.grouped(project.viewports, groups: groups, collapsed: project.canvas.collapsedGroups).frames
        var cards: [ThumbnailComposer.Card] = []
        for viewport in project.viewports {
            guard let frame = frames[viewport.id] else { continue }
            let image = try? await sessions[viewport.id]?.snapshot(.visible)
            cards.append(ThumbnailComposer.Card(frame: frame, image: image))
        }
        return await Task.detached {
            ThumbnailComposer.compose(cards).flatMap(ScreenshotComposer.pngData)
        }.value
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
