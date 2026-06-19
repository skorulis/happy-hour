//Created by Alex Skorulis on 19/6/2026.

import Knit
import SwiftUI

struct ApprovalView: View {

    @State var viewModel: ApprovalViewModel

    var body: some View {
        Group {
            if viewModel.currentSource == nil {
                ContentUnavailableView(
                    "All Caught Up",
                    systemImage: "checkmark.seal",
                    description: Text("No deal sources are waiting for approval.")
                )
            } else {
                reviewContent
            }
        }
        .frame(minWidth: 720, minHeight: 560)
        .onAppear {
            viewModel.load()
        }
    }

    private var reviewContent: some View {
        VStack(spacing: 0) {
            header
                .padding(16)

            Divider()

            previewSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            actionBar
                .padding(24)
        }
    }

    @ViewBuilder
    private var header: some View {
        if let source = viewModel.currentSource {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(viewModel.venueNames[source.venueId] ?? "Unknown Venue")
                        .font(.headline)

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
    private var previewSection: some View {
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

    private var actionBar: some View {
        HStack(spacing: 32) {
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
        .disabled(viewModel.previewState == .loading)
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
