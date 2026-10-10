import EngineCore
import ProjectModel
import SwiftUI

/// State of the add/edit viewport size sheet. `viewportID` nil means a new custom viewport.
struct ViewportSizeEditor: Identifiable {
    let id = UUID()
    var viewportID: ViewportID?
    var name = "Özel"
    var width = 1024
    var height = 768

    init() {}

    init(editing viewport: ViewportConfig) {
        viewportID = viewport.id
        name = viewport.name
        width = viewport.size.width
        height = viewport.size.height
    }

    var isValid: Bool { ViewportSize(width: width, height: height).isWithinLimits }
}

/// Placeholder layout until the design lands.
struct ViewportSizeSheet: View {
    @State var editor: ViewportSizeEditor
    let onSave: (ViewportSizeEditor) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            TextField("Ad", text: $editor.name)
            TextField("Genişlik", value: $editor.width, format: .number.grouping(.never))
            TextField("Yükseklik", value: $editor.height, format: .number.grouping(.never))
            HStack {
                Button("Döndür", systemImage: "rotate.right") {
                    (editor.width, editor.height) = (editor.height, editor.width)
                }
                Spacer()
                if !editor.isValid {
                    Text("Genişlik \(Self.range(ViewportSize.widthRange)), yükseklik \(Self.range(ViewportSize.heightRange)) px olmalı")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .navigationTitle(editor.viewportID == nil ? "Özel Boyut" : "Boyutu Düzenle")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("İptal") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(editor.viewportID == nil ? "Ekle" : "Kaydet") {
                    onSave(editor)
                    dismiss()
                }
                .disabled(!editor.isValid)
            }
        }
    }

    private static func range(_ range: ClosedRange<Int>) -> String {
        "\(range.lowerBound)–\(range.upperBound)"
    }
}

#Preview("Yeni") {
    ViewportSizeSheet(editor: ViewportSizeEditor()) { _ in }
}

#Preview("Geçersiz") {
    var editor = ViewportSizeEditor()
    editor.width = 120
    return ViewportSizeSheet(editor: editor) { _ in }
}
