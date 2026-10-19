import EngineCore
import Foundation

/// What the Senkron panel lists (DESIGN.md §3.4): each event the leader sent, and how every follower
/// took it. Newest first. Back-to-back scrolls (or hovers) from the same leader merge into one row,
/// so a long scroll is one line, not a hundred.
public struct SyncLog: Sendable {
    public struct Entry: Identifiable, Hashable, Sendable {
        public enum Outcome: Hashable, Sendable {
            case pending
            case applied(String)
            case missed
            case failed(String)
        }

        public let id: UUID
        public var time: Date
        public let leader: ViewportID
        /// The event as sent; "Yeniden dene" sends it again (DEV-06).
        public var event: SyncEvent
        /// Each follower's result, in the order they were asked.
        public var outcomes: [ViewportID: Outcome]
        public let followers: [ViewportID]

        /// "scroll", "click", "input", "hover", "navigate".
        public var kind: String {
            switch event {
            case .scroll: "scroll"
            case .click: "click"
            case .input: "input"
            case .hover: "hover"
            case .navigate: "navigate"
            }
        }

        /// The event's argument as the panel shows it: "640 px", ".add-to-cart", "#qty = 2", "/urun".
        public var detail: String {
            switch event {
            case .scroll(let anchor):
                if let y = anchor["y"]?.numberValue { return "\(Int(y)) px" }
                return "%\(Int(((anchor["percent"]?.numberValue ?? 0) * 100).rounded()))"
            case .click(let target), .hover(let target):
                return Self.name(of: target)
            case .input(let value):
                let field = value["field"] ?? .null
                if field["type"]?.stringValue == "checkbox" || field["type"]?.stringValue == "radio" {
                    return "\(Self.name(of: field)) = \(value["checked"]?.boolValue == true ? "açık" : "kapalı")"
                }
                return "\(Self.name(of: field)) = \(value["value"]?.stringValue ?? "")"
            case .navigate(let url):
                return url.path().isEmpty ? "/" : url.path()
            }
        }

        /// Viewports that took the event, the leader included: "2 / 3".
        public var reached: Int { 1 + outcomes.values.filter { if case .applied = $0 { true } else { false } }.count }
        public var total: Int { 1 + followers.count }
        public var missedIDs: [ViewportID] { followers.filter { outcomes[$0] == .missed || isFailed(outcomes[$0]) } }
        public var isMissed: Bool { !missedIDs.isEmpty }

        private func isFailed(_ outcome: Outcome?) -> Bool {
            if case .failed = outcome { true } else { false }
        }

        /// A short, readable name for an agent target: a stable selector as is, else its text, else the
        /// last step of the structural path.
        static func name(of target: JSONValue) -> String {
            let selector = target["selector"]?.stringValue ?? ""
            if target["strong"]?.boolValue == true, !selector.isEmpty { return selector }
            for key in ["label", "text", "name"] {
                if let text = target[key]?.stringValue, !text.isEmpty { return "“\(text.prefix(40))”" }
            }
            return selector.split(separator: ">").last.map { $0.trimmingCharacters(in: .whitespaces) } ?? selector
        }
    }

    public private(set) var entries: [Entry] = []
    /// Kept rows; older ones drop off.
    public var limit = 500
    /// Scrolls and hovers this close together become one row.
    public var mergeWindow: TimeInterval = 1.5

    public init() {}

    /// A new leader event; returns its row (a merged scroll or hover keeps the earlier row).
    @discardableResult
    public mutating func record(_ event: SyncEvent, leader: ViewportID, followers: [ViewportID], at time: Date = .now) -> UUID {
        if let first = entries.first, first.leader == leader, time.timeIntervalSince(first.time) < mergeWindow,
           Self.merges(event, first.event) {
            entries[0].event = event
            entries[0].time = time
            for id in followers { entries[0].outcomes[id] = .pending }
            return entries[0].id
        }
        let entry = Entry(id: UUID(), time: time, leader: leader, event: event,
                          outcomes: Dictionary(uniqueKeysWithValues: followers.map { ($0, .pending) }), followers: followers)
        entries.insert(entry, at: 0)
        if entries.count > limit { entries.removeLast(entries.count - limit) }
        return entry.id
    }

    public mutating func update(_ id: UUID, follower: ViewportID, result: ApplyResult) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].outcomes[follower] = switch result {
        case .applied(let how): .applied(how)
        case .missed: .missed
        case .failed(let reason): .failed(reason)
        }
    }

    mutating func markPending(_ id: UUID, follower: ViewportID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].outcomes[follower] = .pending
    }

    public mutating func clear() {
        entries = []
    }

    static func merges(_ new: SyncEvent, _ old: SyncEvent) -> Bool {
        switch (new, old) {
        case (.scroll, .scroll), (.hover, .hover): true
        default: false
        }
    }

    /// "Dışa aktar (JSON)": the rows as plain JSON, oldest first.
    public func exportJSON(names: [ViewportID: String]) throws -> Data {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let rows: [[String: Any]] = entries.reversed().map { entry in
            [
                "time": formatter.string(from: entry.time),
                "event": entry.kind,
                "detail": entry.detail,
                "leader": names[entry.leader] ?? entry.leader.rawValue.uuidString,
                "reached": "\(entry.reached) / \(entry.total)",
                "followers": entry.followers.map { id -> [String: String] in
                    let outcome: String = switch entry.outcomes[id] ?? .pending {
                    case .pending: "pending"
                    case .applied(let how): "applied: \(how)"
                    case .missed: "missed"
                    case .failed(let reason): "failed: \(reason)"
                    }
                    return ["viewport": names[id] ?? id.rawValue.uuidString, "outcome": outcome]
                },
                "payload": entry.event.payload.anyValue,
            ]
        }
        return try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    }
}

extension SyncEvent {
    /// The event's JSON, for export and diagnosis.
    public var payload: JSONValue {
        switch self {
        case .scroll(let value), .click(let value), .input(let value), .hover(let value): value
        case .navigate(let url): .object(["url": .string(url.absoluteString)])
        }
    }
}
