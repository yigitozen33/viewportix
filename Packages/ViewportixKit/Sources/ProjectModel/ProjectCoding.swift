import Foundation

public enum ProjectCodingError: Error, Equatable {
    /// The file was written by a newer version of Viewportix.
    case unsupportedSchemaVersion(Int)
}

extension Project {
    /// Encodes the project as stable, diff-friendly JSON (sorted keys, pretty printed).
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }

    public init(data: Data) throws {
        let decoder = JSONDecoder()
        let header = try decoder.decode(SchemaHeader.self, from: data)
        guard header.schemaVersion <= Self.currentSchemaVersion else {
            throw ProjectCodingError.unsupportedSchemaVersion(header.schemaVersion)
        }
        self = try decoder.decode(Project.self, from: data)
    }
}

private struct SchemaHeader: Decodable {
    let schemaVersion: Int
}
