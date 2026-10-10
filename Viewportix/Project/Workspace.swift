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
    var addressText = ""
    var zoom: Double = 1
    var isSyncEnabled = true {
        didSet { coordinator.isEnabled = isSyncEnabled }
    }

    @ObservationIgnored weak var canvas: CanvasController?
    @ObservationIgnored private let coordinator = SyncCoordinator()
    @ObservationIgnored private var sessions: [ViewportID: any EngineSession] = [:]
    @ObservationIgnored private var loadingIDs: Set<ViewportID> = []

    init() {
        coordinator.onEvent = { [weak self] id, event in self?.handle(event, from: id) }
        coordinator.onResult = { [weak self] id, _, result in
            if result == .missed { self?.flagMissed(id) }
        }
    }

    func session(for id: ViewportID) -> (any EngineSession)? {
        sessions[id]
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
        viewports = configs
        if let leaderID, !wanted.contains(leaderID) { setLeader(nil) }
    }

    func navigate(to url: URL) {
        currentURL = url
        addressText = url.absoluteString
        coordinator.loadAll(url)
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
