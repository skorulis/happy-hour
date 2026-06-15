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
            Picker("Processing", selection: $viewModel.processingMode) {
                ForEach(DealProcessingMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.processingMode) {
                viewModel.reset()
            }

            if viewModel.processingMode == .openRouter {
                TextField("Model", text: $viewModel.openRouterModel)
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

        case .processing:
            HStack(spacing: 12) {
                ProgressView()
                Text(processingStatusText)
                    .foregroundStyle(.secondary)
            }

        case let .completed(deals, imageURL):
            completedContent(deals: deals, imageURL: imageURL)

        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private var processingStatusText: String {
        switch viewModel.processingMode {
        case .onDevice:
            return "Extracting text and analyzing deals…"
        case .visionAPI:
            return "Analyzing image with OpenAI…"
        case .openRouter:
            return "Analyzing image with OpenRouter…"
        }
    }

    private func completedContent(deals: [Deal], imageURL: URL) -> some View {
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

                    ForEach(Array(deals.enumerated()), id: \.offset) { _, deal in
                        DealCard(deal: deal)
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

private struct DealCard: View {
    let deal: Deal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !deal.title.isEmpty {
                Text(deal.title)
                    .font(.title3.weight(.semibold))
            }

            if !deal.details.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(deal.details, id: \.self) { detail in
                        Text(detail)
                    }
                }
                .font(.body)
            }

            HStack(spacing: 16) {
                if !deal.days.isEmpty {
                    Label(deal.days.map(\.displayName).joined(separator: ", "), systemImage: "calendar")
                }

                if !deal.times.isEmpty {
                    Label(deal.times.map(\.displayName).joined(separator: ", "), systemImage: "clock")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
    }
}

private extension DealDay {
    var displayName: String {
        rawValue.capitalized
    }
}

private extension DealHours {
    var displayName: String {
        switch self {
        case .allDay:
            return "All day"
        case let .from(minutes):
            return "From \(Self.formatMinutes(minutes))"
        case let .between(start, end):
            return "\(Self.formatMinutes(start)) – \(Self.formatMinutes(end))"
        }
    }

    static func formatMinutes(_ minutes: Int) -> String {
        let hour24 = minutes / 60
        let minute = minutes % 60
        let period = hour24 >= 12 ? "PM" : "AM"
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12

        if minute == 0 {
            return "\(hour12) \(period)"
        }
        return String(format: "%d:%02d %@", hour12, minute, period)
    }
}

#Preview {
    let assembler = DealScraperAssembly.testing()
    ImageImportView(viewModel: assembler.resolver.imageImportViewModel())
}
