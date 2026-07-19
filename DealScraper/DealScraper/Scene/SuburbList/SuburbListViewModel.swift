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
    var searchText = ""
    var selectedSuburbId: Int64?

    var filteredSuburbs: [Suburb] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return suburbs }
        return suburbs.filter { suburb in
            suburb.name.localizedCaseInsensitiveContains(query)
                || (suburb.postcode?.localizedCaseInsensitiveContains(query) ?? false)
                || (suburb.state?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private let suburbRepository: SuburbRepository

    @Resolvable<Resolver>
    init(suburbRepository: SuburbRepository) {
        self.suburbRepository = suburbRepository
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
            }
            state = .idle
        } catch {
            state = .failed(message: "Could not load suburbs: \(error.localizedDescription)")
        }
    }
}
