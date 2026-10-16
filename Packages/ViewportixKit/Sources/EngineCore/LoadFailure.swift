import Foundation

/// Why a page did not load in a viewport (DESIGN.md §3.2 "Sayfa yüklenemedi"). A site's own 404 or
/// 500 page is not a failure: it loads and shows as it is.
public struct LoadFailure: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        /// No connection, timeout, connection lost.
        case network
        /// The server's certificate could not be verified (self-signed, expired…).
        case certificate
        /// A local development server refuses connections (retried every 2 s).
        case serverDown
        /// The host name does not resolve.
        case notFound
        case other
    }

    public let kind: Kind
    public let url: URL
    /// Small mono line under the message: "NSURLError -1009", "SSL · süresi dolmuş", "ECONNREFUSED".
    public let code: String

    public init(kind: Kind, url: URL, code: String) {
        self.kind = kind
        self.url = url
        self.code = code
    }

    /// "localhost:3000", "marka.test".
    public var hostLabel: String {
        guard let host = url.host() else { return url.absoluteString }
        return url.port.map { "\(host):\($0)" } ?? host
    }

    /// localhost, 127.0.0.1, ::1, *.local, *.test and bare IPs count as development servers.
    public static func isLocalHost(_ host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        return host == "localhost" || host == "127.0.0.1" || host == "::1" || host.hasSuffix(".local")
            || host.hasSuffix(".localhost") || host.allSatisfy { $0.isNumber || $0 == "." }
    }

    /// Classifies a navigation error; nil for cancellations and interrupted loads, which are not
    /// failures the user needs to see.
    public init?(domain: String, code: Int, url: URL) {
        guard domain == NSURLErrorDomain else {
            // WebKit's own domain: 102 "frame load interrupted" happens on downloads and redirects.
            if domain == "WebKitErrorDomain", code == 102 { return nil }
            self.init(kind: .other, url: url, code: "\(domain) \(code)")
            return
        }
        switch code {
        case NSURLErrorCancelled:
            return nil
        case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
            self.init(kind: .notFound, url: url, code: "DNS · NXDOMAIN")
        case NSURLErrorCannotConnectToHost where Self.isLocalHost(url.host()):
            self.init(kind: .serverDown, url: url, code: "ECONNREFUSED")
        case NSURLErrorServerCertificateHasBadDate:
            self.init(kind: .certificate, url: url, code: "SSL · süresi dolmuş")
        case NSURLErrorServerCertificateUntrusted:
            self.init(kind: .certificate, url: url, code: "SSL · güvenilmeyen sertifika")
        case NSURLErrorServerCertificateHasUnknownRoot:
            self.init(kind: .certificate, url: url, code: "SSL · bilinmeyen kök")
        case NSURLErrorServerCertificateNotYetValid:
            self.init(kind: .certificate, url: url, code: "SSL · henüz geçerli değil")
        case NSURLErrorSecureConnectionFailed, NSURLErrorClientCertificateRejected, NSURLErrorClientCertificateRequired:
            self.init(kind: .certificate, url: url, code: "SSL · \(code)")
        default:
            self.init(kind: .network, url: url, code: "NSURLError \(code)")
        }
    }
}
