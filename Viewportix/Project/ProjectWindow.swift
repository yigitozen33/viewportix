import DesignSystem
import EngineCore
import ProjectModel
import SwiftUI

struct ProjectWindow: View {
    @Binding var document: ProjectDocument
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var workspace = Workspace()
    @State private var selectedPageID: Page.ID?
    @State private var sizeEditor: ViewportSizeEditor?
    @State private var isBarMenuOpen = false

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
            CanvasView(workspace: workspace, onCommand: handle)
            .overlay(alignment: .bottom) {
                // 28 pt gap measured in window-project-dark@2x.png; no spec value yet.
                VStack(spacing: 28) {
                    // The notice sits above the bottom bar and hides while a bar menu is open.
                    if let notice = workspace.notice, !isBarMenuOpen {
                        NoticeBar(notice: notice, dismiss: workspace.dismissNotice)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    BottomBar(workspace: workspace, isMenuOpen: $isBarMenuOpen)
                }
                .padding(.bottom, BottomBar.bottomInset)
            }
            .animation(.snappy, value: workspace.notice)
            .overlay {
                if document.project.viewports.isEmpty {
                    ContentUnavailableView("Viewport yok", systemImage: "rectangle.dashed", description: Text("Toolbar'daki + Cihaz ile ekle."))
                }
            }
        }
        .toolbar {
            ProjectToolbar(workspace: workspace) { preset in
                document.project.viewports.append(ViewportConfig(preset: preset))
            } onAddCustomSize: {
                sizeEditor = ViewportSizeEditor()
            }
        }
        .sheet(item: $sizeEditor) { editor in
            ViewportSizeSheet(editor: editor, onSave: save)
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
            } else if PerfProbe.isCaptureRequested {
                Task { await PerfProbe.runCapture(workspace) }
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

private extension ProjectWindow {
    func handle(_ id: ViewportID, _ command: ViewportCommand) {
        guard let index = document.project.viewports.firstIndex(where: { $0.id == id }) else { return }
        switch command {
        case .remove:
            document.project.viewports.remove(at: index)
        case .rotate:
            document.project.viewports[index].rotate()
        case .editSize:
            sizeEditor = ViewportSizeEditor(editing: document.project.viewports[index])
        case .toggleSync:
            document.project.viewports[index].isSyncEnabled.toggle()
        case .capture:
            break  // handled by the canvas
        }
    }

    func save(_ editor: ViewportSizeEditor) {
        let size = ViewportSize(width: editor.width, height: editor.height)
        let name = editor.name.trimmingCharacters(in: .whitespaces)
        if let id = editor.viewportID, let index = document.project.viewports.firstIndex(where: { $0.id == id }) {
            document.project.viewports[index].size = size
            if !name.isEmpty { document.project.viewports[index].name = name }
        } else {
            document.project.viewports.append(ViewportConfig(name: name.isEmpty ? "Özel" : name, size: size))
        }
    }
}

extension FocusedValues {
    @Entry var workspace: Workspace?
}
