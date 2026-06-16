//Created by Alex Skorulis on 15/6/2026.

import Foundation
@preconcurrency import GRDB

final class DealSourceRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    func find(venueId: Int64) throws -> [DealSource] {
        try store.dbQueue.read { db in
            try DealSource
                .filter(Column("venue_id") == venueId)
                .fetchAll(db)
        }
    }

    @discardableResult
    func deleteAll(venueId: Int64) throws -> Int {
        try store.dbQueue.write { db in
            let count = try DealSource
                .filter(Column("venue_id") == venueId)
                .fetchCount(db)
            try DealSource
                .filter(Column("venue_id") == venueId)
                .deleteAll(db)
            return count
        }
    }

    /// Inserts new sources and refreshes `date` for existing rows. Preserves `.approved` status.
    @discardableResult
    func upsert(sources: [DealSource], forVenueId venueId: Int64) throws -> Int {
        guard !sources.isEmpty else { return 0 }

        return try store.dbQueue.write { db in
            var newCount = 0

            for source in sources {
                let existing = try DealSource
                    .filter(Column("venue_id") == venueId && Column("hash") == source.hash)
                    .fetchOne(db)

                if let existing {
                    var updated = existing
                    updated.date = source.date
                    updated.textPieces = source.textPieces
                    try updated.update(db)
                } else {
                    var newSource = source
                    newSource.id = nil
                    try newSource.insert(db)
                    newCount += 1
                }
            }

            return newCount
        }
    }
}
