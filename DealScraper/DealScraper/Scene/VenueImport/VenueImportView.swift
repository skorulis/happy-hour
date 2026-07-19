//Created by Alex Skorulis on 15/6/2026.

import ASKCoordinator
import ASKCore
import Knit
import SwiftUI

struct VenueImportView: View {

    @Environment(\.resolver) private var resolver
    @State var viewModel: VenueImportViewModel
    @State private var showGoogleImport = false
    @State private var showVenueHeros = false
    @State private var venueHerosViewModel: VenueHerosViewModel?

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
        .onChange(of: viewModel.selectedGoogleMapId) { _, newValue in
            if newValue != nil {
                showVenueHeros = false
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    findVenuesButton
                    heroImagesButton
                }
                loadErrorContent
            }
            .padding(16)

            Divider()

            searchField

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
            } else if viewModel.filteredVenues.isEmpty {
                ContentUnavailableView(
                    "No Matching Venues",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different name or address.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $viewModel.selectedGoogleMapId) {
                    ForEach(viewModel.filteredVenues, id: \.googleMapId) { venue in
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
        if showVenueHeros, let venueHerosViewModel {
            VenueHerosView(
                viewModel: venueHerosViewModel,
                onVenueSelected: { googleMapId in
                    viewModel.selectedGoogleMapId = googleMapId
                }
            )
        } else if let googleMapId = viewModel.selectedGoogleMapId {
            CoordinatorView(coordinator: .init(root: MainPath.venueDetails(googleMapId)))
                .withRenderers(resolver: resolver!)
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

    private var heroImagesButton: some View {
        Button("Hero Images") {
            viewModel.selectedGoogleMapId = nil
            if venueHerosViewModel == nil {
                venueHerosViewModel = resolver!.venueHerosViewModel()
            }
            showVenueHeros = true
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            TextField("Filter venues", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)

            Picker("Filter", selection: $viewModel.venueFilter) {
                ForEach(VenueImportViewModel.VenueFilter.allCases, id: \.self) { filter in
                    Text(filter.label).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var venueCountLabel: String {
        let total = viewModel.savedVenues.count
        let filtered = viewModel.filteredVenues.count
        let isFiltering = viewModel.venueFilter != .all
            || !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isFiltering {
            return "\(filtered) of \(total) venue\(total == 1 ? "" : "s")"
        }
        return "\(total) venue\(total == 1 ? "" : "s")"
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
