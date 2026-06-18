//Created by Alex Skorulis on 15/6/2026.

import Knit
import SwiftUI

struct VenueImportView: View {

    @Environment(\.resolver) private var resolver
    @State var viewModel: VenueImportViewModel

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
        .onChange(of: viewModel.searchMode) {
            viewModel.reset()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                searchControls
                searchButton
                statusContent
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
                        VenueRow(venue: venue)
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

    private var searchControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Search", selection: $viewModel.searchMode) {
                ForEach(VenueSearchMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            switch viewModel.searchMode {
            case .text:
                TextField("Search query", text: $viewModel.textQuery)
                    .textFieldStyle(.roundedBorder)
                TextField("Region code (optional)", text: $viewModel.regionCode)
                    .textFieldStyle(.roundedBorder)
            case .nearby:
                TextField("Latitude", text: $viewModel.latitude)
                    .textFieldStyle(.roundedBorder)
                TextField("Longitude", text: $viewModel.longitude)
                    .textFieldStyle(.roundedBorder)
                TextField("Radius (meters)", text: $viewModel.radiusMeters)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var searchButton: some View {
        Button("Search and Save") {
            viewModel.search()
        }
        .disabled(viewModel.state == .searching)
    }

    private var venueCountLabel: String {
        let count = viewModel.savedVenues.count
        return "\(count) venue\(count == 1 ? "" : "s")"
    }

    @ViewBuilder
    private var statusContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()

        case .searching:
            HStack(spacing: 12) {
                ProgressView()
                Text("Searching Google Places…")
                    .foregroundStyle(.secondary)
            }

        case let .completed(importedCount):
            Label(
                "Saved \(importedCount) venue\(importedCount == 1 ? "" : "s")",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)

        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    VenueImportView(viewModel: assembler.resolver.venueImportViewModel())
}
