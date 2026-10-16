import Foundation
import ProjectModel
import Testing

struct URLHistoryTests {
    let cart = URL(string: "https://marka.com/sepet")!
    let home = URL(string: "https://www.marka.com/")!
    let local = URL(string: "http://localhost:3000/urun")!

    @Test func recordsNewestFirstWithoutDuplicates() {
        var history = URLHistory()
        history.record(cart)
        history.record(home)
        history.record(cart)
        #expect(history.entries.map(\.url) == [cart, home])
    }

    @Test func suggestionsFilterAndLimit() {
        var history = URLHistory()
        for index in 0..<8 { history.record(URL(string: "https://marka.com/\(index)")!) }
        history.record(local)
        #expect(history.suggestions(for: "").count == 5)
        #expect(history.suggestions(for: "localhost").map(\.url) == [local])
        #expect(history.suggestions(for: "marka.com/3").count == 1)
    }

    @Test func capacityIsBounded() {
        var history = URLHistory()
        for index in 0..<(URLHistory.capacity + 10) { history.record(URL(string: "https://a.com/\(index)")!) }
        #expect(history.entries.count == URLHistory.capacity)
    }

    @Test func displayDropsSchemeAndWWW() {
        #expect(URLHistory.display(home) == "marka.com")
        #expect(URLHistory.display(local) == "localhost:3000/urun")
    }

    @Test func pageKindFromPath() {
        #expect(PageKind(url: home) == .home)
        #expect(PageKind(url: cart) == .cart)
        #expect(PageKind(url: local) == .product)
        #expect(PageKind(url: URL(string: "https://marka.com/odeme/adim-1")!) == .checkout)
        #expect(PageKind(url: URL(string: "https://marka.com/kampanya")!) == .other)
    }

    @Test func redirectsAndSchemeVariantsAreOnePage() {
        let typed = URL(string: "https://apple.com/tr")!
        let landed = URL(string: "https://www.apple.com/tr/")!
        #expect(typed.isSamePage(as: landed))
        #expect(!typed.isSamePage(as: URL(string: "https://apple.com/de")!))
        var history = URLHistory()
        history.record(typed)
        history.record(landed)
        history.record(URL(string: "http://apple.com/tr")!)
        #expect(history.entries.count == 1)
    }
}
