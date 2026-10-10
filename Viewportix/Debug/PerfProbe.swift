#if DEBUG
import AppKit
import EngineCore

/// Scripted profiling run, started with `--perf` (see Scripts/perf.sh). Prints `PERF ...` lines the
/// script uses to tag its CPU/memory samples by phase: load → idle → scroll (leader scrolls smoothly
/// for 8 s, followers mirror it) → done.
@MainActor
enum PerfProbe {
    static var isRequested: Bool { CommandLine.arguments.contains("--perf") }
    static var isCaptureRequested: Bool { CommandLine.arguments.contains("--capture-probe") }

    /// `--capture-probe`: after load, captures all viewports (visible, then full page) and prints the files.
    static func runCapture(_ workspace: Workspace) async {
        try? await Task.sleep(for: .seconds(1))
        while workspace.isLoading { try? await Task.sleep(for: .milliseconds(200)) }
        try? await Task.sleep(for: .seconds(2))
        for area in [SnapshotArea.visible, .fullPage] {
            let started = ContinuousClock.now
            await workspace.captureAll(area: area)
            log("CAPTURE \(area) \(milliseconds(ContinuousClock.now - started)) ms → \(workspace.notice?.fileURL?.path ?? workspace.notice?.text ?? "nothing")")
        }
        try? await Task.sleep(for: .seconds(1))
        NSApp.terminate(nil)
    }

    private static let scrollSeconds = 8

    static func run(_ workspace: Workspace) async {
        log("PHASE load viewports=\(workspace.viewports.count) url=\(workspace.currentURL?.absoluteString ?? "-")")
        let started = ContinuousClock.now
        try? await Task.sleep(for: .seconds(1))
        while workspace.isLoading, ContinuousClock.now - started < .seconds(60) {
            try? await Task.sleep(for: .milliseconds(200))
        }
        log("LOADED after \(milliseconds(ContinuousClock.now - started)) ms")
        try? await Task.sleep(for: .seconds(3))  // late images, fonts, scripts

        // A leader as if the pointer rested on the first viewport, so background media rules apply.
        guard let leaderID = workspace.viewports.first?.id, let leader = workspace.session(for: leaderID) else { return }
        workspace.setLeader(leaderID)
        log("PHASE idle suspendBackgroundMedia=\(workspace.suspendsBackgroundMedia)")
        try? await Task.sleep(for: .seconds(8))

        workspace.resetSyncStats()
        log("PHASE scroll leader=\(workspace.viewports[0].name)")
        _ = try? await leader.evaluate("""
            (() => {
              const start = performance.now();
              const step = (now) => {
                window.scrollBy(0, 14);
                if (now - start < \(scrollSeconds * 1000)) requestAnimationFrame(step);
              };
              requestAnimationFrame(step);
              return true;
            })()
            """)
        try? await Task.sleep(for: .seconds(scrollSeconds + 1))

        let stats = workspace.syncStats
        let followers = max(1, workspace.viewports.count - 1)
        log("STATS mirrored=\(stats.mirrored) applied=\(stats.applied) expected=\(stats.mirrored * followers) coalesced=\(stats.coalesced) missed=\(stats.missed) avgApplyMs=\(milliseconds(stats.averageApplyTime)) maxApplyMs=\(milliseconds(stats.maxApplyTime))")
        if stats.mirrored == 0 {
            log("STATS WARNING no scroll events: the window was probably hidden, so WebKit paused the page. Rerun with the window visible.")
        }
        for viewport in workspace.viewports {
            let y = try? await workspace.session(for: viewport.id)?.evaluate("Math.round(window.scrollY)")
            log("SCROLLY \(viewport.name)=\(y.map { "\($0)" } ?? "?")")
        }

        log("PHASE done")
        try? await Task.sleep(for: .seconds(1))
        NSApp.terminate(nil)
    }

    private static func milliseconds(_ duration: Duration) -> String {
        let (seconds, attoseconds) = duration.components
        return String(format: "%.1f", Double(seconds) * 1000 + Double(attoseconds) / 1e15)
    }

    private static func log(_ message: String) {
        print("PERF \(message)")
        fflush(stdout)
    }
}
#endif
