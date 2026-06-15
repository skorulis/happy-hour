//Created by Alex Skorulis on 15/6/2026.

import Foundation

@MainActor
@Observable
final class VenueDetailsViewModel {

    let venue: Venue

    init(venue: Venue) {
        self.venue = venue
    }

    var googlePlace: GooglePlace? {
        guard let data = venue.json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(GooglePlace.self, from: data)
    }

    var formattedAddress: String? {
        googlePlace?.formattedAddress
    }

    var types: [String] {
        googlePlace?.types ?? []
    }

    var coordinateDescription: String {
        String(format: "%.6f, %.6f", venue.lat, venue.lng)
    }

    var lastCrawlDescription: String? {
        guard let lastCrawlDate = venue.lastCrawlDate else { return nil }
        return lastCrawlDate.formatted(date: .abbreviated, time: .shortened)
    }

    var mapsURL: URL? {
        URL(string: "https://www.google.com/maps/search/?api=1&query=\(venue.lat),\(venue.lng)&query_place_id=\(venue.googleMapId)")
    }
}
