import DesignSystem
import ProjectModel
import SwiftUI

/// `Sidebar/Header` (specs/SidebarHeader.json): 48 pt traffic-light row (the system buttons sit
/// there), address field, back / forward / reload.
struct SidebarHeader: View {
    @Bindable var workspace: Workspace

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s1) {
            // The traffic lights' row; 16 pt in full screen, where there are none (§5.20 b).
            Color.clear.frame(height: workspace.isFullScreen ? 16 : 48)
            AddressField(workspace: workspace)
            NavButtons(workspace: workspace, spacing: 14)
                .padding(EdgeInsets(top: 6, leading: 8, bottom: 2, trailing: 8))
        }
        .trafficLights(leading: 15, centerY: 24)
    }
}

/// `Window/CollapsedHeader` (specs/CollapsedSidebarHeader.json): with the sidebar hidden, the traffic
/// lights, sidebar button, navigation and address move into one capsule at the canvas's top left.
struct CollapsedSidebarHeader: View {
    @Bindable var workspace: Workspace

    var body: some View {
        HStack(spacing: 10) {
            // The system traffic lights are moved over this space.
            Color.clear.frame(width: 60, height: 12)
            Rectangle().fill(DesignTokens.Color.line).frame(width: 1, height: 18)
            ChromeIconButton(symbol: "sidebar.left", label: "Kenar çubuğunu göster", shortcut: "⌃⌘S") {
                withAnimation(.easeInOut(duration: DesignTokens.Motion.panel)) { workspace.isSidebarVisible = true }
            }
            NavButtons(workspace: workspace, spacing: 10)
            AddressField(workspace: workspace, isCompact: true)
                .frame(width: 191)
        }
        .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
        .background(DesignTokens.Color.surfaceHeader, in: .rect(cornerRadius: DesignTokens.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
        }
        // Capsule at (16, 16) on the canvas: lights start 10 + 4 pt inside it, centred in its 38 pt.
        .trafficLights(leading: 29, centerY: 35)
    }
}

/// Back, forward, reload: 16 pt, `ink/secondary`.
struct NavButtons: View {
    let workspace: Workspace
    let spacing: CGFloat

    var body: some View {
        HStack(spacing: spacing) {
            ChromeIconButton(symbol: "chevron.left", label: "Geri", shortcut: "⌘[", action: workspace.goBack)
            ChromeIconButton(symbol: "chevron.right", label: "İleri", shortcut: "⌘]", action: workspace.goForward)
            ChromeIconButton(symbol: "arrow.clockwise", label: "Yenile", shortcut: "⌘R", action: workspace.reload)
        }
    }
}

/// A bare 16 pt icon that brightens on hover; used where the design draws icons without a button body.
struct ChromeIconButton: View {
    let symbol: String
    let label: String
    var shortcut: String?
    var box: CGFloat = DesignTokens.Size.icon
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ChromeSymbol(symbol, box: box)
                .foregroundStyle(isHovered ? DesignTokens.Color.inkPrimary : DesignTokens.Color.inkSecondary)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .chromeFocusRing(cornerRadius: 4)
        .chromeTooltip(label, shortcut: shortcut, edge: .bottom)
        .accessibilityLabel(label)
    }
}

/// The address field of the sidebar header and the collapsed capsule. Focused: sky border and the
/// SON menu (last 5 addresses) below it (SIDEBAR-01). ⌘L focuses, ⏎ loads, Esc reverts.
struct AddressField: View {
    @Bindable var workspace: Workspace
    var isCompact = false

    @FocusState private var isFocused: Bool
    @State private var hasEdited = false
    @State private var highlighted: Int?

    var body: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            ChromeSymbol(isSecure ? "lock" : "globe", box: 13)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            ZStack(alignment: .leading) {
                TextField("", text: $workspace.addressText, prompt: Text("Adres yaz ya da yapıştır").foregroundStyle(DesignTokens.Color.inkSecondary))
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .opacity(isFocused || workspace.addressText.isEmpty ? 1 : 0)
                    .onSubmit(submit)
                    .onKeyPress(.escape) {
                        workspace.revertAddress()
                        isFocused = false
                        return .handled
                    }
                    .onKeyPress(.downArrow) { move(1) }
                    .onKeyPress(.upArrow) { move(-1) }
                    .accessibilityLabel("Adres")
                if !isFocused && !workspace.addressText.isEmpty {
                    // Unfocused: the domain stays, the path shortens in the middle (DESIGN.md §5.20 d).
                    Text(workspace.addressText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .allowsHitTesting(false)
                }
            }
            .font(.system(size: DesignTokens.FontSize.body))
            .foregroundStyle(DesignTokens.Color.inkPrimary)
        }
        .padding(EdgeInsets(top: isCompact ? 5 : 7, leading: 12, bottom: isCompact ? 5 : 7, trailing: 12))
        .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                .strokeBorder(DesignTokens.Color.statusLeader, lineWidth: DesignTokens.Stroke.hairline)
                .opacity(isFocused ? 1 : 0)
        }
        .contentShape(.rect)
        .onTapGesture { isFocused = true }
        .overlay(alignment: .topLeading) {
            if isFocused, !suggestions.isEmpty {
                RecentAddressMenu(
                    entries: suggestions, highlighted: highlighted,
                    open: { open($0.url) },
                    clear: { workspace.history.clear() }
                )
                .alignmentGuide(.top) { $0[.top] - fieldHeight - 4 }
                .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .animation(.easeOut(duration: DesignTokens.Motion.fast), value: isFocused)
        .onChange(of: workspace.addressFocusRequest) { isFocused = true }
        .onChange(of: isFocused) { _, focused in
            hasEdited = false
            highlighted = nil
            if !focused { workspace.revertAddress() }
        }
        .onChange(of: workspace.addressText) {
            if isFocused { hasEdited = true; highlighted = nil }
        }
    }

    private var fieldHeight: CGFloat { isCompact ? 26 : 30 }

    private var isSecure: Bool {
        workspace.addressText.hasPrefix("https://")
    }

    /// Filtered by what was typed; before typing, the latest five.
    private var suggestions: [URLHistory.Entry] {
        workspace.history.history.suggestions(for: hasEdited ? workspace.addressText : "")
    }

    private func move(_ step: Int) -> KeyPress.Result {
        guard !suggestions.isEmpty else { return .ignored }
        let next = (highlighted ?? (step > 0 ? -1 : suggestions.count)) + step
        highlighted = min(max(next, 0), suggestions.count - 1)
        return .handled
    }

    private func submit() {
        if let highlighted, suggestions.indices.contains(highlighted) {
            open(suggestions[highlighted].url)
        } else {
            workspace.submitAddress()
            isFocused = false
        }
    }

    private func open(_ url: URL) {
        workspace.navigate(to: url)
        isFocused = false
    }
}

/// SON menu under the address field (`window-project-url-recent@2x.png`).
private struct RecentAddressMenu: View {
    let entries: [URLHistory.Entry]
    let highlighted: Int?
    let open: (URLHistory.Entry) -> Void
    let clear: () -> Void

    @State private var hovered: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SON")
                    .font(.system(size: DesignTokens.FontSize.micro, weight: .semibold))
                    .tracking(0.8)
                Spacer()
                ChromeSymbol("return", box: 12)
            }
            .foregroundStyle(DesignTokens.Color.inkSecondary)
            .padding(EdgeInsets(top: 10, leading: 12, bottom: 6, trailing: 12))

            ForEach(Array(entries.enumerated()), id: \.element.url) { index, entry in
                Button { open(entry) } label: {
                    HStack(spacing: DesignTokens.Space.s2) {
                        Favicon()
                        VStack(alignment: .leading, spacing: 1) {
                            Text(URLHistory.display(entry.url))
                                .font(.system(size: DesignTokens.FontSize.label))
                                .foregroundStyle(DesignTokens.Color.inkPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text(Self.relative(entry.date))
                                .font(.system(size: DesignTokens.FontSize.micro))
                                .foregroundStyle(DesignTokens.Color.inkSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
                    .background(isActive(index, entry) ? DesignTokens.Color.surfaceHeaderLeader : .clear,
                                in: .rect(cornerRadius: DesignTokens.Radius.badge))
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .onHover { hovered = $0 ? entry.url : nil }
                .padding(.horizontal, 4)
            }

            Rectangle().fill(DesignTokens.Color.line).frame(height: 1).padding(.horizontal, 4).padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Button("Geçmişi temizle", action: clear)
                    .buttonStyle(.plain)
                    .font(.system(size: DesignTokens.FontSize.label))
                Text("Listeye ekle: ⌘D")
                    .font(.system(size: DesignTokens.FontSize.caption))
            }
            .foregroundStyle(DesignTokens.Color.inkSecondary)
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 10, trailing: 12))
        }
        .frame(minWidth: 216, alignment: .leading)
        .chromeSurface()
    }

    private func isActive(_ index: Int, _ entry: URLHistory.Entry) -> Bool {
        highlighted == index || (highlighted == nil && hovered == entry.url)
    }

    /// "2 dk. önce", "dün".
    private static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .abbreviated
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
