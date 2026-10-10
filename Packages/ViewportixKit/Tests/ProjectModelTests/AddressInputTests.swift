import Foundation
import ProjectModel
import Testing

struct AddressInputTests {
    @Test(arguments: [
        ("example.com", "https://example.com"),
        ("  example.com/cart?id=1  ", "https://example.com/cart?id=1"),
        ("localhost:3000", "http://localhost:3000"),
        ("localhost:3000/products", "http://localhost:3000/products"),
        ("192.168.1.20:8080", "http://192.168.1.20:8080"),
        ("mac-mini.local", "http://mac-mini.local"),
        ("http://example.com", "http://example.com"),
        ("file:///tmp/index.html", "file:///tmp/index.html"),
    ])
    func parses(input: String, expected: String) {
        #expect(URL(addressBarInput: input)?.absoluteString == expected)
    }

    @Test(arguments: ["", "   ", "two words", "justaword"])
    func rejects(input: String) {
        #expect(URL(addressBarInput: input) == nil)
    }
}
