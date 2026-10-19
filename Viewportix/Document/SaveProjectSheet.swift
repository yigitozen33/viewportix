import AppKit
import DesignSystem
import ProjectModel
import SwiftUI

/// What the save sheet is for: a draft's first save (⌘S) or a copy (⇧⌘S Çoğalt).
struct SaveRequest: Identifiable {
    enum Mode { case save, duplicate }

    let id = UUID()
    let mode: Mode
    /// Saving a draft; false for "Farklı Yere Kaydet…" on a saved project (PW-09).
    var isDraft = true
    /// Suggested name: the page title ("Keten Gömlek"); "<ad> kopya" when duplicating.
    let name: String
}

/// PW-06 (K7 S2, `dialogs-save-alerts@2x.png` 1. bölüm, pen `Our Save Sheet` qHljm): 420 wide, rows
/// 14 apart. Ad (28 pt, `canvas`, selected and focused, `.viewportix` grey and fixed), Konum (SON
/// KONUMLAR + "Başka klasör…"), two checkboxes (remembered; Çoğalt has only the first), Vazgeç esc ·
/// Kaydet ⏎. A project of the same name in the folder (checked 300 ms after typing and when the
/// folder changes) turns the field coral and disables Kaydet; nothing is overwritten.
struct SaveProjectSheet: View {
    let request: SaveRequest
    /// Does the saving; throws to show PW-09.
    let save: (ProjectFiles.SaveOptions) async throws -> Void

    @Environment(\.chromeSheetClose) private var close
    @AppStorage("saveIncludesThumbnail") private var includesThumbnail = true
    @AppStorage("saveRemovesDraft") private var removesDraft = true
    @State private var name: String
    @State private var selection: TextSelection?
    @State private var folder = SaveLocations.recent[0]
    @State private var isTaken = false
    @State private var isSaving = false
    @State private var check: Task<Void, Never>?
    @State private var anchor = MenuAnchor()
    @State private var isMenuOpen = false
    @FocusState private var isNameFocused: Bool

    static let width: CGFloat = 420

    init(request: SaveRequest, folder: URL? = nil, save: @escaping (ProjectFiles.SaveOptions) async throws -> Void) {
        self.request = request
        self.save = save
        if let folder { _folder = State(initialValue: folder) }
        _name = State(initialValue: request.name)
        _selection = State(initialValue: TextSelection(range: request.name.startIndex..<request.name.endIndex))
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && !isTaken && !isSaving }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 14) {
                Text(request.mode == .save ? "Projeyi kaydet" : "Kopyasını kaydet")
                    .font(DesignTokens.Font.title)
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                    .accessibilityAddTraits(.isHeader)
                if request.mode == .save, request.isDraft {
                    Text("Taslak zaten otomatik saklanıyor; kaydetmek ona ad ve yer verir.")
                        .font(DesignTokens.Font.caption)
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                }
            }
            nameField
            locationField
            checkbox("Küçük resmi dosyaya ekle", isOn: $includesThumbnail)
            if request.mode == .save, request.isDraft {
                checkbox("Kaydedince taslağı listeden kaldır", isOn: $removesDraft)
            }
            HStack(spacing: 6) {
                Spacer()
                ActionButton("Vazgeç", key: "esc") { close() }
                    .keyboardShortcut(.cancelAction)
                ActionButton("Kaydet", kind: .primary, key: "⏎") { submit() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .task {
            // The sheet's window becomes key a moment after the view appears.
            try? await Task.sleep(for: .milliseconds(80))
            isNameFocused = true
            selection = TextSelection(range: name.startIndex..<name.endIndex)
            checkName(after: 0)
        }
        .onChange(of: name) { checkName(after: 0.3) }
        .onChange(of: folder) { checkName(after: 0) }
    }

    // MARK: Fields

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("Ad")
            HStack(spacing: 2) {
                TextField("", text: $name, selection: $selection)
                    .textFieldStyle(.plain)
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                    .focused($isNameFocused)
                    .fixedSize()
                    .onSubmit(submit)
                    .accessibilityLabel("Ad")
                Text(".\(ProjectPackage.pathExtension)")
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(DesignTokens.Color.canvas, in: .rect(cornerRadius: DesignTokens.Radius.control))
            .contentShape(.rect)
            .onTapGesture { isNameFocused = true }
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                    .strokeBorder(fieldBorder, lineWidth: isTaken || isNameFocused ? DesignTokens.Stroke.focus : DesignTokens.Stroke.hairline)
            }
            if isTaken {
                Text("Bu klasörde “\(trimmedName)” var · başka ad ver ya da başka klasör seç")
                    .font(DesignTokens.Font.caption)
                    .foregroundStyle(DesignTokens.Color.statusWarning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var fieldBorder: Color {
        if isTaken { return DesignTokens.Color.statusWarning }
        return isNameFocused ? DesignTokens.Color.inkPrimary : DesignTokens.Color.line
    }

    private var locationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("Konum")
            Button(action: openLocations) {
                HStack(spacing: 6) {
                    ChromeSymbol("folder", box: DesignTokens.Size.iconSm)
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                    Text(SaveLocations.display(folder))
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.inkPrimary)
                        .lineLimit(1)
                        .truncationMode(.head)
                    Spacer(minLength: 0)
                    ChromeSymbol("chevron.down", box: 12)
                        .foregroundStyle(DesignTokens.Color.inkSecondary)
                }
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(DesignTokens.Color.surfacePill, in: .rect(cornerRadius: DesignTokens.Radius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                        .strokeBorder(DesignTokens.Color.inkPrimary, lineWidth: DesignTokens.Stroke.focus)
                        .opacity(isMenuOpen ? 1 : 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .background(MenuAnchorView(anchor: anchor))
            .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
            .onKeyPress(.downArrow) {
                openLocations()
                return .handled
            }
            .accessibilityLabel("Konum")
            .accessibilityValue(SaveLocations.display(folder))
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: DesignTokens.FontSize.label))
            .foregroundStyle(DesignTokens.Color.inkSecondary)
            .accessibilityHidden(true)
    }

    private func checkbox(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .toggleStyle(ChromeCheckboxStyle())
    }

    // MARK: Actions

    /// SON KONUMLAR: the last five + iCloud Drive, a separator, "Başka klasör…" (macOS folder picker).
    private func openLocations() {
        var folders = SaveLocations.recent
        if let cloud = SaveLocations.iCloudFolder, !folders.contains(cloud) { folders.append(cloud) }
        var items: [ChromeMenuItem] = [.header("SON KONUMLAR")]
        items += folders.map { candidate in
            .button(SaveLocations.display(candidate), shortcut: candidate == folder ? "✓" : nil) { folder = candidate }
        }
        items += [.separator, .button("Başka klasör…") { chooseFolder() }]
        isMenuOpen = true
        anchor.show(ChromeMenu(style: .list, width: 0, showsChecks: false, items: items), edge: .bottom, gap: DesignTokens.Space.s1) {
            isMenuOpen = false
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = folder
        panel.prompt = "Seç"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        folder = url
        SaveLocations.use(url)
    }

    private func checkName(after delay: Double) {
        check?.cancel()
        let candidate = trimmedName
        let folder = folder
        check = Task {
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            guard !Task.isCancelled else { return }
            let url = ProjectFiles.target(name: candidate, in: folder)
            isTaken = !candidate.isEmpty && FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
        }
    }

    private func submit() {
        guard canSave else { return }
        let url = ProjectFiles.target(name: trimmedName, in: folder)
        // The 300 ms check may not have run yet.
        guard !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            isTaken = true
            return
        }
        isSaving = true
        let options = ProjectFiles.SaveOptions(name: trimmedName, folder: folder, includesThumbnail: includesThumbnail,
                                               removesDraft: request.mode == .save && request.isDraft && removesDraft)
        Task {
            defer { isSaving = false }
            do {
                try await save(options)
                close()
            } catch {
                // PW-09 is shown by the caller; the sheet stays so another folder can be chosen.
            }
        }
    }
}

/// The save sheet's checkbox (pen `Check`: 14 pt box, 4 pt corners, `accent` with an `accent/ink`
/// tick when on, 8 pt to the label in body type).
struct ChromeCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isOn ? DesignTokens.Color.accent : DesignTokens.Color.surfacePill)
                    .overlay {
                        if configuration.isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(DesignTokens.Color.accentInk)
                        } else {
                            RoundedRectangle(cornerRadius: 4).strokeBorder(DesignTokens.Color.lineStrong, lineWidth: DesignTokens.Stroke.hairline)
                        }
                    }
                    .frame(width: 14, height: 14)
                configuration.label
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .chromeFocusRing(cornerRadius: 4)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "Açık" : "Kapalı")
    }
}
