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
    case set(km: Double)
    case unchanged(NearbyRadiusAutoTunerReason)
}

struct NearbyRadiusTuneSummary: Equatable, Sendable {
    var setCount: Int = 0
    var missingCoordinatesCount: Int = 0
    var noneFoundCount: Int = 0
    var missingSuburbIdCount: Int = 0

    var totalProcessed: Int {
        setCount + missingCoordinatesCount + noneFoundCount + missingSuburbIdCount
    }
}

final class NearbyRadiusAutoTuner {

    /// Fixed probe ladder (km). First rung ≥ min distance to a nearby venue is stored.
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

        guard let minDistance = try venueRepository.minimumDistanceKm(
            fromLat: lat,
            lng: lng,
            excludingSuburbId: suburbId,
            maxKm: Self.maxLadderKm
        ),
        let radiusKm = Self.snapToLadder(distanceKm: minDistance)
        else {
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
