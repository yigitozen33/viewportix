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
        history = UserDefaults.standard.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(URLHistory.self, from: $0) } ?? URLHistory()
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
