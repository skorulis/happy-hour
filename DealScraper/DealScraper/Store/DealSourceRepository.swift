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

    func nonRejectedCountsByVenueId() throws -> [Int64: Int] {
        try store.dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT venue_id, COUNT(*) AS count
                FROM deal_source
                WHERE status != ?
                GROUP BY venue_id
                """, arguments: [DealStatus.rejected.rawValue])
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

    func count(status: DealStatus? = nil) throws -> Int {
        try store.dbQueue.read { db in
            var request = DealSource.all()
            if let status {
                request = request.filter(Column("status") == status.rawValue)
            }
            return try request.fetchCount(db)
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
    func delete(id: Int64) throws -> Bool {
        try store.dbQueue.write { db in
            try DealSource.deleteOne(db, key: id)
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

    /// Inserts new sources and refreshes `date` for existing rows.
    /// Preserves `.approved` and `.rejected` status; promotes `.new` to `.approved` when rediscovered as approved.
    @discardableResult
    func upsert(sources: [DealSource], forVenueId venueId: Int64) throws -> Int {
        guard !sources.isEmpty else { return 0 }

        return try store.dbQueue.write { db in
            var newCount = 0
            var seenContentHashes = Set<String>()

            for source in sources {
                let existing = try DealSource
                    .filter(Column("venue_id") == venueId && Column("url") == source.url)
                    .fetchOne(db)

                if let existing {
                    var updated = existing
                    updated.date = source.date
                    updated.textPieces = source.textPieces
                    updated.sourceURL = source.sourceURL
                    if source.status == .approved, existing.status == .new {
                        updated.status = .approved
                    }
                    if let contentHash = source.contentHash {
                        updated.contentHash = contentHash
                    }
                    try updated.update(db)
                    if let contentHash = source.contentHash {
                        seenContentHashes.insert(contentHash)
                    }
                    continue
                }

                if let contentHash = source.contentHash {
                    if seenContentHashes.contains(contentHash) {
                        continue
                    }

                    let duplicateByContent = try DealSource
                        .filter(
                            Column("venue_id") == venueId
                                && Column("content_hash") == contentHash
                        )
                        .fetchOne(db)

                    if duplicateByContent != nil {
                        seenContentHashes.insert(contentHash)
                        continue
                    }
                }

                var newSource = source
                newSource.id = nil
                try newSource.insert(db)
                newCount += 1
                if let contentHash = source.contentHash {
                    seenContentHashes.insert(contentHash)
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
