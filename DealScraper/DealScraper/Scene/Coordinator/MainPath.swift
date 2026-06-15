//Created by Alex Skorulis on 15/6/2026.

import ASKCoordinator
import Knit
import Foundation
import SwiftUI

enum MainPath: CoordinatorPath {
    
    case settings
    
    var id: String {
        switch self {
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
        case .settings:
            SettingsView(viewModel: resolver.settingsViewModel())
        }
    }
}
