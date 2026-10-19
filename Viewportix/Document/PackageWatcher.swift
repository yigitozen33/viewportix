import Foundation
import ProjectModel

/// Watches a package's `project.json` and calls back (on the main actor, after things settle) when
/// something writes to it. The system document only follows the package folder's own date, which
/// an in-place edit of the file doesn't change (PW-07); without this, an autosave could write over
/// the other version unseen.
@MainActor
final class PackageWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var url: URL?
    private let changed: () -> Void
    private var pending: Task<Void, Never>?

    init(changed: @escaping () -> Void) {
        self.changed = changed
    }

    func watch(_ package: URL?) {
        guard package != url else { return }
        url = package
        start()
    }

    private func start() {
        source?.cancel()
        source = nil
        guard let url else { return }
        let descriptor = open(url.appending(path: ProjectPackage.projectFileName).path(percentEncoded: false), O_EVTONLY)
        guard descriptor >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .extend, .delete, .rename], queue: .main)
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.fired() }
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        self.source = source
    }

    /// Our own saves replace the whole package, so the watched file is gone afterwards: look again
    /// at the new one, then report.
    private func fired() {
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            start()
            changed()
        }
    }

    func stop() {
        pending?.cancel()
        source?.cancel()
        source = nil
        url = nil
    }
}
