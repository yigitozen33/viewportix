import AppKit
import EngineCore
import Foundation
@testable import SyncCore
import Testing

@MainActor
final class FakeSession: EngineSession {
    let id = ViewportID()
    let kind = EngineKind.webKit
    let engineVersion = "fake"
    var currentURL: URL?
    let view = NSView()
    var eventHandler: ((EngineEvent) -> Void)?

    private(set) var applied: [SyncEvent] = []
    /// When set, `apply` suspends until `releaseOne()` is called.
    var holdApplies = false
    private var held: [CheckedContinuation<Void, Never>] = []

    func load(_ url: URL) { currentURL = url }
    func reload() {}
    func goBack() {}
    func goForward() {}
    func resize(to size: ViewportSize) {}

    func apply(_ event: SyncEvent) async -> ApplyResult {
        if holdApplies {
            await withCheckedContinuation { held.append($0) }
        }
        applied.append(event)
        return .applied("fake")
    }

    func emit(_ event: EngineEvent) {
        eventHandler?(event)
    }

    func releaseOne() {
        guard !held.isEmpty else { return }
        held.removeFirst().resume()
    }
}

@MainActor
struct SyncCoordinatorTests {
    let coordinator = SyncCoordinator()
    let a = FakeSession()
    let b = FakeSession()
    let c = FakeSession()

    init() {
        coordinator.navigationGrace = .zero
        [a, b, c].forEach(coordinator.add)
    }

    private func scroll(_ n: Double) -> SyncEvent {
        .scroll(.object(["percent": .number(n)]))
    }

    /// Lets queued coordinator tasks run.
    private func settle() async {
        for _ in 0..<20 { await Task.yield() }
    }

    @Test func forwardsOnlyFromTheLeader() async {
        coordinator.leaderID = a.id

        b.emit(.interaction(scroll(1)))
        await settle()
        #expect(a.applied.isEmpty && c.applied.isEmpty)

        a.emit(.interaction(scroll(2)))
        await settle()
        #expect(a.applied.isEmpty)
        #expect(b.applied == [scroll(2)])
        #expect(c.applied == [scroll(2)])
    }

    @Test func nothingIsForwardedWithoutALeaderOrWhenDisabled() async {
        a.emit(.interaction(scroll(1)))
        coordinator.leaderID = a.id
        coordinator.isEnabled = false
        a.emit(.interaction(scroll(2)))
        await settle()
        #expect(b.applied.isEmpty && c.applied.isEmpty)
    }

    @Test func queuedScrollsCoalesceButClicksKeepTheirPlace() async {
        coordinator.leaderID = a.id
        b.holdApplies = true
        let click = SyncEvent.click(.object(["text": .string("Buy")]))

        a.emit(.interaction(scroll(1)))  // starts applying, then blocks
        await settle()
        a.emit(.interaction(scroll(2)))
        a.emit(.interaction(scroll(3)))  // replaces 2 while queued
        a.emit(.interaction(click))
        a.emit(.interaction(scroll(4)))  // after the click, so it queues behind it

        for _ in 0..<4 {
            b.releaseOne()
            await settle()
        }
        #expect(b.applied == [scroll(1), scroll(3), click, scroll(4)])
    }

    @Test func mirrorsNavigationOnlyToFollowersOnAnotherURL() async throws {
        let target = try #require(URL(string: "https://example.com/cart"))
        coordinator.leaderID = a.id
        b.currentURL = target
        c.currentURL = URL(string: "https://example.com/")

        a.emit(.urlChanged(target))
        await settle()

        #expect(b.applied.isEmpty)
        #expect(c.applied == [.navigate(target)])
    }

    @Test func reportsResultsAndEvents() async {
        var results: [ViewportID] = []
        var events: [ViewportID] = []
        coordinator.onResult = { id, _, _ in results.append(id) }
        coordinator.onEvent = { id, _ in events.append(id) }
        coordinator.leaderID = a.id

        a.emit(.interaction(scroll(1)))
        b.emit(.titleChanged("B"))
        await settle()

        #expect(Set(results) == [b.id, c.id])
        #expect(events == [a.id, b.id])
    }

    @Test func removingTheLeaderClearsIt() {
        coordinator.leaderID = a.id
        coordinator.remove(a.id)
        #expect(coordinator.leaderID == nil)
        #expect(coordinator.sessions.count == 2)
        #expect(a.eventHandler == nil)
    }
}
