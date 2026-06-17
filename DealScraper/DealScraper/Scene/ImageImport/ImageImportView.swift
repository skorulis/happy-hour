//Created by Alex Skorulis on 15/6/2026.

import Knit
import SwiftUI

struct ImageImportView: View {

    @State var viewModel: ImageImportViewModel
    @State private var isDropTargeted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                processingControls
                sourceInput
                content
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 480, minHeight: 400)
    }

    private var processingControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Provider", selection: $viewModel.extractionProvider) {
                ForEach(VenueDealExtractionProvider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.extractionProvider) {
                viewModel.reset()
            }

            if viewModel.extractionProvider == .openAI {
                TextField("OpenAI model", text: $viewModel.openAIModel)
                    .textFieldStyle(.roundedBorder)
            } else if viewModel.extractionProvider == .openRouter {
                TextField("OpenRouter model", text: $viewModel.openRouterModel)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    @ViewBuilder
    private var sourceInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Source", selection: $viewModel.inputMode) {
                ForEach(ImageImportViewModel.InputMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.inputMode) {
                viewModel.reset()
            }

            switch viewModel.inputMode {
            case .image:
                dropZone
            case .url:
                urlInput
            }
        }
    }

    private var dropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Drop an image to extract deals")
                .font(.headline)

            Text("JPEG, PNG, HEIC, and other image formats")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 2 : 1, dash: [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
                )
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            viewModel.processDroppedImage(at: url)
            return true
        } isTargeted: { isDropTargeted = $0 }
    }

    private var urlInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("https://example.com/deals", text: $viewModel.sourceURLString)
                .textFieldStyle(.roundedBorder)

            Button("Extract Deals") {
                viewModel.processURL()
            }
            .disabled(viewModel.sourceURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()

        case let .processing(progress):
            HStack(spacing: 12) {
                ProgressView()
                Text(progress)
                    .foregroundStyle(.secondary)
            }

        case let .completed(deals, sourceURL):
            completedContent(deals: deals, sourceURL: sourceURL)

        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private func completedContent(deals: [DealWithSchedules], sourceURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            sourcePreview(for: sourceURL)

            if deals.isEmpty {
                Text("No deals were found in this source.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(deals.count) deal\(deals.count == 1 ? "" : "s") found")
                        .font(.headline)

                    ForEach(Array(deals.enumerated()), id: \.offset) { _, item in
                        DealRow(item: item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sourcePreview(for url: URL) -> some View {
        if url.isFileURL, let preview = localImagePreview(for: url) {
            preview
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 240)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if VenueDealSourceMaterialPreparer.isImageURL(url) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(maxHeight: 240)
                        .overlay { ProgressView() }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    sourceLink(for: url)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            sourceLink(for: url)
        }
    }

    private func sourceLink(for url: URL) -> some View {
        Link(url.absoluteString, destination: url)
            .font(.subheadline)
            .lineLimit(2)
    }

    private func localImagePreview(for url: URL) -> Image? {
        guard let nsImage = NSImage(contentsOf: url) else { return nil }
        return Image(nsImage: nsImage)
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    ImageImportView(viewModel: assembler.resolver.imageImportViewModel())
}
