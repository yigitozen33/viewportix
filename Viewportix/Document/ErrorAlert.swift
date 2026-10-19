import AppKit
import ProjectModel

/// File errors as the system alert (K8 U1; `dialogs-save-alerts@2x.png` 2. bölüm): only the texts,
/// the buttons and a code line under them are ours. The line is the accessory view: mono, selectable
/// so it can be copied (HOME-13, PW-09).
@MainActor
enum ErrorAlert {
    struct Button {
        let title: String
        var action: () -> Void = {}
    }

    /// As a sheet on `window` when there is one, otherwise app-modal. The first button is the default.
    static func show(_ code: ErrorCode, title: String, message: String, detail: String? = nil, buttons: [Button], in window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        for button in buttons { alert.addButton(withTitle: button.title) }
        alert.accessoryView = codeLine(code.line(detail: detail))
        alert.layout()
        let respond: (NSApplication.ModalResponse) -> Void = { response in
            let index = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
            if buttons.indices.contains(index) { buttons[index].action() }
        }
        if let window {
            alert.beginSheetModal(for: window, completionHandler: respond)
        } else {
            respond(alert.runModal())
        }
    }

    /// A one-button alert for failures with no special texts: the system's reason as the message.
    static func show(_ code: ErrorCode, title: String, error: Error, in window: NSWindow? = nil) {
        show(code, title: title, message: error.localizedDescription, buttons: [Button(title: "Tamam")], in: window)
    }

    /// `Alert Accessory Code`: #1E1C1A, 4 pt corners, 6/8 padding, micro mono #B8B0A8 (raw values,
    /// drawn for the system alert's own surface, not our tokens).
    private static func codeLine(_ text: String) -> NSView {
        let field = NSTextField(labelWithString: text)
        field.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        field.textColor = NSColor(srgbRed: 0xB8 / 255, green: 0xB0 / 255, blue: 0xA8 / 255, alpha: 1)
        field.isSelectable = true
        field.lineBreakMode = .byTruncatingMiddle
        field.setAccessibilityLabel("Hata kodu \(text)")
        let box = NSView()
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor(srgbRed: 0x1E / 255, green: 0x1C / 255, blue: 0x1A / 255, alpha: 1).cgColor
        box.layer?.cornerRadius = 4
        field.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 8),
            field.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -8),
            field.centerYAnchor.constraint(equalTo: box.centerYAnchor),
        ])
        box.frame = NSRect(x: 0, y: 0, width: 240, height: 25)
        return box
    }
}
