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
/// has a serial queue; a scroll queued behind another scroll replaces it, so slow followers catch up
/// to the latest position instead of replaying every frame.
@MainActor
public final class SyncCoordinator {
    public private(set) var sessions: [any EngineSession] = []
    /// The viewport the user is interacting with (pointer over it). Nil means nobody leads.
    public var leaderID: ViewportID?
    public var isEnabled = true
    /// Delay before mirroring a leader URL change, so a mirrored click can finish its own navigation first.
    public var navigationGrace: Duration = .milliseconds(400)

    /// Every session event, for UI state (URL bar, titles, loading indicators).
    public var onEvent: ((ViewportID, EngineEvent) -> Void)?
    /// Outcome of each mirrored event, e.g. to flag "sync missed" on a viewport.
    public var onResult: ((ViewportID, SyncEvent, ApplyResult) -> Void)?
    public var stats = SyncStats()

    private var queues: [ViewportID: [SyncEvent]] = [:]
    private var draining: Set<ViewportID> = []

    public init() {}

    public func add(_ session: any EngineSession) {
        sessions.append(session)
        let id = session.id
        session.eventHandler = { [weak self] event in self?.handle(event, from: id) }
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
        guard isEnabled, id == leaderID else { return }
        switch event {
        case .interaction(let sync):
            stats.mirrored += 1
            for follower in sessions where follower.id != id {
                enqueue(sync, for: follower)
            }
        case .urlChanged(let url):
            mirrorNavigation(to: url, from: id)
        case .titleChanged, .loadingChanged:
            break
        }
    }

    private func mirrorNavigation(to url: URL, from id: ViewportID) {
        Task {
            try? await Task.sleep(for: navigationGrace)
            for follower in sessions where follower.id != id && follower.currentURL != url {
                enqueue(.navigate(url), for: follower)
            }
        }
    }

    private func enqueue(_ event: SyncEvent, for follower: any EngineSession) {
        var queue = queues[follower.id, default: []]
        if case .scroll = event, let last = queue.last, case .scroll = last {
            queue[queue.count - 1] = event
            stats.coalesced += 1
        } else {
            queue.append(event)
        }
        queues[follower.id] = queue

        guard !draining.contains(follower.id) else { return }
        draining.insert(follower.id)
        Task { await drain(follower) }
    }

    private func drain(_ follower: any EngineSession) async {
        while let next = queues[follower.id]?.first {
            queues[follower.id]?.removeFirst()
            let start = ContinuousClock.now
            let result = await follower.apply(next)
            let elapsed = ContinuousClock.now - start
            stats.applied += 1
            stats.totalApplyTime += elapsed
            stats.maxApplyTime = max(stats.maxApplyTime, elapsed)
            if result == .missed { stats.missed += 1 }
            onResult?(follower.id, next, result)
        }
        draining.remove(follower.id)
    }
}
