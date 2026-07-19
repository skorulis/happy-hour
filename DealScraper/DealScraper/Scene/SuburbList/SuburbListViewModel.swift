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

    private(set) var state: State = .idle
    private(set) var suburbs: [Suburb] = []
    private(set) var venues: [Venue] = []
    private(set) var selectedCountryName: String?
    var searchText = ""
    var actionMessage: String?

    var selectedSuburbId: Int64? {
        didSet {
            guard selectedSuburbId != oldValue else { return }
            loadSelectionDetails()
        }
    }

    var filteredSuburbs: [Suburb] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return suburbs }
        return suburbs.filter { suburb in
            suburb.name.localizedCaseInsensitiveContains(query)
                || (suburb.postcode?.localizedCaseInsensitiveContains(query) ?? false)
                || (suburb.state?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var selectedSuburb: Suburb? {
        guard let selectedSuburbId else { return nil }
        return suburbs.first { $0.id == selectedSuburbId }
    }

    private let suburbRepository: SuburbRepository
    private let venueRepository: VenueRepository
    private let countryRepository: CountryRepository
    private let jobQueue: JobQueue

    @Resolvable<Resolver>
    init(
        suburbRepository: SuburbRepository,
        venueRepository: VenueRepository,
        countryRepository: CountryRepository,
        jobQueue: JobQueue
    ) {
        self.suburbRepository = suburbRepository
        self.venueRepository = venueRepository
        self.countryRepository = countryRepository
        self.jobQueue = jobQueue
    }

    static func displayName(for suburb: Suburb) -> String {
        if let postcode = suburb.postcode, !postcode.isEmpty {
            return "\(suburb.name) \(postcode)"
        }
        return suburb.name
    }

    func loadSuburbs() {
        do {
            suburbs = try suburbRepository.all().sorted { lhs, rhs in
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
            } else {
                loadSelectionDetails()
            }
            state = .idle
        } catch {
            state = .failed(message: "Could not load suburbs: \(error.localizedDescription)")
        }
    }

    func crawlSelectedSuburb() {
        guard let suburbId = selectedSuburbId,
              let suburb = selectedSuburb
        else {
            actionMessage = "Select a suburb to crawl."
            return
        }

        let name = Self.displayName(for: suburb)
        guard jobQueue.enqueue(suburbId: suburbId, type: .crawlSuburb) != nil else {
            actionMessage = "A suburb crawl is already queued for \(name)."
            return
        }

        actionMessage = "Queued suburb crawl for \(name)."
    }

    private func loadSelectionDetails() {
        guard let selectedSuburbId, let suburb = selectedSuburb else {
            venues = []
            selectedCountryName = nil
            return
        }
        do {
            venues = try venueRepository.find(suburbId: selectedSuburbId)
            if let countryId = suburb.countryId {
                selectedCountryName = try countryRepository.find(id: countryId)?.name
            } else {
                selectedCountryName = nil
            }
        } catch {
            venues = []
            selectedCountryName = nil
            state = .failed(message: "Could not load suburb details: \(error.localizedDescription)")
        }
    }
}
