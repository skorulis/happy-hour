//Created by Alex Skorulis on 22/6/2026.

import ASKCore
import Knit
import SwiftUI

// Coverage tips for dense areas:
// - Text search caps at 60 venues (3 pages). If you see exactly 60, subdivide by suburb.
// - Nearby search caps at 20 venues per circle. Use a smaller radius or Area mode.
// - Area mode grids many small nearby searches and subdivides saturated cells automatically.

struct GoogleImportView: View {

    @Environment(\.dismiss) private var dismiss
    @State var viewModel: GoogleImportViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                searchControls
                searchButton
                statusContent
                Spacer()
            }
            .padding(16)
            .navigationTitle("Find Venues")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
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
                coverageHelpText(
                    """
                    Text search returns at most 60 venues. If you hit 60, run narrower queries \
                    (e.g. "pubs in Surry Hills" instead of "pubs in Sydney").
                    """
                )
            case .nearby:
                TextField("Latitude", text: $viewModel.latitude)
                    .textFieldStyle(.roundedBorder)
                TextField("Longitude", text: $viewModel.longitude)
                    .textFieldStyle(.roundedBorder)
                TextField("Radius (meters)", text: $viewModel.radiusMeters)
                    .textFieldStyle(.roundedBorder)
                coverageHelpText(
                    """
                    Nearby search returns at most 20 venues per circle. In dense areas use \
                    400–500 m radius and repeat on a grid, or use Area mode.
                    """
                )
            case .area:
                TextField("SW latitude", text: $viewModel.southWestLatitude)
                    .textFieldStyle(.roundedBorder)
                TextField("SW longitude", text: $viewModel.southWestLongitude)
                    .textFieldStyle(.roundedBorder)
                TextField("NE latitude", text: $viewModel.northEastLatitude)
                    .textFieldStyle(.roundedBorder)
                TextField("NE longitude", text: $viewModel.northEastLongitude)
                    .textFieldStyle(.roundedBorder)
                TextField("Cell radius (meters)", text: $viewModel.cellRadiusMeters)
                    .textFieldStyle(.roundedBorder)
                if viewModel.estimatedAreaCellCount > 0 {
                    Text("Estimated \(viewModel.estimatedAreaCellCount) API calls (more if cells saturate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                coverageHelpText(
                    """
                    Sweeps a grid of nearby searches across the bounding box. Saturated cells \
                    subdivide automatically; any remaining saturated cells are reported at the end.
                    """
                )
            }
        }
    }

    private func coverageHelpText(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var searchButton: some View {
        Button("Search and Save") {
            viewModel.search()
        }
        .disabled(isSearching)
    }

    private var isSearching: Bool {
        switch viewModel.state {
        case .searching, .sweeping:
            return true
        case .idle, .completed, .failed:
            return false
        }
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

        case let .sweeping(progress):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Sweeping area…")
                        .foregroundStyle(.secondary)
                }
                Text(
                    "Cell \(progress.cellsCompleted)/\(progress.totalCells) · " +
                        "\(progress.venuesFound) venues · " +
                        "\(progress.saturatedCells) saturated"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

        case let .completed(totalCount, newCount, saturatedCellCount, apiCallCount):
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    completionMessage(totalCount: totalCount, newCount: newCount),
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.green)

                if apiCallCount > 0 {
                    Text("\(apiCallCount) API calls")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if saturatedCellCount > 0 {
                    Label(
                        "\(saturatedCellCount) cell\(saturatedCellCount == 1 ? "" : "s") still saturated — try a smaller cell radius",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }

        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private func completionMessage(totalCount: Int, newCount: Int) -> String {
        let venueLabel = "\(totalCount) venue\(totalCount == 1 ? "" : "s")"
        let newLabel = "\(newCount) new"
        return "Found \(venueLabel), \(newLabel)"
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    GoogleImportView(viewModel: assembler.resolver.googleImportViewModel())
}
