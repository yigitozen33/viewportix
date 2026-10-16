import AppKit
import DesignSystem
import ProjectModel
import SwiftUI

/// The project window's sidebar: header (address, navigation) and the SAYFALAR list.
/// SIDEBAR-01…08 (DESIGN.md §3.2); pages only, devices live in the strip (V1).
struct ProjectSidebar: View {
    @Bindable var workspace: Workspace
    @Binding var pages: [Page]
    @Binding var selection: Page.ID?
    let addCurrentPage: () -> Void

    @State private var renamingID: Page.ID?
    @State private var renameText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SidebarHeader(workspace: workspace)
                .padding(.horizontal, DesignTokens.Space.s3)
                .background(DesignTokens.Color.surfaceBar)
                .zIndex(1)  // the SON menu opens over the page list
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s1) {
                    Text("SAYFALAR")
                        .font(.system(size: DesignTokens.FontSize.micro, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                        .padding(EdgeInsets(top: 14, leading: 10, bottom: 6, trailing: 10))
                    if pages.isEmpty {
                        emptyState
                    }
                    ForEach(pages) { page in
                        SidebarRow(
                            page: page,
                            isSelected: page.id == selection,
                            isEditing: page.id == renamingID,
                            editText: $renameText,
                            select: { selection = page.id },
                            beginRename: { beginRename(page) },
                            commitRename: commitRename,
                            cancelRename: { renamingID = nil },
                            menu: { menu(for: page) }
                        )
                    }
                    if let current = workspace.currentURL, !pages.contains(where: { $0.url.isSamePage(as: current) }) {
                        AddCurrentPageRow(url: current, action: addCurrentPage)
                    }
                    AddPageRow(action: addCurrentPage)
                    if renamingID != nil {
                        Text("↩ kaydet · Esc iptal")
                            .font(.system(size: DesignTokens.FontSize.caption))
                            .foregroundStyle(DesignTokens.Color.inkSecondary)
                            .padding(.leading, 2)
                    }
                }
                .padding(EdgeInsets(top: 0, leading: DesignTokens.Space.s3, bottom: DesignTokens.Space.s3, trailing: DesignTokens.Space.s3))
            }
            .scrollClipDisabled()  // row tooltips may reach past the sidebar
            .scrollIndicators(.never)
        }
        .frame(width: workspace.sidebarWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DesignTokens.Color.surfaceBar)
        .overlay(alignment: .trailing) { SidebarResizeHandle(workspace: workspace) }
        .zIndex(1)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s1) {
            Text("Henüz sayfa yok")
                .font(.system(size: DesignTokens.FontSize.label))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
            Text("Açık sayfayı ⌘D ile ekle.")
                .font(.system(size: DesignTokens.FontSize.caption))
                .foregroundStyle(DesignTokens.Color.inkSecondary)
        }
        .padding(EdgeInsets(top: DesignTokens.Space.s6, leading: 10, bottom: DesignTokens.Space.s6, trailing: 10))
    }

    // MARK: Actions

    private func beginRename(_ page: Page) {
        renameText = page.name
        renamingID = page.id
    }

    private func commitRename() {
        let name = renameText.trimmingCharacters(in: .whitespaces)
        if let id = renamingID, !name.isEmpty, let index = pages.firstIndex(where: { $0.id == id }) {
            pages[index].name = name
        }
        renamingID = nil
    }

    private func move(_ page: Page, by offset: Int) {
        guard let index = pages.firstIndex(where: { $0.id == page.id }) else { return }
        let target = index + offset
        guard pages.indices.contains(target) else { return }
        withAnimation(.easeOut(duration: DesignTokens.Motion.panel)) { pages.swapAt(index, target) }
    }

    private func remove(_ page: Page) {
        withAnimation(.easeOut(duration: DesignTokens.Motion.standard)) { pages.removeAll { $0.id == page.id } }
        if selection == page.id { selection = pages.first?.id }
    }

    /// Page row context menu (`sidebar-page-context-menu@2x.png`).
    private func menu(for page: Page) -> NSMenu {
        let index = pages.firstIndex(where: { $0.id == page.id }) ?? 0
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(ActionMenuItem("Aç", key: "\r", modifiers: []) { selection = page.id })
        menu.addItem(ActionMenuItem("Yeniden adlandır") { beginRename(page) })
        menu.addItem(ActionMenuItem("URL'yi kopyala", key: "c", modifiers: [.command, .shift]) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(page.url.absoluteString, forType: .string)
        })
        menu.addItem(.separator())
        menu.addItem(ActionMenuItem("Yukarı taşı", key: String(UnicodeScalar(NSUpArrowFunctionKey)!), modifiers: [.command, .option],
                                    isEnabled: index > 0) { move(page, by: -1) })
        menu.addItem(ActionMenuItem("Aşağı taşı", key: String(UnicodeScalar(NSDownArrowFunctionKey)!), modifiers: [.command, .option],
                                    isEnabled: index < pages.count - 1) { move(page, by: 1) })
        menu.addItem(.separator())
        let remove = ActionMenuItem("Kaldır", key: "\u{8}", modifiers: []) { self.remove(page) }
        remove.attributedTitle = NSAttributedString(string: "Kaldır", attributes: [.foregroundColor: NSColor(DesignTokens.Color.statusWarning)])
        menu.addItem(remove)
        return menu
    }
}

/// `Sidebar/Row` (specs/SidebarRow.json): default, hover (fill + pencil, ⋯), selected (fill + dot),
/// editing (sky border field). SIDEBAR-02, SIDEBAR-03.
struct SidebarRow: View {
    let page: Page
    let isSelected: Bool
    let isEditing: Bool
    @Binding var editText: String
    let select: () -> Void
    let beginRename: () -> Void
    let commitRename: () -> Void
    let cancelRename: () -> Void
    let menu: () -> NSMenu

    @State private var isHovered = false
    @State private var isMenuOpen = false
    @State private var moreAnchor = MenuAnchor()
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        if isEditing {
            editor
        } else {
            row
        }
    }

    private var row: some View {
        Button(action: select) {
            HStack(spacing: DesignTokens.Space.s2) {
                ChromeSymbol(page.symbol, box: DesignTokens.Size.iconSm)
                    .foregroundStyle(isSelected ? DesignTokens.Color.inkPrimary : DesignTokens.Color.inkSecondary)
                Text(page.name)
                    .font(.system(size: DesignTokens.FontSize.body))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isHovered || isMenuOpen {
                    HStack(spacing: 2) {
                        ChromeIconButton(symbol: "pencil", label: "Yeniden adlandır", box: 12, action: beginRename)
                        ChromeIconButton(symbol: "ellipsis", label: "Diğer", box: 12) {
                            isMenuOpen = true
                            moreAnchor.popUpBelow(menu(), gap: 4)
                            isMenuOpen = false
                        }
                        .background(alignment: .bottomLeading) { MenuAnchorView(anchor: moreAnchor).frame(width: 0, height: 0) }
                    }
                } else if isSelected {
                    Circle().fill(DesignTokens.Color.inkPrimary).frame(width: 6, height: 6)
                }
            }
            .padding(EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10))
            .background(isSelected || isHovered || isMenuOpen ? DesignTokens.Color.surfaceHeader : .clear,
                        in: .rect(cornerRadius: DesignTokens.Radius.control))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture(count: 2).onEnded(beginRename))
        .onHover { isHovered = $0 }
        .animation(.linear(duration: DesignTokens.Motion.hover), value: isHovered)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .chromeContextMenu(isOpen: $isMenuOpen, menu: menu)
        .chromeTooltip(page.name, shortcut: URLHistory.display(page.url), edge: .bottom)
        .accessibilityLabel(page.name)
        .accessibilityValue(isSelected ? "açık" : "")
    }

    private var editor: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            ChromeSymbol(page.symbol, box: DesignTokens.Size.iconSm)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            TextField("", text: $editText)
                .textFieldStyle(.plain)
                .font(.system(size: DesignTokens.FontSize.body))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .focused($isFieldFocused)
                .onSubmit(commitRename)
                .onKeyPress(.escape) { cancelRename(); return .handled }
                .onChange(of: isFieldFocused) { _, focused in if !focused { commitRename() } }
        }
        .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
        .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                .strokeBorder(DesignTokens.Color.statusLeader, lineWidth: DesignTokens.Stroke.hairline)
        }
        .onAppear { isFieldFocused = true }
    }
}

/// "+ Ekle", always last.
private struct AddPageRow: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Space.s2) {
                ChromeSymbol("plus", box: DesignTokens.Size.iconSm)
                Text("Ekle").font(.system(size: DesignTokens.FontSize.body))
                Spacer()
            }
            .foregroundStyle(isHovered ? DesignTokens.Color.inkPrimary : DesignTokens.Color.inkSecondary)
            .padding(EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .chromeTooltip("Açık sayfayı ekle", shortcut: "⌘D", edge: .bottom)
    }
}

/// Yellow-bordered "Bu sayfayı ekle · /path · ⌘D" when the open address is not in the list.
private struct AddCurrentPageRow: View {
    let url: URL
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Space.s2) {
                ChromeSymbol("plus", box: DesignTokens.Size.iconSm)
                    .foregroundStyle(DesignTokens.Color.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Bu sayfayı ekle")
                        .font(.system(size: DesignTokens.FontSize.label))
                        .foregroundStyle(DesignTokens.Color.inkPrimary)
                    Text(url.path.isEmpty ? "/" : url.path)
                        .font(.system(size: DesignTokens.FontSize.micro))
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
                Text("⌘D")
                    .font(.system(size: DesignTokens.FontSize.micro))
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
            }
            .padding(EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                    .strokeBorder(DesignTokens.Color.accent, lineWidth: DesignTokens.Stroke.hairline)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .transition(.opacity)
    }
}

/// SIDEBAR-07, SIDEBAR-08: 6 pt invisible handle; on hover or drag a 2 pt sky edge and the width.
private struct SidebarResizeHandle: View {
    @Bindable var workspace: Workspace
    @State private var isHovered = false
    @State private var dragStart: CGFloat?

    var body: some View {
        ZStack(alignment: .trailing) {
            Rectangle().fill(DesignTokens.Color.line).frame(width: DesignTokens.Stroke.hairline)
            Rectangle().fill(DesignTokens.Color.statusLeader).frame(width: 2)
                .opacity(isHovered || dragStart != nil ? 1 : 0)
        }
        .frame(width: 6, alignment: .trailing)
        .frame(maxHeight: .infinity)
        .contentShape(.rect)
        .pointerStyle(.columnResize)
        .onHover { isHovered = $0 }
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { value in
                    let start = dragStart ?? workspace.sidebarWidth
                    dragStart = start
                    let range = Workspace.sidebarWidthRange
                    // Below 200 it stops; it does not close the sidebar (that is ⌃⌘S).
                    workspace.sidebarWidth = min(max(start + value.translation.width, range.lowerBound), range.upperBound)
                }
                .onEnded { _ in dragStart = nil }
        )
        .overlay(alignment: .topLeading) {
            if dragStart != nil {
                Text("\(Int(workspace.sidebarWidth))")
                    .font(.system(size: DesignTokens.FontSize.caption).monospacedDigit())
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                    .padding(EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6))
                    .background(DesignTokens.Color.surfaceTooltip, in: .rect(cornerRadius: DesignTokens.Radius.badge))
                    .fixedSize()
                    .offset(x: 12, y: 60)
            }
        }
        .animation(.linear(duration: DesignTokens.Motion.hover), value: isHovered)
        .offset(x: 3)  // centred on the sidebar's edge
    }
}

extension Page {
    /// icons.md: house, shippingbox, cart, creditcard; doc.text otherwise.
    var symbol: String {
        switch PageKind(url: url) {
        case .home: "house"
        case .product: "shippingbox"
        case .cart: "cart"
        case .checkout: "creditcard"
        case .other: "doc.text"
        }
    }
}
