import ProjectModel
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let viewportixProject = UTType(exportedAs: "com.viewportix.project")
}

/// A `.viewportix` package: `project.json` and `thumbnail.png` (`ProjectPackage`).
struct ProjectDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.viewportixProject]

    var project: Project
    /// PNG of the canvas's last state (`ThumbnailComposer`); kept as read until the window makes a new one.
    var thumbnail: Data?

    init(project: Project = .new(), thumbnail: Data? = nil) {
        self.project = project
        self.thumbnail = thumbnail
    }

    init(configuration: ReadConfiguration) throws {
        (project, thumbnail) = try ProjectPackage.read(configuration.file)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try ProjectPackage.fileWrapper(project: project, thumbnail: thumbnail)
    }
}
