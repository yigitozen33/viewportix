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

    nonisolated static let phone = ViewportSize(width: 393, height: 852)
    nonisolated static let desktop = ViewportSize(width: 1440, height: 900)

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

    // MARK: Input

    private func fieldValue(_ session: WebKitSession, _ selector: String, _ property: String = "value") async throws -> Any? {
        try await session.webView.evaluateJavaScript("document.querySelector('\(selector)').\(property)")
    }

    @Test func inputFindsAFieldByNameAndFiresInputEvents() async throws {
        let leader = try await loadedSession("form.html", size: Self.phone, mobile: true)
        let follower = try await loadedSession("form.html", size: Self.desktop)
        _ = try await follower.webView.evaluateJavaScript(
            "window.inputEvents = 0; document.querySelector('[name=first]').addEventListener('input', () => window.inputEvents++); true"
        )
        let field = try await agentJSON(leader, "return window.__viewportix.describeField(document.querySelector('[name=first]'))")

        let result = await follower.apply(.input(.object(["field": field, "value": .string("Ada"), "checked": .bool(false)])))

        #expect(result == .applied("input:name"))
        #expect(try await fieldValue(follower, "[name=first]") as? String == "Ada")
        #expect(try await follower.webView.evaluateJavaScript("window.inputEvents") as? Int == 1)
    }

    @Test func inputFallsBackToTheLabelText() async throws {
        let follower = try await loadedSession("form.html", size: Self.desktop)
        let field = JSONValue.object([
            "selector": .string("#renamed-email"), "strong": .bool(true), "tag": .string("input"),
            "type": .string("email"), "name": .null, "label": .string("Email"), "placeholder": .string(""), "option": .null,
        ])

        let result = await follower.apply(.input(.object(["field": field, "value": .string("a@b.co"), "checked": .bool(false)])))

        #expect(result == .applied("input:label"))
        #expect(try await fieldValue(follower, "#email") as? String == "a@b.co")
    }

    @Test func checkboxStateIsSetNotToggled() async throws {
        let leader = try await loadedSession("form.html", size: Self.phone, mobile: true)
        let follower = try await loadedSession("form.html", size: Self.desktop)
        let field = try await agentJSON(leader, "return window.__viewportix.describeField(document.querySelector('[data-testid=terms]'))")
        let checked = JSONValue.object(["field": field, "value": .string("on"), "checked": .bool(true)])

        _ = await follower.apply(.input(checked))
        _ = await follower.apply(.input(checked))  // same state twice must not toggle back

        #expect(try await fieldValue(follower, "[data-testid=terms]", "checked") as? Bool == true)
    }

    @Test func selectValueIsMirrored() async throws {
        let leader = try await loadedSession("form.html", size: Self.phone, mobile: true)
        let follower = try await loadedSession("form.html", size: Self.desktop)
        let field = try await agentJSON(leader, "return window.__viewportix.describeField(document.querySelector('select'))")

        let result = await follower.apply(.input(.object(["field": field, "value": .string("Germany"), "checked": .bool(false)])))

        #expect(result == .applied("input:name"))
        #expect(try await fieldValue(follower, "select") as? String == "Germany")
    }

    @Test func inputForAMissingFieldIsMissed() async throws {
        let follower = try await loadedSession("long-page.html", size: Self.desktop)
        let field = JSONValue.object([
            "selector": .string("#email"), "strong": .bool(true), "tag": .string("input"),
            "type": .string("email"), "name": .string("email"), "label": .string("Email"), "placeholder": .string(""), "option": .null,
        ])
        #expect(await follower.apply(.input(.object(["field": field, "value": .string("x"), "checked": .bool(false)]))) == .missed)
    }

    // MARK: Hover

    @Test func hoverEmulatesCSSHoverAndFiresEnterEvents() async throws {
        let session = try await loadedSession("spa.html", size: Self.desktop)
        _ = try await session.webView.evaluateJavaScript(
            "window.entered = 0; document.getElementById('add-to-cart').addEventListener('mouseenter', () => window.entered++); true"
        )
        let target = try await agentJSON(session, "return window.__viewportix.describeTarget(document.getElementById('add-to-cart'))")
        let outline = "getComputedStyle(document.getElementById('add-to-cart')).outlineColor"

        #expect(await session.apply(.hover(target)) == .applied("hover"))
        #expect(try await session.webView.evaluateJavaScript(outline) as? String == "rgb(255, 0, 0)")
        #expect(try await session.webView.evaluateJavaScript("window.entered") as? Int == 1)

        #expect(await session.apply(.hover(.null)) == .applied("hover:clear"))
        #expect(try await session.webView.evaluateJavaScript(outline) as? String != "rgb(255, 0, 0)")
    }

    @Test func hoverRulesInsideMediaQueriesKeepTheirCondition() async throws {
        let desktop = try await loadedSession("spa.html", size: Self.desktop)
        let target = try await agentJSON(desktop, "return window.__viewportix.describeTarget(document.querySelector('nav a[href=\\'/cart\\']'))")

        #expect(await desktop.apply(.hover(target)) == .applied("hover"))
        let color = try await desktop.webView.evaluateJavaScript("getComputedStyle(document.querySelector('nav a[href=\\'/cart\\']')).color") as? String
        #expect(color == "rgb(0, 128, 0)")
    }

    @Test func hoverTargetMissingAtThisWidthIsNotASyncMiss() async throws {
        let session = try await loadedSession("spa.html", size: Self.desktop)
        let target = JSONValue.object(["selector": .string("#menu-toggle"), "strong": .bool(true), "tag": .string("button"), "text": .string("Menu"), "href": .null])
        #expect(await session.apply(.hover(target)) == .applied("hover:none"))
    }

    // MARK: Snapshot

    /// Share of non-white pixels in a horizontal band of the image (0...1 of its height).
    private func inkRatio(_ image: CGImage, band: ClosedRange<Double>) -> Double {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        // Bitmap rows start at the top here (CGContext memory is top-down for drawn images).
        let rows = Int(band.lowerBound * Double(height))..<Int(band.upperBound * Double(height))
        var ink = 0
        for row in rows {
            for column in stride(from: 0, to: width, by: 4) {
                let i = (row * width + column) * 4
                if pixels[i] < 240 || pixels[i + 1] < 240 || pixels[i + 2] < 240 { ink += 1 }
            }
        }
        return Double(ink) / Double(max(1, rows.count * (width / 4)))
    }

    @Test func visibleSnapshotMatchesTheViewport() async throws {
        let session = try await loadedSession("long-page.html", size: Self.phone, mobile: true)
        let image = try await session.snapshot(.visible)
        let scale = Double(image.width) / Double(Self.phone.width)
        #expect(scale >= 1)
        #expect(abs(Double(image.height) / scale - Double(Self.phone.height)) <= 1)
    }

    /// The phone layout of long-page.html is taller than one PDF page can be, so it exercises stacking.
    @Test(arguments: [desktop, phone])
    func fullPageSnapshotCoversTheWholeDocumentWithoutScrolling(size: ViewportSize) async throws {
        let session = try await loadedSession("long-page.html", size: size, mobile: size == Self.phone)
        _ = try await session.webView.evaluateJavaScript("window.scrollTo(0, 1500)")
        let documentHeight = try #require(try await session.webView.evaluateJavaScript("document.documentElement.scrollHeight") as? Double)

        let image = try await session.snapshot(.fullPage)

        let scale = Double(image.width) / Double(size.width)
        #expect(abs(Double(image.height) / scale - documentHeight) <= 2)
        #expect(try await session.webView.evaluateJavaScript("window.scrollY") as? Double == 1500, "capturing must not scroll the page")
        #expect(inkRatio(image, band: 0.0...0.05) > 0.01, "top of the document should be painted")
        #expect(inkRatio(image, band: 0.90...0.99) > 0.01, "bottom of the document should be painted")
    }

    // MARK: Media

    private func mediaState(_ session: WebKitSession) async -> WKMediaPlaybackState {
        await withCheckedContinuation { continuation in
            session.webView.requestMediaPlaybackState { continuation.resume(returning: $0) }
        }
    }

    private func waitForMedia(_ session: WebKitSession, _ expected: WKMediaPlaybackState) async throws -> WKMediaPlaybackState {
        var state = await mediaState(session)
        for _ in 0..<30 where state != expected {
            try await Task.sleep(for: .milliseconds(100))
            state = await mediaState(session)
        }
        return state
    }

    @Test func mediaPlaybackCanBeSuspendedAndResumed() async throws {
        let session = try await loadedSession("media.html", size: Self.desktop)
        let playing = try await waitForMedia(session, .playing)
        try #require(playing == .playing, "fixture audio should autoplay (state \(playing.rawValue))")

        session.setMediaPlaybackSuspended(true)
        #expect(try await waitForMedia(session, .suspended) == .suspended)

        _ = try await session.webView.evaluateJavaScript("document.getElementById('audio').play(); true")
        #expect(try await waitForMedia(session, .suspended) == .suspended, "page play() must not override suspension")

        session.setMediaPlaybackSuspended(false)
        #expect(try await waitForMedia(session, .playing) == .playing)
    }

    @Test func agentMessagesBecomeInteractionEvents() async throws {
        let session = WebKitSession(id: ViewportID(), size: Self.phone, mobileUserAgent: true, dataStore: .nonPersistent())
        var events: [EngineEvent] = []
        session.eventHandler = { events.append($0) }

        session.receive(["kind": "scroll", "anchor": ["edge": "top", "percent": 0]])
        session.receive(["kind": "click", "target": ["tag": "a", "text": "Cart"]])
        session.receive(["kind": "input", "field": ["name": "q"], "value": "shoes", "checked": false])
        session.receive(["kind": "hover", "target": NSNull()])
        session.receive(["kind": "unknown"])

        #expect(events == [
            .interaction(.scroll(.object(["edge": .string("top"), "percent": .number(0)]))),
            .interaction(.click(.object(["tag": .string("a"), "text": .string("Cart")]))),
            .interaction(.input(.object(["field": .object(["name": .string("q")]), "value": .string("shoes"), "checked": .bool(false)]))),
            .interaction(.hover(.null)),
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
