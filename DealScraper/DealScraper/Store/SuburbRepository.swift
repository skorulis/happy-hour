//Created by Alex Skorulis on 22/6/2026.

import Foundation
@preconcurrency import GRDB

final class SuburbRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    func resolve(name: String, postcode: String?, state: String?) throws -> Int64? {
        try store.dbQueue.read { db in
            try Self.resolve(name: name, postcode: postcode, state: state, in: db)
        }
    }

    func resolve(name: String, postcode: String?, state: String?, in db: Database) throws -> Int64? {
        try Self.resolve(name: name, postcode: postcode, state: state, in: db)
    }

    func find(name: String, postcode: String?) throws -> Suburb? {
        try store.dbQueue.read { db in
            try Self.find(name: name, postcode: Self.normalized(postcode), in: db)
        }
    }

    func find(id: Int64) throws -> Suburb? {
        try store.dbQueue.read { db in
            try Suburb.fetchOne(db, key: id)
        }
    }

    func all() throws -> [Suburb] {
        try store.dbQueue.read { db in
            try Suburb.fetchAll(db)
        }
    }

    /// Suburbs the Places API cannot handle reliably — skip for "Crawl Next Suburb".
    static func isExcludedFromCrawl(_ suburb: Suburb) -> Bool {
        suburb.name == "Perrys Crossing" && normalized(suburb.postcode) == "2775"
    }

    func updateLastCrawlDate(suburbId: Int64, date: Date) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE suburb SET last_crawl_date = ? WHERE id = ?",
                arguments: [date, suburbId]
            )
        }
    }

    func updateHeroImage(suburbId: Int64, url: String?) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE suburb SET hero_image = ? WHERE id = ?",
                arguments: [url, suburbId]
            )
        }
    }

    func updateHeroR2Url(suburbId: Int64, url: String?) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE suburb SET hero_r2_url = ? WHERE id = ?",
                arguments: [url, suburbId]
            )
        }
    }

    func clearHeroImageFields(suburbId: Int64) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE suburb SET hero_image = NULL, hero_r2_url = NULL WHERE id = ?",
                arguments: [suburbId]
            )
        }
    }

    static func resolve(name: String, postcode: String?, state: String?, in db: Database) throws -> Int64? {
        let canonicalName = canonicalResolveName(name: name, postcode: postcode, state: state)
        let normalizedPostcode = normalized(postcode)
        let normalizedState = normalizedState(state)

        if let normalizedState, let normalizedPostcode,
           let id = try exactMatch(
               name: canonicalName,
               postcode: normalizedPostcode,
               state: normalizedState,
               in: db
           )
        {
            return id
        }

        if let normalizedState,
           let id = try firstMatch(name: canonicalName, state: normalizedState, in: db)
        {
            return id
        }

        if let normalizedPostcode,
           let id = try firstByPostcode(normalizedPostcode, in: db)
        {
            return id
        }

        return try firstByName(canonicalName, in: db)
    }

    /// Maps source-data suburb names to their canonical DB names.
    private static func canonicalResolveName(
        name: String,
        postcode: String?,
        state: String?
    ) -> String {
        if name == "Sydney",
           normalized(postcode) == "2000",
           normalizedState(state) == "NSW"
        {
            return "Sydney CBD"
        }
        return name
    }

    private static func exactMatch(
        name: String,
        postcode: String,
        state: String,
        in db: Database
    ) throws -> Int64? {
        try Suburb
            .filter(Column("name") == name)
            .filter(Column("postcode") == postcode)
            .filter(Column("state") == state)
            .fetchOne(db)?
            .id
    }

    private static func firstMatch(name: String, state: String, in db: Database) throws -> Int64? {
        try Suburb
            .filter(Column("name") == name)
            .filter(Column("state") == state)
            .order(Column("id"))
            .fetchOne(db)?
            .id
    }

    private static func firstByPostcode(_ postcode: String, in db: Database) throws -> Int64? {
        try Suburb
            .filter(Column("postcode") == postcode)
            .order(Column("id"))
            .fetchOne(db)?
            .id
    }

    private static func firstByName(_ name: String, in db: Database) throws -> Int64? {
        try Suburb
            .filter(Column("name") == name)
            .order(Column("id"))
            .fetchOne(db)?
            .id
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

    private static func normalizedState(_ state: String?) -> String? {
        guard let state else { return nil }
        let trimmed = state.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed.uppercased()
    }
}
