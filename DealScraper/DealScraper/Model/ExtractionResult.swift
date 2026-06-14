//Created by Alexander Skorulis on 14/6/2026.

import Foundation

struct ExtractionResult {
    
    /// All text blocks that were extracted from the image
    let allTexts: [String]
    
    /// The deal that would be shown to a user
    let dealText: String
    
    /// The days this deal applies to
    let days: [DealDay]
}
