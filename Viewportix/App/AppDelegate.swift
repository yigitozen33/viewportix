import AppKit
import ProjectModel

extension Notification.Name {
    /// A save the system started (autosave) failed with a disk-full or permission error; the
    /// project window shows our PW-09 alert. Object: the `NSDocument`; userInfo["error"].
    static let projectSaveFailed = Notification.Name("ViewportixProjectSaveFailed")
}

/// Errors the system would present on its own. Saving errors of projects get our texts and code
/// line instead (PW-09, K8): the system's alert is skipped by handing back a "user cancelled" error,
/// which Cocoa never presents.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, willPresentError error: Error) -> Error {
        let code = ErrorCode.writing(error)
        guard code == .diskFull || code == .writePermission,
              let document = MainActor.assumeIsolated({ Self.failedDocument() }) else { return error }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .projectSaveFailed, object: document, userInfo: ["error": error])
        }
        return CocoaError(.userCancelled)
    }

    /// The document whose save failed: the front window's, else the one the menu bar acts on.
    @MainActor
    private static func failedDocument() -> NSDocument? {
        ProjectFiles.document(for: NSApp.keyWindow ?? NSApp.mainWindow) ?? NSDocumentController.shared.currentDocument
    }
}
