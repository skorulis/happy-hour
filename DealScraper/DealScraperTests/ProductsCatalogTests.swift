//Created by Alex Skorulis on 29/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct ProductsCatalogTests {

    @Test func loadsAllProductNamesFromJSON() {
        let names = ProductsCatalog.loadProductNames()
        #expect(names.count == 60)
        #expect(names.contains("beer"))
        #expect(names.contains("happy hour"))
        #expect(names.contains("2 for 1"))
        #expect(names.contains("schnitty"))
        #expect(names.contains("live music"))
    }

    @Test func filterKeywordsUsesLoadedProductNames() {
        #expect(FilterKeywords.productKeywords == ProductsCatalog.productNames)
        #expect(FilterKeywords.productKeywords.contains("burger"))
        #expect(FilterKeywords.productKeywords.contains("run club"))
    }
}
