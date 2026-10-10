import AppKit
import EngineCore
import ProjectModel

/// What a viewport card asks its owner to do (header buttons and context menu).
enum ViewportCommand {
    case remove
    case rotate
    case editSize
    case capture(SnapshotArea)
}

/// One viewport on the canvas: a header strip above the engine's live view.
/// Placeholder styling until the design lands (DESIGN.md, M3).
final class ViewportCardView: NSView {
    static let headerHeight: CGFloat = 28

    let viewportID: ViewportID
    var onHover: ((ViewportID) -> Void)?
    var onCommand: ((ViewportID, ViewportCommand) -> Void)?

    private let content: NSView
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let missedIcon = NSImageView()
    private let closeButton = NSButton()
    private let captureButton = NSButton()
    private let rotateButton = NSButton()
    private var isLeader = false

    override var isFlipped: Bool { true }

    init(viewportID: ViewportID, content: NSView) {
        self.viewportID = viewportID
        self.content = content
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        detailLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        detailLabel.textColor = .secondaryLabelColor

        missedIcon.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Senkron kaçtı")
        missedIcon.contentTintColor = .systemOrange
        missedIcon.toolTip = "Tıklanan eleman bu viewport'ta bulunamadı"
        missedIcon.isHidden = true

        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Viewport'u kaldır")
        closeButton.isBordered = false
        closeButton.target = self
        closeButton.action = #selector(closeTapped)
        closeButton.toolTip = "Viewport'u kaldır"

        captureButton.image = NSImage(systemSymbolName: "camera", accessibilityDescription: "Ekran görüntüsü")
        captureButton.isBordered = false
        captureButton.target = self
        captureButton.action = #selector(captureTapped)
        captureButton.toolTip = "Ekran görüntüsü (⌥ ile tam sayfa)"

        rotateButton.image = NSImage(systemSymbolName: "rotate.right", accessibilityDescription: "Döndür")
        rotateButton.isBordered = false
        rotateButton.target = self
        rotateButton.action = #selector(rotateTapped)
        rotateButton.toolTip = "Döndür"

        for subview in [titleLabel, detailLabel, missedIcon, rotateButton, captureButton, closeButton, content] {
            addSubview(subview)
        }
        applyStyle()
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func configure(config: ViewportConfig, engineVersion: String, isLeader: Bool, syncMissed: Bool) {
        titleLabel.stringValue = config.name
        detailLabel.stringValue = "\(config.size.width)×\(config.size.height) · \(engineVersion)"
        missedIcon.isHidden = !syncMissed
        if self.isLeader != isLeader {
            self.isLeader = isLeader
            applyStyle()
        }
        let size = NSSize(width: CGFloat(config.size.width), height: CGFloat(config.size.height) + Self.headerHeight)
        if frame.size != size {
            setFrameSize(size)
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let width = bounds.width
        titleLabel.sizeToFit()
        titleLabel.frame.origin = NSPoint(x: 10, y: (Self.headerHeight - titleLabel.frame.height) / 2)
        detailLabel.sizeToFit()
        detailLabel.frame.origin = NSPoint(x: titleLabel.frame.maxX + 8, y: (Self.headerHeight - detailLabel.frame.height) / 2)
        missedIcon.frame = NSRect(x: detailLabel.frame.maxX + 6, y: 6, width: 16, height: 16)
        closeButton.frame = NSRect(x: width - 26, y: 5, width: 18, height: 18)
        captureButton.frame = NSRect(x: width - 50, y: 5, width: 18, height: 18)
        rotateButton.frame = NSRect(x: width - 74, y: 5, width: 18, height: 18)
        content.frame = NSRect(x: 0, y: Self.headerHeight, width: width, height: bounds.height - Self.headerHeight)
    }

    /// Scrolls reach the card from the header, or when the page hands back a scroll it could not use
    /// (already at its edge). The latter must not pan the canvas under the page.
    override func scrollWheel(with event: NSEvent) {
        if convert(event.locationInWindow, from: nil).y < Self.headerHeight {
            enclosingScrollView?.scrollWheel(with: event)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        onHover?(viewportID)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyStyle()
    }

    private func applyStyle() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.borderColor = (isLeader ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
            layer?.borderWidth = isLeader ? 2 : 1
        }
    }

    /// Right-click on the header; the page area keeps WebKit's own context menu.
    override func menu(for event: NSEvent) -> NSMenu? {
        guard convert(event.locationInWindow, from: nil).y < Self.headerHeight else { return super.menu(for: event) }
        let menu = NSMenu()
        menu.addItem(item("Döndür", #selector(rotateTapped)))
        menu.addItem(item("Boyutu Düzenle…", #selector(editSizeTapped)))
        menu.addItem(.separator())
        menu.addItem(item("Ekran Görüntüsü", #selector(captureVisibleTapped)))
        menu.addItem(item("Tam Sayfa Ekran Görüntüsü", #selector(captureFullPageTapped)))
        menu.addItem(.separator())
        menu.addItem(item("Kaldır", #selector(closeTapped)))
        return menu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func captureTapped() {
        onCommand?(viewportID, .capture(NSEvent.modifierFlags.contains(.option) ? .fullPage : .visible))
    }

    @objc private func captureVisibleTapped() { onCommand?(viewportID, .capture(.visible)) }
    @objc private func captureFullPageTapped() { onCommand?(viewportID, .capture(.fullPage)) }
    @objc private func rotateTapped() { onCommand?(viewportID, .rotate) }
    @objc private func editSizeTapped() { onCommand?(viewportID, .editSize) }
    @objc private func closeTapped() { onCommand?(viewportID, .remove) }
}
