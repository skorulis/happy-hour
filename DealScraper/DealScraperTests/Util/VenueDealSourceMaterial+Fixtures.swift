//Created by Alex Skorulis on 19/6/2026.

import Foundation
@testable import DealScraper

extension VenueDealSourceMaterial {
    
    static func fixture(
        index: Int = 1,
        dealSourceId: Int64 = 1,
        url: URL = URL(string: "https://example.com/specials")!,
        sourceURL: URL = URL(string: "https://example.com/specials")!,
        type: DealSourceType = .webpage,
        pngData: Data? = nil,
        markdown: String? = nil,
    ) -> Self {
        .init(
            index: index,
            dealSourceId: dealSourceId,
            url: url,
            sourceURL: sourceURL,
            type: type,
            pngData: pngData,
            markdown: markdown
        )
    }
}
