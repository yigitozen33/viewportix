import DeviceCatalog
import SwiftUI

/// Placeholder layout until the sidebar header and device strip land: navigation · address · devices.
/// Sync, fit, zoom and screenshots moved to the bottom bar (`BottomBar`).
struct ProjectToolbar: ToolbarContent {
    @Bindable var workspace: Workspace
    let onAddDevice: (DevicePreset) -> Void
    let onAddCustomSize: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button("Geri", systemImage: "chevron.left", action: workspace.goBack)
            Button("İleri", systemImage: "chevron.right", action: workspace.goForward)
            Button("Yenile", systemImage: "arrow.clockwise", action: workspace.reload)
        }

        ToolbarItem(placement: .principal) {
            TextField("Adres", text: $workspace.addressText)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 320, idealWidth: 480)
                .onSubmit(workspace.submitAddress)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Menu("Cihaz Ekle", systemImage: "plus") {
                ForEach(DevicePreset.Category.allCases, id: \.self) { category in
                    Section(category.title) {
                        ForEach(DeviceCatalog.all.filter { $0.category == category }) { preset in
                            Button("\(preset.name) · \(preset.size.width)×\(preset.size.height)") {
                                onAddDevice(preset)
                            }
                        }
                    }
                }
                Divider()
                Button("Özel Boyut…", action: onAddCustomSize)
            }
        }
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
