import AppKit
import DesignSystem
import DeviceCatalog
import EngineCore
import ProjectModel
import SwiftUI

/// What a tab (and the "+N" chip) shows about its viewport. Severity orders the chip: the most
/// serious hidden state wins (hata > lider > yükleniyor > normal).
enum DeviceTabStatus: Int, Comparable {
    case normal, loading, leader, missed

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// `Window/DeviceStrip` (specs/DeviceStrip.json): floating capsule centred on the canvas, 16 pt from
/// the top. Tabs (STRIP-01, STRIP-02), overflow with ‹ › and the "+N" chip (STRIP-03…06),
/// "+ Cihaz" always on the right (STRIP-07).
struct DeviceStrip: View {
    @Bindable var workspace: Workspace
    /// Widest the strip may get; tabs scroll beyond it.
    let maxWidth: CGFloat
    let remove: (ViewportID) -> Void
    let add: (DevicePreset) -> Void
    let addCustom: (ViewportSize) -> Void
    var collapsedGroups: Set<String> = []
    /// STRIP-12: opens a folded group.
    var openGroup: (String) -> Void = { _ in }

    @State private var tabFrames: [ViewportID: CGRect] = [:]
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollWidth: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var scrollPosition = ScrollPosition(edge: .leading)
    @State private var isMenuOpen = false

    var body: some View {
        HStack(spacing: DesignTokens.Space.s1) {
            if !workspace.viewports.isEmpty {
                if canScrollBack {
                    ChromeIconButton(symbol: "chevron.left", label: "Önceki sekmeler", box: 14) { page(-1) }
                        .padding(.horizontal, 2)
                }
                tabs
                if canScrollForward {
                    ChromeIconButton(symbol: "chevron.right", label: "Sonraki sekmeler", box: 14) { page(1) }
                        .padding(.horizontal, 2)
                }
                if !hiddenIDs.isEmpty {
                    OverflowChip(count: hiddenIDs.count, status: hiddenStatus, isOpen: isMenuOpen) {
                        isMenuOpen.toggle()
                    }
                    .overlay(alignment: .topTrailing) {
                        if isMenuOpen {
                            HiddenDevicesMenu(
                                workspace: workspace,
                                ids: hiddenIDs,
                                status: status(of:),
                                select: { id in
                                    isMenuOpen = false
                                    scrollTo(id)
                                    workspace.reveal(id)
                                },
                                focus: { workspace.reveal($0) },
                                close: remove,
                                dismiss: { isMenuOpen = false }
                            )
                            .offset(y: 27 + DesignTokens.Space.s2)
                            .transition(.opacity.combined(with: .offset(y: -4)))
                        }
                    }
                }
            }
            ChromeButton(icon: .system("plus"), title: "Cihaz", isActive: workspace.isDevicePickerOpen) {
                workspace.isDevicePickerOpen.toggle()
            }
            .chromeTooltip("Cihaz ekle", shortcut: "⌥⌘N", edge: .bottom)
            .accessibilityLabel("Cihaz ekle")
        }
        .padding(DesignTokens.Space.s1)
        .background(DesignTokens.Color.surfaceHeader, in: .rect(cornerRadius: DesignTokens.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
        }
        .overlay(alignment: .topTrailing) {
            // STRIP-07: under "+ Cihaz", right-aligned with the strip, 8 pt below it.
            if workspace.isDevicePickerOpen {
                DevicePicker(
                    viewports: workspace.viewports,
                    add: add,
                    addCustom: addCustom,
                    reveal: { workspace.reveal($0) },
                    dismiss: { workspace.isDevicePickerOpen = false }
                )
                .dismissOnOutsideClick(extra: EdgeInsets(top: 44, leading: 0, bottom: 0, trailing: 0)) {
                    workspace.isDevicePickerOpen = false
                }
                .offset(y: Self.height + DesignTokens.Space.s2)
                .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .animation(.easeOut(duration: DesignTokens.Motion.fast), value: isMenuOpen)
        .animation(.easeOut(duration: DesignTokens.Motion.fast), value: workspace.isDevicePickerOpen)
        .onChange(of: hiddenIDs.isEmpty) { _, empty in if empty { isMenuOpen = false } }
    }

    // MARK: Tabs

    private var tabs: some View {
        ScrollView(.horizontal) {
            HStack(spacing: DesignTokens.Space.s1) {
                ForEach(items, id: \.id) { item in
                    switch item {
                    case .tab(let viewport):
                        DeviceTab(
                            name: viewport.name,
                            detail: "\(viewport.size.width)×\(viewport.size.height)",
                            status: status(of: viewport.id),
                            select: { workspace.reveal(viewport.id) },
                            close: { remove(viewport.id) }
                        )
                        .id(viewport.id)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { tabFrames[viewport.id] = $0 }
                        .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                    case .separator:
                        Rectangle()
                            .fill(DesignTokens.Color.inkSecondary.opacity(0.45))
                            .frame(width: 1, height: 18)
                            .padding(.horizontal, 2)
                    case .folded(let group):
                        FoldedGroupChip(group: group, status: group.members.map(status(of:)).max() ?? .normal) {
                            openGroup(group.key)
                        }
                    }
                }
            }
            .coordinateSpace(.named(Self.space))
        }
        .scrollIndicators(.never)
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: [CGFloat].self) { geometry in
            [geometry.contentOffset.x, geometry.containerSize.width, geometry.contentSize.width]
        } action: { _, values in
            scrollOffset = values[0]
            scrollWidth = values[1]
            contentWidth = values[2]
        }
        .frame(width: min(contentWidth, tabsMaxWidth))
        .mask(fadeMask)
        .animation(.easeOut(duration: DesignTokens.Motion.standard), value: workspace.viewports.map(\.id))
    }

    /// Tabs in group order with separators between groups; a folded group is one chip.
    private enum Item {
        case tab(ViewportConfig)
        case separator(String)
        case folded(ViewportGroup)

        var id: String {
            switch self {
            case .tab(let viewport): viewport.id.rawValue.uuidString
            case .separator(let key): "separator-\(key)"
            case .folded(let group): "group-\(group.key)"
            }
        }
    }

    private var items: [Item] {
        guard !workspace.groups.isEmpty else { return workspace.viewports.map(Item.tab) }
        let byID = Dictionary(uniqueKeysWithValues: workspace.viewports.map { ($0.id, $0) })
        var items: [Item] = []
        for (index, group) in workspace.groups.enumerated() {
            if index > 0 { items.append(.separator(group.key)) }
            if collapsedGroups.contains(group.key) {
                items.append(.folded(group))
            } else {
                items += group.members.compactMap { byID[$0] }.map(Item.tab)
            }
        }
        return items
    }

    private static let space = "DeviceStripTabs"
    /// 27 pt tabs + 4 pt padding above and below.
    static let height: CGFloat = 35

    /// Room for tabs: the strip's limit minus "+ Cihaz", the chip and the arrows.
    private var tabsMaxWidth: CGFloat {
        max(maxWidth - 81 - (contentWidth > maxWidth - 81 ? 120 : 0), 120)
    }

    private var overflows: Bool { contentWidth > scrollWidth + 1 }
    private var canScrollBack: Bool { overflows && scrollOffset > 1 }
    private var canScrollForward: Bool { overflows && scrollOffset + scrollWidth < contentWidth - 1 }

    /// Tabs not fully inside the scroll window.
    private var hiddenIDs: [ViewportID] {
        guard overflows else { return [] }
        return workspace.viewports.map(\.id).filter { id in
            guard let frame = tabFrames[id] else { return false }
            return frame.minX < scrollOffset - 1 || frame.maxX > scrollOffset + scrollWidth + 1
        }
    }

    private var hiddenStatus: DeviceTabStatus {
        hiddenIDs.map(status(of:)).max() ?? .normal
    }

    /// Edge fades where tabs continue (48 pt, `surface/header` to clear in the design).
    private var fadeMask: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                .frame(width: canScrollBack ? 48 : 0)
            Rectangle()
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: canScrollForward ? 48 : 0)
        }
    }

    private func status(of id: ViewportID) -> DeviceTabStatus {
        // A load failure shows the same coral triangle as a missed sync (card-load-errors@2x.png).
        if workspace.missedIDs.contains(id) || workspace.loadFailures[id] != nil { return .missed }
        if workspace.leaderID == id { return .leader }
        if workspace.loadingIDs.contains(id) { return .loading }
        return .normal
    }

    private func page(_ direction: CGFloat) {
        let target = min(max(scrollOffset + direction * scrollWidth * 0.8, 0), contentWidth - scrollWidth)
        withAnimation(.easeOut(duration: DesignTokens.Motion.canvasPan)) { scrollPosition.scrollTo(x: target) }
    }

    private func scrollTo(_ id: ViewportID) {
        withAnimation(.easeOut(duration: DesignTokens.Motion.canvasPan)) { scrollPosition.scrollTo(id: id) }
    }
}

/// `Toolbar/DeviceTab` (specs/DeviceTab.json): name, status icon, ✕. Leader: `surface/header-leader`
/// with a sky border; sync missed: coral triangle; loading: spinner. The name never hides the status;
/// it shortens from the end past 140 pt (DESIGN.md §5.20 d).
struct DeviceTab: View {
    let name: String
    let detail: String
    let status: DeviceTabStatus
    let select: () -> Void
    let close: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            Button(action: select) {
                HStack(spacing: DesignTokens.Space.s2) {
                    Text(name)
                        .font(.system(size: DesignTokens.FontSize.label))
                        .foregroundStyle(DesignTokens.Color.inkPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 101, alignment: .leading)
                        .fixedSize(horizontal: true, vertical: false)
                    statusIcon
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            Button(action: close) {
                ChromeSymbol("xmark", box: 12)
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(name)'ı kapat")
        }
        .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
        .background(fill, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .overlay {
            if status == .leader {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                    .strokeBorder(DesignTokens.Color.statusLeader, lineWidth: DesignTokens.Stroke.hairline)
            }
        }
        .onHover { isHovered = $0 }
        .animation(.linear(duration: DesignTokens.Motion.hover), value: status)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .chromeTooltip(name, shortcut: detail, edge: .bottom)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(name)
        .accessibilityValue([detail, status.accessibilityText].compactMap(\.self).joined(separator: ", "))
    }

    private var fill: Color {
        status == .leader || isHovered ? DesignTokens.Color.surfaceHeaderLeader : DesignTokens.Color.surfaceCard
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .missed:
            ChromeSymbol("exclamationmark.triangle", box: 13).foregroundStyle(DesignTokens.Color.statusWarning)
        case .loading:
            ProgressView().controlSize(.mini).frame(width: 13, height: 13)
        case .leader, .normal:
            EmptyView()
        }
    }
}

extension DeviceTabStatus {
    var accessibilityText: String? {
        switch self {
        case .normal: nil
        case .loading: "yükleniyor"
        case .leader: "lider"
        case .missed: "senkron kaçtı"
        }
    }
}

/// "+N" chip: `surface/pill`; border and icon from the most serious hidden state.
private struct OverflowChip: View {
    let count: Int
    let status: DeviceTabStatus
    let isOpen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("+\(count)")
                    .font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                switch status {
                case .missed:
                    ChromeSymbol("exclamationmark.triangle", box: 13).foregroundStyle(DesignTokens.Color.statusWarning)
                case .leader:
                    ChromeSymbol("eye", box: 13).foregroundStyle(DesignTokens.Color.statusLeader)
                case .loading:
                    ProgressView().controlSize(.mini).frame(width: 13, height: 13)
                case .normal:
                    EmptyView()
                }
                ChromeSymbol("chevron.down", box: 12).foregroundStyle(DesignTokens.Color.inkSecondary)
            }
            .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
            .background(isOpen ? DesignTokens.Color.surfaceHeaderLeader : DesignTokens.Color.surfacePill,
                        in: .rect(cornerRadius: DesignTokens.Radius.control))
            .overlay {
                if let border {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.control).strokeBorder(border, lineWidth: DesignTokens.Stroke.hairline)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .accessibilityLabel("\(count) gizli cihaz")
        .accessibilityHint("menüyü açar")
    }

    private var border: Color? {
        switch status {
        case .missed: DesignTokens.Color.statusWarning
        case .leader: DesignTokens.Color.statusLeader
        case .loading, .normal: nil
        }
    }
}

/// "GİZLİ CİHAZLAR" menu under the chip (`tab-states-overflow-menu@2x.png`): row click scrolls the
/// strip to the tab and selects it (STRIP-04), focus pans the canvas and keeps the menu open
/// (STRIP-05), ✕ closes the viewport (STRIP-06). Esc or a click outside closes the menu.
private struct HiddenDevicesMenu: View {
    let workspace: Workspace
    let ids: [ViewportID]
    let status: (ViewportID) -> DeviceTabStatus
    let select: (ViewportID) -> Void
    let focus: (ViewportID) -> Void
    let close: (ViewportID) -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("GİZLİ CİHAZLAR · tıkla: sekmeye kaydır")
                .font(.system(size: DesignTokens.FontSize.micro, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
                .padding(EdgeInsets(top: 8, leading: 10, bottom: 6, trailing: 10))
            ForEach(ids, id: \.self) { id in
                if let viewport = workspace.viewports.first(where: { $0.id == id }) {
                    row(viewport, status: status(id))
                }
            }
        }
        .padding(6)
        .frame(width: 340)
        .chromeSurface()
        .fixedSize()
        .dismissOnOutsideClick(extra: EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 0), dismiss)
    }

    private func row(_ viewport: ViewportConfig, status: DeviceTabStatus) -> some View {
        let isMissed = status == .missed
        return HStack(spacing: 10) {
            ChromeSymbol(viewport.deviceSymbol, box: DesignTokens.Size.iconSm)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(viewport.name)
                    .font(.system(size: DesignTokens.FontSize.label, weight: .medium))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                Text(meta(viewport, status: status))
                    .font(.system(size: DesignTokens.FontSize.caption))
                    .foregroundStyle(isMissed ? DesignTokens.Color.statusWarning : DesignTokens.Color.inkSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            switch status {
            case .missed: ChromeSymbol("exclamationmark.triangle", box: 13).foregroundStyle(DesignTokens.Color.statusWarning)
            case .loading: ProgressView().controlSize(.mini).frame(width: 13, height: 13)
            case .leader: ChromeSymbol("eye", box: 13).foregroundStyle(DesignTokens.Color.statusLeader)
            case .normal: EmptyView()
            }
            ChromeIconButton(symbol: "viewfinder", label: "Odakla", box: 14) { focus(viewport.id) }
            ChromeIconButton(symbol: "xmark", label: "Kapat", box: 13) { close(viewport.id) }
        }
        .padding(EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10))
        .background(isMissed ? DesignTokens.Color.statusWarningBg : .clear, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .contentShape(.rect)
        .onTapGesture { select(viewport.id) }
    }

    private func meta(_ viewport: ViewportConfig, status: DeviceTabStatus) -> String {
        var parts = ["\(viewport.size.width)×\(viewport.size.height)", viewport.engine.displayName]
        switch status {
        case .missed: parts.append("Element bulunamadı")
        case .loading: parts.append("Yükleniyor")
        case .leader: parts.append("Lider")
        case .normal: break
        }
        return parts.joined(separator: " · ")
    }
}

extension ViewportConfig {
    /// icons.md: smartphone → iphone, tablet → ipad, laptop → laptopcomputer, monitor → display.
    var deviceSymbol: String {
        switch presetID.flatMap(DeviceCatalog.preset(id:))?.category {
        case .phone: "iphone"
        case .tablet: "ipad"
        case .desktop: presetID == "laptop" ? "laptopcomputer" : "display"
        case nil: size.width < 600 ? "iphone" : size.width < 1100 ? "ipad" : "display"
        }
    }
}

extension EngineKind {
    var displayName: String {
        switch self {
        case .webKit: "WebKit"
        case .chromium: "Chromium"
        case .firefox: "Firefox"
        }
    }
}

/// A folded group in the strip: "Telefon 2 ›", carrying the group's most serious state.
private struct FoldedGroupChip: View {
    let group: ViewportGroup
    let status: DeviceTabStatus
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: DesignTokens.Space.s2) {
                Text(group.title)
                    .font(.system(size: DesignTokens.FontSize.label))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                Text("\(group.members.count)")
                    .font(.system(size: DesignTokens.FontSize.label))
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                if status == .missed {
                    ChromeSymbol("exclamationmark.triangle", box: 13).foregroundStyle(DesignTokens.Color.statusWarning)
                }
                ChromeSymbol("chevron.right", box: 12).foregroundStyle(DesignTokens.Color.inkSecondary)
            }
            .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
            .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.control))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .chromeTooltip("\(group.title) grubunu aç", edge: .bottom)
        .accessibilityLabel("\(group.title) grubu")
        .accessibilityValue("\(group.members.count) cihaz; katlı")
    }
}
