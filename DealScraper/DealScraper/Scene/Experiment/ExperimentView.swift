//Created by Alex Skorulis on 15/6/2026.

import Knit
import SwiftUI

struct ExperimentView: View {

    @State var viewModel: ExperimentViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                controls
                status
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 480, minHeight: 300)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content Block Extraction")
                .font(.headline)

            TextField("URL", text: $viewModel.urlString)
                .textFieldStyle(.roundedBorder)

            Button("Load & Extract") {
                viewModel.loadAndExtract()
            }
            .disabled(isLoading)
        }
    }

    @ViewBuilder
    private var status: some View {
        switch viewModel.state {
        case .idle:
            Text("Enter a URL and press Load & Extract. Results are printed to the Xcode console.")
                .foregroundStyle(.secondary)

        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading page and extracting content blocks…")
            }

        case let .completed(blockCount):
            Label(
                "Extracted \(blockCount) block\(blockCount == 1 ? "" : "s"). See Xcode console for output.",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)

        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
}

#Preview {
    ExperimentView(viewModel: DealScraperAssembly.testing().resolver.experimentViewModel())
}
