//Created by Alex Skorulis on 18/6/2026.

import Foundation

struct DealWithSchedules: Sendable {
    var deal: Deal
    let schedules: [DealSchedule]
    let products: [DealProduct]
    let sourceIds: [Int64]

    init(
        deal: Deal,
        schedules: [DealSchedule],
        products: [DealProduct] = [],
        sourceIds: [Int64] = []
    ) {
        self.deal = deal
        self.schedules = schedules
        self.products = products
        self.sourceIds = sourceIds
    }

    /// Merges products by name, preserving left-hand order and preferring a non-nil price.
    static func mergedProducts(_ lhs: [DealProduct], _ rhs: [DealProduct]) -> [DealProduct] {
        var result = lhs
        for product in rhs {
            if let index = result.firstIndex(where: { $0.product == product.product }) {
                if result[index].price == nil, let price = product.price {
                    result[index].price = price
                }
            } else {
                result.append(product)
            }
        }
        return result
    }

    /// Ordered unique union of source IDs, preserving left-hand order.
    static func mergedSourceIds(_ lhs: [Int64], _ rhs: [Int64]) -> [Int64] {
        var seen: Set<Int64> = []
        var result: [Int64] = []
        for id in lhs + rhs {
            guard id > 0, !seen.contains(id) else { continue }
            seen.insert(id)
            result.append(id)
        }
        return result
    }
}
