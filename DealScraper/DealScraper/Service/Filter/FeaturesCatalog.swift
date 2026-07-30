//Created by Alex Skorulis on 30/7/2026.

import Foundation

struct Feature: Decodable, Equatable {
    let name: String
    let synonyms: [String]?
}

nonisolated enum FeaturesCatalog {
    static let featureNames: [String] = loadFeatureNames()

    static func loadFeatureNames(from bundle: Bundle = .dealScraper) -> [String] {
        loadFeatures(from: bundle).map(\.name)
    }

    static func loadFeatures(from bundle: Bundle = .dealScraper) -> [Feature] {
        guard let url = bundle.url(forResource: "features", withExtension: "json") else {
            fatalError("Missing features.json in bundle")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Feature].self, from: data)
        } catch {
            fatalError("Failed to load features.json: \(error)")
        }
    }

    static func isKnownFeature(_ name: String) -> Bool {
        let key = name.lowercased()
        return loadFeatures().contains { $0.name.lowercased() == key }
    }

    /// Features implied by Google Places types when a venue is synced.
    static func featuresInferred(fromGoogleTypes types: [String]?) -> [String] {
        guard let types, !types.isEmpty else { return [] }

        let lower = Set(types.map { $0.lowercased() })
        var inferred: [String] = []

        if lower.contains("brewery") {
            inferred.append(contentsOf: ["brewery", "craft beer"])
        }

        return inferred.filter { isKnownFeature($0) }
    }
}
