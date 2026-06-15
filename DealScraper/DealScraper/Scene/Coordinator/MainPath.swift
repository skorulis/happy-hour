//Created by Alex Skorulis on 15/6/2026.

import ASKCoordinator
import Knit
import Foundation
import SwiftUI

enum MainPath: CoordinatorPath {
    
    case venueImport
    case settings
    
    var id: String {
        switch self {
        case .venueImport: "venueImport"
        case .settings: "settings"
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
        case .settings:
            SettingsView(viewModel: resolver.settingsViewModel())
        }
    }
}
