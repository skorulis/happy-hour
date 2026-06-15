//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

enum VenueSearchMode: String, CaseIterable {
    case text = "Text"
    case nearby = "Nearby"
}

@MainActor
@Observable
final class VenueImportViewModel {

    enum State: Equatable {
        case idle
        case searching
        case completed(importedCount: Int)
        case failed(message: String)
    }

    private(set) var state: State = .idle
    private(set) var savedVenues: [Venue] = []
    var selectedGoogleMapId: String?

    var searchMode: VenueSearchMode = .text
    var textQuery: String = "pubs in Sydney"
    var regionCode: String = "AU"
    var latitude: String = "-33.8688"
    var longitude: String = "151.2093"
    var radiusMeters: String = "1500"

    private let googlePlacesClient: GooglePlacesClient
    private let venueRepository: VenueRepository
    private let apiKeyStore: APIKeyStore

    @Resolvable<Resolver>
    init(
        googlePlacesClient: GooglePlacesClient,
        venueRepository: VenueRepository,
        apiKeyStore: APIKeyStore
    ) {
        self.googlePlacesClient = googlePlacesClient
        self.venueRepository = venueRepository
        self.apiKeyStore = apiKeyStore
    }

    func loadSavedVenues() {
        do {
            savedVenues = try venueRepository.all()
            if let selectedGoogleMapId,
               !savedVenues.contains(where: { $0.googleMapId == selectedGoogleMapId })
            {
                self.selectedGoogleMapId = nil
            }
        } catch {
            state = .failed(message: "Could not load saved venues: \(error.localizedDescription)")
        }
    }

    func search() {
        Task {
            await performSearch()
        }
    }

    func reset() {
        state = .idle
    }

    private func performSearch() async {
        let apiKey = apiKeyStore.googlePlacesAPIKey
        guard !apiKey.isEmpty else {
            state = .failed(message: "Configure a Google Places API key in Settings.")
            return
        }

        switch searchMode {
        case .text:
            let query = textQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else {
                state = .failed(message: "Enter a search query.")
                return
            }
        case .nearby:
            guard parsedCoordinate(latitude, name: "latitude") != nil else { return }
            guard parsedCoordinate(longitude, name: "longitude") != nil else { return }
            guard parsedRadius() != nil else { return }
        }

        state = .searching

        do {
            let response: GooglePlacesSearchResponse
            switch searchMode {
            case .text:
                let query = textQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                let region = regionCode.trimmingCharacters(in: .whitespacesAndNewlines)
                response = try await googlePlacesClient.searchText(
                    apiKey: apiKey,
                    textQuery: query,
                    includedType: "bar",
                    regionCode: region.isEmpty ? nil : region
                )
            case .nearby:
                let lat = parsedCoordinate(latitude, name: "latitude")!
                let lng = parsedCoordinate(longitude, name: "longitude")!
                let radius = parsedRadius()!
                response = try await googlePlacesClient.searchNearby(
                    apiKey: apiKey,
                    latitude: lat,
                    longitude: lng,
                    radiusMeters: radius,
                    includedTypes: ["bar"]
                )
            }

            try venueRepository.upsert(places: response.places)
            loadSavedVenues()
            state = .completed(importedCount: response.places.count)
        } catch {
            state = .failed(message: localizedMessage(for: error))
        }
    }

    private func parsedCoordinate(_ value: String, name: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let coordinate = Double(trimmed) else {
            state = .failed(message: "Enter a valid \(name).")
            return nil
        }
        return coordinate
    }

    private func parsedRadius() -> Double? {
        let trimmed = radiusMeters.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let radius = Double(trimmed), radius > 0 else {
            state = .failed(message: "Enter a valid radius in meters.")
            return nil
        }
        return radius
    }

    private func localizedMessage(for error: Error) -> String {
        switch error {
        case GooglePlacesAPI.Error.invalidResponse:
            return "Received an invalid response from Google Places."
        case GooglePlacesAPI.Error.decodingFailure:
            return "Could not parse the Google Places response."
        case let GooglePlacesAPI.Error.apiError(statusCode, message):
            return "Google Places API error (\(statusCode)): \(message)"
        default:
            return error.localizedDescription
        }
    }
}
