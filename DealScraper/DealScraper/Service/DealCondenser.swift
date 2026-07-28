//Created by Alex Skorulis on 18/6/2026.

import Foundation

protocol DealCondenser: Sendable {
    func condense(_ deals: [DealWithSchedules]) -> [DealWithSchedules]
}
