//  Created by Alexander Skorulis on 14/6/2026.

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

            VenueImportView(viewModel: resolver!.venueImportViewModel())
                .tabItem {
                    Label("Venues", systemImage: "mappin.and.ellipse")
                }

            SettingsView(viewModel: resolver!.settingsViewModel())
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
