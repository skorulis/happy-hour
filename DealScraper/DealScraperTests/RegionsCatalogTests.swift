// Created by Alexander Skorulis on 23/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct RegionsCatalogTests {

    @Test func loadsAllRegionNamesFromJSON() {
        let names = RegionsCatalog.loadRegionNames()
        #expect(names.count == 13)
        #expect(names.contains("Sydney"))
        #expect(names.contains("Melbourne"))
        #expect(names.contains("Brisbane"))
        #expect(names.contains("Perth"))
        #expect(names.contains("Adelaide"))
        #expect(names.contains("Darwin"))
        #expect(names.contains("The Sunshine Coast"))
        #expect(names.contains("Central Coast"))
        #expect(names.contains("Blue Mountains"))
        #expect(names.contains("Hawkesbury"))
        #expect(names.contains("Wollondilly"))
        #expect(names.contains("Regional NSW"))
        #expect(names.contains("Queenstown Lakes"))
    }

    @Test func loadsRegionsWithStatusAndCountry() {
        let regions = RegionsCatalog.loadRegions()
        #expect(regions.count == 13)
        #expect(regions.allSatisfy { ["live", "in-progress", "future"].contains($0.status) })
        #expect(regions.contains { $0.name == "Sydney" && $0.status == "live" && $0.country == "AUS" })
        #expect(regions.contains {
            $0.name == "Central Coast" && $0.status == "future" && $0.country == "AUS"
        })
        #expect(regions.contains {
            $0.name == "Blue Mountains" && $0.status == "future" && $0.country == "AUS"
        })
        #expect(regions.contains {
            $0.name == "Hawkesbury" && $0.status == "future" && $0.country == "AUS"
        })
        #expect(regions.contains {
            $0.name == "Wollondilly" && $0.status == "future" && $0.country == "AUS"
        })
        #expect(regions.contains {
            $0.name == "Queenstown Lakes" && $0.status == "live" && $0.country == "NZL"
        })
    }

    @Test func regionNamesMatchesStaticProperty() {
        #expect(RegionsCatalog.regionNames == RegionsCatalog.loadRegionNames())
    }
}
