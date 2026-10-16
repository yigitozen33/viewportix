import Foundation

/// Addresses opened in any project, newest first (SIDEBAR-01 "SON" menu). Belongs to the app, not
/// to a project file (DESIGN.md §3.2).
public struct URLHistory: Codable, Hashable, Sendable {
    public struct Entry: Codable, Hashable, Sendable {
        public var url: URL
        public var date: Date

        public init(url: URL, date: Date) {
            self.url = url
            self.date = date
        }
    }

    public private(set) var entries: [Entry]
    public static let capacity = 50

    public init(entries: [Entry] = []) {
        self.entries = entries
    }

    /// Moves `url` to the top; the same address appears once.
    public mutating func record(_ url: URL, at date: Date = .now) {
        entries.removeAll { $0.url == url }
        entries.insert(Entry(url: url, date: date), at: 0)
        if entries.count > Self.capacity { entries.removeLast(entries.count - Self.capacity) }
    }

    public mutating func clear() {
        entries = []
    }

    /// Up to `limit` entries whose address contains `query` (scheme ignored); all when empty.
    public func suggestions(for query: String, limit: Int = 5) -> [Entry] {
        let query = query.trimmingCharacters(in: .whitespaces)
        let matching = query.isEmpty ? entries : entries.filter {
            Self.display($0.url).localizedStandardContains(query) || $0.url.absoluteString.localizedStandardContains(query)
        }
        return Array(matching.prefix(limit))
    }

    /// "marka.com/sepet": no scheme, no "www.", no trailing slash.
    public static func display(_ url: URL) -> String {
        var text = url.absoluteString
        for prefix in ["https://", "http://"] where text.hasPrefix(prefix) {
            text.removeFirst(prefix.count)
        }
        if text.hasPrefix("www.") { text.removeFirst(4) }
        if text.hasSuffix("/") { text.removeLast() }
        return text
    }
}

/// What a page is, guessed from its address; the sidebar picks its icon from this.
public enum PageKind: Sendable, Equatable {
    case home, product, cart, checkout, other

    public init(url: URL) {
        let path = url.path.lowercased()
        if path.isEmpty || path == "/" {
            self = .home
        } else if ["cart", "sepet", "basket", "bag"].contains(where: path.contains) {
            self = .cart
        } else if ["checkout", "odeme", "ödeme", "payment"].contains(where: path.contains) {
            self = .checkout
        } else if ["product", "urun", "ürün", "/p/"].contains(where: path.contains) {
            self = .product
        } else {
            self = .other
        }
    }
}
