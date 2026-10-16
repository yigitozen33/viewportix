import DesignSystem
import DeviceCatalog
import EngineCore
import ProjectModel
import SwiftUI

/// `Device/Picker` (specs/DevicePicker.json): 660 pt popover under the strip's "+ Cihaz".
/// Search (or type "1024×768"), engine choice (WebKit; Chromium and Firefox "yakında"), SON chips,
/// three independently scrolling columns, custom size, "Cihazları yönet…". STRIP-07…11.
struct DevicePicker: View {
    let viewports: [ViewportConfig]
    let add: (DevicePreset) -> Void
    let addCustom: (ViewportSize) -> Void
    let reveal: (ViewportID) -> Void
    let dismiss: () -> Void

    @State private var query = ""
    @State private var customWidth = 1024
    @State private var customHeight = 768
    @AppStorage("recentDevicePresets") private var recentStorage = ""
    @FocusState private var isSearchFocused: Bool

    private var library: DeviceLibrary { DeviceLibraryStore.shared.library }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s2) {
            HStack(spacing: DesignTokens.Space.s2) {
                searchField
                enginePicker
            }
            if !recent.isEmpty {
                recentRow
            }
            HStack(alignment: .top, spacing: DesignTokens.Space.s2) {
                ForEach(DevicePreset.Category.allCases, id: \.self) { category in
                    column(category)
                }
            }
            footer
        }
        .padding(DesignTokens.Space.s2)
        .frame(width: 660)
        .chromeSurface()
        .onAppear { isSearchFocused = true }
    }

    // MARK: Parts

    private var searchField: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            ChromeSymbol("magnifyingglass", box: DesignTokens.Size.iconSm)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            TextField("", text: $query, prompt: Text("Cihaz ara ya da 1024×768 yaz").foregroundStyle(DesignTokens.Color.inkSecondary))
                .textFieldStyle(.plain)
                .font(.system(size: DesignTokens.FontSize.label))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .focused($isSearchFocused)
                .onSubmit(submitSearch)
                .accessibilityLabel("Cihaz ara")
        }
        .padding(EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10))
        .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.control))
    }

    /// WebKit only until Chromium (M4) and Firefox (M6).
    private var enginePicker: some View {
        HStack(spacing: 1) {
            ForEach(EngineKind.allCases, id: \.self) { engine in
                let isAvailable = engine == .webKit
                HStack(spacing: DesignTokens.Space.s1) {
                    ChromeSymbol(asset: engine.glyph, box: 13)
                        .foregroundStyle(isAvailable ? DesignTokens.Color.inkPrimary : DesignTokens.Color.inkSecondary)
                    if !isAvailable {
                        Text("yakında")
                            .font(.system(size: DesignTokens.FontSize.micro))
                            .foregroundStyle(DesignTokens.Color.inkSecondary)
                    }
                }
                .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                .background(isAvailable ? DesignTokens.Color.surfaceHeaderLeader : DesignTokens.Color.surfaceCard)
                .opacity(isAvailable ? 1 : 0.5)
                .chromeTooltip(engine.displayName, shortcut: isAvailable ? nil : "yakında", edge: .bottom)
                .accessibilityLabel(engine.displayName)
                .accessibilityValue(isAvailable ? "seçili" : "yakında")
            }
        }
        .background(DesignTokens.Color.line)
        .clipShape(.rect(cornerRadius: DesignTokens.Radius.control))
    }

    private var recentRow: some View {
        HStack(spacing: DesignTokens.Space.s1) {
            Text("SON")
                .font(.system(size: DesignTokens.FontSize.micro, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(DesignTokens.Color.inkSecondary)
                .padding(.trailing, DesignTokens.Space.s1)
            ForEach(recent) { preset in
                Button { choose(preset) } label: {
                    HStack(spacing: DesignTokens.Space.s1) {
                        ChromeSymbol(preset.category.symbol, box: 12).foregroundStyle(DesignTokens.Color.inkSecondary)
                        Text(preset.name)
                            .font(.system(size: DesignTokens.FontSize.caption))
                            .foregroundStyle(DesignTokens.Color.inkPrimary)
                    }
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.badge))
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .chromeFocusRing(cornerRadius: DesignTokens.Radius.badge)
            }
        }
        .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
    }

    private func column(_ category: DevicePreset.Category) -> some View {
        let presets = DeviceSearch.presets(matching: query, in: library.pickerPresets).filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(category.title.uppercased(with: Locale(identifier: "tr_TR")))
                    .font(.system(size: DesignTokens.FontSize.micro, weight: .semibold))
                    .tracking(0.8)
                Text("\(presets.count)")
                    .font(.system(size: DesignTokens.FontSize.micro))
            }
            .foregroundStyle(DesignTokens.Color.inkSecondary)
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 6, trailing: 10))
            // Each column scrolls in its own fixed window (≈ 6 rows); the list never grows the popover.
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(presets) { preset in
                        PickerRow(preset: preset, isAdded: added(preset) != nil) { choose(preset) }
                    }
                }
            }
            .scrollIndicators(.automatic)
            .frame(height: 186)
            .overlay(alignment: .bottom) {
                if presets.count > 6 {
                    LinearGradient(colors: [DesignTokens.Color.surfaceHeader.opacity(0), DesignTokens.Color.surfaceHeader],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 24)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack(spacing: DesignTokens.Space.s2) {
            ChromeSymbol("ruler", box: DesignTokens.Size.iconSm).foregroundStyle(DesignTokens.Color.inkSecondary)
            Text("Özel boyut")
                .font(.system(size: DesignTokens.FontSize.label))
                .foregroundStyle(DesignTokens.Color.inkPrimary)
            sizeField("W", value: $customWidth, valid: ViewportSize.widthRange.contains(customWidth))
            sizeField("H", value: $customHeight, valid: ViewportSize.heightRange.contains(customHeight))
            Button { addCustom(customSize) } label: {
                Text("Ekle")
                    .font(.system(size: DesignTokens.FontSize.label, weight: .semibold))
                    .foregroundStyle(DesignTokens.Color.accentInk)
                    .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                    .background(DesignTokens.Color.accent, in: .rect(cornerRadius: DesignTokens.Radius.badge))
                    .opacity(customSize.isWithinLimits ? 1 : 0.4)
            }
            .buttonStyle(.plain)
            .disabled(!customSize.isWithinLimits)
            .chromeTooltip(String(describing: "\(ViewportSize.widthRange.lowerBound)–\(ViewportSize.widthRange.upperBound) × \(ViewportSize.heightRange.lowerBound)–\(ViewportSize.heightRange.upperBound) px"), edge: .bottom)
            Spacer()
            // Ayarlar › Cihazlar arrives with the settings panel (§12 step 7).
            HStack(spacing: DesignTokens.Space.s1) {
                Text("Cihazları yönet…").font(.system(size: DesignTokens.FontSize.caption))
                ChromeSymbol("arrow.up.right", box: 12)
            }
            .foregroundStyle(DesignTokens.Color.inkSecondary)
            .opacity(0.5)
        }
        .padding(EdgeInsets(top: 8, leading: 10, bottom: 4, trailing: 10))
        .overlay(alignment: .top) {
            Rectangle().fill(DesignTokens.Color.line).frame(height: DesignTokens.Stroke.hairline)
        }
    }

    private func sizeField(_ label: String, value: Binding<Int>, valid: Bool) -> some View {
        HStack(spacing: DesignTokens.Space.s1) {
            Text(label)
                .font(.system(size: DesignTokens.FontSize.micro))
                .foregroundStyle(DesignTokens.Color.inkSecondary)
            TextField("", value: value, format: .number.grouping(.never))
                .textFieldStyle(.plain)
                .font(.system(size: DesignTokens.FontSize.label).monospacedDigit())
                .foregroundStyle(DesignTokens.Color.inkPrimary)
                .onSubmit { if customSize.isWithinLimits { addCustom(customSize) } }
        }
        .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
        .frame(width: 64)
        .background(DesignTokens.Color.surfaceCard, in: .rect(cornerRadius: DesignTokens.Radius.badge))
        .overlay {
            if !valid {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.badge).strokeBorder(DesignTokens.Color.statusWarning, lineWidth: DesignTokens.Stroke.hairline)
            }
        }
    }

    // MARK: Actions

    private var customSize: ViewportSize { ViewportSize(width: customWidth, height: customHeight) }

    private var recent: [DevicePreset] {
        recentStorage.split(separator: ",").compactMap { library.preset(id: String($0)) }
    }

    private func added(_ preset: DevicePreset) -> ViewportConfig? {
        viewports.first { $0.presetID == preset.id }
    }

    /// STRIP-08: adds and stays open; STRIP-09: an added device is revealed, not added again.
    private func choose(_ preset: DevicePreset) {
        if let existing = added(preset) {
            reveal(existing.id)
            return
        }
        recentStorage = DeviceSearch.recordRecent(preset.id, in: recent.map(\.id)).joined(separator: ",")
        add(preset)
    }

    /// STRIP-10: "W×H" + ⏎ adds that size; a single match + ⏎ adds it.
    private func submitSearch() {
        if let size = ViewportSize(parsing: query), size.isWithinLimits {
            addCustom(size)
            query = ""
        } else {
            let matches = DeviceSearch.presets(matching: query, in: library.pickerPresets)
            if matches.count == 1 { choose(matches[0]) }
        }
    }
}

private struct PickerRow: View {
    let preset: DevicePreset
    let isAdded: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                ChromeSymbol(preset.category.symbol, box: 13).foregroundStyle(DesignTokens.Color.inkSecondary)
                Text(preset.name)
                    .font(.system(size: DesignTokens.FontSize.label))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(verbatim: "\(preset.size.width)×\(preset.size.height)")
                    .font(.system(size: DesignTokens.FontSize.micro).monospacedDigit())
                    .foregroundStyle(DesignTokens.Color.inkSecondary)
                ChromeSymbol(isAdded ? "checkmark" : "plus", box: 13)
                    .foregroundStyle(isAdded ? DesignTokens.Color.statusLeader : DesignTokens.Color.inkSecondary)
            }
            .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
            .background(isHovered ? DesignTokens.Color.surfaceCard : .clear, in: .rect(cornerRadius: DesignTokens.Radius.control))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .accessibilityLabel(preset.name)
        .accessibilityValue(isAdded ? "eklendi" : "")
    }
}

extension DevicePreset.Category {
    var title: String {
        switch self {
        case .phone: "Telefon"
        case .tablet: "Tablet"
        case .desktop: "Masaüstü"
        }
    }

    /// icons.md: smartphone → iphone, tablet → ipad, monitor → display.
    var symbol: String {
        switch self {
        case .phone: "iphone"
        case .tablet: "ipad"
        case .desktop: "display"
        }
    }
}
