//Created by Alex Skorulis on 15/6/2026.

import Knit
import SwiftUI
import UniformTypeIdentifiers

struct ImageImportView: View {

    @State var viewModel: ImageImportViewModel
    @State private var isDropTargeted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                processingControls
                dropZone
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

            if viewModel.extractionProvider == .cursor {
                TextField("Cursor model", text: $viewModel.cursorModel)
                    .textFieldStyle(.roundedBorder)
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

        case let .completed(deals, imageURL):
            completedContent(deals: deals, imageURL: imageURL)

        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private func completedContent(deals: [DealWithSchedules], imageURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            if let preview = imagePreview(for: imageURL) {
                preview
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if deals.isEmpty {
                Text("No deals were found in this image.")
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

    private func imagePreview(for url: URL) -> Image? {
        guard let nsImage = NSImage(contentsOf: url) else { return nil }
        return Image(nsImage: nsImage)
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    ImageImportView(viewModel: assembler.resolver.imageImportViewModel())
}
