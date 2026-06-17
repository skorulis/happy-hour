//Created by Alex Skorulis on 17/6/2026.

import Foundation
@preconcurrency import GRDB

struct DealWithSchedules: Sendable {
    let deal: Deal
    let schedules: [DealSchedule]
}

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
}

enum DealRepositoryError: Error {
    case missingDealID
}
