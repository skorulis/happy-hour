// Created by Alexander Skorulis on 19/7/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class SuburbListViewModel {

    enum State: Equatable {
        case idle
        case failed(message: String)
    }

    enum RegionFilter: Equatable, Hashable {
        case any
        case none
        case region(Int64)
    }

    private(set) var state: State = .idle
    private(set) var suburbs: [Suburb] = []
    private(set) var regions: [GeographicRegion] = []
    private(set) var venueCountsBySuburbId: [Int64: Int] = [:]
    var searchText = ""
    var selectedRegionFilter: RegionFilter = .any
    var selectedSuburbId: Int64?

    var filteredSuburbs: [Suburb] {
        var result = suburbs
        switch selectedRegionFilter {
        case .any:
            break
        case .none:
            result = result.filter { $0.regionId == nil }
        case .region(let regionId):
            result = result.filter { $0.regionId == regionId }
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return result }
        return result.filter { suburb in
            suburb.name.localizedCaseInsensitiveContains(query)
                || (suburb.postcode?.localizedCaseInsensitiveContains(query) ?? false)
                || (suburb.state?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private let suburbRepository: SuburbRepository
    private let venueRepository: VenueRepository
    private let geographicRegionRepository: GeographicRegionRepository

    @Resolvable<Resolver>
    init(
        suburbRepository: SuburbRepository,
        venueRepository: VenueRepository,
        geographicRegionRepository: GeographicRegionRepository
    ) {
        self.suburbRepository = suburbRepository
        self.venueRepository = venueRepository
        self.geographicRegionRepository = geographicRegionRepository
    }

    static func displayName(for suburb: Suburb) -> String {
        if let postcode = suburb.postcode, !postcode.isEmpty {
            return "\(suburb.name) \(postcode)"
        }
        return suburb.name
    }

    func venueCount(for suburb: Suburb) -> Int {
        guard let suburbId = suburb.id else { return 0 }
        return venueCountsBySuburbId[suburbId] ?? 0
    }

    func loadSuburbs() {
        do {
            regions = try geographicRegionRepository.all()
            let allSuburbs = try suburbRepository.all()
            venueCountsBySuburbId = try venueRepository.countsBySuburbId()
            suburbs = allSuburbs.sorted { lhs, rhs in
                let lhsCount = venueCount(for: lhs)
                let rhsCount = venueCount(for: rhs)
                if lhsCount != rhsCount {
                    return lhsCount > rhsCount
                }
                let nameOrder = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if nameOrder != .orderedSame {
                    return nameOrder == .orderedAscending
                }
                return (lhs.postcode ?? "") < (rhs.postcode ?? "")
            }
            if let selectedSuburbId,
               !suburbs.contains(where: { $0.id == selectedSuburbId })
            {
                self.selectedSuburbId = nil
            }
            state = .idle
        } catch {
            state = .failed(message: "Could not load suburbs: \(error.localizedDescription)")
        }
    }
}
