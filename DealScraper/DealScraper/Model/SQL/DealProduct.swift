//Created by Alex Skorulis on 24/7/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct DealProduct: Codable, Sendable {
    var id: Int64?
    let dealId: Int64
    var product: String
    var price: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case dealId = "deal_id"
        case product
        case price
    }

    init(
        id: Int64? = nil,
        dealId: Int64,
        product: String,
        price: Double? = nil
    ) {
        self.id = id
        self.dealId = dealId
        self.product = product
        self.price = price
    }
}

nonisolated extension DealProduct: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "deal_product"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
