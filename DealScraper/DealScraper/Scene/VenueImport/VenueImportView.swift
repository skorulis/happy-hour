//Created by Alex Skorulis on 15/6/2026.

import Knit
import SwiftUI

struct VenueImportView: View {

    @State var viewModel: VenueImportViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                searchControls
                searchButton
                statusContent
                savedVenuesSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 480, minHeight: 400)
        .onAppear {
            viewModel.loadSavedVenues()
        }
        .onChange(of: viewModel.searchMode) {
            viewModel.reset()
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

    @ViewBuilder
    private var savedVenuesSection: some View {
        if !viewModel.savedVenues.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Saved Venues")
                    .font(.headline)

                ForEach(viewModel.savedVenues, id: \.googleMapId) { venue in
                    VenueRow(venue: venue)
                }
            }
        }
    }
}

private struct VenueRow: View {
    let venue: Venue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(venue.name)
                .font(.body.weight(.semibold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
    }

    private var subtitle: String {
        if let address = formattedAddress(from: venue.json) {
            return address
        }
        return String(format: "%.4f, %.4f", venue.lat, venue.lng)
    }

    private func formattedAddress(from json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let place = try? JSONDecoder().decode(GooglePlace.self, from: data)
        else {
            return nil
        }
        return place.formattedAddress
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    VenueImportView(viewModel: assembler.resolver.venueImportViewModel())
}
