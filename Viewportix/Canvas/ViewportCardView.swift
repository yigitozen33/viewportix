import AppKit
import EngineCore
import ProjectModel

/// What a viewport card asks its owner to do (hover strip, header menu, camera).
enum ViewportCommand {
    case remove
    case rotate
    case editSize
    case toggleSync
    case capture(SnapshotArea)
    case setEngine(EngineKind)
}

/// The scaled part of a viewport card on the canvas: the engine's live view, sized in CSS pixels.
/// Everything that keeps a constant size on screen — header, borders, selection ring, warning note,
/// hover strip — is drawn above the canvas by `CardChromeLayer`, following `Workspace.cardFrames`.
final class ViewportCardView: NSView {
    let viewportID: ViewportID
    /// Pointer entered (true) or left (false) the page area.
    var onHover: ((ViewportID, Bool) -> Void)?

    private(set) var content: NSView

    override var isFlipped: Bool { true }

    init(viewportID: ViewportID, content: NSView) {
        self.viewportID = viewportID
        self.content = content
        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = true
        // The header sits above (screen space); only the bottom corners round here.
        layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        addSubview(content)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func configure(size: ViewportSize) {
        let size = NSSize(width: CGFloat(size.width), height: CGFloat(size.height))
        if frame.size != size {
            setFrameSize(size)
        }
    }

    /// Corner radius in document units, so it stays `radius/card` on screen at any zoom.
    func setScreenCornerRadius(_ radius: CGFloat, magnification: CGFloat) {
        layer?.cornerRadius = radius / max(magnification, 0.01)
    }

    override func layout() {
        super.layout()
        content.frame = bounds
    }

    /// Motor ›: the viewport's new engine view takes the old one's place.
    func replaceContent(_ view: NSView) {
        content.removeFromSuperview()
        content = view
        addSubview(view)
        view.frame = bounds
    }

    /// A scroll the page hands back (already at its edge) must not pan the canvas under it.
    override func scrollWheel(with event: NSEvent) {}

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        onHover?(viewportID, true)
    }

    override func mouseExited(with event: NSEvent) {
        onHover?(viewportID, false)
    }
}
