import AppKit

/// Shows a Chromium viewport's screencast and sends the user's input to it. Its frame is the page
/// in CSS px, like a WKWebView on the canvas; the canvas's zoom scales it.
@MainActor
final class ChromiumView: NSView {
    weak var session: ChromiumSession?
    private var sizeCheck: Timer?
    private var lastPixelSize = CGSize.zero
    private let messageLabel = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        layer?.contentsGravity = .resize
        layer?.magnificationFilter = .linear
        layer?.minificationFilter = .trilinear
        messageLabel.font = .systemFont(ofSize: 15, weight: .medium)
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.alignment = .center
        messageLabel.isHidden = true
        addSubview(messageLabel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    /// Like the WebKit pages: Tab goes between the app's controls (PW-05); ⏎ on the card header enters.
    override var canBecomeKeyView: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: Frames

    func showFrame(base64: String) {
        guard let data = Data(base64Encoded: base64), let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.contents = image
        CATransaction.commit()
        messageLabel.isHidden = true
    }

    /// "Chrome bulunamadı" in the page area.
    func showUnavailable(_ message: String) {
        layer?.contents = nil
        layer?.backgroundColor = NSColor(white: 0.12, alpha: 1).cgColor
        messageLabel.stringValue = message
        messageLabel.isHidden = false
        needsLayout = true
    }

    override func layout() {
        super.layout()
        messageLabel.sizeToFit()
        messageLabel.frame.origin = CGPoint(x: (bounds.width - messageLabel.frame.width) / 2, y: (bounds.height - messageLabel.frame.height) / 2)
    }

    /// The view's size on the display in pixels (canvas zoom and backing scale included).
    var onScreenPixelSize: CGSize {
        guard let window else { return CGSize(width: bounds.width * 2, height: bounds.height * 2) }
        let size = convert(bounds, to: nil).size
        return CGSize(width: size.width * window.backingScaleFactor, height: size.height * window.backingScaleFactor)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        sizeCheck?.invalidate()
        guard window != nil else { return }
        // Zoom changes the view's scale, not its frame: look twice a second.
        sizeCheck = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkSize() }
        }
        checkSize()
    }

    private func checkSize() {
        let size = onScreenPixelSize
        guard size != lastPixelSize else { return }
        lastPixelSize = size
        session?.onScreenSizeChanged()
    }

    // MARK: Input

    private func cssPoint(_ event: NSEvent) -> CGPoint {
        let point = convert(event.locationInWindow, from: nil)
        guard let session else { return point }
        return CGPoint(x: point.x / bounds.width * session.cssSize.width, y: point.y / bounds.height * session.cssSize.height)
    }

    private func mouse(_ type: String, _ event: NSEvent, button: String) {
        session?.dispatchMouse(type, at: cssPoint(event), button: button, clicks: max(event.clickCount, type == "mouseMoved" ? 0 : 1),
                               modifiers: KeyMapping.modifiers(event.modifierFlags))
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        mouse("mousePressed", event, button: "left")
    }
    override func mouseUp(with event: NSEvent) { mouse("mouseReleased", event, button: "left") }
    override func mouseDragged(with event: NSEvent) { mouse("mouseMoved", event, button: "left") }
    override func mouseMoved(with event: NSEvent) { mouse("mouseMoved", event, button: "none") }
    override func rightMouseDown(with event: NSEvent) { mouse("mousePressed", event, button: "right") }
    override func rightMouseUp(with event: NSEvent) { mouse("mouseReleased", event, button: "right") }
    override func mouseExited(with event: NSEvent) {
        // Out of the page: the page's own :hover ends (the agent then reports hover null).
        session?.dispatchMouse("mouseMoved", at: CGPoint(x: -1, y: -1), button: "none", clicks: 0, modifiers: 0)
    }

    override func scrollWheel(with event: NSEvent) {
        let scale: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 40
        session?.dispatchWheel(at: cssPoint(event), dx: -event.scrollingDeltaX * scale, dy: -event.scrollingDeltaY * scale,
                               modifiers: KeyMapping.modifiers(event.modifierFlags))
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self))
    }

    override func keyDown(with event: NSEvent) {
        session?.dispatchKey(KeyMapping.params(for: event, down: true))
    }

    override func keyUp(with event: NSEvent) {
        session?.dispatchKey(KeyMapping.params(for: event, down: false))
    }

    // Edit menu commands reach the page (headless Chrome has no system pasteboard of its own).
    @objc func copy(_ sender: Any?) {
        Task {
            guard let text = await session?.selectedText(), !text.isEmpty else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }

    @objc func cut(_ sender: Any?) {
        copy(sender)
        session?.editCommand("delete")
    }

    @objc func paste(_ sender: Any?) {
        if let text = NSPasteboard.general.string(forType: .string) { session?.insertText(text) }
    }

    @objc override func selectAll(_ sender: Any?) { session?.editCommand("selectAll") }
    @objc func undo(_ sender: Any?) { session?.editCommand("undo") }
    @objc func redo(_ sender: Any?) { session?.editCommand("redo") }

    deinit {
        MainActor.assumeIsolated { sizeCheck?.invalidate() }
    }
}
