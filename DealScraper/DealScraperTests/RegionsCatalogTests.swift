// Created by Alexander Skorulis on 23/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct RegionsCatalogTests {

    @Test func loadsAllRegionNamesFromJSON() {
        let names = RegionsCatalog.loadRegionNames()
        #expect(names.count == 8)
        #expect(names.contains("Sydney"))
        #expect(names.contains("Melbourne"))
        #expect(names.contains("Brisbane"))
        #expect(names.contains("Perth"))
        #expect(names.contains("Adelaide"))
        #expect(names.contains("Darwin"))
        #expect(names.contains("The Sunshine Coast"))
        #expect(names.contains("Regional NSW"))
    }

    @Test func loadsRegionsWithStatus() {
        let regions = RegionsCatalog.loadRegions()
        #expect(regions.count == 8)
        #expect(regions.allSatisfy { $0.status == "live" || $0.status == "in-progress" })
        #expect(regions.contains { $0.name == "Sydney" && $0.status == "live" })
    }

    @Test func regionNamesMatchesStaticProperty() {
        #expect(RegionsCatalog.regionNames == RegionsCatalog.loadRegionNames())
    }
}
