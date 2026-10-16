import EngineCore
import Foundation
import ProjectModel
import Testing

struct ProjectTemplateTests {
    let url = URL(string: "https://marka.com")!

    @Test func everyTemplateResolvesAllItsDevices() {
        #expect(ProjectTemplate.mobileFocused.viewports.count == 4)
        #expect(ProjectTemplate.fullMatrix.viewports.count == 8)
        #expect(ProjectTemplate.engineComparison.viewports.count == 6)
    }

    @Test func engineComparisonPairsEachDeviceWithEveryEngine() {
        let engines = ProjectTemplate.engineComparison.viewports.map(\.engine)
        #expect(Set(engines) == Set(EngineKind.allCases))
        #expect(!ProjectTemplate.engineComparison.isAvailable)
    }

    @Test func newProjectFromTemplateStartsAtTheURL() {
        let project = Project.new(url: url, template: .fullMatrix)
        #expect(project.selectedPage?.url == url)
        #expect(project.viewports.map(\.presetID) == ProjectTemplate.fullMatrix.viewports.map(\.presetID))
    }

    @Test func summaryOfMissingFile() {
        let summary = ProjectSummary.read(URL(filePath: "/nonexistent/Marka C.viewportix"))
        #expect(summary.isMissing)
        #expect(summary.name == "Marka C")
        #expect(summary.meta() == "")
    }

    @Test func summaryReadsPackageAndFormatsMeta() throws {
        let folder = URL.temporaryDirectory.appending(path: "Marka A.viewportix")
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Project.new(url: url, template: .mobileFocused).encoded().write(to: folder.appending(path: "project.json"))

        var summary = ProjectSummary.read(folder)
        #expect(!summary.isMissing)
        #expect(summary.project?.viewports.count == 4)
        summary.modified = Date(timeIntervalSince1970: 1_000_000)
        #expect(summary.meta(now: Date(timeIntervalSince1970: 1_000_000 + 2 * 3600)) == "2 sa. önce · 4 cihaz")
        #expect(summary.matches("marka.com"))
        #expect(summary.matches("marka a"))
        #expect(!summary.matches("başka"))
    }

    @Test func summaryReportsUnreadableAndNewerFiles() throws {
        let folder = URL.temporaryDirectory.appending(path: "Bozuk.viewportix")
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(ProjectSummary.read(folder).problem == .unreadable)

        try Data(#"{"schemaVersion": 99}"#.utf8).write(to: folder.appending(path: "project.json"))
        #expect(ProjectSummary.read(folder).problem == .newerVersion(99))
    }
}
