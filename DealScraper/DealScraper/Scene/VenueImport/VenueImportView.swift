//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Knit
import SwiftUI

struct VenueImportView: View {

    @Environment(\.resolver) private var resolver
    @State var viewModel: VenueImportViewModel
    @State private var showGoogleImport = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(minWidth: 720, minHeight: 400)
        .onAppear {
            viewModel.loadSavedVenues()
        }
        .sheet(isPresented: $showGoogleImport, onDismiss: {
            viewModel.loadSavedVenues()
        }) {
            GoogleImportView(viewModel: resolver!.googleImportViewModel())
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                findVenuesButton
                loadErrorContent
            }
            .padding(16)

            Divider()

            Text(venueCountLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            if viewModel.savedVenues.isEmpty {
                ContentUnavailableView(
                    "No Saved Venues",
                    systemImage: "building.2",
                    description: Text("Search Google Places to add venues.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $viewModel.selectedGoogleMapId) {
                    ForEach(viewModel.savedVenues, id: \.googleMapId) { venue in
                        VenueRow(
                            venue: venue,
                            sourceCount: viewModel.sourceCount(for: venue),
                            dealCount: viewModel.dealCount(for: venue)
                        )
                        .tag(venue.googleMapId)
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .navigationSplitViewColumnWidth(min: 280, ideal: 320)
    }

    @ViewBuilder
    private var detail: some View {
        if let googleMapId = viewModel.selectedGoogleMapId {
            VenueDetailsView(
                viewModel: resolver!.venueDetailsViewModel(googleID: googleMapId)
            )
            .id(googleMapId)
        } else {
            ContentUnavailableView(
                "Select a Venue",
                systemImage: "building.2",
                description: Text("Choose a venue from the list to view its details.")
            )
        }
    }

    private var findVenuesButton: some View {
        Button("Find Venues") {
            showGoogleImport = true
        }
    }

    private var venueCountLabel: String {
        let count = viewModel.savedVenues.count
        return "\(count) venue\(count == 1 ? "" : "s")"
    }

    @ViewBuilder
    private var loadErrorContent: some View {
        if case let .failed(message) = viewModel.state {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    VenueImportView(viewModel: assembler.resolver.venueImportViewModel())
}
