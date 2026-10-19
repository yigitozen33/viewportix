import DiffCore
import EngineCore
import Foundation
import Testing

struct DiffCoreTests {
    typealias Element = ElementSnapshot.Element

    @Test func typeDiffersAtAnyWidthBoxesOnlyAtTheSame() {
        let baseline = ElementSnapshot(viewportWidth: 820, elements: [
            Element(selector: ".price", top: 300, height: 20, fontWeight: "500"),
            Element(selector: ".product-title", top: 200, height: 34, lineHeight: "34px"),
            Element(selector: ".add-to-cart", top: 284, height: 44),
        ])
        let phone = ElementSnapshot(viewportWidth: 393, elements: [
            Element(selector: ".price", top: 500, height: 20, fontWeight: "600"),
            Element(selector: ".product-title", top: 400, height: 36, lineHeight: "36px"),
        ])
        let differences = DiffEngine.compare(baseline: baseline, compared: phone)
        #expect(differences.map(\.summary) == ["yok", "500 → 600", "+2 px"])
        #expect(differences[0].needsAttention && !differences[1].needsAttention)

        // Same width: the box counts too.
        let sameWidth = ElementSnapshot(viewportWidth: 820, elements: [Element(selector: ".add-to-cart", top: 296, height: 44)])
        let moved = DiffEngine.compare(baseline: ElementSnapshot(viewportWidth: 820, elements: [baseline.elements[2]]), compared: sameWidth)
        #expect(moved.map(\.summary) == ["+12 px"] && moved[0].property == .top && moved[0].change == "284 → 296 px")
    }

    @Test func readsTheCollectorsJSON() throws {
        let json = JSONValue.object([
            "width": .number(393),
            "elements": .array([.object([
                "selector": .string(".price"), "top": .number(10), "left": .number(0), "width": .number(80), "height": .number(20),
                "visible": .bool(true), "fontSize": .string("16px"), "fontWeight": .string("600"),
                "lineHeight": .string("normal"), "color": .string("rgb(51, 51, 51)"),
            ])]),
        ])
        let snapshot = try #require(ElementSnapshot(json: json))
        #expect(snapshot.viewportWidth == 393 && snapshot.elements.first?.fontWeight == "600")
        #expect(Difference(selector: "a", property: .color, baselineValue: "#000000", comparedValue: "#333333", needsAttention: false).summary
            == "#000000 → #333333")
    }
}
