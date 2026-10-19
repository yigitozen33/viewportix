import AppKit
import DesignSystem
import DeviceCatalog
import EngineCore
import ProjectModel
import SwiftUI
import UniformTypeIdentifiers

enum SettingsTab: String, CaseIterable {
    case general, devices, mcp, account

    var title: String {
        switch self {
        case .general: "Genel"
        case .devices: "Cihazlar"
        case .mcp: "MCP"
        case .account: "Hesap"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .devices: "iphone"
        case .mcp: "powerplug.portrait"
        case .account: "person"
        }
    }

    /// MCP stays hidden until the server exists (M7; KOD-OTURUMU-ISLERI §11).
    static let visible: [SettingsTab] = [.general, .devices, .account]
}

/// The settings panel (DESIGN.md §3.3): 340 pt, slides over the canvas from the right; in the home
/// window under the top row. Everything applies at once (SETTINGS-01).
struct SettingsPanel: View {
    @Binding var tab: SettingsTab
    /// The project window's workspace; nil on the home screen, which has no "Bu proje" section.
    var workspace: Workspace?
    let close: () -> Void

    @State private var query = ""

    /// A capsule in the window this panel is in (project window or home).
    private func notify(_ notice: Workspace.Notice) {
        if let workspace { workspace.show(notice) } else { HomeNotices.shared.show(notice) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Ayarlar")
                    .font(DesignTokens.Font.title)
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                Spacer()
                ChromeIconButton(symbol: "xmark", label: "Kapat", shortcut: "Esc", action: close)
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 10, trailing: 16))
            tabs
                .padding(.horizontal, 12)
            Group {
                switch tab {
                case .general: GeneralSettings(workspace: workspace, query: query, showDevices: { tab = .devices })
                case .devices: DeviceSettings(query: query, notify: notify)
                case .mcp, .account: AccountSettings()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if tab != .account {
                    SettingsSearchField(text: $query, prompt: tab == .devices ? "Cihaz ara" : "Ayar ara")
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
                        .background(DesignTokens.Color.surfaceHeader)
                }
            }
        }
        .frame(width: DesignTokens.Size.panelOverlay)
        .frame(maxHeight: .infinity, alignment: .top)
        .chromeSurface()
        .onChange(of: tab) { query = "" }
        .onKeyPress(.escape) { close(); return .handled }
    }

    private var tabs: some View {
        HStack(spacing: DesignTokens.Space.s1) {
            ForEach(SettingsTab.visible, id: \.self) { item in
                Button { tab = item } label: {
                    HStack(spacing: 6) {
                        ChromeSymbol(item.symbol, box: DesignTokens.Size.iconSm)
                        Text(item.title).font(.system(size: DesignTokens.FontSize.label))
                    }
                    .foregroundStyle(tab == item ? DesignTokens.Color.inkPrimary : DesignTokens.Color.inkSecondary)
                    .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                    .background(tab == item ? DesignTokens.Color.surfaceHeaderLeader : .clear, in: .rect(cornerRadius: DesignTokens.Radius.control))
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
                .accessibilityAddTraits(tab == item ? .isSelected : [])
            }
        }
    }
}

// MARK: Shared pieces

struct SettingsSearchField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            ChromeSymbol("magnifyingglass", box: DesignTokens.Size.iconSm).foregroundStyle(DesignTokens.Color.inkSecondary)
            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(DesignTokens.Color.inkSecondary))
                .textFieldStyle(.plain)
                .font(.system(size: DesignTokens.FontSize.label))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
        }
        .padding(EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10))
        .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.control))
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased(with: Locale(identifier: "tr_TR")))
                .font(.system(size: DesignTokens.FontSize.micro, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 4, trailing: 0))
            content
        }
    }
}

struct SettingsRow<Control: View>: View {
    let label: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: DesignTokens.Space.s3) {
            Text(label)
                .font(.system(size: DesignTokens.FontSize.body))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            control
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.Color.line).frame(height: DesignTokens.Stroke.hairline)
        }
    }
}

// MARK: Genel

private struct GeneralSettings: View {
    var workspace: Workspace?
    let query: String
    let showDevices: () -> Void

    @AppStorage("homeTemplate") private var template = ProjectTemplate.default
    @AppStorage(AppSettings.syncOnStart) private var syncOnStart = true
    @AppStorage(AppSettings.keepDrafts) private var keepDrafts = true
    @AppStorage(Workspace.suspendMediaKey) private var suspendMedia = true
    @AppStorage(AppSettings.copyScreenshot) private var copyScreenshot = true
    @AppStorage(AppSettings.screenshotScale) private var scale = 2
    @AppStorage(AppSettings.screenshotFolder) private var folderPath = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if shows("Görünüm", rows: ["Dil"]) {
                    SettingsSection(title: "Görünüm") {
                        if matches("Dil") {
                            SettingsRow(label: "Dil") {
                                ChromeSelect(value: "Türkçe") { [.init(title: "Türkçe", isSelected: true) {}] }
                                .accessibilityLabel("Dil")
                            }
                        }
                    }
                }
                if shows("Proje", rows: ["Varsayılan şablon", "Senkron açık başlasın", "Taslakları sakla", "Arka plandaki viewport'larda medyayı duraklat"]) {
                    SettingsSection(title: "Proje") {
                        if matches("Varsayılan şablon") {
                            SettingsRow(label: "Varsayılan şablon") {
                                ChromeSelect(value: template.title) {
                                    ProjectTemplate.allCases.map { item in
                                        .init(title: item.title, isSelected: item == template, isEnabled: item.isAvailable) { template = item }
                                    }
                                }
                                .accessibilityLabel("Varsayılan şablon")
                            }
                        }
                        if matches("Senkron açık başlasın") {
                            SettingsRow(label: "Senkron açık başlasın") { Toggle("", isOn: $syncOnStart).toggleStyle(ChromeToggleStyle()).accessibilityLabel("Senkron açık başlasın") }
                        }
                        if matches("Taslakları sakla") {
                            // Off: a draft goes to the app's trash (30 days) when its window closes.
                            SettingsRow(label: "Taslakları sakla") { Toggle("", isOn: $keepDrafts).toggleStyle(ChromeToggleStyle()).accessibilityLabel("Taslakları sakla") }
                        }
                        if matches("Arka plandaki viewport'larda medyayı duraklat") {
                            SettingsRow(label: "Arka plandaki viewport'larda medyayı duraklat") {
                                Toggle("", isOn: mediaBinding).toggleStyle(ChromeToggleStyle()).accessibilityLabel("Arka plandaki viewport'larda medyayı duraklat")
                            }
                        }
                    }
                }
                if shows("Ekran görüntüsü", rows: ["Klasör", "Panoya da kopyala", "Ölçek"]) {
                    SettingsSection(title: "Ekran görüntüsü") {
                        if matches("Klasör") {
                            SettingsRow(label: "Klasör") {
                                ChromeSelect(value: folderLabel) {
                                    [
                                        .init(title: folderLabel, isSelected: true) {},
                                        .init(title: "-") {},
                                        .init(title: "Başka bir klasör…", action: chooseFolder),
                                        .init(title: "Finder'da göster") {
                                            NSWorkspace.shared.activateFileViewerSelecting([AppSettings.screenshotFolderURL])
                                        },
                                    ]
                                }
                                .accessibilityLabel("Klasör")
                            }
                        }
                        if matches("Panoya da kopyala") {
                            SettingsRow(label: "Panoya da kopyala") { Toggle("", isOn: $copyScreenshot).toggleStyle(ChromeToggleStyle()).accessibilityLabel("Panoya da kopyala") }
                        }
                        if matches("Ölçek") {
                            SettingsRow(label: "Ölçek") { ChromeSegments(items: [(1, "1×"), (2, "2×")], selection: $scale) }
                        }
                    }
                }
                if let workspace, shows("Bu proje", rows: ["Cihazlar", "Motor"]) {
                    SettingsSection(title: "Bu proje") {
                        if matches("Cihazlar") {
                            Button(action: showDevices) {
                                SettingsRow(label: "Cihazlar (\(workspace.viewports.count))") {
                                    ChromeSymbol("chevron.right", box: DesignTokens.Size.iconSm).foregroundStyle(DesignTokens.Color.inkSecondary)
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                        if matches("Motor") {
                            SettingsRow(label: "Motor") {
                                // Every viewport of the project to one engine; "Karışık" when they differ.
                                let engines = Set(workspace.viewports.map(\.engine))
                                ChromeSelect(value: engines.count > 1 ? "Karışık" : engineTitle(workspace)) {
                                    EngineKind.allCases.map { engine in
                                        .init(title: engines == [engine] ? engineTitle(workspace)
                                                : engine.unavailableReason.map { "\(engine.displayName) · \($0)" } ?? engine.displayName,
                                              isSelected: engines == [engine], isEnabled: engine.isAvailable) {
                                            for viewport in workspace.viewports where viewport.engine != engine {
                                                workspace.performCommand?(viewport.id, .setEngine(engine))
                                            }
                                        }
                                    }
                                }
                                .accessibilityLabel("Motor")
                            }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
        }
        .scrollIndicators(.never)
    }

    private func matches(_ label: String) -> Bool {
        query.isEmpty || label.localizedStandardContains(query)
    }

    private func shows(_ section: String, rows: [String]) -> Bool {
        query.isEmpty || section.localizedStandardContains(query) || rows.contains(where: matches)
    }

    /// In a project window the switch drives the open workspace; elsewhere just the preference.
    private var mediaBinding: Binding<Bool> {
        guard let workspace else { return $suspendMedia }
        return Binding { workspace.suspendsBackgroundMedia } set: { workspace.suspendsBackgroundMedia = $0 }
    }

    private var folderLabel: String {
        (AppSettings.screenshotFolderURL.path(percentEncoded: false) as NSString).abbreviatingWithTildeInPath
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = AppSettings.screenshotFolderURL
        panel.prompt = "Seç"
        if panel.runModal() == .OK, let url = panel.url {
            folderPath = url.path(percentEncoded: false)
        }
    }

    private func engineTitle(_ workspace: Workspace) -> String {
        guard let viewport = workspace.viewports.first else { return "WebKit" }
        return viewport.engine.title(version: workspace.session(for: viewport.id)?.engineVersion ?? "")
    }
}

// MARK: Cihazlar

/// C1 two-line list (`window-project-settings-devices@2x.png`): type filter, "Seçicide" switch,
/// hover ⋯ (Düzenle, Çoğalt, Sil — Sil only for custom), "+ Cihaz" for a custom device.
private struct DeviceSettings: View {
    let query: String
    let notify: (Workspace.Notice) -> Void

    enum Filter: Hashable { case all, phone, tablet, desktop, custom }

    @State private var filter = Filter.all
    @State private var editing: DevicePreset?
    @State private var isAdding = false
    private var store: DeviceLibraryStore { DeviceLibraryStore.shared }

    /// "İçe aktar…": a JSON list of devices becomes custom devices; the list jumps to "Özel".
    private func importDevices() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.prompt = "İçe aktar"
        panel.message = "Cihaz listesi (JSON): ad, genişlik, yükseklik"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let added = try store.library.importDevices(from: Data(contentsOf: url))
            withAnimation(.easeInOut(duration: DesignTokens.Motion.standard)) { filter = .custom }
            if added > 0 { notify(Workspace.Notice(kind: .success, text: "\(added) cihaz eklendi")) }
            if added == 0 {
                ErrorAlert.show(.devicesUnreadable, title: "Yeni cihaz yok", message: "“\(url.lastPathComponent)” içindeki cihazların hepsi listede zaten var.",
                                buttons: [.init(title: "Tamam")])
            }
        } catch {
            ErrorAlert.show(.devicesUnreadable, title: "“\(url.lastPathComponent)” içe aktarılamadı",
                            message: "Dosyada okunabilir cihaz yok. Her cihazın adı, genişliği ve yüksekliği olmalı.", buttons: [.init(title: "Tamam")])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s3) {
            HStack(spacing: DesignTokens.Space.s2) {
                Text("\(store.library.all.count) cihaz · \(store.library.custom.count) özel")
                    .font(.system(size: DesignTokens.FontSize.caption))
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                Spacer()
                ChromeButton(icon: .system("square.and.arrow.down"), title: "İçe aktar…", action: importDevices)
                Button { isAdding = true; editing = nil } label: {
                    HStack(spacing: DesignTokens.Space.s1) {
                        ChromeSymbol("plus", box: DesignTokens.Size.iconSm)
                        Text("Cihaz").font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                    }
                    .foregroundStyle(DesignTokens.Color.accentInk)
                    .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                    .background(DesignTokens.Color.accent, in: .rect(cornerRadius: DesignTokens.Radius.control))
                }
                .buttonStyle(.plain)
                .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
            }
            ChromeSegments(items: [(.all, "Tümü"), (.phone, "Telefon"), (.tablet, "Tablet"), (.desktop, "Masaüstü"), (.custom, "Özel")],
                           selection: $filter)
            if isAdding {
                CustomDeviceForm(name: "Özel", width: 1024, height: 768) { name, size in
                    store.library.addCustom(name: name, size: size)
                    isAdding = false
                } cancel: { isAdding = false }
            }
            ScrollView {
                VStack(spacing: 0) {
                VStack(spacing: 0) {
                    ForEach(devices) { preset in
                        if editing?.id == preset.id {
                            CustomDeviceForm(name: preset.name, width: preset.size.width, height: preset.size.height) { name, size in
                                store.library.updateCustom(preset.id, name: name, size: size)
                                editing = nil
                            } cancel: { editing = nil }
                            .padding(.vertical, 6)
                        } else {
                            DeviceSettingsRow(
                                preset: preset,
                                isCustom: store.library.isCustom(preset.id),
                                isInPicker: Binding { store.library.isInPicker(preset.id) } set: { store.library.setInPicker(preset.id, $0) },
                                edit: { editing = preset; isAdding = false },
                                duplicate: { store.library.duplicate(preset.id) },
                                delete: { withAnimation(.easeOut(duration: DesignTokens.Motion.standard)) { store.library.deleteCustom(preset.id) } }
                            )
                        }
                    }
                }
                Text("Seçicide kapalı = “+ Cihaz” menüsünde görünmez, açık projelerdeki kartlar kalır. Yerleşik cihaz silinmez, gizlenir.")
                    .font(.system(size: DesignTokens.FontSize.caption))
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, DesignTokens.Space.s3)
                }
            }
            .scrollIndicators(.never)
        }
        .padding(EdgeInsets(top: DesignTokens.Space.s3, leading: 16, bottom: 16, trailing: 16))
    }

    private var devices: [DevicePreset] {
        store.library.all.filter { preset in
            let kind: Bool = switch filter {
            case .all: true
            case .phone: preset.category == .phone
            case .tablet: preset.category == .tablet
            case .desktop: preset.category == .desktop
            case .custom: store.library.isCustom(preset.id)
            }
            return kind && (query.isEmpty || preset.name.localizedStandardContains(query))
        }
    }
}

private struct DeviceSettingsRow: View {
    let preset: DevicePreset
    let isCustom: Bool
    @Binding var isInPicker: Bool
    let edit: () -> Void
    let duplicate: () -> Void
    let delete: () -> Void

    @State private var isHovered = false
    @State private var isMenuOpen = false
    @State private var anchor = MenuAnchor()

    var body: some View {
        HStack(spacing: DesignTokens.Space.s3) {
            ChromeSymbol(isCustom ? "ruler" : preset.category.symbol, box: DesignTokens.Size.iconSm)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(preset.name)
                        .font(.system(size: DesignTokens.FontSize.body))
                        .foregroundStyle(DesignTokens.Color.inkPrimary)
                        .lineLimit(1)
                    if isCustom {
                        Text("özel")
                            .font(.system(size: DesignTokens.FontSize.micro))
                            .foregroundStyle(DesignTokens.Color.inkSecondary)
                            .padding(EdgeInsets(top: 1, leading: 5, bottom: 1, trailing: 5))
                            .background(DesignTokens.Color.surfacePill, in: .rect(cornerRadius: DesignTokens.Radius.badge))
                    }
                }
                Text(verbatim: "\(preset.size.width)×\(preset.size.height) · \(isCustom ? "Özel" : preset.category.title)")
                    .font(.system(size: DesignTokens.FontSize.caption))
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if isHovered || isMenuOpen {
                ChromeIconButton(symbol: "ellipsis", label: "Diğer") {
                    isMenuOpen = true
                    anchor.show(menu(), edge: .bottom, gap: 4) { isMenuOpen = false }
                }
                .background(MenuAnchorView(anchor: anchor))
            }
            Toggle("", isOn: $isInPicker)
                .toggleStyle(ChromeToggleStyle())
                .accessibilityLabel("Seçicide")
                .chromeTooltip("Seçicide", edge: .leading)
        }
        .padding(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 0))
        .background(isHovered ? DesignTokens.Color.surfaceHeaderLeader.opacity(0.5) : .clear, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.Color.line).frame(height: DesignTokens.Stroke.hairline)
        }
        .onHover { isHovered = $0 }
        .transition(.opacity)
    }

    private func menu() -> ChromeMenu {
        var items: [ChromeMenuItem] = [
            .button("Düzenle", isEnabled: isCustom, action: edit),
            .button("Çoğalt", action: duplicate),
        ]
        if isCustom {
            items += [.separator, .button("Sil", role: .destructive, action: delete)]
        }
        return ChromeMenu(width: 180, items: items)
    }
}

/// Name + W × H for a custom device; limits as everywhere (200–3840 × 200–4320).
private struct CustomDeviceForm: View {
    @State var name: String
    @State var width: Int
    @State var height: Int
    let save: (String, ViewportSize) -> Void
    let cancel: () -> Void

    var body: some View {
        let size = ViewportSize(width: width, height: height)
        VStack(alignment: .leading, spacing: DesignTokens.Space.s2) {
            HStack(spacing: DesignTokens.Space.s2) {
                field { TextField("", text: $name, prompt: Text("Ad")) }
                field(invalid: !ViewportSize.widthRange.contains(width)) {
                    TextField("", value: $width, format: .number.grouping(.never))
                }
                .frame(width: 64)
                Text("×").foregroundStyle(DesignTokens.Color.inkSecondary)
                field(invalid: !ViewportSize.heightRange.contains(height)) {
                    TextField("", value: $height, format: .number.grouping(.never))
                }
                .frame(width: 64)
            }
            HStack(spacing: DesignTokens.Space.s2) {
                Text("200–3840 × 200–4320 px")
                    .font(.system(size: DesignTokens.FontSize.caption))
                    .foregroundStyle(size.isWithinLimits ? DesignTokens.Color.inkSecondary : DesignTokens.Color.statusWarning)
                Spacer()
                ChromeButton(icon: .system("xmark"), title: "İptal", action: cancel)
                Button { save(name.trimmingCharacters(in: .whitespaces).isEmpty ? "Özel" : name, size) } label: {
                    Text("Kaydet")
                        .font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                        .foregroundStyle(DesignTokens.Color.accentInk)
                        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .background(DesignTokens.Color.accent, in: .rect(cornerRadius: DesignTokens.Radius.control))
                        .opacity(size.isWithinLimits ? 1 : 0.4)
                }
                .buttonStyle(.plain)
                .disabled(!size.isWithinLimits)
            }
        }
        .padding(DesignTokens.Space.s3)
        .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.control).strokeBorder(DesignTokens.Color.statusLeader, lineWidth: DesignTokens.Stroke.hairline)
        }
    }

    private func field(invalid: Bool = false, @ViewBuilder content: () -> some View) -> some View {
        content()
            .textFieldStyle(.plain)
            .font(.system(size: DesignTokens.FontSize.label).monospacedDigit())
            .foregroundStyle(DesignTokens.Color.inkPrimary)
            .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
            .background(DesignTokens.Color.surfaceHeader, in: .rect(cornerRadius: DesignTokens.Radius.badge))
            .overlay {
                if invalid {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.badge).strokeBorder(DesignTokens.Color.statusWarning, lineWidth: DesignTokens.Stroke.hairline)
                }
            }
    }
}

// MARK: Hesap

/// Accounts, teams and licences come with the business model; until then only what is true on
/// this Mac: the user's name, plan "Dahili", the app version.
private struct AccountSettings: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: DesignTokens.Space.s3) {
                    Text(initials)
                        .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                        .foregroundStyle(DesignTokens.Color.accentInk)
                        .frame(width: 36, height: 36)
                        .background(DesignTokens.Color.accent, in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSFullUserName())
                            .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                            .foregroundStyle(DesignTokens.Color.inkPrimary)
                        Text("Bu Mac'teki kullanıcı")
                            .font(.system(size: DesignTokens.FontSize.caption))
                            .foregroundStyle(DesignTokens.Color.inkSecondary)
                    }
                    Spacer()
                    ChromeButton(icon: .system("rectangle.portrait.and.arrow.right"), title: "Çıkış yap") {}
                        .disabled(true)
                }
                .padding(.top, 16)
                SettingsSection(title: "Takım") {
                    SettingsRow(label: "Takım") { secondary("Yakında") }
                }
                SettingsSection(title: "Lisans") {
                    SettingsRow(label: "Plan") { secondary("Dahili") }
                }
                SettingsSection(title: "Güncelleme") {
                    SettingsRow(label: "Sürüm \(version)") {
                        ChromeButton(icon: .system("arrow.clockwise"), title: "Denetle") {}.disabled(true)
                    }
                    SettingsRow(label: "Otomatik güncelle") {
                        Toggle("", isOn: .constant(true)).toggleStyle(ChromeToggleStyle()).disabled(true).accessibilityLabel("Otomatik güncelle")
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
        }
        .scrollIndicators(.never)
    }

    private func secondary(_ text: String) -> some View {
        Text(text)
            .font(.system(size: DesignTokens.FontSize.label))
            .foregroundStyle(DesignTokens.Color.inkSecondary)
    }

    private var initials: String {
        NSFullUserName().split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased(with: Locale(identifier: "tr_TR"))
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }
}
