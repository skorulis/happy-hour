//Created by Alex Skorulis on 22/6/2026.

import Foundation
@preconcurrency import GRDB

final class SuburbRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    func upsert(name: String, postcode: String?) throws -> Int64 {
        try store.dbQueue.write { db in
            try Self.upsert(name: name, postcode: postcode, in: db)
        }
    }

    func upsert(name: String, postcode: String?, in db: Database) throws -> Int64 {
        try Self.upsert(name: name, postcode: postcode, in: db)
    }

    func find(name: String, postcode: String?) throws -> Suburb? {
        try store.dbQueue.read { db in
            try Self.find(name: name, postcode: Self.normalized(postcode), in: db)
        }
    }

    static func upsert(name: String, postcode: String?, in db: Database) throws -> Int64 {
        let normalizedPostcode = normalized(postcode)

        if let existing = try find(name: name, postcode: normalizedPostcode, in: db),
           let existingId = existing.id
        {
            return existingId
        }

        var suburb = Suburb(name: name, postcode: normalizedPostcode)
        try suburb.insert(db)
        guard let suburbId = suburb.id else {
            throw DatabaseError(resultCode: .SQLITE_ERROR, message: "Failed to insert suburb")
        }
        return suburbId
    }

    private static func find(name: String, postcode: String?, in db: Database) throws -> Suburb? {
        var request = Suburb.filter(Column("name") == name)
        if let postcode {
            request = request.filter(Column("postcode") == postcode)
        } else {
            request = request.filter(Column("postcode") == nil)
        }
        return try request.fetchOne(db)
    }

    private static func normalized(_ postcode: String?) -> String? {
        guard let postcode else { return nil }
        let trimmed = postcode.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
