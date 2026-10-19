import AppKit
import DesignSystem
import DiffCore
import EngineCore
import ProjectModel
import SwiftUI
import UniformTypeIdentifiers
import WebKit

/// Farklar (DESIGN.md §3.4, `devpanel-diff-calm@2x.png`, `devpanel-diff-zero-calm@2x.png`): the
/// baseline viewport against the one chosen in the header menu (PLAN.md M5 2026-10-19). Calm: only a
/// row that needs attention gets the coral dot and value. A row opens in place (DEV-01) with
/// Kabul A · Yoksay I · Takip et T · Göster ⏎ across its full width; J / K move between rows
/// without animation (DEV-02, K5).
struct DiffPanel: View {
    @Bindable var workspace: Workspace
    @Binding var review: DiffReview

    @State private var openID: String?
    @State private var pairAnchor = MenuAnchor()
    @State private var moreAnchor = MenuAnchor()
    @State private var keyMonitor: Any?
    @State private var modeAnchor = MenuAnchor()

    private var center: DiffCenter { workspace.diffCenter }
    private var rows: [DiffCenter.Row] { center.rows(review: review) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if rows.isEmpty {
                zeroState
            } else {
                columns
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(rows) { row in
                                DiffRow(row: row, isOpen: openID == row.id, name: workspace.viewportName,
                                        baselineName: center.baselineID.map(workspace.viewportName) ?? "",
                                        toggle: { toggle(row) }, decide: { decide($0, row) })
                                    .id(row.id)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .fixedSize(horizontal: false, vertical: rows.count < 14)
                    .onChange(of: openID) { _, id in
                        if let id { proxy.scrollTo(id) }
                    }
                }
                footer
            }
            Spacer(minLength: 0)
        }
        .frame(width: SyncLogPanel.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DesignTokens.Color.surfaceBar)
        .overlay(alignment: .leading) {
            Rectangle().fill(DesignTokens.Color.line).frame(width: DesignTokens.Stroke.hairline)
        }
        .onAppear {
            startKeys()
            center.panelOpened(review: review)
        }
        .onDisappear {
            stopKeys()
            center.highlight = nil
            center.mode = .sideBySide
            center.overlay = nil
        }
        .onChange(of: center.comparedID) {
            if center.mode != .sideBySide { Task { await workspace.captureDiffOverlay() } }
        }
        .onChange(of: center.baselineID) {
            if center.mode != .sideBySide { Task { await workspace.captureDiffOverlay() } }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Farklar")
    }

    // MARK: Parts

    private var pairTitle: String {
        guard let baseline = center.baselineID, let compared = center.comparedID else { return "Karşılaştırılacak viewport yok" }
        return "\(workspace.viewportName(baseline)) ↔ \(workspace.viewportName(compared))"
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Farklar")
                .font(DesignTokens.Font.title)
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .accessibilityAddTraits(.isHeader)
            if center.isComparing {
                // The "iş sürüyor" language (K1/K2): the glyph while viewports are measured.
                AIActivityGlyph(phase: .running).accessibilityLabel("Karşılaştırılıyor")
            }
            Spacer(minLength: 0)
            Button(action: openPairMenu) {
                HStack(spacing: 4) {
                    Text(pairTitle)
                        .font(DesignTokens.Font.caption)
                        .foregroundStyle(DesignTokens.Color.inkPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    ChromeSymbol("chevron.down", box: 12).foregroundStyle(DesignTokens.Color.inkSecondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .background(MenuAnchorView(anchor: pairAnchor))
            .accessibilityLabel("Karşılaştırma")
            .accessibilityValue(pairTitle)
            Button(action: openMoreMenu) {
                ChromeSymbol("ellipsis", box: 14).foregroundStyle(DesignTokens.Color.inkSecondary).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .background(MenuAnchorView(anchor: moreAnchor))
            .accessibilityLabel("Diğer")
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 10, trailing: 16))
    }

    private var columns: some View {
        HStack(spacing: 12) {
            Text("ELEMAN").frame(maxWidth: .infinity, alignment: .leading)
            Text("FARK").frame(width: 64, alignment: .trailing)
        }
        .font(.system(size: DesignTokens.FontSize.micro))
        .tracking(0.6)
        .foregroundStyle(DesignTokens.Color.inkSecondary)
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
        .accessibilityHidden(true)
    }

    /// `Fark yok`: "3 viewport, 142 eleman karşılaştırıldı · az önce".
    private var zeroState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(center.comparedAt == nil ? "Karşılaştırılıyor…" : "Fark yok")
                .font(.system(size: DesignTokens.FontSize.label))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
            if let date = center.comparedAt {
                Text("\(center.snapshots.count) viewport, \(center.elementCount) eleman karşılaştırıldı · \(Self.relative(date))")
                    .font(DesignTokens.Font.caption)
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
            }
        }
        .padding(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        let reviewed = center.reviewed(review: review)
        return HStack(spacing: 12) {
            Button(action: openModeMenu) {
                Text(Self.title(of: center.mode)).foregroundStyle(DesignTokens.Color.inkPrimary).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .background(MenuAnchorView(anchor: modeAnchor))
            .accessibilityLabel("Karşılaştırma modu")
            .accessibilityValue(Self.title(of: center.mode))
            Text("·").foregroundStyle(DesignTokens.Color.inkSecondary).accessibilityHidden(true)
            Text("\(reviewed.done) / \(reviewed.total) incelendi").foregroundStyle(DesignTokens.Color.inkSecondary)
            Spacer(minLength: 0)
            Button(action: exportReport) {
                Text("Rapor").foregroundStyle(DesignTokens.Color.inkPrimary).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .chromeFocusRing(cornerRadius: 4)
        }
        .font(DesignTokens.Font.caption)
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    // MARK: Menus

    /// BASELINE (the leader by default) and KARŞILAŞTIRILAN, each a list of viewports.
    private func openPairMenu() {
        let viewports = workspace.viewports
        var items: [ChromeMenuItem] = [.header("BASELINE")]
        items += viewports.map { viewport in
            .button(viewport.name, shortcut: viewport.id == center.baselineID ? "✓" : nil) {
                center.baselineID = viewport.id
                if center.comparedID == viewport.id { center.comparedID = viewports.first { $0.id != viewport.id }?.id }
                openID = nil
            }
        }
        items += [.separator, .header("KARŞILAŞTIRILAN")]
        items += viewports.filter { $0.id != center.baselineID }.map { viewport in
            .button(viewport.name, shortcut: viewport.id == center.comparedID ? "✓" : nil) {
                center.comparedID = viewport.id
                openID = nil
            }
        }
        pairAnchor.show(ChromeMenu(style: .list, width: 220, items: items), edge: .bottom, alignment: .trailing, gap: DesignTokens.Space.s1)
    }

    static func title(of mode: DiffCenter.Mode) -> String {
        switch mode {
        case .sideBySide: "Yan yana"
        case .overlay: "Üst üste"
        case .blink: "Yanıp sönme"
        }
    }

    /// Yan yana / Üst üste / Yanıp sönme (§3.4 ⋯ "mod"); the overlay is taken when chosen.
    private func openModeMenu() {
        let items: [ChromeMenuItem] = [DiffCenter.Mode.sideBySide, .overlay, .blink].map { mode in
            .button(Self.title(of: mode), isChecked: center.mode == mode) {
                center.mode = mode
                if mode == .sideBySide {
                    center.overlay = nil
                } else {
                    Task { await workspace.captureDiffOverlay() }
                }
            }
        }
        modeAnchor.show(ChromeMenu(width: 180, showsChecks: true, items: items), edge: .bottom, gap: DesignTokens.Space.s1)
    }

    private func openMoreMenu() {
        var items: [ChromeMenuItem] = [
            .button("Yeniden karşılaştır") { Task { await workspace.refreshDiffs(review: review) } },
            .button("Rapor…", action: exportReport),
        ]
        if !review.ignoredSelectors.isEmpty {
            let ignored = review.ignoredSelectors.sorted().map { selector in
                ChromeMenuItem.button(selector, subtitle: "Geri almak için seç") { review.ignoredSelectors.remove(selector) }
            }
            items += [.separator, .submenu("Yoksayılanlar", ChromeMenu(width: 240, items: ignored))]
        }
        moreAnchor.show(ChromeMenu(width: 200, items: items), edge: .bottom, alignment: .trailing, gap: DesignTokens.Space.s1)
    }

    // MARK: Decisions

    enum Decision { case accept, ignore, track, show }

    private func toggle(_ row: DiffCenter.Row) {
        withAnimation(Motion.curve(DesignTokens.Motion.standard)) { openID = openID == row.id ? nil : row.id }
        if openID == nil { center.highlight = nil }
        if let window = NSApp.keyWindow, window.firstResponder is WKWebView { window.makeFirstResponder(nil) }
    }

    /// DEV-03…05 and Göster. Accepting or ignoring drops the row; the next one opens.
    private func decide(_ decision: Decision, _ row: DiffCenter.Row, animated: Bool = true) {
        let next = rows.firstIndex(of: row).flatMap { index in rows.indices.contains(index + 1) ? rows[index + 1].id : nil }
        let change = { [self] in
            switch decision {
            case .accept:
                review.accepted[row.key] = row.difference.change
                review.tracked.remove(row.key)
            case .ignore:
                review.ignoredSelectors.insert(row.difference.selector)
            case .track:
                if review.tracked.contains(row.key) { review.tracked.remove(row.key) } else { review.tracked.insert(row.key) }
            case .show:
                Task { await workspace.showDifference(row) }
            }
            if decision == .accept || decision == .ignore {
                openID = next
                center.highlight = nil
            }
        }
        if animated { withAnimation(Motion.curve(DesignTokens.Motion.standard), change) } else { change() }
    }

    /// J / K and A · I · T · ⏎ on the open row: keyboard decisions are instant (K5). Not while a text
    /// field or a page has the keyboard.
    private func startKeys() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            nonisolated(unsafe) let event = event
            let used = MainActor.assumeIsolated { handleKey(event) }
            return used ? nil : event
        }
    }

    private func stopKeys() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection([.command, .option, .control]).isEmpty,
              let window = event.window, window.isKeyWindow, !(window.firstResponder is NSText) else { return false }
        var view = window.firstResponder as? NSView
        while let current = view {
            if current is WKWebView { return false }
            view = current.superview
        }
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        if key == "j" || key == "k" {
            guard !rows.isEmpty else { return false }
            let index = rows.firstIndex { $0.id == openID }.map { $0 + (key == "j" ? 1 : -1) } ?? (key == "j" ? 0 : rows.count - 1)
            openID = rows[min(max(index, 0), rows.count - 1)].id
            return true
        }
        guard let row = rows.first(where: { $0.id == openID }) else { return false }
        switch key {
        case "a": decide(.accept, row, animated: false)
        case "i", "ı": decide(.ignore, row, animated: false)  // Turkish Q: the I key types "ı"
        case "t": decide(.track, row, animated: false)
        case "\r": decide(.show, row, animated: false)
        default: return false
        }
        return true
    }

    /// Rapor: the pair's differences as Markdown, decisions included.
    private func exportReport() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.nameFieldStringValue = "Farklar.md"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        var lines = ["# Farklar · \(pairTitle)", "", "| Eleman | Özellik | Fark | Durum |", "|---|---|---|---|"]
        for difference in center.allDifferences() {
            let key = center.comparedID.map { DiffReview.key(viewport: $0.rawValue, difference: difference.id) } ?? ""
            let state = review.ignoredSelectors.contains(difference.selector) ? "yoksayıldı"
                : review.isAccepted(key, change: difference.change) ? "kabul" : review.tracked.contains(key) ? "takipte" : "açık"
            lines.append("| `\(difference.selector)` | \(difference.property.rawValue) | \(difference.summary) | \(state) |")
        }
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        } catch {
            ErrorAlert.show(ErrorCode.writing(error), title: "Rapor yazılamadı", error: error)
        }
    }

    static func relative(_ date: Date) -> String {
        if Date.now.timeIntervalSince(date) < 60 { return "az önce" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

private struct DiffRow: View {
    let row: DiffCenter.Row
    let isOpen: Bool
    let name: (ViewportID) -> String
    let baselineName: String
    let toggle: () -> Void
    let decide: (DiffPanel.Decision) -> Void

    private var difference: Difference { row.difference }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: toggle) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(difference.needsAttention ? DesignTokens.Color.statusWarning : .clear)
                        .frame(width: 6, height: 6)
                    HStack(spacing: 8) {
                        Text(difference.selector)
                            .font(.system(size: DesignTokens.FontSize.label))
                            .foregroundStyle(DesignTokens.Color.inkPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text(difference.property.rawValue)
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(DesignTokens.Color.inkSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(row.isTracked ? 0.6 : 1)  // Takip et: stays, faded (DEV-05)
                    Text(difference.summary)
                        .font(.system(size: DesignTokens.FontSize.label).monospacedDigit())
                        .foregroundStyle(difference.needsAttention ? DesignTokens.Color.statusWarning : DesignTokens.Color.inkPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: 64, alignment: .trailing)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            if isOpen {
                Text(detail)
                    .font(DesignTokens.Font.caption)
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 16)
                HStack(spacing: 6) {
                    ActionButton("Kabul", kind: .primary, key: "A") { decide(.accept) }
                    ActionButton("Yoksay", key: "I") { decide(.ignore) }
                    ActionButton(row.isTracked ? "Takibi bırak" : "Takip et", key: "T") { decide(.track) }
                    ActionButton("Göster", key: "⏎") { decide(.show) }
                }
                .transition(.opacity)
            }
        }
        .padding(8)
        .background(isOpen ? DesignTokens.Color.surfaceHeader : .clear, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: "\(difference.selector) \(difference.property.rawValue), \(difference.summary)"))
        .accessibilityValue(difference.needsAttention ? "dikkat" : "")
    }

    /// "284 → 296 px · iPhone 16'da aynı fark · baseline: iPad (lider)".
    private var detail: String {
        var parts = [difference.change]
        // "aynı fark: …" rather than a suffix: Turkish case endings follow each name's last vowel.
        if !row.alsoIn.isEmpty { parts.append("aynı fark: \(row.alsoIn.map(name).joined(separator: ", "))") }
        parts.append("baseline: \(baselineName)")
        return parts.joined(separator: " · ")
    }
}
