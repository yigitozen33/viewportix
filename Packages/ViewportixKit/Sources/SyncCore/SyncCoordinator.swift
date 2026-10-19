import EngineCore
import Foundation

/// Counters for profiling and, later, the developer panel.
public struct SyncStats: Equatable, Sendable {
    /// Leader events accepted for mirroring (counted once, not per follower).
    public var mirrored = 0
    /// Follower applies completed.
    public var applied = 0
    /// Queued scrolls replaced by a newer one before being applied.
    public var coalesced = 0
    public var missed = 0
    public var totalApplyTime: Duration = .zero
    public var maxApplyTime: Duration = .zero

    public var averageApplyTime: Duration {
        applied > 0 ? totalApplyTime / applied : .zero
    }

    public init() {}
}

/// Mirrors the leading viewport's interactions in all other viewports.
///
/// Only the leader's events are forwarded, which rules out echo loops between viewports. Each follower
/// has a serial queue; a scroll, hover or same-field input queued behind one of its kind replaces it,
/// so slow followers catch up to the latest state instead of replaying every frame.
@MainActor
public final class SyncCoordinator {
    public private(set) var sessions: [any EngineSession] = []
    /// The viewport the user is interacting with (pointer over it). Nil means nobody leads.
    public var leaderID: ViewportID? {
        didSet {
            guard leaderID != oldValue else { return }
            applyMediaPolicy()
            // The new leader now has the real pointer; drop hover it was emulating as a follower.
            guard let leaderID, let leader = session(leaderID) else { return }
            enqueue(.hover(.null), for: leader)
        }
    }
    public var isEnabled = true
    /// Viewports with sync turned off: their interactions are not mirrored and they mirror nothing.
    public var excludedIDs: Set<ViewportID> = []
    /// Suspend media everywhere except the leader. With no leader yet, everything plays.
    public var suspendsFollowerMedia = false {
        didSet { applyMediaPolicy() }
    }
    /// Delay before mirroring a leader URL change, so a mirrored click can finish its own navigation first.
    public var navigationGrace: Duration = .milliseconds(400)

    /// Every session event, for UI state (URL bar, titles, loading indicators).
    public var onEvent: ((ViewportID, EngineEvent) -> Void)?
    /// Outcome of each mirrored event, e.g. to flag "sync missed" on a viewport.
    public var onResult: ((ViewportID, SyncEvent, ApplyResult) -> Void)?
    public var stats = SyncStats()
    /// The Senkron panel's rows (DESIGN.md §3.4). Recording stops while `isLogging` is false
    /// ("Duraklatıldı"); sync itself goes on.
    public private(set) var log = SyncLog()
    public var isLogging = true
    public var onLogChange: (() -> Void)?

    private struct Queued {
        var event: SyncEvent
        /// The log row this apply reports to.
        var entry: UUID?
    }

    private var queues: [ViewportID: [Queued]] = [:]
    private var draining: Set<ViewportID> = []

    public init() {}

    public func add(_ session: any EngineSession) {
        sessions.append(session)
        let id = session.id
        session.eventHandler = { [weak self] event in self?.handle(event, from: id) }
        session.setMediaPlaybackSuspended(shouldSuspendMedia(id))
    }

    public func remove(_ id: ViewportID) {
        sessions.first { $0.id == id }?.eventHandler = nil
        sessions.removeAll { $0.id == id }
        queues[id] = nil
        if leaderID == id { leaderID = nil }
    }

    public func session(_ id: ViewportID) -> (any EngineSession)? {
        sessions.first { $0.id == id }
    }

    public func loadAll(_ url: URL) { sessions.forEach { $0.load(url) } }
    public func reloadAll() { sessions.forEach { $0.reload() } }
    public func goBackAll() { sessions.forEach { $0.goBack() } }
    public func goForwardAll() { sessions.forEach { $0.goForward() } }

    func handle(_ event: EngineEvent, from id: ViewportID) {
        onEvent?(id, event)
        guard isEnabled, id == leaderID, !excludedIDs.contains(id) else { return }
        switch event {
        case .interaction(let sync):
            stats.mirrored += 1
            let followers = followers(of: id)
            let entry = record(sync, leader: id, followers: followers.map(\.id))
            for follower in followers {
                enqueue(sync, entry: entry, for: follower)
            }
        case .urlChanged(let url):
            mirrorNavigation(to: url, from: id)
        case .titleChanged, .loadingChanged, .loadFailure, .syncAvailable, .developer:
            break
        }
    }

    private func mirrorNavigation(to url: URL, from id: ViewportID) {
        Task {
            try? await Task.sleep(for: navigationGrace)
            let followers = followers(of: id).filter { $0.currentURL != url }
            // Already everywhere (the address bar loads every viewport): nothing to mirror or list.
            guard !followers.isEmpty else { return }
            let entry = record(.navigate(url), leader: id, followers: followers.map(\.id))
            for follower in followers {
                enqueue(.navigate(url), entry: entry, for: follower)
            }
        }
    }

    private func followers(of leader: ViewportID) -> [any EngineSession] {
        sessions.filter { $0.id != leader && !excludedIDs.contains($0.id) }
    }

    private func shouldSuspendMedia(_ id: ViewportID) -> Bool {
        suspendsFollowerMedia && leaderID != nil && id != leaderID
    }

    private func applyMediaPolicy() {
        for session in sessions {
            session.setMediaPlaybackSuspended(shouldSuspendMedia(session.id))
        }
    }

    private func record(_ event: SyncEvent, leader: ViewportID, followers: [ViewportID]) -> UUID? {
        // The pointer leaving the page (hover → nothing) is not something to list.
        guard isLogging, event != .hover(.null) else { return nil }
        let id = log.record(event, leader: leader, followers: followers)
        onLogChange?()
        return id
    }

    /// "Yeniden dene" (DEV-06): the row's event again, only in the viewport that missed it.
    public func retry(_ entryID: UUID, in viewport: ViewportID) {
        guard let entry = log.entries.first(where: { $0.id == entryID }), let follower = session(viewport) else { return }
        log.markPending(entryID, follower: viewport)
        onLogChange?()
        enqueue(entry.event, entry: entryID, for: follower)
    }

    public func clearLog() {
        log.clear()
        onLogChange?()
    }

    private func enqueue(_ event: SyncEvent, entry: UUID? = nil, for follower: any EngineSession) {
        var queue = queues[follower.id, default: []]
        if let last = queue.last, Self.supersedes(event, last.event) {
            queue[queue.count - 1] = Queued(event: event, entry: entry)
            stats.coalesced += 1
        } else {
            queue.append(Queued(event: event, entry: entry))
        }
        queues[follower.id] = queue

        guard !draining.contains(follower.id) else { return }
        draining.insert(follower.id)
        Task { await drain(follower) }
    }

    /// Whether `new` makes the still-queued `old` pointless: only the latest state matters.
    static func supersedes(_ new: SyncEvent, _ old: SyncEvent) -> Bool {
        switch (new, old) {
        case (.scroll, .scroll), (.hover, .hover):
            true
        case (.input(let a), .input(let b)):
            a["field"]?["selector"] == b["field"]?["selector"]
        default:
            false
        }
    }

    private func drain(_ follower: any EngineSession) async {
        while let queued = queues[follower.id]?.first {
            queues[follower.id]?.removeFirst()
            let next = queued.event
            let start = ContinuousClock.now
            let result = await follower.apply(next)
            let elapsed = ContinuousClock.now - start
            stats.applied += 1
            stats.totalApplyTime += elapsed
            stats.maxApplyTime = max(stats.maxApplyTime, elapsed)
            if result == .missed { stats.missed += 1 }
            if let entry = queued.entry {
                log.update(entry, follower: follower.id, result: result)
                onLogChange?()
            }
            onResult?(follower.id, next, result)
        }
        draining.remove(follower.id)
    }
}
