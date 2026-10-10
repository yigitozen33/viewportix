import ProjectModel
import SwiftUI

/// The project's pages (home, product, cart...). Selecting one loads it in every viewport.
struct PageSidebar: View {
    @Binding var pages: [Page]
    @Binding var selection: Page.ID?
    let currentURL: URL?
    let currentTitle: String

    @State private var renamingID: Page.ID?

    var body: some View {
        List(selection: $selection) {
            Section("Sayfalar") {
                ForEach($pages) { $page in
                    row(for: $page)
                        .tag(page.id)
                        .contextMenu {
                            Button("Yeniden Adlandır") { renamingID = page.id }
                            Button("Kaldır", role: .destructive) { remove(page.id) }
                        }
                }
                .onMove { pages.move(fromOffsets: $0, toOffset: $1) }
            }
        }
        .onDeleteCommand {
            if let selection { remove(selection) }
        }
        .overlay {
            if pages.isEmpty {
                ContentUnavailableView("Henüz sayfa yok", systemImage: "doc", description: Text("Bir adres aç, sonra listeye ekle."))
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let currentURL, !pages.contains(where: { $0.url == currentURL }) {
                Button {
                    addCurrentPage(currentURL)
                } label: {
                    Label("Bu sayfayı ekle", systemImage: "plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .padding(12)
            }
        }
    }

    @ViewBuilder
    private func row(for page: Binding<Page>) -> some View {
        if renamingID == page.wrappedValue.id {
            TextField("Sayfa adı", text: page.name)
                .onSubmit { renamingID = nil }
        } else {
            Label(page.wrappedValue.name, systemImage: "doc.text")
                .help(page.wrappedValue.url.absoluteString)
        }
    }

    private func addCurrentPage(_ url: URL) {
        let title = currentTitle.trimmingCharacters(in: .whitespaces)
        let page = Page(name: title.isEmpty ? (url.host() ?? url.absoluteString) : title, url: url)
        pages.append(page)
        selection = page.id
    }

    private func remove(_ id: Page.ID) {
        pages.removeAll { $0.id == id }
        if selection == id { selection = pages.first?.id }
    }
}
