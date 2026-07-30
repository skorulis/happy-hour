//Created by Alex Skorulis on 30/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct FeaturesCatalogTests {

    @Test func loadsAllFeatureNamesFromJSON() {
        let names = FeaturesCatalog.loadFeatureNames()
        #expect(names.count == 3)
        #expect(names.contains("courtyard"))
        #expect(names.contains("beer garden"))
        #expect(names.contains("rooftop"))
    }

    @Test func isKnownFeatureMatchesCatalogNames() {
        #expect(FeaturesCatalog.isKnownFeature("beer garden"))
        #expect(FeaturesCatalog.isKnownFeature("Rooftop"))
        #expect(!FeaturesCatalog.isKnownFeature("sports bar"))
    }
}
