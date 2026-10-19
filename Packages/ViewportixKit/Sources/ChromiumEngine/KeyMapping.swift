import AppKit

/// Chrome's key events want Windows virtual key codes and DOM key / code names; macOS key codes
/// are something else ("m" is 46 on the Mac, VK_DELETE in Chrome — found in S5).
enum KeyMapping {
    struct Key {
        let vk: Int
        let key: String
        let code: String
    }

    static let special: [UInt16: Key] = [
        36: Key(vk: 13, key: "Enter", code: "Enter"), 76: Key(vk: 13, key: "Enter", code: "NumpadEnter"),
        48: Key(vk: 9, key: "Tab", code: "Tab"), 51: Key(vk: 8, key: "Backspace", code: "Backspace"),
        53: Key(vk: 27, key: "Escape", code: "Escape"), 117: Key(vk: 46, key: "Delete", code: "Delete"),
        123: Key(vk: 37, key: "ArrowLeft", code: "ArrowLeft"), 124: Key(vk: 39, key: "ArrowRight", code: "ArrowRight"),
        125: Key(vk: 40, key: "ArrowDown", code: "ArrowDown"), 126: Key(vk: 38, key: "ArrowUp", code: "ArrowUp"),
        49: Key(vk: 32, key: " ", code: "Space"), 115: Key(vk: 36, key: "Home", code: "Home"),
        119: Key(vk: 35, key: "End", code: "End"), 116: Key(vk: 33, key: "PageUp", code: "PageUp"),
        121: Key(vk: 34, key: "PageDown", code: "PageDown"),
    ]

    /// CDP modifier bits: Alt 1, Ctrl 2, Meta 4, Shift 8.
    static func modifiers(_ flags: NSEvent.ModifierFlags) -> Int {
        (flags.contains(.option) ? 1 : 0) | (flags.contains(.control) ? 2 : 0)
            | (flags.contains(.command) ? 4 : 0) | (flags.contains(.shift) ? 8 : 0)
    }

    /// `Input.dispatchKeyEvent` parameters for a key press or release.
    static func params(for event: NSEvent, down: Bool) -> [String: Any] {
        let text = event.characters ?? ""
        let printable = !text.isEmpty && text.unicodeScalars.allSatisfy { $0.value >= 32 && $0.value != 127 && !(0xF700...0xF8FF).contains($0.value) }
        var params: [String: Any] = ["modifiers": modifiers(event.modifierFlags)]
        if let key = special[event.keyCode] {
            params["windowsVirtualKeyCode"] = key.vk
            params["key"] = key.key
            params["code"] = key.code
        } else {
            let plain = event.charactersIgnoringModifiers ?? ""
            if let scalar = plain.uppercased().unicodeScalars.first, scalar.isASCII, scalar.properties.isAlphabetic || ("0"..."9").contains(Character(scalar)) {
                params["windowsVirtualKeyCode"] = Int(scalar.value)
                params["code"] = scalar.properties.isAlphabetic ? "Key\(Character(scalar))" : "Digit\(Character(scalar))"
            }
            params["key"] = plain
        }
        if down {
            params["type"] = printable ? "keyDown" : "rawKeyDown"
            if printable { params["text"] = text; params["unmodifiedText"] = event.charactersIgnoringModifiers ?? text }
            if event.keyCode == 36 || event.keyCode == 76 { params["type"] = "keyDown"; params["text"] = "\r" }
        } else {
            params["type"] = "keyUp"
        }
        return params
    }
}
