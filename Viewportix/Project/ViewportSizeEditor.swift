import EngineCore
import Foundation
import ProjectModel

/// State of the "Boyutu düzenle" popover (`SizeEditorPopover`, CARD-06).
struct ViewportSizeEditor: Identifiable {
    let id = UUID()
    var viewportID: ViewportID?
    var name = "Özel"
    var width = 1024
    var height = 768

    init(editing viewport: ViewportConfig) {
        viewportID = viewport.id
        name = viewport.name
        width = viewport.size.width
        height = viewport.size.height
    }

    var isValid: Bool { ViewportSize(width: width, height: height).isWithinLimits }
}
