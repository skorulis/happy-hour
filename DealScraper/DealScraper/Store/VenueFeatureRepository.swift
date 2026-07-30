//Created by Alex Skorulis on 30/7/2026.

import Foundation
@preconcurrency import GRDB

enum VenueFeatureRepositoryError: Error {
    case unknownFeature(String)
}

final class VenueFeatureRepository {

    private let store: SQLStore

    init(store: SQLStore) {
        self.store = store
    }

    func find(venueId: Int64) throws -> [VenueFeature] {
        try store.dbQueue.read { db in
            try VenueFeature
                .filter(Column("venue_id") == venueId)
                .order(Column("feature"))
                .fetchAll(db)
        }
    }

    func replaceAll(venueId: Int64, features: [String]) throws {
        let normalized = try normalizeFeatures(features)

        try store.dbQueue.write { db in
            try VenueFeature
                .filter(Column("venue_id") == venueId)
                .deleteAll(db)

            for feature in normalized {
                var row = VenueFeature(venueId: venueId, feature: feature)
                try row.insert(db)
            }

            try Venue.touchLastUpdate(db, venueId: venueId)
        }
    }

    private func normalizeFeatures(_ features: [String]) throws -> [String] {
        var seen = Set<String>()
        var normalized: [String] = []

        for raw in features {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            guard FeaturesCatalog.isKnownFeature(trimmed) else {
                throw VenueFeatureRepositoryError.unknownFeature(trimmed)
            }

            let canonical = FeaturesCatalog.loadFeatures().first {
                $0.name.lowercased() == trimmed.lowercased()
            }?.name ?? trimmed

            let key = canonical.lowercased()
            guard !seen.contains(key) else { continue }

            seen.insert(key)
            normalized.append(canonical)
        }

        return normalized.sorted()
    }
}
