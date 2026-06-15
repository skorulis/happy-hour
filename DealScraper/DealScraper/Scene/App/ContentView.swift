//  Created by Alexander Skorulis on 14/6/2026.

import ASKCoordinator
import SwiftUI
import Knit

struct ContentView: View {
    
    @Environment(\.resolver) private var resolver
    
    var body: some View {
        TabView {
            ImageImportView(viewModel: resolver!.imageImportViewModel())
                .tabItem {
                    Label("Import", systemImage: "photo.on.rectangle.angled")
                }

            ExperimentView(viewModel: resolver!.experimentViewModel())
                .tabItem {
                    Label("Experiment", systemImage: "flask")
                }
            
            CoordinatorView(coordinator: .init(root: MainPath.venueImport))
                .withRenderers(resolver: resolver!)
                .tabItem {
                    Label("Venues", systemImage: "mappin.and.ellipse")
                }
            
            CoordinatorView(coordinator: .init(root: MainPath.settings))
                .withRenderers(resolver: resolver!)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
