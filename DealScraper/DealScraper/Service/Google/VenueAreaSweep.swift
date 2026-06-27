//Created by Alex Skorulis on 27/6/2026.

import Foundation

nonisolated struct VenueAreaSweepBoundingBox: Equatable, Sendable {
    let southWestLat: Double
    let southWestLng: Double
    let northEastLat: Double
    let northEastLng: Double

    var isValid: Bool {
        southWestLat < northEastLat && southWestLng < northEastLng
    }
}

nonisolated struct VenueAreaSweepCell: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let radiusMeters: Double
}

nonisolated struct VenueAreaSweepProgress: Equatable, Sendable {
    let cellsCompleted: Int
    let totalCells: Int
    let venuesFound: Int
    let saturatedCells: Int
}

nonisolated struct VenueAreaSweepResult: Sendable {
    let places: [GooglePlace]
    let saturatedCells: [VenueAreaSweepCell]
    let apiCallCount: Int
}

enum VenueAreaSweep {

    static let nearbyResultCap = 20
    static let defaultIncludedTypes = ["bar", "night_club"]
    static let spacingOverlapFactor = 0.7
    static let maxSubdivisionDepth = 3
    static let nearbyCallDelay: Duration = .milliseconds(200)

    typealias NearbySearch = (
        _ latitude: Double,
        _ longitude: Double,
        _ radiusMeters: Double
    ) async throws -> [GooglePlace]

    static func generateGrid(
        boundingBox: VenueAreaSweepBoundingBox,
        cellRadiusMeters: Double
    ) -> [VenueAreaSweepCell] {
        guard boundingBox.isValid, cellRadiusMeters > 0 else { return [] }

        let spacingMeters = cellRadiusMeters * spacingOverlapFactor
        let centerLatitude = (boundingBox.southWestLat + boundingBox.northEastLat) / 2
        let latStep = spacingMeters / metersPerDegreeLatitude
        let lngStep = spacingMeters / metersPerDegreeLongitude(at: centerLatitude)
        let halfLatStep = latStep / 2
        let halfLngStep = lngStep / 2

        var cells: [VenueAreaSweepCell] = []
        var lat = boundingBox.southWestLat + halfLatStep
        while lat <= boundingBox.northEastLat + halfLatStep {
            var lng = boundingBox.southWestLng + halfLngStep
            while lng <= boundingBox.northEastLng + halfLngStep {
                cells.append(
                    VenueAreaSweepCell(
                        latitude: lat,
                        longitude: lng,
                        radiusMeters: cellRadiusMeters
                    )
                )
                lng += lngStep
            }
            lat += latStep
        }
        return cells
    }

    static func subdivideCell(_ cell: VenueAreaSweepCell) -> [VenueAreaSweepCell] {
        let halfRadius = cell.radiusMeters / 2
        let offsetMeters = cell.radiusMeters * spacingOverlapFactor / 2
        let latOffset = offsetMeters / metersPerDegreeLatitude
        let lngOffset = offsetMeters / metersPerDegreeLongitude(at: cell.latitude)

        return [
            VenueAreaSweepCell(
                latitude: cell.latitude + latOffset,
                longitude: cell.longitude + lngOffset,
                radiusMeters: halfRadius
            ),
            VenueAreaSweepCell(
                latitude: cell.latitude + latOffset,
                longitude: cell.longitude - lngOffset,
                radiusMeters: halfRadius
            ),
            VenueAreaSweepCell(
                latitude: cell.latitude - latOffset,
                longitude: cell.longitude + lngOffset,
                radiusMeters: halfRadius
            ),
            VenueAreaSweepCell(
                latitude: cell.latitude - latOffset,
                longitude: cell.longitude - lngOffset,
                radiusMeters: halfRadius
            ),
        ]
    }

    static func sweep(
        boundingBox: VenueAreaSweepBoundingBox,
        cellRadiusMeters: Double,
        maxSubdivisionDepth: Int = VenueAreaSweep.maxSubdivisionDepth,
        searchNearby: NearbySearch,
        onProgress: ((VenueAreaSweepProgress) -> Void)? = nil
    ) async throws -> VenueAreaSweepResult {
        let topLevelCells = generateGrid(
            boundingBox: boundingBox,
            cellRadiusMeters: cellRadiusMeters
        )

        var allPlaces: [GooglePlace] = []
        var seenIDs = Set<String>()
        var saturatedCells: [VenueAreaSweepCell] = []
        var apiCallCount = 0
        var cellsCompleted = 0
        var totalCells = topLevelCells.count

        try await processCells(
            topLevelCells,
            depth: 0,
            maxSubdivisionDepth: maxSubdivisionDepth,
            searchNearby: searchNearby,
            allPlaces: &allPlaces,
            seenIDs: &seenIDs,
            saturatedCells: &saturatedCells,
            apiCallCount: &apiCallCount,
            cellsCompleted: &cellsCompleted,
            totalCells: &totalCells,
            onProgress: onProgress
        )

        return VenueAreaSweepResult(
            places: allPlaces,
            saturatedCells: saturatedCells,
            apiCallCount: apiCallCount
        )
    }

    private static let metersPerDegreeLatitude = 111_320.0

    private static func metersPerDegreeLongitude(at latitude: Double) -> Double {
        metersPerDegreeLatitude * cos(latitude * .pi / 180)
    }

    private static func processCells(
        _ cells: [VenueAreaSweepCell],
        depth: Int,
        maxSubdivisionDepth: Int,
        searchNearby: NearbySearch,
        allPlaces: inout [GooglePlace],
        seenIDs: inout Set<String>,
        saturatedCells: inout [VenueAreaSweepCell],
        apiCallCount: inout Int,
        cellsCompleted: inout Int,
        totalCells: inout Int,
        onProgress: ((VenueAreaSweepProgress) -> Void)?
    ) async throws {
        for cell in cells {
            if apiCallCount > 0 {
                try await Task.sleep(for: nearbyCallDelay)
            }

            let places = try await searchNearby(
                cell.latitude,
                cell.longitude,
                cell.radiusMeters
            )
            apiCallCount += 1

            for place in places where seenIDs.insert(place.id).inserted {
                allPlaces.append(place)
            }

            cellsCompleted += 1
            onProgress?(
                VenueAreaSweepProgress(
                    cellsCompleted: cellsCompleted,
                    totalCells: totalCells,
                    venuesFound: allPlaces.count,
                    saturatedCells: saturatedCells.count
                )
            )

            guard places.count >= nearbyResultCap else { continue }

            if depth < maxSubdivisionDepth {
                let subCells = subdivideCell(cell)
                totalCells += subCells.count
                try await processCells(
                    subCells,
                    depth: depth + 1,
                    maxSubdivisionDepth: maxSubdivisionDepth,
                    searchNearby: searchNearby,
                    allPlaces: &allPlaces,
                    seenIDs: &seenIDs,
                    saturatedCells: &saturatedCells,
                    apiCallCount: &apiCallCount,
                    cellsCompleted: &cellsCompleted,
                    totalCells: &totalCells,
                    onProgress: onProgress
                )
            } else {
                saturatedCells.append(cell)
                onProgress?(
                    VenueAreaSweepProgress(
                        cellsCompleted: cellsCompleted,
                        totalCells: totalCells,
                        venuesFound: allPlaces.count,
                        saturatedCells: saturatedCells.count
                    )
                )
            }
        }
    }
}
