//Created by Alex Skorulis on 30/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct FeaturesCatalogTests {

    @Test func loadsAllFeatureNamesFromJSON() {
        let names = FeaturesCatalog.loadFeatureNames()
        #expect(names.count == 10)
        #expect(names.contains("courtyard"))
        #expect(names.contains("beer garden"))
        #expect(names.contains("craft beer"))
        #expect(names.contains("brewery"))
        #expect(names.contains("tab facilities"))
        #expect(names.contains("sports"))
        #expect(names.contains("irish pub"))
        #expect(names.contains("whiskey"))
        #expect(names.contains("rooftop"))
        #expect(names.contains("water views"))
    }

    @Test func isKnownFeatureMatchesCatalogNames() {
        #expect(FeaturesCatalog.isKnownFeature("beer garden"))
        #expect(FeaturesCatalog.isKnownFeature("Rooftop"))
        #expect(!FeaturesCatalog.isKnownFeature("sports bar"))
    }

    @Test func featuresInferredFromBreweryGoogleType() {
        #expect(
            FeaturesCatalog.featuresInferred(fromGoogleTypes: ["brewery"])
                == ["brewery", "craft beer"]
        )
        #expect(
            FeaturesCatalog.featuresInferred(fromGoogleTypes: ["bar", "BREWERY", "point_of_interest"])
                == ["brewery", "craft beer"]
        )
        #expect(FeaturesCatalog.featuresInferred(fromGoogleTypes: ["bar", "pub"]).isEmpty)
        #expect(FeaturesCatalog.featuresInferred(fromGoogleTypes: nil).isEmpty)
    }
}
