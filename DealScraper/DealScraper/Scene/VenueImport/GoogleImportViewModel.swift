//Created by Alex Skorulis on 22/6/2026.

import Foundation
import Knit
import KnitMacros

enum VenueSearchMode: String, CaseIterable {
    case text = "Text"
    case nearby = "Nearby"
    case area = "Area"
}

@MainActor
@Observable
final class GoogleImportViewModel {

    enum State: Equatable {
        case idle
        case searching
        case sweeping(VenueAreaSweepProgress)
        case completed(
            totalCount: Int,
            newCount: Int,
            saturatedCellCount: Int = 0,
            apiCallCount: Int = 0
        )
        case failed(message: String)
    }

    private(set) var state: State = .idle

    var searchMode: VenueSearchMode = .text
    var textQuery: String = "pubs in Sydney"
    var regionCode: String = "AU"
    var latitude: String = "-33.8688"
    var longitude: String = "151.2093"
    var radiusMeters: String = "1500"
    var southWestLatitude: String = "-33.875"
    var southWestLongitude: String = "151.200"
    var northEastLatitude: String = "-33.862"
    var northEastLongitude: String = "151.220"
    var cellRadiusMeters: String = "500"

    private let googlePlacesClient: GooglePlacesClient
    private let venueRepository: VenueRepository
    private let apiKeyStore: APIKeyStore

    var estimatedAreaCellCount: Int {
        guard let boundingBox = parsedBoundingBox(),
              let cellRadius = parsedCellRadius()
        else {
            return 0
        }
        return VenueAreaSweep.generateGrid(
            boundingBox: boundingBox,
            cellRadiusMeters: cellRadius
        ).count
    }

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
        case .area:
            guard parsedBoundingBox() != nil else { return }
            guard parsedCellRadius() != nil else { return }
        }

        state = .searching

        do {
            switch searchMode {
            case .text:
                let query = textQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                let region = regionCode.trimmingCharacters(in: .whitespacesAndNewlines)
                let response = try await googlePlacesClient.searchTextAllPages(
                    apiKey: apiKey,
                    textQuery: query,
                    includedType: "bar",
                    regionCode: region.isEmpty ? nil : region
                )
                let newCount = try venueRepository.upsert(places: response.places)
                state = .completed(totalCount: response.places.count, newCount: newCount)

            case .nearby:
                let lat = parsedCoordinate(latitude, name: "latitude")!
                let lng = parsedCoordinate(longitude, name: "longitude")!
                let radius = parsedRadius()!
                let response = try await googlePlacesClient.searchNearby(
                    apiKey: apiKey,
                    latitude: lat,
                    longitude: lng,
                    radiusMeters: radius,
                    includedTypes: VenueAreaSweep.defaultIncludedTypes
                )
                let newCount = try venueRepository.upsert(places: response.places)
                state = .completed(totalCount: response.places.count, newCount: newCount)

            case .area:
                let boundingBox = parsedBoundingBox()!
                let cellRadius = parsedCellRadius()!
                let result = try await googlePlacesClient.searchArea(
                    apiKey: apiKey,
                    boundingBox: boundingBox,
                    cellRadiusMeters: cellRadius,
                    includedTypes: VenueAreaSweep.defaultIncludedTypes,
                    onProgress: { [weak self] progress in
                        self?.state = .sweeping(progress)
                    }
                )
                let newCount = try venueRepository.upsert(places: result.places)
                state = .completed(
                    totalCount: result.places.count,
                    newCount: newCount,
                    saturatedCellCount: result.saturatedCells.count,
                    apiCallCount: result.apiCallCount
                )
            }
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

    private func parsedCellRadius() -> Double? {
        let trimmed = cellRadiusMeters.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let radius = Double(trimmed), radius > 0 else {
            state = .failed(message: "Enter a valid cell radius in meters.")
            return nil
        }
        return radius
    }

    private func parsedBoundingBox() -> VenueAreaSweepBoundingBox? {
        guard let southWestLat = parsedCoordinate(southWestLatitude, name: "south-west latitude"),
              let southWestLng = parsedCoordinate(southWestLongitude, name: "south-west longitude"),
              let northEastLat = parsedCoordinate(northEastLatitude, name: "north-east latitude"),
              let northEastLng = parsedCoordinate(northEastLongitude, name: "north-east longitude")
        else {
            return nil
        }

        let boundingBox = VenueAreaSweepBoundingBox(
            southWestLat: southWestLat,
            southWestLng: southWestLng,
            northEastLat: northEastLat,
            northEastLng: northEastLng
        )

        guard boundingBox.isValid else {
            state = .failed(
                message: "Bounding box is invalid. South-west corner must be south and west of north-east corner."
            )
            return nil
        }

        return boundingBox
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
