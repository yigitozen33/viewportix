import EngineCore
import Foundation
import Testing
import WebKit
@testable import WebKitEngine

/// Integration tests against real WKWebViews and the HTML fixtures. The agent's own listeners
/// (scroll → message) need a visible page and are covered by the S3 spike; here we drive the agent's
/// capture/apply functions directly and the native message parsing.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct WebKitSessionTests {
    static let fixtures = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Fixtures")

    static let phone = ViewportSize(width: 393, height: 852)
    static let desktop = ViewportSize(width: 1440, height: 900)

    private func loadedSession(_ fixture: String, size: ViewportSize, mobile: Bool = false) async throws -> WebKitSession {
        let session = WebKitSession(id: ViewportID(), size: size, mobileUserAgent: mobile, dataStore: .nonPersistent())
        session.load(Self.fixtures.appending(path: fixture))
        for _ in 0..<100 {
            if let ready = try? await session.evaluateInAgentWorld("return !!window.__viewportix") as? Bool, ready,
               !session.webView.isLoading {
                return session
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw TimeoutError(fixture: fixture)
    }

    struct TimeoutError: Error {
        let fixture: String
    }

    /// Runs an agent expression and converts its result to JSON.
    private func agentJSON(_ session: WebKitSession, _ body: String) async throws -> JSONValue {
        let raw = try await session.evaluateInAgentWorld(body)
        return try #require(raw.flatMap { JSONValue(any: $0) })
    }

    private func pageScrollY(_ session: WebKitSession) async throws -> Double {
        try await session.webView.evaluateJavaScript("window.scrollY") as? Double ?? -1
    }

    @Test func scrollAnchorKeepsTheSameSectionOnScreenAcrossWidths() async throws {
        let phone = try await loadedSession("long-page.html", size: Self.phone, mobile: true)
        let desktop = try await loadedSession("long-page.html", size: Self.desktop)

        _ = try await phone.webView.evaluateJavaScript("window.scrollTo(0, 6000)")
        let anchor = try await agentJSON(phone, "return window.__viewportix.captureAnchor()")
        let heading = try #require(anchor["section"]?["text"]?.stringValue)

        let result = await desktop.apply(.scroll(anchor))
        #expect(result == .applied("anchor:strong"))

        // The section the phone is reading must be on the desktop screen too.
        let sectionID = "section-" + heading.replacingOccurrences(of: "Section ", with: "")
        let visible = try await desktop.webView.evaluateJavaScript(
            "(() => { const r = document.getElementById('\(sectionID)').getBoundingClientRect(); return r.top < innerHeight && r.bottom > 0; })()"
        ) as? Bool
        #expect(visible == true, "desktop should show \(sectionID)")
        #expect(try await pageScrollY(desktop) > 0)
    }

    @Test func scrollToTopEdgeIsMirrored() async throws {
        let follower = try await loadedSession("long-page.html", size: Self.desktop)
        _ = try await follower.webView.evaluateJavaScript("window.scrollTo(0, 2000)")

        let result = await follower.apply(.scroll(.object(["edge": .string("top"), "percent": .number(0)])))

        #expect(result == .applied("edge:top"))
        #expect(try await pageScrollY(follower) == 0)
    }

    @Test func clickFindsTheTargetByStableSelector() async throws {
        let leader = try await loadedSession("form.html", size: Self.phone, mobile: true)
        let follower = try await loadedSession("form.html", size: Self.desktop)
        let target = try await agentJSON(leader, "return window.__viewportix.describeTarget(document.querySelector('[data-testid=terms]'))")

        let result = await follower.apply(.click(target))

        #expect(result == .applied("click:selector"))
        let checked = try await follower.webView.evaluateJavaScript("document.querySelector('[data-testid=terms]').checked") as? Bool
        #expect(checked == true)
    }

    @Test func clickFallsBackToVisibleText() async throws {
        let follower = try await loadedSession("form.html", size: Self.desktop)
        let target = JSONValue.object([
            "selector": .string("#renamed-in-this-layout"),
            "strong": .bool(true),
            "tag": .string("button"),
            "text": .string("Submit"),
            "href": .null,
        ])

        let result = await follower.apply(.click(target))

        #expect(result == .applied("click:text"))
        let output = try await follower.webView.evaluateJavaScript("document.getElementById('result').textContent") as? String
        #expect(output?.hasPrefix("Submitted") == true)
    }

    @Test func clickOnAnElementHiddenAtThisWidthIsMissed() async throws {
        // spa.html shows the menu toggle only below 600px.
        let follower = try await loadedSession("spa.html", size: Self.desktop)
        let target = JSONValue.object([
            "selector": .string("#menu-toggle"),
            "strong": .bool(true),
            "tag": .string("button"),
            "text": .string("Menu"),
            "href": .null,
        ])

        #expect(await follower.apply(.click(target)) == .missed)
    }

    @Test func agentMessagesBecomeInteractionEvents() async throws {
        let session = WebKitSession(id: ViewportID(), size: Self.phone, mobileUserAgent: true, dataStore: .nonPersistent())
        var events: [EngineEvent] = []
        session.eventHandler = { events.append($0) }

        session.receive(["kind": "scroll", "anchor": ["edge": "top", "percent": 0]])
        session.receive(["kind": "click", "target": ["tag": "a", "text": "Cart"]])
        session.receive(["kind": "unknown"])

        #expect(events == [
            .interaction(.scroll(.object(["edge": .string("top"), "percent": .number(0)]))),
            .interaction(.click(.object(["tag": .string("a"), "text": .string("Cart")]))),
        ])
    }

    @Test func reportsURLChanges() async throws {
        let session = WebKitSession(id: ViewportID(), size: Self.phone, mobileUserAgent: false, dataStore: .nonPersistent())
        var urls: [URL] = []
        session.eventHandler = { if case .urlChanged(let url) = $0 { urls.append(url) } }
        let fixture = Self.fixtures.appending(path: "form.html")

        session.load(fixture)
        for _ in 0..<50 where urls.isEmpty {
            try await Task.sleep(for: .milliseconds(100))
        }

        #expect(urls.last?.lastPathComponent == "form.html")
    }

    @Test func mobileUserAgentIdentifiesAsIPhone() async throws {
        let session = try await loadedSession("form.html", size: Self.phone, mobile: true)
        let agent = try await session.webView.evaluateJavaScript("navigator.userAgent") as? String
        #expect(agent?.contains("iPhone") == true)
    }
}
