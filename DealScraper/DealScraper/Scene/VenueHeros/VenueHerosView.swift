//Created by Alex Skorulis on 15/7/2026.

import ASKCore
import AppKit
import Knit
import SwiftUI

struct VenueHerosView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.resolver) private var resolver
    @State var viewModel: VenueHerosViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                controls
                Divider()
                content
            }
            .navigationTitle("Hero Images")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .onAppear {
            viewModel.load()
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button("Process Images") {
                Task {
                    await viewModel.processImages()
                }
            }
            .disabled(viewModel.isProcessing || viewModel.missingR2Count == 0)

            statusLabel

            Spacer()

            Text("\(viewModel.venues.count) with hero · \(viewModel.missingR2Count) missing R2")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch viewModel.state {
        case .processing(let completed, let total):
            ProgressView(value: Double(completed), total: Double(max(total, 1)))
                .frame(width: 120)
            Text("\(completed)/\(total)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        case .loading:
            ProgressView()
                .controlSize(.small)
        case .idle:
            if let summary = viewModel.lastProcessSummary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.venues.isEmpty {
            ContentUnavailableView(
                "No Hero Images",
                systemImage: "photo",
                description: Text("Venues with a hero image source will appear here.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.venues, id: \.googleMapId) { venue in
                        NavigationLink {
                            VenueDetailsView(
                                viewModel: resolver!.venueDetailsViewModel(googleID: venue.googleMapId),
                                onVenueDeleted: {
                                    viewModel.load()
                                }
                            )
                        } label: {
                            heroCell(venue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .onAppear {
                    viewModel.load()
                }

                if !viewModel.processFailures.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Failures")
                            .font(.headline)
                        ForEach(Array(viewModel.processFailures.enumerated()), id: \.offset) { _, failure in
                            Text("\(failure.name): \(failure.message)")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private func heroCell(_ venue: Venue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            heroThumbnail(venue)
                .frame(maxWidth: .infinity)
                .aspectRatio(3 / 2, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .background(Color(nsColor: .controlBackgroundColor))

            Text(venue.name)
                .font(.caption)
                .lineLimit(2)

            Label(
                hasR2(venue) ? "Uploaded" : "Missing R2",
                systemImage: hasR2(venue) ? "checkmark.circle.fill" : "exclamationmark.circle"
            )
            .font(.caption2)
            .foregroundStyle(hasR2(venue) ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))
        }
    }

    @ViewBuilder
    private func heroThumbnail(_ venue: Venue) -> some View {
        if let source = venue.heroImage, let url = URL(string: source) {
            if url.isFileURL {
                localImage(url)
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholder
                    }
                }
            }
        } else {
            placeholder
        }
    }

    @ViewBuilder
    private func localImage(_ url: URL) -> some View {
        if let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func hasR2(_ venue: Venue) -> Bool {
        guard let r2 = venue.heroR2Url else { return false }
        return !r2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    VenueHerosView(viewModel: assembler.resolver.venueHerosViewModel())
}
