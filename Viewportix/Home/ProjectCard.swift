import AppKit
import DesignSystem
import ProjectModel
import SwiftUI

/// `Home/ProjectCard` (specs/ProjectCard.json): normal, hover (`line/strong` + ⋯), draft (pill),
/// context target (sky border + ⋯), file missing (faded thumbnail, coral meta). HOME-04…08, HOME-12.
struct ProjectCard: View {
    let summary: ProjectSummary
    var isDraft = false
    /// Click / ⏎: opens the project, or "Bul…" when the file is missing.
    let action: () -> Void
    let menu: () -> ChromeMenu
    /// Snapshots only: draw the hover / context-target look without a pointer.
    var forcesHover = false
    var forcesMenuOpen = false
    /// HOME-07: the name turns into a field; ⏎ (or leaving it) renames, Esc cancels.
    var isRenaming = false
    var rename: (String?) -> Void = { _ in }

    @State private var hovering = false
    @State private var menuOpen = false

    private var isHovered: Bool { hovering || forcesHover }
    private var isMenuOpen: Bool { menuOpen || forcesMenuOpen }

    var body: some View {
        // While renaming, a click in the name field must not open the project.
        Button { if !isRenaming { action() } } label: {
            VStack(spacing: 0) {
                // Overlay, so the mini cards never widen the card.
                DesignTokens.Color.canvas
                    .frame(height: 140)
                    .overlay(alignment: .topLeading) {
                        Group {
                            if let image = summary.thumbnail.flatMap(NSImage.init(contentsOf:)) {
                                // thumbnail.png: the canvas's last state, drawn for this 140 pt band.
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 140, alignment: .topLeading)
                            } else {
                                ProjectThumbnail(viewports: summary.project?.viewports ?? [])
                            }
                        }
                        .opacity(summary.isMissing ? 0.3 : 1)
                    }
                    .clipped()
                details
            }
            .background(DesignTokens.Color.surfaceCard)
            .clipShape(.rect(cornerRadius: DesignTokens.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .strokeBorder(borderColor, lineWidth: DesignTokens.Stroke.hairline)
            }
            .contentShape(.rect(cornerRadius: DesignTokens.Radius.card))
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.card)
        .onHover { hovering = $0 }
        .chromeContextMenu(isOpen: $menuOpen, menu: menu)
        .animation(.linear(duration: DesignTokens.Motion.hover), value: isHovered)
        .accessibilityLabel(summary.name)
        .accessibilityValue(isDraft ? "Taslak, \(meta)" : meta)
    }

    private var borderColor: Color {
        if isMenuOpen { return DesignTokens.Color.statusLeader }
        if isHovered { return DesignTokens.Color.lineStrong }
        return DesignTokens.Color.line
    }

    /// ⋯ only on hover and while the context menu is open; never on drafts (states in the spec).
    private var showsMore: Bool { (isHovered || isMenuOpen) && !isDraft }

    private var meta: String {
        summary.isMissing ? "Dosya bulunamadı" : summary.meta()
    }

    private var details: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Favicon()
                    if isRenaming {
                        RenameField(name: summary.name, weight: .semibold, done: rename)
                    } else {
                        Text(summary.name)
                            .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                            .foregroundStyle(summary.isMissing ? DesignTokens.Color.inkSecondary : DesignTokens.Color.inkPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                Text(meta)
                    .font(.system(size: DesignTokens.FontSize.caption))
                    .foregroundStyle(summary.isMissing ? DesignTokens.Color.statusWarning : DesignTokens.Color.inkSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if isDraft {
                DraftPill()
            }
            ChromeSymbol("ellipsis", box: DesignTokens.Size.icon)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
                .opacity(showsMore ? 1 : 0)
                .accessibilityHidden(true)
        }
        .padding(DesignTokens.Space.s3)
    }
}

/// HOME-07: the project's name in place as a field, all of it selected. ⏎ or leaving the field
/// gives the new name; Esc gives nil (no change).
struct RenameField: View {
    let name: String
    var weight = Font.Weight.regular
    let done: (String?) -> Void

    @State private var text: String
    @State private var selection: TextSelection?
    @State private var isFinished = false
    @FocusState private var isFocused: Bool

    init(name: String, weight: Font.Weight = .regular, done: @escaping (String?) -> Void) {
        self.name = name
        self.weight = weight
        self.done = done
        _text = State(initialValue: name)
    }

    var body: some View {
        TextField("", text: $text, selection: $selection)
            .textFieldStyle(.plain)
            .font(.system(size: DesignTokens.FontSize.body, weight: weight))
            .foregroundStyle(DesignTokens.Color.inkPrimary)
            .padding(.horizontal, 4)
            .background(DesignTokens.Color.canvas, in: .rect(cornerRadius: 4))
            .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(DesignTokens.Color.statusLeader, lineWidth: DesignTokens.Stroke.hairline) }
            .focused($isFocused)
            .onSubmit { finish(text) }
            .onKeyPress(.escape) {
                finish(nil)
                return .handled
            }
            .onChange(of: isFocused) { _, focused in
                if !focused { finish(text) }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(50))
                isFocused = true
                selection = TextSelection(range: text.startIndex..<text.endIndex)
            }
            .accessibilityLabel("Yeni ad")
    }

    private func finish(_ value: String?) {
        guard !isFinished else { return }
        isFinished = true
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        done(trimmed.flatMap { $0.isEmpty || $0 == name ? nil : $0 })
    }
}

/// Placeholder favicon: the spec's 14 pt `surface/pill` square until favicons are stored (M3).
struct Favicon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(DesignTokens.Color.surfacePill)
            .frame(width: 14, height: 14)
    }
}

struct DraftPill: View {
    var body: some View {
        Text("Taslak")
            .font(.system(size: DesignTokens.FontSize.micro, weight: .medium))
            .foregroundStyle(DesignTokens.Color.inkSecondary)
            .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
            .background(DesignTokens.Color.surfacePill, in: .rect(cornerRadius: DesignTokens.Radius.badge))
    }
}

/// Without a `thumbnail.png` (turned off, or a file from before thumbnails) the card draws the
/// project's viewports as the spec's mini cards: page-coloured rectangles in a row, scaled together, top-aligned.
struct ProjectThumbnail: View {
    let viewports: [ViewportConfig]

    /// Raw page colours from the spec (`MiniCard` #FAF8F5, `MiniImg` #E6E1DA); not tokens on purpose.
    private static let page = Color(red: 0xFA / 255, green: 0xF8 / 255, blue: 0xF5 / 255)
    private static let image = Color(red: 0xE6 / 255, green: 0xE1 / 255, blue: 0xDA / 255)
    /// Height the tallest mini card gets, as in the spec's samples (96–100 pt).
    private static let tallest: CGFloat = 100

    var body: some View {
        let tallest = CGFloat(viewports.map(\.size.height).max() ?? 1)
        let scale = Self.tallest / tallest
        HStack(alignment: .top, spacing: DesignTokens.Space.s2) {
            ForEach(viewports.prefix(6)) { viewport in
                miniCard(width: CGFloat(viewport.size.width) * scale, height: CGFloat(viewport.size.height) * scale)
            }
        }
        .padding(14)
    }

    private func miniCard(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(DesignTokens.Color.surfaceHeader).frame(height: 6)
            Self.page
        }
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Self.image)
                .frame(width: max(width - 8, 0), height: min(30, height * 0.3))
                .offset(x: 4, y: 10)
        }
        .frame(width: width, height: height)
        .clipShape(.rect(cornerRadius: 3))
        .overlay {
            RoundedRectangle(cornerRadius: 3).strokeBorder(DesignTokens.Color.line, lineWidth: 1)
        }
    }
}

/// List view row (window-home-list@2x.png): Ad · Cihazlar · Sayfalar · Düzenlendi · ⋯.
struct ProjectRow: View {
    let summary: ProjectSummary
    var isDraft = false
    let action: () -> Void
    let menu: () -> ChromeMenu
    var isRenaming = false
    var rename: (String?) -> Void = { _ in }

    @State private var isHovered = false
    @State private var isMenuOpen = false

    var body: some View {
        // While renaming, a click in the name field must not open the project.
        Button { if !isRenaming { action() } } label: {
            HStack(spacing: 0) {
                HStack(spacing: DesignTokens.Space.s2) {
                    Favicon()
                    if isRenaming {
                        RenameField(name: summary.name, weight: .semibold, done: rename)
                    } else {
                        Text(summary.name)
                            .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                            .foregroundStyle(summary.isMissing ? DesignTokens.Color.inkSecondary : DesignTokens.Color.inkPrimary)
                            .lineLimit(1)
                    }
                    if isDraft { DraftPill() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if summary.isMissing {
                    HStack {
                        Text("Dosya bulunamadı")
                            .foregroundStyle(DesignTokens.Color.statusWarning)
                        Spacer()
                        Text("Bul…")
                            .font(.system(size: DesignTokens.FontSize.label))
                            .foregroundStyle(DesignTokens.Color.inkPrimary)
                            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                                    .strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
                            }
                    }
                    .padding(.trailing, DesignTokens.Space.s3)
                    .frame(width: ProjectListHeader.trailingColumns, alignment: .leading)
                } else {
                    Group {
                        Text(summary.project.map { "\($0.viewports.count)" } ?? "–").frame(width: ProjectListHeader.devices, alignment: .leading)
                        Text(summary.project.map { "\($0.pages.count)" } ?? "–").frame(width: ProjectListHeader.pages, alignment: .leading)
                        Text(summary.meta().components(separatedBy: " · ").first ?? "").frame(width: ProjectListHeader.edited, alignment: .leading)
                    }
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                }
                ChromeSymbol("ellipsis", box: DesignTokens.Size.icon)
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
            }
            .font(.system(size: DesignTokens.FontSize.body))
            .padding(.horizontal, DesignTokens.Space.s3)
            .frame(height: 32)
            .background((isHovered || isMenuOpen) ? DesignTokens.Color.surfaceHeader : .clear,
                        in: .rect(cornerRadius: DesignTokens.Radius.control))
            .overlay {
                if isMenuOpen {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                        .strokeBorder(DesignTokens.Color.statusLeader, lineWidth: DesignTokens.Stroke.hairline)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .onHover { isHovered = $0 }
        .chromeContextMenu(isOpen: $isMenuOpen, menu: menu)
        .accessibilityLabel(summary.name)
    }
}

/// Column headers for `ProjectRow`.
struct ProjectListHeader: View {
    /// Column widths measured in window-home-list@2x.png; the name column takes the rest.
    static let devices: CGFloat = 132
    static let pages: CGFloat = 112
    static let edited: CGFloat = 220
    static var trailingColumns: CGFloat { devices + pages + edited }

    var body: some View {
        HStack(spacing: 0) {
            Text("Ad").frame(maxWidth: .infinity, alignment: .leading)
            Text("Cihazlar").frame(width: Self.devices, alignment: .leading)
            Text("Sayfalar").frame(width: Self.pages, alignment: .leading)
            Text("Düzenlendi").frame(width: Self.edited, alignment: .leading)
            Color.clear.frame(width: DesignTokens.Size.icon)
        }
        .font(.system(size: DesignTokens.FontSize.caption, weight: .semibold))
        .tracking(1)
        .foregroundStyle(DesignTokens.Color.inkSecondary)
        .padding(.horizontal, DesignTokens.Space.s3)
    }
}
