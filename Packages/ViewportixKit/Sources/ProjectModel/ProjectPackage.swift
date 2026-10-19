import Foundation

/// The `.viewportix` package on disk: `project.json` and, unless turned off, `thumbnail.png`
/// (PLAN.md §3.5). The document and the drafts write through here so both agree on the layout.
public enum ProjectPackage {
    public static let projectFileName = "project.json"
    public static let thumbnailFileName = "thumbnail.png"
    public static let pathExtension = "viewportix"

    public static func fileWrapper(project: Project, thumbnail: Data?) throws -> FileWrapper {
        var files = [projectFileName: FileWrapper(regularFileWithContents: try project.encoded())]
        if project.includesThumbnail, let thumbnail {
            files[thumbnailFileName] = FileWrapper(regularFileWithContents: thumbnail)
        }
        return FileWrapper(directoryWithFileWrappers: files)
    }

    /// Writes a new package at `url` (fails if something is already there).
    public static func write(project: Project, thumbnail: Data?, to url: URL) throws {
        try fileWrapper(project: project, thumbnail: thumbnail).write(to: url, options: [], originalContentsURL: nil)
    }

    public static func read(_ wrapper: FileWrapper) throws -> (project: Project, thumbnail: Data?) {
        guard let data = wrapper.fileWrappers?[projectFileName]?.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return (try Project(data: data), wrapper.fileWrappers?[thumbnailFileName]?.regularFileContents)
    }

    public static func thumbnailURL(in package: URL) -> URL {
        package.appending(path: thumbnailFileName)
    }
}
