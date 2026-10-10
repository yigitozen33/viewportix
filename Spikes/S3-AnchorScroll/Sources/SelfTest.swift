import AppKit

/// Measures how well followers keep the leader's content on screen: anchor sync vs. plain percentage.
///
/// For each page, leader (phone, then desktop) and scroll depth, the leader lists the landmarks near
/// the top of its screen. Each follower is synced both ways and we count how many of those landmarks
/// it shows. Score = shown / listed, averaged.
@MainActor
final class SelfTest {
    private let sync: SyncController

    private static let pages: [(name: String, url: URL)] = [
        ("fixture: long page", Paths.fixture("long-page.html")),
        ("fixture: sticky header", Paths.fixture("sticky-header.html")),
        ("Wikipedia article", URL(string: "https://en.wikipedia.org/wiki/Responsive_web_design")!),
        ("MDN reference", URL(string: "https://developer.mozilla.org/en-US/docs/Web/CSS/position")!),
        ("Apple product page", URL(string: "https://www.apple.com/iphone/")!),
        ("Stripe marketing page", URL(string: "https://stripe.com/payments")!),
        ("BBC News front", URL(string: "https://www.bbc.com/news")!),
    ]
    private static let depths = [0.15, 0.35, 0.55, 0.75]

    init(sync: SyncController) {
        self.sync = sync
    }

    func run() async -> Bool {
        var totalAnchor = 0.0
        var totalPercent = 0.0
        var counted = 0

        let arguments = CommandLine.arguments
        let only = arguments.firstIndex(of: "--only").map { arguments[$0 + 1] }
        let verbose = arguments.contains("--verbose")

        print("page | anchor | percent | samples | non-strong syncs")
        for page in Self.pages where only.map({ page.name.localizedCaseInsensitiveContains($0) }) ?? true {
            await sync.loadAll(page.url)
            try? await Task.sleep(for: .seconds(2))  // late layout, fonts, hero images

            var anchorScores: [Double] = []
            var percentScores: [Double] = []
            var fallbacks = 0

            for leader in [sync.viewports[0], sync.viewports[2]] {
                for depth in Self.depths {
                    guard let max = await leader.agent("maxScroll()") as? Double, max > 0 else { continue }
                    await leader.agent("applyPercent(p)", ["p": depth])
                    try? await Task.sleep(for: .milliseconds(400))  // lazy-loaded content settles

                    guard let anchor = await leader.agent("captureAnchor()") as? [String: Any],
                          let marks = await leader.agent("landmarks()") as? [String], !marks.isEmpty,
                          let percent = anchor["percent"] as? Double else { continue }

                    for follower in sync.viewports where follower !== leader {
                        await follower.agent("applyPercent(p)", ["p": percent])
                        try? await Task.sleep(for: .milliseconds(200))
                        let shownByPercent = await follower.agent("visibleCount(s)", ["s": marks]) as? Double ?? 0

                        let method = await follower.agent("applyAnchor(a)", ["a": anchor]) as? String ?? "error"
                        try? await Task.sleep(for: .milliseconds(200))
                        let shownByAnchor = await follower.agent("visibleCount(s)", ["s": marks]) as? Double ?? 0

                        if method != "anchor:strong" && !method.hasPrefix("edge") { fallbacks += 1 }
                        if verbose {
                            let host = (try? await follower.webView.evaluateJavaScript("location.host")) as? String ?? "?"
                            print("  \(leader.name)→\(follower.name) @\(depth) [\(host)] marks \(marks.count): percent \(Int(shownByPercent)), anchor \(Int(shownByAnchor)) via \(method)")
                            if shownByAnchor < Double(marks.count) { print("    marks: \(marks.prefix(3))") }
                        }
                        anchorScores.append(shownByAnchor / Double(marks.count))
                        percentScores.append(shownByPercent / Double(marks.count))
                    }
                }
            }

            guard !anchorScores.isEmpty else {
                print("\(page.name) | — | — | 0 | page did not load or does not scroll")
                continue
            }
            let anchorMean = anchorScores.reduce(0, +) / Double(anchorScores.count)
            let percentMean = percentScores.reduce(0, +) / Double(percentScores.count)
            print("\(page.name) | \(Self.pct(anchorMean)) | \(Self.pct(percentMean)) | \(anchorScores.count) | \(fallbacks)")
            totalAnchor += anchorMean
            totalPercent += percentMean
            counted += 1
        }

        let liveSyncPassed = await checkLiveSync()

        guard counted > 0 else { return false }
        let anchor = totalAnchor / Double(counted)
        let percent = totalPercent / Double(counted)
        print("MEAN | \(Self.pct(anchor)) | \(Self.pct(percent)) | \(counted) pages |")
        // Success: anchor keeps most of the leader's content on screen and beats the naive baseline.
        let passed = anchor >= 0.8 && anchor > percent && liveSyncPassed
        print("S3 SELF-TEST: \(passed ? "PASSED" : "FAILED") (target: anchor ≥ 80% and above percent)")
        return passed
    }

    /// The real event path: a page scroll in the leader posts an anchor, the app forwards it, and the
    /// followers' own programmatic scrolls must not echo back.
    private func checkLiveSync() async -> Bool {
        await sync.loadAll(Paths.fixture("long-page.html"))
        let leader = sync.viewports[0]
        sync.leaderOverride = leader
        defer { sync.leaderOverride = nil }
        sync.resetCounters()

        _ = try? await leader.webView.evaluateJavaScript("window.scrollTo(0, 3000)")
        try? await Task.sleep(for: .seconds(1))

        var followerY: [Double] = []
        for follower in sync.viewports where follower !== leader {
            followerY.append((try? await follower.webView.evaluateJavaScript("window.scrollY")) as? Double ?? 0)
        }
        let leaderY = (try? await leader.webView.evaluateJavaScript("window.scrollY")) as? Double ?? 0
        let passed = followerY.allSatisfy { $0 > 0 } && (1...3).contains(sync.forwardedCount)
            && sync.ignoredCount == 0 && leaderY == 3000
        print("live sync: \(passed ? "PASS" : "FAIL")  —  forwarded \(sync.forwardedCount), echoes \(sync.ignoredCount), leader y \(Int(leaderY)), followers y \(followerY.map { Int($0) })")
        return passed
    }

    private static func pct(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
