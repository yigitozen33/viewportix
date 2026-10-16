import EngineCore
import Foundation
import Testing

struct LoadFailureTests {
    let site = URL(string: "https://marka.com/urun")!
    let local = URL(string: "http://localhost:3000/urun")!

    @Test func classifiesNetworkDNSAndLocalServer() throws {
        #expect(LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, url: site)?.kind == .network)
        #expect(LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, url: site)?.code == "NSURLError -1009")
        #expect(LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost, url: site)?.kind == .notFound)
        let down = try #require(LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, url: local))
        #expect(down.kind == .serverDown && down.code == "ECONNREFUSED" && down.hostLabel == "localhost:3000")
        #expect(LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, url: site)?.kind == .network)
    }

    @Test func classifiesCertificates() {
        let expired = LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateHasBadDate, url: site)
        #expect(expired?.kind == .certificate && expired?.code == "SSL · süresi dolmuş")
        #expect(LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted, url: site)?.kind == .certificate)
    }

    @Test func ignoresCancellationsAndInterruptions() {
        #expect(LoadFailure(domain: NSURLErrorDomain, code: NSURLErrorCancelled, url: site) == nil)
        #expect(LoadFailure(domain: "WebKitErrorDomain", code: 102, url: site) == nil)
    }

    @Test func localHosts() {
        #expect(LoadFailure.isLocalHost("localhost"))
        #expect(LoadFailure.isLocalHost("192.168.1.20"))
        #expect(LoadFailure.isLocalHost("marka.local"))
        #expect(!LoadFailure.isLocalHost("marka.com"))
    }
}
