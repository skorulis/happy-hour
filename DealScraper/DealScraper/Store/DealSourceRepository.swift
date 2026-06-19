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

    func countsByVenueId() throws -> [Int64: Int] {
        try store.dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT venue_id, COUNT(*) AS count FROM deal_source GROUP BY venue_id
                """)
            return Dictionary(uniqueKeysWithValues: rows.compactMap { row in
                guard let venueId: Int64 = row["venue_id"] else { return nil }
                return (venueId, Int(row["count"] ?? 0))
            })
        }
    }

    func findApproved(venueId: Int64) throws -> [DealSource] {
        try store.dbQueue.read { db in
            try DealSource
                .filter(
                    Column("venue_id") == venueId
                        && Column("status") == DealStatus.approved.rawValue
                )
                .fetchAll(db)
        }
    }

    func findNew() throws -> [DealSource] {
        try store.dbQueue.read { db in
            try DealSource
                .filter(Column("status") == DealStatus.new.rawValue)
                .order(Column("date").asc)
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
                    .filter(Column("venue_id") == venueId && Column("url") == source.url)
                    .fetchOne(db)

                if let existing {
                    var updated = existing
                    updated.date = source.date
                    updated.textPieces = source.textPieces
                    updated.sourceURL = source.sourceURL
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

    func updateStatus(id: Int64, status: DealStatus) throws {
        try store.dbQueue.write { db in
            guard var source = try DealSource.fetchOne(db, key: id) else { return }
            source.status = status
            try source.update(db)
        }
    }
}
