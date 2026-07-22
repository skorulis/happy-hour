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
}
