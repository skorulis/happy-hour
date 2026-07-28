// Created by Alexander Skorulis on 28/7/2026.

import Foundation
import Knit
import KnitMacros

enum NearbyRadiusAutoTunerReason: Equatable, Sendable {
    case missingCoordinates
    case noVenuesWithinMax
    case missingSuburbId
}

enum NearbyRadiusTuneResult: Equatable, Sendable {
    /// Absolute override written because the default area radius found nothing.
    case set(km: Double)
    /// Default area radius already finds nearby venues; field left blank.
    case cleared
    case unchanged(NearbyRadiusAutoTunerReason)
}

struct NearbyRadiusTuneSummary: Equatable, Sendable {
    var setCount: Int = 0
    var clearedCount: Int = 0
    var missingCoordinatesCount: Int = 0
    var noneFoundCount: Int = 0
    var missingSuburbIdCount: Int = 0

    var totalProcessed: Int {
        setCount
            + clearedCount
            + missingCoordinatesCount
            + noneFoundCount
            + missingSuburbIdCount
    }
}

final class NearbyRadiusAutoTuner {

    /// Matches web `NEARBY_SUBURB_BUFFER_KM`.
    static let defaultBufferKm: Double = 0.5

    /// Fixed probe ladder (km). First rung ≥ min distance to a nearby venue is stored
    /// when the default area radius is insufficient.
    static let ladderKm: [Double] = [2, 5, 10, 15, 20, 25, 35, 50, 75, 100]

    static var maxLadderKm: Double { ladderKm.last ?? 100 }

    private let venueRepository: VenueRepository
    private let suburbRepository: SuburbRepository

    @Resolvable<Resolver>
    init(
        venueRepository: VenueRepository,
        suburbRepository: SuburbRepository
    ) {
        self.venueRepository = venueRepository
        self.suburbRepository = suburbRepository
    }

    /// Area-based default radius: √(sqkm / π) + buffer (same as web when override is nil).
    static func defaultRadiusKm(sqkm: Double?) -> Double {
        let areaSqkm = (sqkm ?? 0) > 0 ? (sqkm ?? 0) : 0
        return sqrt(areaSqkm / .pi) + defaultBufferKm
    }

    /// First ladder value ≥ `distanceKm`, or nil if beyond the ladder.
    static func snapToLadder(distanceKm: Double) -> Double? {
        ladderKm.first { $0 >= distanceKm }
    }

    @discardableResult
    func tune(suburb: Suburb) throws -> NearbyRadiusTuneResult {
        guard let suburbId = suburb.id else {
            return .unchanged(.missingSuburbId)
        }
        guard let lat = suburb.lat, let lng = suburb.lng else {
            return .unchanged(.missingCoordinates)
        }

        let defaultRadius = Self.defaultRadiusKm(sqkm: suburb.sqkm)

        guard let minDistance = try venueRepository.minimumDistanceKm(
            fromLat: lat,
            lng: lng,
            excludingSuburbId: suburbId,
            maxKm: Self.maxLadderKm
        ) else {
            return .unchanged(.noVenuesWithinMax)
        }

        // Default formula already reaches a nearby venue — keep override blank.
        if minDistance <= defaultRadius {
            try suburbRepository.updateNearbyRadiusKm(
                suburbId: suburbId,
                nearbyRadiusKm: nil
            )
            return .cleared
        }

        guard let radiusKm = Self.snapToLadder(distanceKm: minDistance) else {
            return .unchanged(.noVenuesWithinMax)
        }

        try suburbRepository.updateNearbyRadiusKm(
            suburbId: suburbId,
            nearbyRadiusKm: radiusKm
        )
        return .set(km: radiusKm)
    }

    func tuneAll(suburbs: [Suburb]) throws -> NearbyRadiusTuneSummary {
        var summary = NearbyRadiusTuneSummary()
        for suburb in suburbs {
            switch try tune(suburb: suburb) {
            case .set:
                summary.setCount += 1
            case .cleared:
                summary.clearedCount += 1
            case .unchanged(.missingCoordinates):
                summary.missingCoordinatesCount += 1
            case .unchanged(.noVenuesWithinMax):
                summary.noneFoundCount += 1
            case .unchanged(.missingSuburbId):
                summary.missingSuburbIdCount += 1
            }
        }
        return summary
    }
}
