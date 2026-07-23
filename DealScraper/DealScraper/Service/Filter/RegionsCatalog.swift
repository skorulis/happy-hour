// Created by Alexander Skorulis on 23/7/2026.

import Foundation

struct RegionEntry: Decodable, Equatable {
    let name: String
    let status: String
}

nonisolated enum RegionsCatalog {
    static let regionNames: [String] = loadRegionNames()

    static func loadRegionNames(from bundle: Bundle = .dealScraper) -> [String] {
        loadRegions(from: bundle).map(\.name)
    }

    static func loadRegions(from bundle: Bundle = .dealScraper) -> [RegionEntry] {
        guard let url = bundle.url(forResource: "regions", withExtension: "json") else {
            fatalError("Missing regions.json in bundle")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([RegionEntry].self, from: data)
        } catch {
            fatalError("Failed to load regions.json: \(error)")
        }
    }
}
