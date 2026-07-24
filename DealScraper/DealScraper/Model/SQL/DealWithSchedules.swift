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
}
