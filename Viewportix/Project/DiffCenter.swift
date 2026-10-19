import CoreGraphics
import DiffCore
import EngineCore
import Foundation
import Observation
import ProjectModel

/// Farklar's state for one window (DESIGN.md §3.4; PLAN.md M5 2026-10-19): the last measurement of
/// every viewport, which pair the panel compares, and the element shown on the canvas.
@MainActor
@Observable
final class DiffCenter {
    /// One row: a difference between the pair, and which other viewports differ the same way.
    struct Row: Identifiable, Hashable {
        let difference: Difference
        /// Other viewports where the element differs from the baseline in the same way.
        let alsoIn: [ViewportID]
        let isTracked: Bool
        let key: String
        var id: String { difference.id }
    }

    /// Göster ⏎: the element on the canvas, in its viewport's CSS px (visible area).
    struct Highlight: Equatable {
        let viewport: ViewportID
        let rect: CGRect
        let label: String
        /// Senkron's Göster: where a missed element would be, in coral (`devpanel-synclog-calm`).
        var isMissing = false
    }

    var baselineID: ViewportID?
    var comparedID: ViewportID?
    private(set) var snapshots: [ViewportID: ElementSnapshot] = [:]
    private(set) var isComparing = false
    private(set) var comparedAt: Date?
    /// DEV-07: something new to look at while the panel was closed (the rail's Farklar dot).
    var hasUnseen = false
    var highlight: Highlight?

    /// Footer's mode: side by side is the canvas itself; Üst üste lays the compared viewport over the
    /// baseline card at 50 %, Yanıp sönme switches it on and off every 500 ms.
    enum Mode: String { case sideBySide, overlay, blink }
    var mode = Mode.sideBySide
    /// The compared viewport as it looks now, drawn over the baseline card in CSS px.
    struct Overlay {
        let image: CGImage
        let baseline: ViewportID
        /// CSS px width of the compared viewport (the image is drawn at the baseline card's scale).
        let width: Double
    }
    var overlay: Overlay?

    @ObservationIgnored private var lastSeen: Set<String> = []

    /// Measures every viewport again. `evaluate` runs the collector in one viewport.
    func refresh(viewports: [ViewportConfig], leader: ViewportID?, isPanelOpen: Bool, review: DiffReview,
                 evaluate: (ViewportID, String) async -> JSONValue?) async {
        guard !isComparing else { return }
        isComparing = true
        defer { isComparing = false }
        var measured: [ViewportID: ElementSnapshot] = [:]
        for viewport in viewports {
            if let json = await evaluate(viewport.id, ElementSnapshot.collectScript), let snapshot = ElementSnapshot(json: json) {
                measured[viewport.id] = snapshot
            }
        }
        snapshots = measured
        comparedAt = .now
        choosePair(viewports: viewports, leader: leader)
        let current = Set(rows(review: review).map(\.key))
        if !isPanelOpen, !current.subtracting(lastSeen).isEmpty { hasUnseen = true }
        if isPanelOpen { lastSeen = current }
    }

    /// Keeps the user's pair while both viewports exist; else baseline = leader (or the first),
    /// compared = the next one.
    func choosePair(viewports: [ViewportConfig], leader: ViewportID?) {
        let ids = viewports.map(\.id)
        if baselineID.map(ids.contains) != true { baselineID = leader.flatMap { ids.contains($0) ? $0 : nil } ?? ids.first }
        if comparedID.map({ ids.contains($0) && $0 != baselineID }) != true { comparedID = ids.first { $0 != baselineID } }
    }

    func panelOpened(review: DiffReview) {
        hasUnseen = false
        lastSeen = Set(rows(review: review).map(\.key))
    }

    /// Every difference between baseline and compared, before review.
    func allDifferences() -> [Difference] {
        guard let baselineID, let comparedID, let baseline = snapshots[baselineID], let compared = snapshots[comparedID] else { return [] }
        return DiffEngine.compare(baseline: baseline, compared: compared)
    }

    /// The panel's rows: accepted (with these values) and ignored selectors left out.
    func rows(review: DiffReview) -> [Row] {
        guard let baselineID, let comparedID, let baseline = snapshots[baselineID] else { return [] }
        let others = snapshots.keys.filter { $0 != baselineID && $0 != comparedID }.compactMap { id in
            snapshots[id].map { (id, Dictionary(DiffEngine.compare(baseline: baseline, compared: $0).map { ($0.id, $0.comparedValue) },
                                                uniquingKeysWith: { first, _ in first })) }
        }
        return allDifferences().compactMap { difference in
            let key = DiffReview.key(viewport: comparedID.rawValue, difference: difference.id)
            guard !review.ignoredSelectors.contains(difference.selector), !review.isAccepted(key, change: difference.change) else { return nil }
            let alsoIn = others.filter { $0.1[difference.id] == difference.comparedValue }.map(\.0)
            return Row(difference: difference, alsoIn: alsoIn, isTracked: review.tracked.contains(key), key: key)
        }
    }

    /// "1 / 3 incelendi": accepted or ignored out of all differences of the pair.
    func reviewed(review: DiffReview) -> (done: Int, total: Int) {
        let all = allDifferences()
        return (all.count - rows(review: review).count, all.count)
    }

    var elementCount: Int {
        snapshots.values.map(\.elements.count).max() ?? 0
    }

    /// Senkron's Göster, in the leader: where the element sits as a share of the page.
    static func shareScript(_ selector: String) -> String {
        let quoted = selector.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
        return """
        (() => {
          const el = document.querySelector('\(quoted)');
          if (!el) return null;
          const r = el.getBoundingClientRect();
          const page = Math.max(document.documentElement.scrollHeight, 1);
          return { x: r.left / innerWidth, w: r.width / innerWidth, y: (r.top + scrollY) / page, h: r.height };
        })()
        """
    }

    /// In the viewport that missed: scrolls to that share of its page and returns the spot in view.
    static func spotScript(y: Double) -> String {
        """
        (() => {
          const page = Math.max(document.documentElement.scrollHeight, 1);
          const target = \(y) * page;
          scrollTo(0, Math.max(0, target - innerHeight / 2));
          return { width: innerWidth, y: target - scrollY };
        })()
        """
    }

    /// Script for Göster: scrolls the element to the middle and returns where it is now.
    static func locateScript(_ selector: String) -> String {
        let quoted = selector.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
        return """
        (() => {
          const el = document.querySelector('\(quoted)');
          if (!el || el.getClientRects().length === 0) return null;
          el.scrollIntoView({ block: 'center', inline: 'nearest' });
          const r = el.getBoundingClientRect();
          return { x: r.left, y: r.top, w: r.width, h: r.height };
        })()
        """
    }
}
