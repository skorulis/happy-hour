//Created by Alex Skorulis on 19/6/2026.

import ASKCore
import Knit
import SwiftUI

struct ApprovalView: View {

    @Environment(\.resolver) private var resolver
    @State var viewModel: ApprovalViewModel
    var onOpenInExperiment: () -> Void

    init(viewModel: ApprovalViewModel, onOpenInExperiment: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenInExperiment = onOpenInExperiment
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Type", selection: $viewModel.mode) {
                ForEach(ApprovalViewModel.Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(16)
            .onChange(of: viewModel.mode) {
                viewModel.onModeChanged()
            }

            Divider()

            Group {
                if viewModel.hasPendingItems {
                    reviewContent
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 720, minHeight: 560)
        .onAppear {
            viewModel.load()
        }
    }

    @ViewBuilder
    private func venueNameLabel(name: String, venueId: Int64) -> some View {
        if viewModel.googleMapId(for: venueId) != nil {
            Button(name) {
                viewModel.openVenueDetails(venueId: venueId)
            }
            .buttonStyle(.plain)
            .font(.headline)
            .help("View venue details")
        } else {
            Text(name)
                .font(.headline)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "All Caught Up",
            systemImage: "checkmark.seal",
            description: Text(emptyStateMessage)
        )
    }

    private var emptyStateMessage: String {
        switch viewModel.mode {
        case .sources:
            return "No deal sources are waiting for approval."
        case .deals:
            return "No deals are waiting for approval."
        }
    }

    @ViewBuilder
    private var reviewContent: some View {
        switch viewModel.mode {
        case .sources:
            sourceReviewContent
        case .deals:
            if let item = viewModel.currentDeal {
                EditDealView(
                    item: item,
                    venueName: viewModel.venueNames[item.deal.venueId] ?? "Unknown Venue",
                    remainingCount: viewModel.remainingCount,
                    onVenueTap: { viewModel.openVenueDetails(venueId: $0) }
                ) { status, draft in
                    viewModel.decideDeal(status: status, draft: draft)
                }
                .id(item.deal.id)
            }
        }
    }

    private var sourceReviewContent: some View {
        VStack(spacing: 0) {
            sourceHeader
                .padding(16)

            Divider()

            sourcePreviewSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            sourceActionBar
                .padding(24)
        }
    }

    @ViewBuilder
    private var sourceHeader: some View {
        if let source = viewModel.currentSource {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    venueNameLabel(
                        name: viewModel.venueNames[source.venueId] ?? "Unknown Venue",
                        venueId: source.venueId
                    )

                    Spacer()

                    Text("\(viewModel.remainingCount) remaining")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    Label(source.type.rawValue.capitalized, systemImage: typeIcon(for: source.type))
                    Text(source.date.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let url = URL(string: source.sourceURL) {
                    Link(url.absoluteString, destination: url)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var sourcePreviewSection: some View {
        switch viewModel.previewState {
        case .idle, .loading:
            ProgressView("Loading preview…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .ready(content):
            DealSourcePreviewView(content: content)
                .padding(8)

        case let .failed(message):
            VStack(spacing: 12) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)

                if let source = viewModel.currentSource,
                   let url = URL(string: source.sourceURL) {
                    Link("Open source in browser", destination: url)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sourceActionBar: some View {
        HStack(spacing: 32) {
            statusButton(
                systemImage: "flask",
                color: .accentColor,
                action: {
                    viewModel.sendToExperiment()
                    onOpenInExperiment()
                }
            )
            .disabled(viewModel.currentSourceURL == nil)

            statusButton(
                systemImage: "checkmark",
                color: .green,
                action: { viewModel.decide(status: .approved) }
            )

            statusButton(
                systemImage: "xmark",
                color: .red,
                action: { viewModel.decide(status: .rejected) }
            )
        }
        .frame(maxWidth: .infinity)
        .disabled(viewModel.previewState == .loading)
    }

    private func statusButton(
        systemImage: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background {
                    Circle()
                        .fill(.clear)
                }
                .overlay {
                    Circle()
                        .strokeBorder(color, lineWidth: 2)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func typeIcon(for type: DealSourceType) -> String {
        switch type {
        case .image:
            return "photo"
        case .webpage:
            return "globe"
        case .pdf:
            return "doc.fill"
        }
    }
}

#Preview {
    ApprovalView(viewModel: DealScraperAssembly.testing().resolver.approvalViewModel())
}
