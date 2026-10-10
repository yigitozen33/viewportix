import ProjectModel
import SwiftUI

struct ProjectWindow: View {
    @Binding var document: ProjectDocument
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var workspace = Workspace()
    @State private var selectedPageID: Page.ID?

    init(document: Binding<ProjectDocument>) {
        _document = document
        _selectedPageID = State(initialValue: document.wrappedValue.project.selectedPageID)
    }

    var body: some View {
        NavigationSplitView {
            PageSidebar(
                pages: $document.project.pages,
                selection: $selectedPageID,
                currentURL: workspace.currentURL,
                currentTitle: workspace.currentTitle
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        } detail: {
            CanvasView(workspace: workspace) { id in
                document.project.viewports.removeAll { $0.id == id }
            }
            .overlay {
                if document.project.viewports.isEmpty {
                    ContentUnavailableView("Viewport yok", systemImage: "rectangle.dashed", description: Text("Toolbar'daki + Cihaz ile ekle."))
                }
            }
        }
        .toolbar {
            ProjectToolbar(workspace: workspace) { preset in
                document.project.viewports.append(ViewportConfig(preset: preset))
            }
        }
        .focusedSceneValue(\.workspace, workspace)
        .onAppear {
            // Opening a project from Finder or Open Recent should not leave the home window behind.
            dismissWindow(id: HomeView.windowID)
            workspace.reconcile(with: document.project.viewports)
            if let page = document.project.selectedPage {
                workspace.navigate(to: page.url)
            }
            #if DEBUG
            if PerfProbe.isRequested {
                Task { await PerfProbe.run(workspace) }
            }
            #endif
        }
        .onChange(of: document.project.viewports) { _, viewports in
            workspace.reconcile(with: viewports)
        }
        .onChange(of: selectedPageID) { _, id in
            document.project.selectedPageID = id
            guard let page = document.project.pages.first(where: { $0.id == id }),
                  page.url != workspace.currentURL else { return }
            workspace.navigate(to: page.url)
        }
    }
}

extension FocusedValues {
    @Entry var workspace: Workspace?
}
