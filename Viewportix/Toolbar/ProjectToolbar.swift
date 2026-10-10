import DeviceCatalog
import SwiftUI

/// Placeholder layout until the design lands: navigation · address · devices, zoom, sync.
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

            Menu("\(Int((workspace.zoom * 100).rounded()))%") {
                Button("Sığdır") { workspace.canvas?.fit() }
                Divider()
                ForEach([25, 50, 100, 200], id: \.self) { percent in
                    Button("%\(percent)") { workspace.canvas?.setZoomPercent(Double(percent)) }
                }
            }
            .help("Zoom")

            Menu("Ekran Görüntüsü", systemImage: "camera") {
                Button("Tüm Viewport'lar") { Task { await workspace.captureAll(area: .visible) } }
                Button("Tüm Viewport'lar — Tam Sayfa") { Task { await workspace.captureAll(area: .fullPage) } }
            }
            .help("Ekran görüntüsü")

            Toggle("Senkron", systemImage: "arrow.triangle.2.circlepath", isOn: $workspace.isSyncEnabled)
                .help(workspace.isSyncEnabled ? "Senkron açık" : "Senkron kapalı")
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
