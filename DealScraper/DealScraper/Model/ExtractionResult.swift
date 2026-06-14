//Created by Alexander Skorulis on 14/6/2026.

import Foundation

nonisolated struct ExtractionResult {
    
    /// All text blocks that were extracted from the image
    let allTexts: [String]
    
    /// The product(s) that are being offered
    let deals: [String]
    
    /// The days this deal applies to
    let days: [DealDay]
    
    let times: [DealTime]
}
