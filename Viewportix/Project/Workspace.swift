import AppKit
import Capture
import ChromiumEngine
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
    /// The device picker's engine for this window.
    var pickerEngine = EngineKind.webKit
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
    /// Senkron › Geliştirici: console and network lines too (§3.4); remembered.
    var isDeveloperScope = UserDefaults.standard.bool(forKey: Workspace.developerScopeKey) {
        didSet {
            UserDefaults.standard.set(isDeveloperScope, forKey: Self.developerScopeKey)
            for session in sessions.values { session.setDeveloperLogging(isDeveloperScope) }
            awaitsDeveloperReload = isDeveloperScope
        }
    }
    /// The developer script goes in on the next load: the panel offers "Yenile" until then.
    var awaitsDeveloperReload = false
    private(set) var developerLog: [DeveloperEntry] = []
    nonisolated static let developerScopeKey = "syncLogDeveloperScope"

    /// A console or network line; the same line from several viewports within 3 s is one row.
    struct DeveloperEntry: Identifiable, Hashable {
        let id = UUID()
        var time: Date
        let message: DeveloperMessage
        var viewports: [ViewportID]
    }

    /// Times in the log count from here (mm:ss).
    @ObservationIgnored let logStart = Date.now
    /// Farklar: measurements, the compared pair, the element shown on the canvas.
    let diffCenter = DiffCenter()

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

    // MARK: Farklar

    /// Runs a script in one viewport's page (Farklar's collector, Göster).
    func evaluate(_ script: String, in id: ViewportID) async -> JSONValue? {
        guard let session = sessions[id] else { return nil }
        return try? await session.evaluate(script)
    }

    func refreshDiffs(review: DiffReview) async {
        await diffCenter.refresh(viewports: viewports, leader: leaderID, isPanelOpen: devPanel == .diffs, review: review) { id, script in
            await self.evaluate(script, in: id)
        }
        if diffCenter.mode != .sideBySide { await captureDiffOverlay() }
    }

    @ObservationIgnored private var overlayRefresh: Task<Void, Never>?

    /// 300 ms after the last scroll, after the followers have applied it (2026-10-19 decision).
    private func refreshOverlaySoon() {
        overlayRefresh?.cancel()
        overlayRefresh = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await captureDiffOverlay()
        }
    }

    /// Üst üste / Yanıp sönme: what the compared viewport shows now, for the baseline card.
    func captureDiffOverlay() async {
        guard let baseline = diffCenter.baselineID, let compared = diffCenter.comparedID,
              let config = viewports.first(where: { $0.id == compared }),
              let image = try? await sessions[compared]?.snapshot(.visible) else {
            diffCenter.overlay = nil
            return
        }
        diffCenter.overlay = .init(image: image, baseline: baseline, width: Double(config.size.width))
    }

    /// Göster ⏎: the element comes to the middle of its viewport, which comes into view, with a sky
    /// box and the difference on the canvas.
    func showDifference(_ row: DiffCenter.Row) async {
        let target = row.difference.property == .presence ? diffCenter.baselineID : diffCenter.comparedID
        guard let target else { return }
        reveal(target)
        guard let json = await evaluate(DiffCenter.locateScript(row.difference.selector), in: target),
              let x = json["x"]?.numberValue, let y = json["y"]?.numberValue,
              let width = json["w"]?.numberValue, let height = json["h"]?.numberValue else {
            diffCenter.highlight = nil
            return
        }
        diffCenter.highlight = .init(viewport: target, rect: CGRect(x: x, y: y, width: width, height: height),
                                     label: row.difference.summary)
    }

    // MARK: Senkron panel

    /// Senkron › Göster (`devpanel-synclog-calm@2x.png`): the viewport that missed comes into view;
    /// where the element is in the leader's page, scaled to this page, gets a coral box and
    /// "bulunamadı". Events without an element (scroll, navigate) only bring the viewport.
    func showSyncMiss(_ entry: SyncLog.Entry) async {
        guard let target = entry.missedIDs.first ?? entry.followers.first else { return }
        reveal(target)
        diffCenter.highlight = nil
        guard entry.isMissed, let selector = entry.targetSelector,
              let share = await evaluate(DiffCenter.shareScript(selector), in: entry.leader),
              let x = share["x"]?.numberValue, let width = share["w"]?.numberValue,
              let y = share["y"]?.numberValue, let height = share["h"]?.numberValue,
              let spot = await evaluate(DiffCenter.spotScript(y: y), in: target),
              let pageWidth = spot["width"]?.numberValue, let top = spot["y"]?.numberValue else { return }
        diffCenter.highlight = .init(viewport: target,
                                     rect: CGRect(x: x * pageWidth, y: top, width: max(width * pageWidth, 24), height: max(height, 16)),
                                     label: "bulunamadı", isMissing: true)
    }

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
        developerLog = []
    }

    private func recordDeveloper(_ message: DeveloperMessage, from id: ViewportID) {
        guard isDeveloperScope, isSyncLogLive else { return }
        let now = Date.now
        if let index = developerLog.prefix(20).firstIndex(where: { $0.message == message && now.timeIntervalSince($0.time) < 3 }) {
            if !developerLog[index].viewports.contains(id) { developerLog[index].viewports.append(id) }
            return
        }
        developerLog.insert(DeveloperEntry(time: now, message: message, viewports: [id]), at: 0)
        if developerLog.count > 500 { developerLog.removeLast(developerLog.count - 500) }
    }

    /// "Dışa aktar (JSON)".
    func exportSyncLog() throws -> Data {
        let names = Dictionary(uniqueKeysWithValues: viewports.map { ($0.id, $0.tabName(among: viewports)) })
        let sync = try coordinator.log.exportJSON(names: names)
        guard isDeveloperScope, var rows = try JSONSerialization.jsonObject(with: sync) as? [[String: Any]] else { return sync }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        rows += developerLog.reversed().map { entry in
            ["time": formatter.string(from: entry.time), "event": entry.message.kind == .console ? "konsol" : "ağ",
             "level": entry.message.level.rawValue, "detail": entry.message.text, "url": entry.message.url ?? "",
             "viewports": entry.viewports.map { names[$0] ?? "" }]
        }
        rows.sort { ($0["time"] as? String ?? "") < ($1["time"] as? String ?? "") }
        return try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    }

    /// The name lists use: "iPad · Chromium" when the same device is open in two engines.
    func viewportName(_ id: ViewportID) -> String {
        viewports.first { $0.id == id }?.tabName(among: viewports) ?? "Viewport"
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
    /// PW-05 / 2026-10-19 decision: ⏎ on a focused card header puts the keyboard in its page; Esc in
    /// that page comes back to the header (only when the page was entered with ⏎: a click into the page
    /// leaves Esc to the page).
    private(set) var keyboardEnteredPage: ViewportID?
    /// The card header that should take keyboard focus (after Esc), with a fresh token per request.
    private(set) var headerFocusRequest: (id: ViewportID, token: UUID)?

    func enterPage(_ id: ViewportID) {
        guard let view = sessions[id]?.view, let window = view.window else { return }
        selectedViewportID = id
        window.makeFirstResponder(view)
        keyboardEnteredPage = id
    }

    /// Esc from a page entered with ⏎. Returns false when Esc belongs to the page.
    func leavePage() -> Bool {
        guard let id = keyboardEnteredPage else { return false }
        keyboardEnteredPage = nil
        sessions[id]?.view.window?.makeFirstResponder(nil)
        headerFocusRequest = (id, UUID())
        return true
    }

    func pageClicked() {
        keyboardEnteredPage = nil
    }

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
            if let session = sessions[config.id], session.kind != EngineFactory.kind(for: config) {
                // Motor ›: a new engine for this viewport; it reopens the current page.
                coordinator.remove(config.id)
                sessions[config.id] = nil
                loadFailures[config.id] = nil
            }
            if let session = sessions[config.id] {
                session.resize(to: config.size)
                continue
            }
            let session = EngineFactory.makeSession(for: config)
            session.setDeveloperLogging(isDeveloperScope)
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
            if loading { awaitsDeveloperReload = false }
            if loading { loadingIDs.insert(id) } else { loadingIDs.remove(id) }
            isLoading = !loadingIDs.isEmpty
        case .loadFailure(let failure):
            setLoadFailure(failure, for: id)
        case .developer(let message):
            recordDeveloper(message, from: id)
        case .syncAvailable(let available):
            if available {
                syncBlockedIDs.remove(id)
            } else {
                syncBlockedIDs.insert(id)
                explainSyncBlock()
            }
        case .interaction(.scroll):
            // Üst üste / Yanıp sönme: the compared page's picture follows the scroll once it settles.
            if diffCenter.mode != .sideBySide { refreshOverlaySoon() }
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
        // Undo capsules count down themselves and wait while the pointer is on them.
        guard !notice.isError, !notice.isProgress, notice.kind != .undo else { return }
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
        case .chromium:
            // Chromium ships on Android phones and tablets: both get touch and a mobile viewport.
            chromiumSession(for: config)
        case .webKit, .firefox:  // Firefox (M6) falls back to WebKit for now.
            WebKitSession(id: config.id, size: config.size, mobileUserAgent: usesMobileUserAgent(config))
        }
    }

    private static func chromiumSession(for config: ViewportConfig) -> ChromiumSession {
        let session = ChromiumSession(id: config.id, size: config.size, mobile: config.category != .desktop,
                                      tablet: config.category == .tablet)
        session.onSelectMenu = { [weak session] menu in
            guard let session else { return }
            showSelectMenu(menu, for: session)
        }
        return session
    }

    /// A `<select>` in a Chromium page opens our menu under it (headless Chrome draws none).
    private static func showSelectMenu(_ menu: ChromiumSession.SelectMenu, for session: ChromiumSession) {
        guard let window = session.view.window else { return }
        let anchor = session.view.convert(menu.rect, to: nil)
        var items: [ChromeMenuItem] = []
        var group: String?
        for (index, option) in menu.options.enumerated() {
            if option.group != group, let title = option.group {
                items.append(.header(title))
            }
            group = option.group
            items.append(.button(option.label, isChecked: index == menu.selectedIndex, isEnabled: option.isEnabled) {
                session.chooseSelectOption(index)
            })
        }
        ChromeMenuPresenter.show(ChromeMenu(width: max(anchor.width, 160), showsChecks: true, items: items), in: window,
                                 placement: .below(anchor, .leading, gap: 2))
    }

    /// The engine a viewport's session really runs.
    static func kind(for config: ViewportConfig) -> EngineKind {
        config.engine == .chromium ? .chromium : .webKit
    }

    /// Phones get an iPhone user agent; iPadOS Safari sends a desktop one, so tablets do too.
    private static func usesMobileUserAgent(_ config: ViewportConfig) -> Bool {
        if let category = config.presetID.flatMap(DeviceCatalog.preset(id:))?.category {
            return category == .phone
        }
        return config.size.width < 600
    }
}
