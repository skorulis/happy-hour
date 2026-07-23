//Created by Alex Skorulis on 15/6/2026.

import ASKCoordinator
import Knit
import Foundation
import SwiftUI

enum MainPath: CoordinatorPath {
    
    case venueImport
    case suburbList
    case settings
    case stats
    case venueDetails(String)
    case suburbDetails(Int64)
    case regionDetails(Int64)
    case jobQueue
    case approval
    
    var id: String {
        switch self {
        case .venueImport: "venueImport"
        case .suburbList: "suburbList"
        case .settings: "settings"
        case .stats: "stats"
        case .venueDetails(let id): "venue-details-\(id)"
        case .suburbDetails(let id): "suburb-details-\(id)"
        case .regionDetails(let id): "region-details-\(id)"
        case .jobQueue: "job-queue"
        case .approval: "approval"
        }
    }
}

struct MainPathRenderer: CoordinatorPathRenderer {
    typealias PathType = MainPath
    
    let resolver: Resolver
    
    @MainActor @ViewBuilder
    func render(path: PathType, in coordinator: Coordinator) -> some View {
        switch path {
        case .venueImport:
            VenueImportView(viewModel: resolver.venueImportViewModel())
        case .suburbList:
            SuburbListView(viewModel: resolver.suburbListViewModel())
        case .settings:
            SettingsView(viewModel: coordinator.apply(resolver.settingsViewModel()))
        case .stats:
            StatsView(viewModel: resolver.statsViewModel())
        case let .venueDetails(id):
            VenueDetailsView(
                viewModel: coordinator.apply(resolver.venueDetailsViewModel(googleID: id)),
                onVenueDeleted: { coordinator.pop() }
            )
        case let .suburbDetails(id):
            SuburbDetailView(viewModel: coordinator.apply(resolver.suburbDetailViewModel(suburbId: id)))
        case let .regionDetails(id):
            GeographicRegionDetailView(
                viewModel: coordinator.apply(resolver.geographicRegionDetailViewModel(regionId: id))
            )
        case .jobQueue:
            JobQueueView(viewModel: coordinator.apply(resolver.jobQueueViewModel()))
        case .approval:
            ApprovalView(viewModel: coordinator.apply(resolver.approvalViewModel()))
        }
    }
}
