//Created by Alex Skorulis on 15/6/2026.

import Foundation

nonisolated struct LegacyDeal {
    let title: String
    
    let details: [String]

    let conditions: [String]
    
    /// The days this deal applies to
    let days: [DealDay]
    
    let times: [DealHours]
}
