//Created by Alex Skorulis on 17/6/2026.

import Foundation
@preconcurrency import GRDB

final class DealRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
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
}

enum DealRepositoryError: Error {
    case missingDealID
}
