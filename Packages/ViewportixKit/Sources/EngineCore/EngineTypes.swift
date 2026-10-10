import Foundation

/// A browser engine that can render a viewport.
public enum EngineKind: String, Codable, Hashable, Sendable, CaseIterable {
    case webKit
    case chromium
    case firefox
}

/// Size of a viewport in CSS pixels.
public struct ViewportSize: Codable, Hashable, Sendable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public var rotated: ViewportSize {
        ViewportSize(width: height, height: width)
    }
}

/// Stable identity of a viewport, shared by the canvas, sync and engine layers.
public struct ViewportID: Codable, Hashable, Sendable {
    public let rawValue: UUID

    public init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(UUID.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
