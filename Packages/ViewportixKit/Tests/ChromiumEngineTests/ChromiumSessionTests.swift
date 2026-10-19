import AppKit
import DiffCore
import EngineCore
import Foundation
import SyncCore
import Testing
@testable import ChromiumEngine

/// Integration tests against the installed Chrome (skipped without one), headless, with a throwaway
/// profile. Each test starts and stops the browser.
@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)), .enabled(if: ChromeBrowser.isAvailable, "Chrome is not installed"))
final class ChromiumSessionTests {
    static let fixtures = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Fixtures")

    nonisolated static let phone = ViewportSize(width: 393, height: 852)
    nonisolated static let desktop = ViewportSize(width: 1440, height: 900)

    private var sessions: [ChromiumSession] = []
    private var events: [ViewportID: [EngineEvent]] = [:]

    init() {
        ChromeBrowser.shared.profileFolder = URL.temporaryDirectory.appending(path: "viewportix-chromium-tests", directoryHint: .isDirectory)
    }

    isolated deinit {
        sessions.removeAll()
        ChromeBrowser.shared.stop()
    }

    private func session(_ size: ViewportSize, mobile: Bool = false) -> ChromiumSession {
        let session = ChromiumSession(id: ViewportID(), size: size, mobile: mobile)
        let id = session.id
        session.eventHandler = { [weak self] event in self?.events[id, default: []].append(event) }
        sessions.append(session)
        return session
    }

    private func loadedSession(_ fixture: String, size: ViewportSize, mobile: Bool = false) async throws -> ChromiumSession {
        let session = session(size, mobile: mobile)
        session.load(Self.fixtures.appending(path: fixture))
        for _ in 0..<100 {
            if let ready = try? await session.evaluateInAgentWorld("!!window.__viewportix")?.boolValue, ready, !session.isLoading {
                return session
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw TimeoutError(fixture: fixture)
    }

    struct TimeoutError: Error {
        let fixture: String
    }

    private func waitFor(_ session: ChromiumSession, _ match: (EngineEvent) -> Bool) async throws -> EngineEvent? {
        for _ in 0..<50 {
            if let event = events[session.id]?.first(where: match) { return event }
            try await Task.sleep(for: .milliseconds(100))
        }
        return nil
    }

    @Test func reportsVersionAndTitle() async throws {
        let session = try await loadedSession("form.html", size: Self.phone, mobile: true)
        #expect(session.engineVersion.hasPrefix("Chrome ") || session.engineVersion.contains(" "))
        let userAgent = try await session.evaluate("navigator.userAgent")?.stringValue
        #expect(userAgent?.contains("Android") == true && userAgent?.contains(" Mobile ") == true)
        let major = session.engineVersion.split(separator: " ").last?.split(separator: ".").first.map(String.init) ?? "?"
        #expect(userAgent?.contains("Chrome/\(major).") == true)
        #expect(try await session.evaluate("innerWidth")?.numberValue == 393)
        let title = try await waitFor(session) { if case .titleChanged(let title) = $0 { !title.isEmpty && title != "about:blank" } else { false } }
        #expect(title != nil)
    }

    @Test func scrollAnchorKeepsTheSameSectionOnScreenAcrossWidths() async throws {
        let phone = try await loadedSession("long-page.html", size: Self.phone, mobile: true)
        let desktop = try await loadedSession("long-page.html", size: Self.desktop)

        _ = try await phone.evaluate("window.scrollTo(0, 6000)")
        let anchor = try #require(try await phone.evaluateInAgentWorld("window.__viewportix.captureAnchor()"))
        let heading = try #require(anchor["section"]?["text"]?.stringValue)

        #expect(await desktop.apply(.scroll(anchor)) == .applied("anchor:strong"))

        let sectionID = "section-" + heading.replacingOccurrences(of: "Section ", with: "")
        let visible = try await desktop.evaluate(
            "(() => { const r = document.getElementById('\(sectionID)').getBoundingClientRect(); return r.top < innerHeight && r.bottom > 0; })()"
        )?.boolValue
        #expect(visible == true, "desktop should show \(sectionID)")
    }

    @Test func clickFindsTheTargetByStableSelector() async throws {
        let follower = try await loadedSession("form.html", size: Self.desktop)
        let target = JSONValue.object(["selector": .string("[data-testid=\"terms\"]"), "strong": .bool(true), "tag": .string("input"),
                                       "text": .string(""), "href": .null])
        #expect(await follower.apply(.click(target)) == .applied("click:selector"))
        #expect(try await follower.evaluate("document.querySelector('[data-testid=terms]').checked")?.boolValue == true)
    }

    /// The leader path: real input through CDP reaches the agent, whose message comes back through
    /// the binding as a sync event.
    @Test func userInputComesBackAsSyncEvents() async throws {
        let session = try await loadedSession("long-page.html", size: Self.desktop)
        session.dispatchWheel(at: CGPoint(x: 400, y: 400), dx: 0, dy: 1200, modifiers: 0)
        let scroll = try await waitFor(session) { if case .interaction(.scroll) = $0 { true } else { false } }
        #expect(scroll != nil)

        let form = try await loadedSession("form.html", size: Self.desktop)
        let box = try #require(try await form.evaluate(
            "(() => { const r = document.querySelector('[data-testid=terms]').getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()"))
        let point = CGPoint(x: box["x"]?.numberValue ?? 0, y: box["y"]?.numberValue ?? 0)
        form.dispatchMouse("mousePressed", at: point, button: "left", clicks: 1, modifiers: 0)
        form.dispatchMouse("mouseReleased", at: point, button: "left", clicks: 1, modifiers: 0)
        // A checkbox syncs as its state (input), not as a click.
        let input = try await waitFor(form) { if case .interaction(.input) = $0 { true } else { false } }
        guard case .interaction(.input(let payload))? = input else { Issue.record("no input event"); return }
        #expect(payload["checked"]?.boolValue == true)
    }

    /// Headless Chrome paints no `<select>` popup: a click hands the options to the app instead, and
    /// the choice lands in the page and goes out as a sync event.
    @Test func selectOpensOurMenuAndTheChoiceSyncs() async throws {
        let form = try await loadedSession("form.html", size: Self.desktop)
        var menu: ChromiumSession.SelectMenu?
        form.onSelectMenu = { menu = $0 }
        let box = try #require(try await form.evaluate(
            "(() => { const r = document.querySelector('select').getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()"))
        let point = CGPoint(x: box["x"]?.numberValue ?? 0, y: box["y"]?.numberValue ?? 0)
        form.dispatchMouse("mousePressed", at: point, button: "left", clicks: 1, modifiers: 0)
        form.dispatchMouse("mouseReleased", at: point, button: "left", clicks: 1, modifiers: 0)
        for _ in 0..<30 where menu == nil { try await Task.sleep(for: .milliseconds(100)) }
        let shown = try #require(menu)
        #expect(shown.options.count > 1 && shown.rect.width > 0)

        let last = shown.options.count - 1
        form.chooseSelectOption(last)
        let input = try await waitFor(form) { if case .interaction(.input) = $0 { true } else { false } }
        guard case .interaction(.input(let payload))? = input else { Issue.record("no input event"); return }
        let value = try await form.evaluate("document.querySelector('select').value")?.stringValue
        #expect(payload["value"]?.stringValue == value)
        #expect(try await form.evaluate("document.querySelector('select').selectedIndex")?.numberValue == Double(last))
    }

    @Test func reportsAClosedLocalServer() async throws {
        let session = session(Self.phone)
        session.load(URL(string: "http://localhost:59999/urun")!)
        let event = try await waitFor(session) { if case .loadFailure(_?) = $0 { true } else { false } }
        guard case .loadFailure(let failure?)? = event else { Issue.record("no failure"); return }
        #expect(failure.kind == .serverDown)
    }

    @Test func snapshotsAtTwiceTheCSSSize() async throws {
        let session = try await loadedSession("long-page.html", size: Self.phone, mobile: true)
        let visible = try await session.snapshot(.visible)
        #expect(visible.width == 393 * 2)
        let full = try await session.snapshot(.fullPage)
        #expect(full.height > visible.height)
    }

    /// Farklar runs the same collector in Chromium as in WebKit.
    @Test func collectsElementsForFarklar() async throws {
        let session = try await loadedSession("sample-product.html", size: Self.phone, mobile: true)
        let snapshot = try #require(try await session.evaluate(ElementSnapshot.collectScript).flatMap(ElementSnapshot.init(json:)))
        #expect(snapshot.viewportWidth == 393)
        #expect(snapshot.elements.contains { $0.selector == ".add-to-cart" })
    }

    @Test func reportsSyncAvailability() async throws {
        let session = try await loadedSession("form.html", size: Self.phone)
        let event = try await waitFor(session) { if case .syncAvailable = $0 { true } else { false } }
        guard case .syncAvailable(let available)? = event else { Issue.record("no availability"); return }
        #expect(available)
    }
}

/// Key translation needs no browser.
@MainActor
struct KeyMappingTests {
    private func key(_ characters: String, code: UInt16, flags: NSEvent.ModifierFlags = []) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0, context: nil,
                         characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code)!
    }

    @Test func lettersUseWindowsKeyCodesNotMacOnes() {
        let params = KeyMapping.params(for: key("m", code: 46), down: true)
        #expect(params["windowsVirtualKeyCode"] as? Int == 77)
        #expect(params["code"] as? String == "KeyM")
        #expect(params["text"] as? String == "m")
        #expect(params["type"] as? String == "keyDown")
    }

    @Test func enterAndArrowsAreNamed() {
        let enter = KeyMapping.params(for: key("\r", code: 36), down: true)
        #expect(enter["key"] as? String == "Enter" && enter["windowsVirtualKeyCode"] as? Int == 13)
        let left = KeyMapping.params(for: key("\u{F702}", code: 123), down: true)
        #expect(left["key"] as? String == "ArrowLeft" && left["text"] == nil)
        #expect(KeyMapping.modifiers([.command, .shift]) == 12)
    }
}
