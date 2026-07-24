//Created by Alex Skorulis on 18/6/2026.

import Foundation

struct DealWithSchedules: Sendable {
    var deal: Deal
    let schedules: [DealSchedule]
    let products: [DealProduct]

    init(
        deal: Deal,
        schedules: [DealSchedule],
        products: [DealProduct] = []
    ) {
        self.deal = deal
        self.schedules = schedules
        self.products = products
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
}
