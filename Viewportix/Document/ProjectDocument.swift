import ProjectModel
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let viewportixProject = UTType(exportedAs: "com.viewportix.project")
}

/// A `.viewportix` package: `project.json` now, a canvas thumbnail later (M3).
struct ProjectDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.viewportixProject]

    private static let projectFileName = "project.json"

    var project: Project

    init(project: Project = .new()) {
        self.project = project
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.fileWrappers?[Self.projectFileName]?.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        project = try Project(data: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(directoryWithFileWrappers: [
            Self.projectFileName: FileWrapper(regularFileWithContents: try project.encoded()),
        ])
    }
}
