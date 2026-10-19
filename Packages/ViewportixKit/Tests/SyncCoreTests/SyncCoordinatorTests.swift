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
    func evaluate(_ script: String) async throws -> JSONValue? { nil }
    func snapshot(_ area: SnapshotArea) async throws -> CGImage { throw CancellationError() }
    private(set) var mediaSuspended = false
    func setMediaPlaybackSuspended(_ suspended: Bool) { mediaSuspended = suspended }
    func trustCertificates(forHost host: String) {}

    /// What `apply` answers; `.missed` makes this viewport miss every event.
    var result = ApplyResult.applied("fake")

    func apply(_ event: SyncEvent) async -> ApplyResult {
        if holdApplies {
            await withCheckedContinuation { held.append($0) }
        }
        applied.append(event)
        return result
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
        #expect(a.applied == [.hover(.null)])  // only its own emulated hover is cleared
        #expect(c.applied.isEmpty)

        a.emit(.interaction(scroll(2)))
        await settle()
        #expect(a.applied == [.hover(.null)])
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
        #expect(coordinator.stats.mirrored == 5)
        // c (not held) also had scroll 2 and 3 queued back to back, so both followers coalesce once.
        #expect(coordinator.stats.coalesced == 2)
    }

    @Test func latestStateSupersedesQueuedEventsOfTheSameKind() {
        let field = { (selector: String, value: String) in
            SyncEvent.input(.object(["field": .object(["selector": .string(selector)]), "value": .string(value)]))
        }
        let click = SyncEvent.click(.object([:]))

        #expect(SyncCoordinator.supersedes(scroll(2), scroll(1)))
        #expect(SyncCoordinator.supersedes(.hover(.null), .hover(.object([:]))))
        #expect(SyncCoordinator.supersedes(field("#q", "sho"), field("#q", "sh")))
        #expect(!SyncCoordinator.supersedes(field("#q", "a"), field("#email", "a")))
        #expect(!SyncCoordinator.supersedes(click, click))
        #expect(!SyncCoordinator.supersedes(scroll(1), click))
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

        #expect(Set(results) == [a.id, b.id, c.id])  // a: hover cleared on becoming leader
        #expect(events == [a.id, b.id])
    }

    @Test func becomingLeaderClearsEmulatedHoverOnce() async {
        coordinator.leaderID = b.id
        coordinator.leaderID = b.id
        await settle()
        #expect(b.applied == [.hover(.null)])
        #expect(a.applied.isEmpty && c.applied.isEmpty)
    }

    @Test func excludedViewportsNeitherLeadNorFollow() async {
        coordinator.excludedIDs = [c.id]
        coordinator.leaderID = a.id
        a.emit(.interaction(scroll(1)))
        await settle()
        #expect(b.applied == [scroll(1)])
        #expect(c.applied.isEmpty)

        coordinator.leaderID = c.id
        c.emit(.interaction(scroll(2)))
        await settle()
        #expect(a.applied == [.hover(.null)] && b.applied == [scroll(1)])
    }

    @Test func excludedViewportsDoNotFollowNavigation() async throws {
        let target = try #require(URL(string: "https://example.com/cart"))
        coordinator.excludedIDs = [c.id]
        coordinator.leaderID = a.id
        a.emit(.urlChanged(target))
        await settle()
        #expect(b.applied == [.navigate(target)])
        #expect(c.applied.isEmpty)
    }

    @Test func mediaPlaysOnlyInTheLeader() {
        coordinator.suspendsFollowerMedia = true
        #expect(![a, b, c].contains { $0.mediaSuspended }, "no leader yet: everything plays")

        coordinator.leaderID = a.id
        #expect(!a.mediaSuspended && b.mediaSuspended && c.mediaSuspended)

        coordinator.leaderID = b.id
        #expect(a.mediaSuspended && !b.mediaSuspended && c.mediaSuspended)

        let late = FakeSession()
        coordinator.add(late)
        #expect(late.mediaSuspended, "a viewport added later follows the policy")

        coordinator.suspendsFollowerMedia = false
        #expect(![a, b, c, late].contains { $0.mediaSuspended })
    }

    @Test func removingTheLeaderClearsIt() {
        coordinator.leaderID = a.id
        coordinator.remove(a.id)
        #expect(coordinator.leaderID == nil)
        #expect(coordinator.sessions.count == 2)
        #expect(a.eventHandler == nil)
    }

    @Test func logsEachEventWithItsFollowersAndMergesScrolls() async {
        coordinator.leaderID = a.id
        c.result = .missed
        let click = SyncEvent.click(.object(["selector": .string(".add-to-cart"), "strong": .bool(true)]))
        a.emit(.interaction(scroll(0.1)))
        a.emit(.interaction(scroll(0.2)))
        a.emit(.interaction(click))
        await settle()

        let entries = coordinator.log.entries
        #expect(entries.map(\.kind) == ["click", "scroll"])  // two scrolls, one row; newest first
        #expect(entries[0].detail == ".add-to-cart")
        #expect(entries[0].reached == 2 && entries[0].total == 3 && entries[0].missedIDs == [c.id])
        #expect(entries[1].detail == "%20")

        // DEV-06: once the page has the element, "Yeniden dene" goes only to the viewport that missed.
        c.result = .applied("selector")
        let before = b.applied.count
        coordinator.retry(entries[0].id, in: c.id)
        await settle()
        #expect(coordinator.log.entries[0].reached == 3 && b.applied.count == before)

        coordinator.isLogging = false
        a.emit(.interaction(click))
        await settle()
        #expect(coordinator.log.entries.count == 2)
    }
}
