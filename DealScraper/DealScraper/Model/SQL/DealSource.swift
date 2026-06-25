//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated enum DealSourceType: String, Codable, Sendable {
    case image
    case webpage
    case pdf
}

nonisolated enum DealSourceTextPieces: Codable, Sendable, Equatable {
    case contentBlocks([ContentBlock])
    case textLines([String])

    private enum CodingKeys: String, CodingKey {
        case contentBlocks
        case textLines
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let blocks = try container.decodeIfPresent([ContentBlock].self, forKey: .contentBlocks) {
            self = .contentBlocks(blocks)
        } else if let lines = try container.decodeIfPresent([String].self, forKey: .textLines) {
            self = .textLines(lines)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Missing contentBlocks or textLines")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .contentBlocks(blocks):
            try container.encode(blocks, forKey: .contentBlocks)
        case let .textLines(lines):
            try container.encode(lines, forKey: .textLines)
        }
    }
}

nonisolated struct DealSource: Codable, Sendable {
    var id: Int64?
    let venueId: Int64
    let url: String
    var sourceURL: String
    let type: DealSourceType
    var status: DealStatus
    var date: Date
    var textPieces: DealSourceTextPieces?
    var contentHash: String?

    enum CodingKeys: String, CodingKey {
        case id
        case venueId = "venue_id"
        case url
        case sourceURL = "source_url"
        case type
        case status
        case date
        case textPieces = "text_pieces"
        case contentHash = "content_hash"
    }

    init(
        id: Int64? = nil,
        venueId: Int64,
        url: String,
        sourceURL: String? = nil,
        type: DealSourceType,
        status: DealStatus = .new,
        date: Date = .now,
        textPieces: DealSourceTextPieces? = nil,
        contentHash: String? = nil
    ) {
        self.id = id
        self.venueId = venueId
        self.url = url
        self.sourceURL = sourceURL ?? url
        self.type = type
        self.status = status
        self.date = date
        self.textPieces = textPieces
        self.contentHash = contentHash
    }
}

nonisolated extension DealSource: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "deal_source"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

nonisolated extension DealSourceTextPieces: DatabaseValueConvertible {
    var databaseValue: DatabaseValue {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8)
        else {
            return .null
        }
        return string.databaseValue
    }

    static func fromDatabaseValue(_ dbValue: DatabaseValue) -> DealSourceTextPieces? {
        guard let string = String.fromDatabaseValue(dbValue),
              let data = string.data(using: .utf8)
        else {
            return nil
        }
        return try? JSONDecoder().decode(DealSourceTextPieces.self, from: data)
    }
}
