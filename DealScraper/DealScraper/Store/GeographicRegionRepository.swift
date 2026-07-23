// Created by Alexander Skorulis on 22/7/2026.

import Foundation
@preconcurrency import GRDB

final class GeographicRegionRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    func find(id: Int64) throws -> GeographicRegion? {
        try store.dbQueue.read { db in
            try GeographicRegion.fetchOne(db, key: id)
        }
    }

    func all() throws -> [GeographicRegion] {
        try store.dbQueue.read { db in
            try GeographicRegion
                .order(Column("name"))
                .fetchAll(db)
        }
    }

    func suburbCount(regionId: Int64) throws -> Int {
        try store.dbQueue.read { db in
            try Suburb
                .filter(Column("region_id") == regionId)
                .fetchCount(db)
        }
    }

    func updateHeroImage(regionId: Int64, url: String?) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE geographic_region SET hero_image = ? WHERE id = ?",
                arguments: [url, regionId]
            )
        }
    }

    func updateHeroR2Url(regionId: Int64, url: String?) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE geographic_region SET hero_r2_url = ? WHERE id = ?",
                arguments: [url, regionId]
            )
        }
    }

    func clearHeroImageFields(regionId: Int64) throws {
        try store.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE geographic_region SET hero_image = NULL, hero_r2_url = NULL WHERE id = ?",
                arguments: [regionId]
            )
        }
    }
}
