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
                try Self.dealWithRelations(db: db, deal: deal)
            }
        }
    }

    /// Approved deals that have no linked `deal_product` rows.
    func findApprovedWithoutProducts() throws -> [DealWithSchedules] {
        try store.dbQueue.read { db in
            let deals = try Deal.fetchAll(
                db,
                sql: """
                    SELECT d.*
                    FROM deal d
                    WHERE d.status = ?
                      AND NOT EXISTS (
                          SELECT 1 FROM deal_product dp WHERE dp.deal_id = d.id
                      )
                    ORDER BY d.id ASC
                    """,
                arguments: [DealStatus.approved.rawValue]
            )

            return try deals.map { deal in
                try Self.dealWithRelations(db: db, deal: deal)
            }
        }
    }

    /// Approved deals with two or more schedules that overlap on the same weekday.
    func findApprovedWithOverlappingSchedules() throws -> [DealWithSchedules] {
        try store.dbQueue.read { db in
            let deals = try Deal.fetchAll(
                db,
                sql: """
                    SELECT DISTINCT d.*
                    FROM deal d
                    WHERE d.status = ?
                      AND EXISTS (
                          SELECT 1
                          FROM deal_schedule s1
                          INNER JOIN deal_schedule s2
                            ON s1.deal_id = s2.deal_id
                            AND s1.id < s2.id
                            AND s1.day_of_week = s2.day_of_week
                            AND s1.start_minute < s2.end_minute
                            AND s2.start_minute < s1.end_minute
                          WHERE s1.deal_id = d.id
                      )
                    ORDER BY d.id ASC
                    """,
                arguments: [DealStatus.approved.rawValue]
            )

            return try deals.map { deal in
                try Self.dealWithRelations(db: db, deal: deal)
            }
        }
    }

    /// Approved deals mentioning "happy hour" with any schedule longer than 12 hours.
    func findApprovedHappyHourWithLongSchedules() throws -> [DealWithSchedules] {
        try store.dbQueue.read { db in
            let deals = try Deal.fetchAll(
                db,
                sql: """
                    SELECT DISTINCT d.*
                    FROM deal d
                    WHERE d.status = ?
                      AND (
                          LOWER(IFNULL(d.title, '')) LIKE '%happy hour%'
                          OR LOWER(IFNULL(d.details, '')) LIKE '%happy hour%'
                      )
                      AND EXISTS (
                          SELECT 1
                          FROM deal_schedule s
                          WHERE s.deal_id = d.id
                            AND (s.end_minute - s.start_minute) > 720
                      )
                    ORDER BY d.id ASC
                    """,
                arguments: [DealStatus.approved.rawValue]
            )

            return try deals.map { deal in
                try Self.dealWithRelations(db: db, deal: deal)
            }
        }
    }

    func find(venueId: Int64) throws -> [DealWithSchedules] {
        try store.dbQueue.read { db in
            let deals = try Deal
                .filter(Column("venue_id") == venueId)
                .fetchAll(db)

            return try deals.map { deal in
                try Self.dealWithRelations(db: db, deal: deal)
            }
        }
    }

    func count(status: DealStatus? = nil) throws -> Int {
        try store.dbQueue.read { db in
            var request = Deal.all()
            if let status {
                request = request.filter(Column("status") == status.rawValue)
            }
            return try request.fetchCount(db)
        }
    }

    func countDistinctSuburbsWithDeals() throws -> Int {
        try store.dbQueue.read { db in
            try Int.fetchOne(db, sql: """
                SELECT COUNT(DISTINCT v.suburb_id)
                FROM venue v
                INNER JOIN deal d ON d.venue_id = v.id
                WHERE v.suburb_id IS NOT NULL
                """) ?? 0
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

    func countsBySuburbId() throws -> [Int64: Int] {
        try store.dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT v.suburb_id, COUNT(*) AS count
                FROM deal d
                INNER JOIN venue v ON v.id = d.venue_id
                WHERE v.suburb_id IS NOT NULL
                GROUP BY v.suburb_id
                """)
            return Dictionary(uniqueKeysWithValues: rows.compactMap { row in
                guard let suburbId: Int64 = row["suburb_id"] else { return nil }
                return (suburbId, Int(row["count"] ?? 0))
            })
        }
    }

    @discardableResult
    func delete(id: Int64) throws -> Bool {
        try store.dbQueue.write { db in
            guard let deal = try Deal.fetchOne(db, key: id) else { return false }
            let deleted = try Deal.deleteOne(db, key: id)
            if deleted {
                try Venue.touchLastUpdate(db, venueId: deal.venueId)
            }
            return deleted
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
            try db.execute(
                sql: "UPDATE venue SET last_extraction_date = NULL, last_update = ? WHERE id = ?",
                arguments: [Date(), venueId]
            )
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

                for product in item.products {
                    var newProduct = DealProduct(
                        dealId: dealId,
                        product: product.product,
                        price: product.price
                    )
                    try newProduct.insert(db)
                }

                for sourceId in item.sourceIds where sourceId > 0 {
                    var link = DealSourceLink(dealId: dealId, dealSourceId: sourceId)
                    try link.insert(db)
                }
            }

            try Venue.touchLastUpdate(db, venueId: venueId)
            return deals.count
        }
    }

    func duplicate(id: Int64) throws -> DealWithSchedules? {
        try store.dbQueue.write { db in
            guard let original = try Deal.fetchOne(db, key: id) else { return nil }
            let schedules = try DealSchedule
                .filter(Column("deal_id") == id)
                .fetchAll(db)
            let products = try DealProduct
                .filter(Column("deal_id") == id)
                .fetchAll(db)
            let sourceLinks = try DealSourceLink
                .filter(Column("deal_id") == id)
                .fetchAll(db)

            var newDeal = Deal(
                venueId: original.venueId,
                title: original.title,
                creativeURL: original.creativeURL,
                sourceURL: original.sourceURL,
                details: original.details,
                conditions: original.conditions,
                status: original.status,
                updateDate: .now
            )
            try newDeal.insert(db)
            guard let newDealId = newDeal.id else {
                throw DealRepositoryError.missingDealID
            }

            var newSchedules: [DealSchedule] = []
            for schedule in schedules {
                var newSchedule = DealSchedule(
                    dealId: newDealId,
                    dayOfWeek: schedule.dayOfWeek,
                    startMinute: schedule.startMinute,
                    endMinute: schedule.endMinute
                )
                try newSchedule.insert(db)
                newSchedules.append(newSchedule)
            }

            var newProducts: [DealProduct] = []
            for product in products {
                var newProduct = DealProduct(
                    dealId: newDealId,
                    product: product.product,
                    price: product.price
                )
                try newProduct.insert(db)
                newProducts.append(newProduct)
            }

            var newSourceIds: [Int64] = []
            for link in sourceLinks {
                var newLink = DealSourceLink(dealId: newDealId, dealSourceId: link.dealSourceId)
                try newLink.insert(db)
                newSourceIds.append(link.dealSourceId)
            }

            try Venue.touchLastUpdate(db, venueId: original.venueId)
            return DealWithSchedules(
                deal: newDeal,
                schedules: newSchedules,
                products: newProducts,
                sourceIds: newSourceIds
            )
        }
    }

    func updateStatus(id: Int64, status: DealStatus) throws {
        try store.dbQueue.write { db in
            guard var deal = try Deal.fetchOne(db, key: id) else { return }
            deal.status = status
            try deal.update(db)
            try Venue.touchLastUpdate(db, venueId: deal.venueId)
        }
    }

    func update(
        id: Int64,
        title: String?,
        details: String?,
        conditions: String?,
        sourceURL: String?,
        creativeURL: String?,
        startDate: Date? = nil,
        endDate: Date? = nil,
        schedules: [DealSchedule]? = nil,
        products: [DealProduct]? = nil,
        status: DealStatus
    ) throws {
        try store.dbQueue.write { db in
            guard var deal = try Deal.fetchOne(db, key: id) else { return }
            deal.title = title
            deal.details = details
            deal.conditions = conditions
            deal.sourceURL = sourceURL
            deal.creativeURL = creativeURL
            deal.startDate = startDate
            deal.endDate = endDate
            deal.status = status
            deal.updateDate = .now
            try deal.update(db)

            if let schedules {
                try DealSchedule
                    .filter(Column("deal_id") == id)
                    .deleteAll(db)

                for schedule in schedules {
                    var newSchedule = DealSchedule(
                        dealId: id,
                        dayOfWeek: schedule.dayOfWeek,
                        startMinute: schedule.startMinute,
                        endMinute: schedule.endMinute
                    )
                    try newSchedule.insert(db)
                }
            }

            if let products {
                try DealProduct
                    .filter(Column("deal_id") == id)
                    .deleteAll(db)

                for product in products {
                    var newProduct = DealProduct(
                        dealId: id,
                        product: product.product,
                        price: product.price
                    )
                    try newProduct.insert(db)
                }
            }

            try Venue.touchLastUpdate(db, venueId: deal.venueId)
        }
    }

    private static func dealWithRelations(db: Database, deal: Deal) throws -> DealWithSchedules {
        guard let dealId = deal.id else {
            throw DealRepositoryError.missingDealID
        }
        let schedules = try DealSchedule
            .filter(Column("deal_id") == dealId)
            .fetchAll(db)
        let products = try DealProduct
            .filter(Column("deal_id") == dealId)
            .fetchAll(db)
        let sourceIds = try DealSourceLink
            .filter(Column("deal_id") == dealId)
            .fetchAll(db)
            .map(\.dealSourceId)
        return DealWithSchedules(
            deal: deal,
            schedules: schedules,
            products: products,
            sourceIds: sourceIds
        )
    }
}

enum DealRepositoryError: Error {
    case missingDealID
}
