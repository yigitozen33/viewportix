import Foundation

/// What the home screen shows about a project file without opening it as a document.
public struct ProjectSummary: Hashable, Sendable {
    public var url: URL
    public var name: String
    public var modified: Date?
    /// Nil when the file is missing (moved or deleted) or unreadable.
    public var project: Project?
    public var isMissing: Bool
    /// Why an existing file can't be opened (HOME-13); nil when it reads fine or is missing.
    public var problem: ReadProblem?
    /// The `VPX-NNNN` reason behind `problem` (HOME-13's code line).
    public var errorCode: ErrorCode?
    /// `thumbnail.png` inside the package, when there is one.
    public var thumbnail: URL?

    public enum ReadProblem: Hashable, Sendable {
        /// Damaged or incomplete package.
        case unreadable
        /// Written by a newer Viewportix (schema version).
        case newerVersion(Int)
    }

    public init(url: URL, name: String, modified: Date?, project: Project?, isMissing: Bool, problem: ReadProblem? = nil, thumbnail: URL? = nil) {
        self.thumbnail = thumbnail
        self.url = url
        self.name = name
        self.modified = modified
        self.project = project
        self.isMissing = isMissing
        self.problem = problem
    }

    /// Reads `project.json` (and notes `thumbnail.png`) from a `.viewportix` package.
    public static func read(_ url: URL, fileManager: FileManager = .default) -> ProjectSummary {
        let name = url.deletingPathExtension().lastPathComponent
        guard fileManager.fileExists(atPath: url.path(percentEncoded: false)) else {
            return ProjectSummary(url: url, name: name, modified: nil, project: nil, isMissing: true)
        }
        let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        do {
            let project = try Project(data: Data(contentsOf: url.appending(path: ProjectPackage.projectFileName)))
            let thumbnail = ProjectPackage.thumbnailURL(in: url)
            return ProjectSummary(url: url, name: name, modified: modified, project: project, isMissing: false,
                                  thumbnail: fileManager.fileExists(atPath: thumbnail.path(percentEncoded: false)) ? thumbnail : nil)
        } catch ProjectCodingError.unsupportedSchemaVersion(let version) {
            var summary = ProjectSummary(url: url, name: name, modified: modified, project: nil, isMissing: false, problem: .newerVersion(version))
            summary.errorCode = .newerSchema
            return summary
        } catch {
            var summary = ProjectSummary(url: url, name: name, modified: modified, project: nil, isMissing: false, problem: .unreadable)
            // A missing project.json reads as "no such file" here; the package itself exists.
            let code = ErrorCode.reading(error)
            summary.errorCode = code == .fileMissing ? .projectFileMissing : code
            return summary
        }
    }

    /// Search on the home screen matches the name and page URLs (HOME-10).
    public func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        if name.localizedStandardContains(query) { return true }
        return project?.pages.contains { $0.url.absoluteString.localizedStandardContains(query) } ?? false
    }

    /// "2 sa. önce · 3 cihaz", "Dün · 5 cihaz".
    public func meta(now: Date = .now, locale: Locale = Locale(identifier: "tr_TR")) -> String {
        var parts: [String] = []
        if let modified {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = locale
            formatter.unitsStyle = .abbreviated
            formatter.dateTimeStyle = .named
            let text = formatter.localizedString(for: modified, relativeTo: now)
            parts.append(text.prefix(1).uppercased(with: locale) + text.dropFirst())
        }
        if let project {
            parts.append("\(project.viewports.count) cihaz")
        }
        return parts.joined(separator: " · ")
    }
}
