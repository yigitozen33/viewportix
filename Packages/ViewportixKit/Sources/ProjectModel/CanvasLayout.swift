import CoreGraphics
import EngineCore
import Foundation

/// A point on the canvas in CSS px (document coordinates, y down).
public struct CanvasPoint: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Where cards sit on the canvas: dragged cards keep their position, the rest line up in one
/// top-aligned row after them (DESIGN.md §3.2; CARD-08, PW-01).
public enum CanvasLayout {
    public static let margin: Double = 64
    public static let gap: Double = 48

    /// Page-area frames in document coordinates.
    public static func frames(for viewports: [ViewportConfig]) -> [ViewportID: CGRect] {
        var frames: [ViewportID: CGRect] = [:]
        var nextX = margin
        for viewport in viewports {
            if let position = viewport.position {
                nextX = max(nextX, position.x + Double(viewport.size.width) + gap)
            }
        }
        for viewport in viewports {
            let size = CGSize(width: viewport.size.width, height: viewport.size.height)
            if let position = viewport.position {
                frames[viewport.id] = CGRect(origin: CGPoint(x: position.x, y: position.y), size: size)
            } else {
                frames[viewport.id] = CGRect(origin: CGPoint(x: nextX, y: margin), size: size)
                nextX += size.width + gap
            }
        }
        return frames
    }

    /// An alignment the dragged card snapped to: a vertical (x) or horizontal (y) line in document
    /// coordinates, from `start` to `end` along the other axis.
    public struct Guide: Hashable, Sendable {
        public enum Axis: Hashable, Sendable { case vertical, horizontal }
        public let axis: Axis
        public let position: Double
        public let start: Double
        public let end: Double
    }

    /// Snaps `rect` to the edges and centres of `others` when within `threshold` (document units;
    /// the canvas passes 6 screen px / zoom). Returns the adjusted origin and the guides to draw.
    public static func snap(_ rect: CGRect, to others: [CGRect], threshold: Double) -> (origin: CGPoint, guides: [Guide]) {
        var origin = rect.origin
        var guides: [Guide] = []

        func best(_ candidates: [(mine: Double, theirs: Double, other: CGRect)]) -> (delta: Double, theirs: Double, other: CGRect)? {
            candidates
                .map { (delta: $0.theirs - $0.mine, theirs: $0.theirs, other: $0.other) }
                .filter { abs($0.delta) <= threshold }
                .min { abs($0.delta) < abs($1.delta) }
        }

        let xs = others.flatMap { other in
            [rect.minX, rect.midX, rect.maxX].flatMap { mine in
                [other.minX, other.midX, other.maxX].map { (mine: Double(mine), theirs: Double($0), other: other) }
            }
        }
        if let hit = best(xs) {
            origin.x += hit.delta
            let moved = CGRect(origin: origin, size: rect.size)
            guides.append(Guide(axis: .vertical, position: hit.theirs,
                                start: min(moved.minY, hit.other.minY), end: max(moved.maxY, hit.other.maxY)))
        }
        let ys = others.flatMap { other in
            [rect.minY, rect.midY, rect.maxY].flatMap { mine in
                [other.minY, other.midY, other.maxY].map { (mine: Double(mine), theirs: Double($0), other: other) }
            }
        }
        if let hit = best(ys) {
            origin.y += hit.delta
            let moved = CGRect(origin: origin, size: rect.size)
            guides.append(Guide(axis: .horizontal, position: hit.theirs,
                                start: min(moved.minX, hit.other.minX), end: max(moved.maxX, hit.other.maxX)))
        }
        return (origin, guides)
    }
}
