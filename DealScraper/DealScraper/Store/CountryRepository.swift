// Created by Alexander Skorulis on 19/7/2026.

import Foundation
@preconcurrency import GRDB

final class CountryRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    func find(id: Int64) throws -> Country? {
        try store.dbQueue.read { db in
            try Country.fetchOne(db, key: id)
        }
    }
}
