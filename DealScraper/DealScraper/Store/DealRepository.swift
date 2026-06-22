//Created by Alex Skorulis on 17/6/2026.

import Foundation
@preconcurrency import GRDB

final class DealRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    func findNew() throws -> [DealWithSchedules] {
        try store.dbQueue.read { db in
            let deals = try Deal
                .filter(Column("status") == DealStatus.new.rawValue)
                .order(Column("id").asc)
                .fetchAll(db)

            return try deals.map { deal in
                guard let dealId = deal.id else {
                    throw DealRepositoryError.missingDealID
                }
                let schedules = try DealSchedule
                    .filter(Column("deal_id") == dealId)
                    .fetchAll(db)
                return DealWithSchedules(deal: deal, schedules: schedules)
            }
        }
    }

    func find(venueId: Int64) throws -> [DealWithSchedules] {
        try store.dbQueue.read { db in
            let deals = try Deal
                .filter(Column("venue_id") == venueId)
                .fetchAll(db)

            return try deals.map { deal in
                guard let dealId = deal.id else {
                    throw DealRepositoryError.missingDealID
                }
                let schedules = try DealSchedule
                    .filter(Column("deal_id") == dealId)
                    .fetchAll(db)
                return DealWithSchedules(deal: deal, schedules: schedules)
            }
        }
    }

    func countsByVenueId() throws -> [Int64: Int] {
        try store.dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT venue_id, COUNT(*) AS count FROM deal GROUP BY venue_id
                """)
            return Dictionary(uniqueKeysWithValues: rows.compactMap { row in
                guard let venueId: Int64 = row["venue_id"] else { return nil }
                return (venueId, Int(row["count"] ?? 0))
            })
        }
    }

    @discardableResult
    func deleteAll(venueId: Int64) throws -> Int {
        try store.dbQueue.write { db in
            let count = try Deal
                .filter(Column("venue_id") == venueId)
                .fetchCount(db)
            try Deal
                .filter(Column("venue_id") == venueId)
                .deleteAll(db)
            return count
        }
    }

    @discardableResult
    func replaceAll(venueId: Int64, deals: [DealWithSchedules]) throws -> Int {
        try store.dbQueue.write { db in
            try Deal
                .filter(Column("venue_id") == venueId)
                .deleteAll(db)

            for item in deals {
                var deal = item.deal
                deal.id = nil
                try deal.insert(db)
                guard let dealId = deal.id else {
                    throw DealRepositoryError.missingDealID
                }

                for schedule in item.schedules {
                    var newSchedule = DealSchedule(
                        dealId: dealId,
                        dayOfWeek: schedule.dayOfWeek,
                        startMinute: schedule.startMinute,
                        endMinute: schedule.endMinute
                    )
                    try newSchedule.insert(db)
                }
            }

            return deals.count
        }
    }

    func updateStatus(id: Int64, status: DealStatus) throws {
        try store.dbQueue.write { db in
            guard var deal = try Deal.fetchOne(db, key: id) else { return }
            deal.status = status
            try deal.update(db)
        }
    }

    func update(
        id: Int64,
        title: String?,
        details: String?,
        conditions: String?,
        status: DealStatus
    ) throws {
        try store.dbQueue.write { db in
            guard var deal = try Deal.fetchOne(db, key: id) else { return }
            deal.title = title
            deal.details = details
            deal.conditions = conditions
            deal.status = status
            try deal.update(db)
        }
    }
}

enum DealRepositoryError: Error {
    case missingDealID
}
