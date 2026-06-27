//Created by Alex Skorulis on 27/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueAreaSweepTests {

    @Test func generateGridCoversBoundingBox() {
        let boundingBox = VenueAreaSweepBoundingBox(
            southWestLat: -33.875,
            southWestLng: 151.200,
            northEastLat: -33.862,
            northEastLng: 151.220
        )

        let cells = VenueAreaSweep.generateGrid(
            boundingBox: boundingBox,
            cellRadiusMeters: 500
        )

        #expect(cells.count >= 4)
        #expect(cells.allSatisfy { $0.radiusMeters == 500 })
    }

    @Test func generateGridReturnsEmptyForInvalidBoundingBox() {
        let boundingBox = VenueAreaSweepBoundingBox(
            southWestLat: -33.862,
            southWestLng: 151.220,
            northEastLat: -33.875,
            northEastLng: 151.200
        )

        let cells = VenueAreaSweep.generateGrid(
            boundingBox: boundingBox,
            cellRadiusMeters: 500
        )

        #expect(cells.isEmpty)
    }

    @Test func subdivideCellProducesFourQuadrants() {
        let cell = VenueAreaSweepCell(
            latitude: -33.8688,
            longitude: 151.2093,
            radiusMeters: 500
        )

        let subCells = VenueAreaSweep.subdivideCell(cell)

        #expect(subCells.count == 4)
        #expect(subCells.allSatisfy { $0.radiusMeters == 250 })
        #expect(Set(subCells.map(\.latitude)).count == 2)
        #expect(Set(subCells.map(\.longitude)).count == 2)
    }

    @Test func sweepDedupesPlacesAcrossCells() async throws {
        let sharedPlace = samplePlace(id: "places/shared", name: "Shared Pub")
        var callCount = 0

        let result = try await VenueAreaSweep.sweep(
            boundingBox: smallBoundingBox,
            cellRadiusMeters: 500,
            searchNearby: { _, _, _ in
                callCount += 1
                return [sharedPlace]
            }
        )

        #expect(result.places.count == 1)
        #expect(result.places.first?.id == "places/shared")
        #expect(callCount == VenueAreaSweep.generateGrid(
            boundingBox: smallBoundingBox,
            cellRadiusMeters: 500
        ).count)
    }

    @Test func sweepSubdividesSaturatedCells() async throws {
        let boundingBox = VenueAreaSweepBoundingBox(
            southWestLat: -33.8695,
            southWestLng: 151.2085,
            northEastLat: -33.8690,
            northEastLng: 151.2090
        )
        let topLevelCells = VenueAreaSweep.generateGrid(
            boundingBox: boundingBox,
            cellRadiusMeters: 500
        )
        #expect(topLevelCells.count == 1)

        var saturatedSearchCount = 0
        var subdividedSearchCount = 0

        let result = try await VenueAreaSweep.sweep(
            boundingBox: boundingBox,
            cellRadiusMeters: 500,
            maxSubdivisionDepth: 1,
            searchNearby: { _, _, radiusMeters in
                if radiusMeters == 500 {
                    saturatedSearchCount += 1
                    return (0..<VenueAreaSweep.nearbyResultCap).map { index in
                        samplePlace(id: "places/sat-\(saturatedSearchCount)-\(index)", name: "Pub \(index)")
                    }
                }

                subdividedSearchCount += 1
                return [
                    samplePlace(
                        id: "places/sub-\(subdividedSearchCount)",
                        name: "Sub Pub \(subdividedSearchCount)"
                    ),
                ]
            }
        )

        #expect(saturatedSearchCount == 1)
        #expect(subdividedSearchCount == 4)
        #expect(result.places.count == VenueAreaSweep.nearbyResultCap + 4)
        #expect(result.saturatedCells.isEmpty)
    }

    @Test func sweepRecordsSaturatedCellsAtMaxDepth() async throws {
        let boundingBox = VenueAreaSweepBoundingBox(
            southWestLat: -33.8695,
            southWestLng: 151.2085,
            northEastLat: -33.8690,
            northEastLng: 151.2090
        )

        let result = try await VenueAreaSweep.sweep(
            boundingBox: boundingBox,
            cellRadiusMeters: 500,
            maxSubdivisionDepth: 0,
            searchNearby: { _, _, _ in
                (0..<VenueAreaSweep.nearbyResultCap).map { index in
                    samplePlace(id: "places/full-\(index)", name: "Pub \(index)")
                }
            }
        )

        #expect(result.places.count == VenueAreaSweep.nearbyResultCap)
        #expect(result.saturatedCells.count == 1)
        #expect(result.saturatedCells.first?.radiusMeters == 500)
    }

    @Test func sweepReportsProgress() async throws {
        let boundingBox = VenueAreaSweepBoundingBox(
            southWestLat: -33.8695,
            southWestLng: 151.2085,
            northEastLat: -33.8690,
            northEastLng: 151.2090
        )
        var progressUpdates: [VenueAreaSweepProgress] = []

        _ = try await VenueAreaSweep.sweep(
            boundingBox: boundingBox,
            cellRadiusMeters: 500,
            searchNearby: { _, _, _ in [] },
            onProgress: { progress in
                progressUpdates.append(progress)
            }
        )

        #expect(progressUpdates.count == 1)
        #expect(progressUpdates.first?.cellsCompleted == 1)
        #expect(progressUpdates.first?.totalCells == 1)
    }

    private var smallBoundingBox: VenueAreaSweepBoundingBox {
        VenueAreaSweepBoundingBox(
            southWestLat: -33.875,
            southWestLng: 151.200,
            northEastLat: -33.862,
            northEastLng: 151.220
        )
    }

    private func samplePlace(id: String, name: String) -> GooglePlace {
        GooglePlace(
            id: id,
            displayName: .init(text: name, languageCode: "en"),
            location: .init(latitude: -33.8688, longitude: 151.2093),
            formattedAddress: "123 George St, Sydney NSW 2000",
            websiteUri: "https://example.com",
            types: ["bar"]
        )
    }
}
