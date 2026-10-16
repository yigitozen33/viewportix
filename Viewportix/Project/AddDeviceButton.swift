import AppKit
import DesignSystem
import DeviceCatalog
import SwiftUI

/// "+ Cihaz" (STRIP-07). Until the device picker popover (`DevicePicker`, §12 step 6) it opens a
/// menu of the catalogue, grouped by type, with "Özel Boyut…" last.
struct AddDeviceButton: View {
    let onAddDevice: (DevicePreset) -> Void
    let onAddCustomSize: () -> Void

    @State private var anchor = MenuAnchor()
    @State private var isOpen = false

    var body: some View {
        ChromeButton(icon: .system("plus"), title: "Cihaz", isActive: isOpen) {
            isOpen = true
            DispatchQueue.main.async {
                anchor.popUpBelow(menu(), gap: DesignTokens.Space.s1)
                isOpen = false
            }
        }
        .background(alignment: .bottomLeading) { MenuAnchorView(anchor: anchor).frame(width: 0, height: 0) }
        .chromeTooltip("Cihaz ekle", shortcut: "⌥⌘N", edge: .bottom)
        .accessibilityLabel("Cihaz ekle")
    }

    private func menu() -> NSMenu {
        let menu = NSMenu()
        for category in DevicePreset.Category.allCases {
            menu.addItem(.sectionHeader(title: category.title.uppercased(with: Locale(identifier: "tr_TR"))))
            for preset in DeviceCatalog.all where preset.category == category {
                menu.addItem(ActionMenuItem("\(preset.name) · \(preset.size.width)×\(preset.size.height)") { onAddDevice(preset) })
            }
        }
        menu.addItem(.separator())
        menu.addItem(ActionMenuItem("Özel Boyut…", action: onAddCustomSize))
        return menu
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
}
