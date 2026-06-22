//Created by Alex Skorulis on 22/6/2026.

import ASKCore
import Knit
import SwiftUI

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

        case let .completed(totalCount, newCount):
            Label(
                completionMessage(totalCount: totalCount, newCount: newCount),
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)

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
