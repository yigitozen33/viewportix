import EngineCore
import Foundation

/// One Chrome DevTools Protocol WebSocket. Page sessions share it (flatten mode): a command or event
/// carries the page's `sessionId`; browser-level ones carry none.
@MainActor
final class CDPConnection {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    typealias Event = (method: String, params: JSONValue, sessionID: String?)

    private let task: URLSessionWebSocketTask
    private var nextID = 1
    private var pending: [Int: CheckedContinuation<JSONValue, Error>] = [:]
    private var listeners: [UUID: (Event) -> Void] = [:]
    private(set) var isClosed = false
    var onClose: (() -> Void)?

    init(url: URL) {
        task = URLSession(configuration: .ephemeral).webSocketTask(with: url)
        task.maximumMessageSize = 64 * 1024 * 1024  // screencast frames and screenshots are large
        task.resume()
        receive()
    }

    /// Sends a command and waits for its result.
    @discardableResult
    func send(_ method: String, _ params: [String: Any] = [:], session: String? = nil) async throws -> JSONValue {
        guard !isClosed else { throw Failure(description: "Chrome bağlantısı kapandı") }
        let id = nextID
        nextID += 1
        var message: [String: Any] = ["id": id, "method": method, "params": params]
        if let session { message["sessionId"] = session }
        let data = try JSONSerialization.data(withJSONObject: message)
        return try await withCheckedThrowingContinuation { continuation in
            pending[id] = continuation
            task.send(.string(String(decoding: data, as: UTF8.self))) { error in
                guard let error else { return }
                Task { @MainActor in self.pending.removeValue(forKey: id)?.resume(throwing: error) }
            }
        }
    }

    /// Sends without waiting (acks, input during a burst). Order is kept: one socket, sent in turn.
    func post(_ method: String, _ params: [String: Any] = [:], session: String? = nil) {
        guard !isClosed else { return }
        let id = nextID
        nextID += 1
        var message: [String: Any] = ["id": id, "method": method, "params": params]
        if let session { message["sessionId"] = session }
        guard let data = try? JSONSerialization.data(withJSONObject: message) else { return }
        task.send(.string(String(decoding: data, as: UTF8.self))) { _ in }
    }

    func listen(_ handler: @escaping (Event) -> Void) -> UUID {
        let token = UUID()
        listeners[token] = handler
        return token
    }

    func stopListening(_ token: UUID) {
        listeners[token] = nil
    }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        task.cancel(with: .goingAway, reason: nil)
        for continuation in pending.values { continuation.resume(throwing: Failure(description: "Chrome bağlantısı kapandı")) }
        pending = [:]
        onClose?()
    }

    private func receive() {
        task.receive { [weak self] result in
            Task { @MainActor in
                guard let self, !self.isClosed else { return }
                switch result {
                case .failure:
                    self.close()
                case .success(let message):
                    let data: Data
                    switch message {
                    case .string(let text): data = Data(text.utf8)
                    case .data(let bytes): data = bytes
                    @unknown default: data = Data()
                    }
                    if let object = try? JSONSerialization.jsonObject(with: data), let json = JSONValue(any: object) {
                        self.handle(json)
                    }
                    self.receive()
                }
            }
        }
    }

    private func handle(_ message: JSONValue) {
        if let id = message["id"]?.numberValue.map(Int.init), let continuation = pending.removeValue(forKey: id) {
            if let error = message["error"] {
                continuation.resume(throwing: Failure(description: error["message"]?.stringValue ?? "CDP hatası"))
            } else {
                continuation.resume(returning: message["result"] ?? .object([:]))
            }
        } else if let method = message["method"]?.stringValue {
            let event = (method, message["params"] ?? .object([:]), message["sessionId"]?.stringValue)
            for listener in listeners.values { listener(event) }
        }
    }
}
