//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class VenueDetailsViewModel {

    let googleMapId: String
    private(set) var venue: Venue?

    private let venueRepository: VenueRepository

    @Resolvable<Resolver>
    init(@Argument googleMapId: String, venueRepository: VenueRepository) {
        self.googleMapId = googleMapId
        self.venueRepository = venueRepository
        load()
    }

    private func load() {
        venue = try? venueRepository.find(googleMapId: googleMapId)
    }

    var googlePlace: GooglePlace? {
        guard let venue, let data = venue.json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(GooglePlace.self, from: data)
    }

    var formattedAddress: String? {
        googlePlace?.formattedAddress
    }

    var types: [String] {
        googlePlace?.types ?? []
    }

    var coordinateDescription: String? {
        guard let venue else { return nil }
        return String(format: "%.6f, %.6f", venue.lat, venue.lng)
    }

    var lastCrawlDescription: String? {
        guard let venue, let lastCrawlDate = venue.lastCrawlDate else { return nil }
        return lastCrawlDate.formatted(date: .abbreviated, time: .shortened)
    }

    var mapsURL: URL? {
        guard let venue else { return nil }
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(venue.lat),\(venue.lng)&query_place_id=\(venue.googleMapId)")
    }
}
