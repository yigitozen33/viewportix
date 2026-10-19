import Foundation

/// A difference between the baseline viewport and the compared one, for one element and property.
public struct Difference: Identifiable, Hashable, Sendable {
    public enum Property: String, Hashable, Sendable, CaseIterable {
        case presence = "görünürlük"
        case top, height, width
        case fontSize = "font-size"
        case fontWeight = "font-weight"
        case lineHeight = "line-height"
        case color
    }

    public var selector: String
    public var property: Property
    public var baselineValue: String
    public var comparedValue: String
    /// Coral (dot and value): the element is gone, or it moved or resized at the same width.
    public var needsAttention: Bool
    /// Signed px difference where it has one (top +12 px), for the canvas label.
    public var delta: Double?

    public init(selector: String, property: Property, baselineValue: String, comparedValue: String,
                needsAttention: Bool, delta: Double? = nil) {
        self.selector = selector
        self.property = property
        self.baselineValue = baselineValue
        self.comparedValue = comparedValue
        self.needsAttention = needsAttention
        self.delta = delta
    }

    public var id: String { "\(selector)|\(property.rawValue)" }

    /// The FARK column: "+12 px", "500 → 600", "yok".
    public var summary: String {
        if property == .presence { return comparedValue }
        if let delta, property != .fontWeight, property != .color {
            return "\(delta > 0 ? "+" : "")\(Self.format(delta)) px"
        }
        return "\(baselineValue) → \(comparedValue)"
    }

    /// The open row's first line: "284 → 296 px".
    public var change: String {
        switch property {
        case .presence: "baseline'da görünür, burada \(comparedValue)"
        case .top, .height, .width: "\(baselineValue) → \(comparedValue) px"
        default: "\(baselineValue) → \(comparedValue)"
        }
    }

    static func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }
}

/// Pairs two snapshots by selector and lists what differs (DESIGN.md §3.4; PLAN.md M5 2026-10-19).
/// Type is compared at any width; boxes only when both viewports are equally wide (different widths
/// lay out differently on purpose). Sub-pixel noise is ignored.
public enum DiffEngine {
    /// Smallest px change worth a row.
    public static let threshold: Double = 1

    public static func compare(baseline: ElementSnapshot, compared: ElementSnapshot) -> [Difference] {
        let sameWidth = baseline.viewportWidth == compared.viewportWidth
        let others = Dictionary(compared.elements.map { ($0.selector, $0) }, uniquingKeysWith: { first, _ in first })
        var differences: [Difference] = []
        for element in baseline.elements where element.isVisible {
            guard let other = others[element.selector], other.isVisible else {
                differences.append(Difference(selector: element.selector, property: .presence, baselineValue: "görünür",
                                              comparedValue: others[element.selector] == nil ? "yok" : "gizli", needsAttention: true))
                continue
            }
            if sameWidth {
                for (property, a, b) in [(Difference.Property.top, element.top, other.top),
                                         (.height, element.height, other.height), (.width, element.width, other.width)]
                where abs(b - a) >= threshold {
                    differences.append(Difference(selector: element.selector, property: property, baselineValue: Difference.format(a),
                                                  comparedValue: Difference.format(b), needsAttention: true, delta: b - a))
                }
            }
            for (property, a, b) in [(Difference.Property.fontSize, element.fontSize, other.fontSize),
                                     (.lineHeight, element.lineHeight, other.lineHeight)]
            where a != b {
                let delta = px(a).flatMap { x in px(b).map { $0 - x } }
                if let delta, abs(delta) < threshold { continue }
                differences.append(Difference(selector: element.selector, property: property, baselineValue: a, comparedValue: b,
                                              needsAttention: false, delta: delta))
            }
            if element.fontWeight != other.fontWeight {
                differences.append(Difference(selector: element.selector, property: .fontWeight, baselineValue: element.fontWeight,
                                              comparedValue: other.fontWeight, needsAttention: false))
            }
            if element.color != other.color {
                differences.append(Difference(selector: element.selector, property: .color, baselineValue: hex(element.color),
                                              comparedValue: hex(other.color), needsAttention: false))
            }
        }
        // Coral first, then page order.
        return differences.enumerated().sorted { a, b in
            a.element.needsAttention != b.element.needsAttention ? a.element.needsAttention : a.offset < b.offset
        }.map(\.element)
    }

    static func px(_ value: String) -> Double? {
        value.hasSuffix("px") ? Double(value.dropLast(2)) : nil
    }

    /// "rgb(51, 51, 51)" → "#333333"; anything else as is.
    static func hex(_ color: String) -> String {
        let parts = color.drop { $0 != "(" }.dropFirst().prefix { $0 != ")" }.split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard color.hasPrefix("rgb"), parts.count >= 3 else { return color }
        return "#" + parts.prefix(3).map { String(format: "%02X", Int($0)) }.joined()
    }
}
