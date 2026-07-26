// Created by Alexander Skorulis on 23/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct RegionsCatalogTests {

    @Test func loadsAllRegionNamesFromJSON() {
        let names = RegionsCatalog.loadRegionNames()
        #expect(names.count == 9)
        #expect(names.contains("Sydney"))
        #expect(names.contains("Melbourne"))
        #expect(names.contains("Brisbane"))
        #expect(names.contains("Perth"))
        #expect(names.contains("Adelaide"))
        #expect(names.contains("Darwin"))
        #expect(names.contains("The Sunshine Coast"))
        #expect(names.contains("Regional NSW"))
        #expect(names.contains("Queenstown Lakes"))
    }

    @Test func loadsRegionsWithStatusAndCountry() {
        let regions = RegionsCatalog.loadRegions()
        #expect(regions.count == 9)
        #expect(regions.allSatisfy { ["live", "in-progress", "future"].contains($0.status) })
        #expect(regions.contains { $0.name == "Sydney" && $0.status == "live" && $0.country == "AUS" })
        #expect(regions.contains {
            $0.name == "Queenstown Lakes" && $0.status == "future" && $0.country == "NZL"
        })
    }

    @Test func regionNamesMatchesStaticProperty() {
        #expect(RegionsCatalog.regionNames == RegionsCatalog.loadRegionNames())
    }
}
