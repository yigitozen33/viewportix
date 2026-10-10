import Foundation

extension URL {
    /// Turns address bar input into a URL. Adds `https://`, or `http://` for local development hosts
    /// (localhost, *.local, IP addresses), which rarely have certificates.
    public init?(addressBarInput input: String) {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.contains(" ") else { return nil }

        if text.contains("://") {
            guard let url = URL(string: text), url.scheme != nil else { return nil }
            self = url
            return
        }

        let authority = text.split(separator: "/", maxSplits: 1).first.map(String.init) ?? text
        let host = authority.split(separator: ":").first.map(String.init) ?? authority
        let isLocal = host == "localhost" || host.hasSuffix(".local") || host.allSatisfy { $0.isNumber || $0 == "." }
        guard host.contains(".") || host == "localhost",
              let url = URL(string: (isLocal ? "http://" : "https://") + text), url.host != nil else { return nil }
        self = url
    }
}
