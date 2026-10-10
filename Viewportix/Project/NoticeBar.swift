import AppKit
import SwiftUI

/// Bottom status capsule for screenshot progress and results. Placeholder styling until the design lands.
struct NoticeBar: View {
    let notice: Workspace.Notice
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if notice.isProgress {
                ProgressView().controlSize(.small)
            }
            Text(notice.text)
            if let url = notice.fileURL {
                Button("Finder'da Göster") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    dismiss()
                }
                .buttonStyle(.link)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
    }
}
