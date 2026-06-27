//  Created by Alexander Skorulis on 14/6/2026.

import ASKCore
import ASKCoordinator
import SwiftUI
import Knit

struct ContentView: View {

    private enum Tab: Hashable {
        case imageImport
        case experiment
        case venues
        case jobs
        case approval
        case settings
    }

    @Environment(\.resolver) private var resolver
    @State private var selectedTab: Tab = .imageImport

    var body: some View {
        TabView(selection: $selectedTab) {
            ImageImportView(viewModel: resolver!.imageImportViewModel())
                .tabItem {
                    Label("Import", systemImage: "photo.on.rectangle.angled")
                }
                .tag(Tab.imageImport)

            ExperimentView(viewModel: resolver!.experimentViewModel())
                .tabItem {
                    Label("Experiment", systemImage: "flask")
                }
                .tag(Tab.experiment)

            CoordinatorView(coordinator: .init(root: MainPath.venueImport))
                .withRenderers(resolver: resolver!)
                .tabItem {
                    Label("Venues", systemImage: "mappin.and.ellipse")
                }
                .tag(Tab.venues)

            CoordinatorView(coordinator: .init(root: MainPath.jobQueue))
                .withRenderers(resolver: resolver!)
                .tabItem {
                    Label("Jobs", systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.jobs)

            CoordinatorView(coordinator: .init(root: MainPath.approval))
                .withRenderers(resolver: resolver!)
            .tabItem {
                Label("Approval", systemImage: "checkmark.seal")
            }
            .tag(Tab.approval)

            CoordinatorView(coordinator: .init(root: MainPath.settings))
                .withRenderers(resolver: resolver!)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView()
}
