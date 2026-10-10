import AppKit
import ProjectModel
import SwiftUI

/// Basic home window (M2): URL box and recent projects. The pen.dev-style version with thumbnails,
/// templates and drafts comes in M3 (DESIGN.md 3.1).
struct HomeView: View {
    static let windowID = "home"

    @Environment(\.newDocument) private var newDocument
    @Environment(\.openDocument) private var openDocument
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var address = ""
    @State private var recentProjects: [URL] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Viewportix").font(.largeTitle.bold())
                Text("Every width. Every engine.").foregroundStyle(.secondary)
            }

            HStack {
                TextField("URL yapıştır…", text: $address)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(openAddress)
                Button("Aç", action: openAddress)
                    .keyboardShortcut(.defaultAction)
                    .disabled(URL(addressBarInput: address) == nil)
            }

            Text("Son Projeler").font(.headline)
            if recentProjects.isEmpty {
                Text("Henüz proje yok.").foregroundStyle(.secondary)
                Spacer()
            } else {
                List(recentProjects, id: \.self) { url in
                    Button { open(url) } label: {
                        VStack(alignment: .leading) {
                            Text(url.deletingPathExtension().lastPathComponent)
                            Text(url.deletingLastPathComponent().path(percentEncoded: false))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(28)
        .frame(width: 560, height: 440)
        .onAppear {
            recentProjects = NSDocumentController.shared.recentDocumentURLs
        }
    }

    private func openAddress() {
        guard let url = URL(addressBarInput: address) else { return }
        newDocument(ProjectDocument(project: .new(url: url)))
        dismissWindow(id: Self.windowID)
    }

    private func open(_ url: URL) {
        Task {
            try? await openDocument(at: url)
            dismissWindow(id: Self.windowID)
        }
    }
}
