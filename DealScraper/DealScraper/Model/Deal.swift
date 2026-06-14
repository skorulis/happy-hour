//Created by Alex Skorulis on 15/6/2026.

import Foundation

nonisolated struct Deal {
    let title: String
    
    let details: [String]
    
    /// The days this deal applies to
    let days: [DealDay]
    
    let times: [DealHours]
}
