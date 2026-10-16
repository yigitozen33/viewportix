#if DEBUG
import AppKit
import DesignSystem
import SwiftUI

/// `--snapshots <folder>`: renders chrome previews to @2x PNGs and quits. Stands in for Xcode's
/// preview canvas, which can't build the signed app target here ("No Accounts"); used for parity
/// rounds (`docs/parity/`, design/handoff/PLAN.md stage 8).
@MainActor
enum PreviewSnapshots {
    static var folder: URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--snapshots"),
              CommandLine.arguments.indices.contains(index + 1) else { return nil }
        return URL(filePath: CommandLine.arguments[index + 1], directoryHint: .isDirectory)
    }

    /// Name → view. Each is rendered on the canvas colour with 24 pt of margin unless it fills itself.
    static var entries: [(String, AnyView)] {
        [
            ("BottomBar-syncOn", AnyView(bottomBar(syncOn: true).padding(24).background(DesignTokens.Color.canvas))),
            ("BottomBar-syncOff", AnyView(bottomBar(syncOn: false).padding(24).background(DesignTokens.Color.canvas))),
            ("BottomBar-zoom25", AnyView(bottomBar(syncOn: true, zoom: 0.25).padding(24).background(DesignTokens.Color.canvas))),
            ("BottomBar-zoom400", AnyView(bottomBar(syncOn: true, zoom: 4).padding(24).background(DesignTokens.Color.canvas))),
        ]
    }

    static func bottomBar(syncOn: Bool, zoom: Double = 1) -> some View {
        let workspace = Workspace()
        workspace.isSyncEnabled = syncOn
        workspace.zoom = zoom
        return BottomBar(workspace: workspace, isMenuOpen: .constant(false))
    }

    static func runIfRequested() {
        guard let folder else { return }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, view) in entries {
            let renderer = ImageRenderer(content: view.environment(\.colorScheme, .dark))
            renderer.scale = 2
            guard let image = renderer.cgImage else {
                print("SNAPSHOT \(name) failed")
                continue
            }
            let rep = NSBitmapImageRep(cgImage: image)
            let url = folder.appending(path: "\(name)@2x.png")
            try? rep.representation(using: .png, properties: [:])?.write(to: url)
            print("SNAPSHOT \(name) \(image.width)x\(image.height) → \(url.path)")
        }
        exit(0)
    }
}
#endif
