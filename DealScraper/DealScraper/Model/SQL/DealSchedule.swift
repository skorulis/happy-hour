//Created by Alex Skorulis on 17/6/2026.

import Foundation
@preconcurrency import GRDB

nonisolated struct DealSchedule: Codable, Sendable {
    var id: Int64?
    let dealId: Int64
    let dayOfWeek: Int
    let startMinute: Int
    let endMinute: Int

    enum CodingKeys: String, CodingKey {
        case id
        case dealId = "deal_id"
        case dayOfWeek = "day_of_week"
        case startMinute = "start_minute"
        case endMinute = "end_minute"
    }

    init(
        id: Int64? = nil,
        dealId: Int64,
        dayOfWeek: Int,
        startMinute: Int,
        endMinute: Int
    ) {
        self.id = id
        self.dealId = dealId
        self.dayOfWeek = dayOfWeek
        self.startMinute = startMinute
        self.endMinute = endMinute
    }
}

nonisolated extension DealSchedule: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "deal_schedule"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
