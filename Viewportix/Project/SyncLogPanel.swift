import AppKit
import DesignSystem
import EngineCore
import ProjectModel
import SwiftUI
import SyncCore
import UniformTypeIdentifiers
import WebKit

/// Senkron (DESIGN.md §3.4, `devpanel-synclog-calm@2x.png`, pen `Dev Panel · Senkron (sakin)`):
/// 320 pt, docked left of the rail, pushes the canvas. Calm: no colour until something is missed,
/// then only the count turns coral. A row opens in place (DEV-01): what was missed, and the actions
/// Yeniden dene R · Göster ⏎ · Teşhis et D across the full width (K4 f, §15 b).
struct SyncLogPanel: View {
    @Bindable var workspace: Workspace

    @State private var openID: UUID?
    @State private var onlyMissed = false
    /// Rows that came in while the list was scrolled away from the newest (DEV-08).
    @State private var unseen = 0
    @State private var isAtTop = true
    @State private var liveAnchor = MenuAnchor()
    @State private var moreAnchor = MenuAnchor()
    @State private var keyMonitor: Any?
    @State private var scopeAnchor = MenuAnchor()

    static let width: CGFloat = 320

    private var rows: [SyncLog.Entry] {
        onlyMissed ? workspace.syncLog.filter(\.isMissed) : workspace.syncLog
    }

    /// One list, newest first: sync events, and in the developer scope console and network lines.
    private enum LogItem: Identifiable {
        case sync(SyncLog.Entry)
        case developer(Workspace.DeveloperEntry)

        var id: UUID {
            switch self {
            case .sync(let entry): entry.id
            case .developer(let entry): entry.id
            }
        }

        var time: Date {
            switch self {
            case .sync(let entry): entry.time
            case .developer(let entry): entry.time
            }
        }
    }

    private var items: [LogItem] {
        let sync = rows.map(LogItem.sync)
        guard workspace.isDeveloperScope else { return sync }
        let developer = workspace.developerLog.filter { !onlyMissed || $0.message.level == .error }.map(LogItem.developer)
        return (sync + developer).sorted { $0.time > $1.time }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            columns
            list
            if unseen > 0 {
                Button { scrollToNewest() } label: {
                    Text("\(unseen) yeni olay ↓")
                        .font(DesignTokens.Font.caption)
                        .foregroundStyle(DesignTokens.Color.inkPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            footer
            Spacer(minLength: 0)
        }
        .frame(width: Self.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DesignTokens.Color.surfaceBar)
        .overlay(alignment: .leading) {
            Rectangle().fill(DesignTokens.Color.line).frame(width: DesignTokens.Stroke.hairline)
        }
        .onAppear(perform: startKeys)
        .onDisappear {
            stopKeys()
            workspace.diffCenter.highlight = nil
        }
        .onChange(of: items.first?.id) { _, _ in
            if !isAtTop { unseen += 1 }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Senkron")
    }

    // MARK: Parts

    private var header: some View {
        HStack(spacing: 10) {
            Text("Senkron")
                .font(DesignTokens.Font.title)
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Button {
                liveAnchor.show(ChromeMenu(width: 160, showsChecks: true, items: [
                    .button("Canlı", isChecked: workspace.isSyncLogLive) { workspace.isSyncLogLive = true },
                    .button("Duraklatıldı", isChecked: !workspace.isSyncLogLive) { workspace.isSyncLogLive = false },
                ]), edge: .bottom, alignment: .trailing, gap: DesignTokens.Space.s1)
            } label: {
                HStack(spacing: 4) {
                    Text(workspace.isSyncLogLive ? "Canlı" : "Duraklatıldı")
                        .font(DesignTokens.Font.caption)
                        .foregroundStyle(DesignTokens.Color.inkPrimary)
                    ChromeSymbol("chevron.down", box: 12).foregroundStyle(DesignTokens.Color.inkSecondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .background(MenuAnchorView(anchor: liveAnchor))
            .accessibilityLabel("Kayıt")
            .accessibilityValue(workspace.isSyncLogLive ? "Canlı" : "Duraklatıldı")
            Button {
                moreAnchor.show(ChromeMenu(width: 200, showsChecks: true, items: [
                    .button("Yalnız kaçıranlar", isChecked: onlyMissed) { onlyMissed.toggle() },
                    .separator,
                    .button("Temizle") { clear() },
                    .button("Dışa aktar…") { export() },
                ]), edge: .bottom, alignment: .trailing, gap: DesignTokens.Space.s1)
            } label: {
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
            Text("OLAY").frame(maxWidth: .infinity, alignment: .leading)
            Text("VIEWPORT").frame(width: 64, alignment: .trailing)
        }
        .font(.system(size: DesignTokens.FontSize.micro))
        .tracking(0.6)
        .foregroundStyle(DesignTokens.Color.inkSecondary)
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
        .accessibilityHidden(true)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    Color.clear.frame(height: 0).id("top")
                    if workspace.isDeveloperScope, workspace.awaitsDeveloperReload {
                        // The developer script goes in with the next load.
                        HStack(spacing: 8) {
                            Text("Konsol ve ağ, sayfalar yeniden yüklenince görünür")
                                .font(DesignTokens.Font.caption)
                                .foregroundStyle(DesignTokens.Color.inkSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ActionButton("Yenile", key: "⌘R") { workspace.reload() }
                        }
                        .padding(EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8))
                    }
                    ForEach(items) { item in
                        switch item {
                        case .sync(let entry):
                            SyncLogRow(entry: entry, start: workspace.logStart, isOpen: openID == entry.id,
                                       name: workspace.viewportName, toggle: { toggle(entry.id) },
                                       retry: { workspace.retrySync(entry) }, show: { show(entry) })
                                .id(entry.id)
                        case .developer(let entry):
                            DeveloperLogRow(entry: entry, start: workspace.logStart, total: workspace.viewports.count,
                                            isOpen: openID == entry.id, name: workspace.viewportName, toggle: { toggle(entry.id) },
                                            show: { if let first = entry.viewports.first { workspace.reveal(first) } })
                                .id(entry.id)
                        }
                    }
                    if items.isEmpty {
                        Text(onlyMissed ? "Kaçıran olay yok" : "Henüz olay yok · bir viewport'ta kaydırın ya da tıklayın")
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(DesignTokens.Color.inkSecondary)
                            .padding(EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 8)
            }
            .scrollIndicators(.automatic)
            // DEV-08: away from the newest rows, new ones are counted instead of pushing the list.
            .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y <= 4 } action: { _, atTop in
                isAtTop = atTop
                if atTop { unseen = 0 }
            }
            .fixedSize(horizontal: false, vertical: items.count < 12)
            .onChange(of: scrollRequest) { _, _ in
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }

    @State private var scrollRequest = 0

    private var footer: some View {
        HStack(spacing: 12) {
            // Tasarımcı / Geliştirici: the developer scope adds console and network lines (§3.4).
            Button {
                scopeAnchor.show(ChromeMenu(width: 200, showsChecks: true, items: [
                    .button("Tasarımcı", subtitle: "Senkron olayları", isChecked: !workspace.isDeveloperScope) { workspace.isDeveloperScope = false },
                    .button("Geliştirici", subtitle: "Ayrıca konsol ve ağ", isChecked: workspace.isDeveloperScope) { workspace.isDeveloperScope = true },
                ]), edge: .top, gap: DesignTokens.Space.s1)
            } label: {
                Text(workspace.isDeveloperScope ? "Geliştirici" : "Tasarımcı").foregroundStyle(DesignTokens.Color.inkPrimary).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .background(MenuAnchorView(anchor: scopeAnchor))
            .accessibilityLabel("Kapsam")
            .accessibilityValue(workspace.isDeveloperScope ? "Geliştirici" : "Tasarımcı")
            Text("·").foregroundStyle(DesignTokens.Color.inkSecondary).accessibilityHidden(true)
            footerButton(workspace.isSyncLogLive ? "Duraklat" : "Sürdür") { workspace.isSyncLogLive.toggle() }
            Spacer(minLength: 0)
            footerButton("Temizle", action: clear)
            footerButton("Dışa aktar", action: export)
        }
        .font(DesignTokens.Font.caption)
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private func footerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).foregroundStyle(DesignTokens.Color.inkPrimary).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: 4)
    }

    // MARK: Actions

    /// DEV-01: one open row at a time.
    private func toggle(_ id: UUID) {
        withAnimation(Motion.curve(DesignTokens.Motion.standard)) { openID = openID == id ? nil : id }
        if openID == nil { workspace.diffCenter.highlight = nil }
        // A click on a row takes the keyboard out of the page, so R · ⏎ reach the panel.
        if let window = NSApp.keyWindow, Self.isWebContent(window.firstResponder) { window.makeFirstResponder(nil) }
    }

    /// Göster ⏎: the viewport that missed comes into view with a coral box where the element would be.
    private func show(_ entry: SyncLog.Entry) {
        Task { await workspace.showSyncMiss(entry) }
    }

    private func scrollToNewest() {
        scrollRequest += 1
        unseen = 0
    }

    private func clear() {
        openID = nil
        unseen = 0
        workspace.clearSyncLog()
    }

    /// Dışa aktar (JSON): the system save panel (a plain export, not a project).
    private func export() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Senkron kaydı.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try workspace.exportSyncLog().write(to: url)
        } catch {
            ErrorAlert.show(ErrorCode.writing(error), title: "Senkron kaydı yazılamadı", error: error)
        }
    }

    /// R · ⏎ (· D) act on the open row, unless a text field or a page has the keyboard. Taken from
    /// the window's key events, so the panel needn't hold focus (a focused container would make every
    /// button in it draw its focus ring). Keyboard presses don't animate the buttons (K5).
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
              let window = event.window, window.isKeyWindow,
              !(window.firstResponder is NSText), !Self.isWebContent(window.firstResponder) else { return false }
        let key = event.charactersIgnoringModifiers?.lowercased()
        if key == "\r", let developer = workspace.developerLog.first(where: { $0.id == openID }), let first = developer.viewports.first {
            workspace.reveal(first)
            return true
        }
        guard let entry = rows.first(where: { $0.id == openID }) else { return false }
        switch key {
        case "r" where entry.isMissed: workspace.retrySync(entry)
        case "\r": show(entry)
        default: return false
        }
        return true
    }

    private static func isWebContent(_ responder: NSResponder?) -> Bool {
        var view = responder as? NSView
        while let current = view {
            if current is WKWebView { return true }
            view = current.superview
        }
        return false
    }
}

/// A console or network line (developer scope): kind, text, and how many viewports reported it;
/// errors in coral. Opens to the address and the viewports, with Göster.
private struct DeveloperLogRow: View {
    let entry: Workspace.DeveloperEntry
    let start: Date
    let total: Int
    let isOpen: Bool
    let name: (ViewportID) -> String
    let toggle: () -> Void
    let show: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: toggle) {
                HStack(spacing: 10) {
                    Text(Self.elapsed(entry.time, since: start))
                        .font(DesignTokens.Font.caption.monospacedDigit())
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                        .frame(width: 36, alignment: .leading)
                    HStack(spacing: 6) {
                        Text(entry.message.kind == .console ? "konsol" : "ağ")
                            .font(.system(size: DesignTokens.FontSize.label))
                            .foregroundStyle(DesignTokens.Color.inkPrimary)
                        Text(summary)
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(DesignTokens.Color.inkSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(verbatim: "\(entry.viewports.count) / \(total)")
                        .font(.system(size: DesignTokens.FontSize.label).monospacedDigit())
                        .foregroundStyle(entry.message.level == .error ? DesignTokens.Color.statusWarning : DesignTokens.Color.inkSecondary)
                        .frame(width: 64, alignment: .trailing)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            if isOpen {
                Text(detail)
                    .font(DesignTokens.Font.caption)
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 46)
                ActionButton("Göster", key: "⏎", action: show)
                    .transition(.opacity)
            }
        }
        .padding(EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8))
        .background(isOpen ? DesignTokens.Color.surfaceHeader : .clear, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: "\(entry.message.kind == .console ? "konsol" : "ağ") \(summary), \(entry.viewports.count) / \(total)"))
    }

    /// Console: the text. Network: "404 urun.json".
    private var summary: String {
        guard entry.message.kind == .network, let url = entry.message.url else { return entry.message.text }
        let file = URL(string: url)?.lastPathComponent ?? url
        return "\(entry.message.text) \(file.isEmpty ? url : file)"
    }

    private var detail: String {
        var lines: [String] = []
        if entry.message.kind == .console { lines.append(entry.message.text) }
        if let url = entry.message.url { lines.append(url) }
        lines.append(entry.viewports.map(name).joined(separator: ", "))
        return lines.joined(separator: "\n")
    }

    static func elapsed(_ time: Date, since start: Date) -> String {
        let seconds = max(Int(time.timeIntervalSince(start)), 0)
        return String(format: "%02d:%02d", seconds / 60 % 100, seconds % 60)
    }
}

private struct SyncLogRow: View {
    let entry: SyncLog.Entry
    let start: Date
    let isOpen: Bool
    let name: (ViewportID) -> String
    let toggle: () -> Void
    let retry: () -> Void
    let show: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: toggle) {
                HStack(spacing: 10) {
                    Text(elapsed)
                        .font(DesignTokens.Font.caption.monospacedDigit())
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                        .frame(width: 36, alignment: .leading)
                    HStack(spacing: 6) {
                        Text(entry.kind)
                            .font(.system(size: DesignTokens.FontSize.label))
                            .foregroundStyle(DesignTokens.Color.inkPrimary)
                        Text(entry.detail)
                            .font(DesignTokens.Font.caption)
                            .foregroundStyle(DesignTokens.Color.inkSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(verbatim: "\(entry.reached) / \(entry.total)")
                        .font(.system(size: DesignTokens.FontSize.label).monospacedDigit())
                        .foregroundStyle(entry.isMissed ? DesignTokens.Color.statusWarning : DesignTokens.Color.inkSecondary)
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
                    .padding(.leading, 46)
                // The actions take the row's full width, under the description (§15 b).
                HStack(spacing: 6) {
                    if entry.isMissed {
                        ActionButton("Yeniden dene", kind: .primary, key: "R", action: retry)
                    }
                    ActionButton("Göster", key: "⏎", action: show)
                    if entry.isMissed {
                        // A (satır içi teşhis) waits for M7 (PLAN.md M5, 2026-10-19 decision).
                        ActionButton("Teşhis et", key: "D") {}
                            .disabled(true)
                            .chromeTooltip("Teşhis MCP ile gelecek")
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8))
        .background(isOpen ? DesignTokens.Color.surfaceHeader : .clear, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: "\(entry.kind) \(entry.detail), \(entry.reached) / \(entry.total)"))
    }

    /// Minutes and seconds since the window opened ("04:28").
    private var elapsed: String {
        let seconds = max(Int(entry.time.timeIntervalSince(start)), 0)
        return String(format: "%02d:%02d", seconds / 60 % 100, seconds % 60)
    }

    /// "Masaüstü kaçırdı: .add-to-cart bulunamadı"; "3 viewport'a ulaştı" when nothing was missed.
    private var detail: String {
        let missed = entry.missedIDs
        guard !missed.isEmpty else {
            let pending = entry.outcomes.values.filter { $0 == .pending }.count
            return pending > 0 ? "\(pending) viewport bekliyor" : "\(entry.total) viewport'a ulaştı"
        }
        let names = missed.map(name).joined(separator: ", ")
        let reason: String = switch entry.outcomes[missed[0]] {
        case .failed(let message): message
        default: "\(entry.detail) bulunamadı"
        }
        return "\(names) kaçırdı: \(reason)"
    }
}
