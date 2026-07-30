//Created by Alex Skorulis on 30/7/2026.

import SwiftUI

struct VenueDetailsAboutView: View {

    @Bindable var viewModel: VenueDetailsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            featuresSection
            aboutSection
        }
    }

    private var aboutSection: some View {
        detailSection(title: "About") {
            TextEditor(text: $viewModel.blurbText)
                .frame(minHeight: 100)
                .font(.body)
                .disabled(viewModel.generateBlurbState == .generating)

            HStack {
                Button("Save") {
                    viewModel.saveBlurb()
                }
                .disabled(!viewModel.canSaveBlurb)

                Button("Generate Blurb") {
                    Task {
                        await viewModel.generateBlurb()
                    }
                }
                .disabled(!viewModel.canGenerateBlurb)

                Button("Fetch Places Summaries") {
                    Task {
                        await viewModel.fetchPlacesSummaries()
                    }
                }
                .disabled(!viewModel.canFetchPlacesSummaries)
            }

            switch viewModel.saveBlurbState {
            case .idle:
                EmptyView()
            case .completed:
                Text("Blurb saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case let .failed(message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            switch viewModel.generateBlurbState {
            case .idle:
                EmptyView()
            case .generating:
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case let .failed(message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            switch viewModel.fetchPlacesSummariesState {
            case .idle:
                EmptyView()
            case .fetching:
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Fetching Places summaries…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case let .failed(message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if viewModel.hasFetchedPlacesSummaries {
                placesSummariesSection
            }

            if viewModel.suburbName == nil {
                Text("Suburb could not be determined from the venue address.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isPlacesAPIKeyMissing {
                Text("Add a Google Places API key in Settings to fetch summaries.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var featuresSection: some View {
        detailSection(title: "Features") {
            if viewModel.availableFeatures.isEmpty {
                Text("No features defined in features.json.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.availableFeatures, id: \.self) { feature in
                    Toggle(
                        feature,
                        isOn: Binding(
                            get: { viewModel.isFeatureSelected(feature) },
                            set: { viewModel.setFeatureSelected(feature, isSelected: $0) }
                        )
                    )
                }

                Button("Save") {
                    viewModel.saveFeatures()
                }
                .disabled(!viewModel.canSaveFeatures)

                switch viewModel.saveFeaturesState {
                case .idle:
                    EmptyView()
                case .completed:
                    Text("Features saved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case let .failed(message):
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    @ViewBuilder
    private var placesSummariesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            placesSummaryBlock(
                title: "Editorial summary",
                text: viewModel.fetchedEditorialSummary,
                emptyMessage: "No editorial summary returned."
            )
            placesSummaryBlock(
                title: "Review summary",
                text: viewModel.fetchedReviewSummary,
                emptyMessage: "No review summary returned. Google only offers these in select regions (AU is not included)."
            )
            placesSummaryBlock(
                title: "Generative summary",
                text: viewModel.fetchedGenerativeSummary,
                emptyMessage: "No generative summary returned."
            )
        }
        .padding(.top, 4)
    }

    private func placesSummaryBlock(title: String, text: String?, emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if trimmed.isEmpty {
                Text(emptyMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(trimmed)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
        }
    }
}
