import Foundation
import Observation
import ProjectModel

/// App-wide address history (`URLHistory`) kept in user defaults, shared by every project window.
@MainActor
@Observable
final class URLHistoryStore {
    static let shared = URLHistoryStore()

    private(set) var history: URLHistory
    private static let key = "urlHistory"

    private init() {
        let saved = UserDefaults.standard.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(URLHistory.self, from: $0) } ?? URLHistory()
        // Older builds kept redirect variants of one page as separate entries; fold them.
        var history = URLHistory()
        for entry in saved.entries.reversed() { history.record(entry.url, at: entry.date) }
        self.history = history
    }

    func record(_ url: URL) {
        guard url.scheme == "http" || url.scheme == "https" else { return }
        history.record(url)
        save()
    }

    func clear() {
        history.clear()
        save()
    }

    private func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(history), forKey: Self.key)
    }
}
