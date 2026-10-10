import ProjectModel
import SwiftUI

/// Placeholder until the canvas exists; proves the app links ViewportixKit.
struct ContentView: View {
    private let project = Project.new(url: URL(string: "https://example.com")!)

    var body: some View {
        VStack(spacing: 12) {
            Text("Viewportix")
                .font(.largeTitle)
            Text("Every width. Every engine.")
                .foregroundStyle(.secondary)
            ForEach(project.viewports) { viewport in
                // Verbatim: CSS pixel sizes must not get locale grouping ("1.180").
                Text(verbatim: "\(viewport.name) · \(viewport.size.width)×\(viewport.size.height)")
                    .monospacedDigit()
            }
        }
        .padding(40)
        .frame(minWidth: 640, minHeight: 400)
    }
}

#Preview {
    ContentView()
}
