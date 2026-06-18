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
                results
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 480, minHeight: 300)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Page Extraction")
                .font(.headline)

            TextField("URL", text: $viewModel.urlString)
                .textFieldStyle(.roundedBorder)

            Button("Load page") {
                viewModel.loadPage()
            }
            .disabled(isLoading)
        }
    }

    @ViewBuilder
    private var status: some View {
        switch viewModel.state {
        case .idle:
            Text("Enter a URL and tap Load page.")
                .foregroundStyle(.secondary)

        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading page…")
            }

        case .loaded:
            EmptyView()

        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var results: some View {
        if case let .loaded(page) = viewModel.state {
            linksSection(page.links)
            imagesSection(page)
            dealContentBlocksSection(page.dealContentBlocks)
        }
    }

    private func linksSection(_ links: [ContentBlockLink]) -> some View {
        detailSection(title: "Links (\(links.count))") {
            if links.isEmpty {
                Text("No links found.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(links.enumerated()), id: \.offset) { _, link in
                    VStack(alignment: .leading, spacing: 2) {
                        Link(link.text ?? link.url.absoluteString, destination: link.url)
                        Text(link.url.absoluteString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func imagesSection(_ page: LoadedPage) -> some View {
        let imageCount = page.imageURLs.count

        return detailSection(title: "Images (\(imageCount))") {
            Text("\(imageCount) image\(imageCount == 1 ? "" : "s") on page.")
                .foregroundStyle(.secondary)

            Button("Process images") {
                viewModel.processImages()
            }
            .disabled(viewModel.isProcessingImages || imageCount == 0)

            if viewModel.isProcessingImages {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Processing images…")
                }
            }

            if let validatedImages = viewModel.validatedImages {
                if validatedImages.isEmpty {
                    Text("No valid images found.")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 12) {
                            ForEach(Array(validatedImages.enumerated()), id: \.offset) { _, result in
                                validatedImageThumbnail(result)
                            }
                        }
                    }
                }
            }
        }
    }

    private func validatedImageThumbnail(_ result: ImageValidationResult) -> some View {
        Link(destination: result.url) {
            AsyncImage(url: result.url) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .overlay { ProgressView() }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 200, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help("Open image in browser")
    }

    private func dealContentBlocksSection(_ blocks: [ContentBlock]) -> some View {
        detailSection(title: "Deal Content Blocks (\(blocks.count))") {
            if blocks.isEmpty {
                Text("No deal content blocks found.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = block.title {
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                        }

                        if !block.text.isEmpty {
                            Text(block.text)
                                .font(.body)
                        }

                        if !block.links.isEmpty {
                            ForEach(Array(block.links.enumerated()), id: \.offset) { _, link in
                                Link(link.text ?? link.url.absoluteString, destination: link.url)
                                    .font(.caption)
                            }
                        }

                        if index < blocks.count - 1 {
                            Divider()
                                .padding(.top, 4)
                        }
                    }
                }
            }
        }
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

    private var isLoading: Bool {
        if case .loading = viewModel.state {
            return true
        }
        return false
    }
}

#Preview {
    ExperimentView(viewModel: DealScraperAssembly.testing().resolver.experimentViewModel())
}
