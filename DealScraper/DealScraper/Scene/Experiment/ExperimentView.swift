//Created by Alex Skorulis on 15/6/2026.


import Knit
import SwiftUI

struct ExperimentView: View {

    @State var viewModel: ExperimentViewModel
    @State private var linkDisplayMode: LinkDisplayMode = .filtered
    @State private var contentBlockDisplayMode: ContentBlockDisplayMode = .deal
    @State private var pdfMarkdownDisplayMode: PDFMarkdownDisplayMode = .filtered
    @State private var isPDFMarkdownExpanded = false
    @State private var isMarkdownExpanded = false

    private let pageLinkFilter = PageLinkFilter()

    private enum LinkDisplayMode: String, CaseIterable {
        case filtered
        case all
    }

    private enum ContentBlockDisplayMode: String, CaseIterable {
        case deal
        case all
    }

    private enum PDFMarkdownDisplayMode: String, CaseIterable {
        case filtered
        case full
    }

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

        case let .loading(message):
            LoadingView(text: message)
        
        case .loaded:
            if let validation = viewModel.crawlDealValidation {
                crawlDealValidationBanner(validation)
            }

        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var results: some View {
        if case let .loaded(content) = viewModel.state {
            switch content {
            case let .page(page):
                if let markdown = page.markdown {
                    markdownSection(markdown)
                }
                linksSection(page.links)
                imagesSection(page)
                contentBlocksSection(page)
            case let .image(url, lines):
                imageOCRSection(url: url, lines: lines, heroScore: viewModel.heroImageScore)
            case let .pdf(url, extraction):
                pdfMarkdownSection(url: url, extraction: extraction)
            }
        }
    }

    private func markdownSection(_ markdown: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    isMarkdownExpanded.toggle()
                } label: {
                    HStack {
                        Text("Markdown")
                            .font(.headline)
                        Image(systemName: isMarkdownExpanded ? "chevron.down" : "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                printMarkdownButton(markdown)
                copyMarkdownButton(markdown)
            }

            if isMarkdownExpanded {
                ScrollView {
                    Text(markdown)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 400)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
        .onChange(of: markdown) {
            isMarkdownExpanded = false
        }
    }
    
    private func copyMarkdownButton(_ markdown: String) -> some View {
        Button {
            viewModel.copyMarkdownToClipboard(markdown)
        } label: {
            Image(systemName: "doc.on.doc")
        }
        .buttonStyle(.plain)
        .help("Copy markdown to clipboard")
    }
    
    private func printMarkdownButton(_ markdown: String) -> some View {
        Button {
            viewModel.printMarkdownDocument(markdown)
        } label: {
            Image(systemName: "terminal")
        }
        .buttonStyle(.plain)
        .help("Parse markdown and print Document tree to terminal")
    }

    private func imageOCRSection(url: URL, lines: [ExtractedTextLine], heroScore: HeroImageScore?) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            if let heroScore {
                heroImageScoreSection(heroScore)
            }

            detailSection(title: "OCR (\(lines.count) line\(lines.count == 1 ? "" : "s"))") {
                imagePreview(url: url)

                if lines.isEmpty {
                    Text("No text was recognized in this image.")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        Text(lines.map(\.text).joined(separator: "\n"))
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 400)
                }
            }
        }
    }

    private func heroImageScoreSection(_ score: HeroImageScore) -> some View {
        detailSection(title: "Hero Image Score") {
            if let skipReason = score.skipReason {
                Label(skipReason, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }

            if let dimensions = score.dimensions {
                Text("Dimensions: \(Int(dimensions.width)) × \(Int(dimensions.height))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if score.skipReason == nil || score.skipReason == "Below viability threshold" {
                scoreRow(label: "Aspect", value: score.aspectScore)
                scoreRow(
                    label: "Text",
                    value: score.textScore,
                    detail: "coverage \(percentString(score.textCoverageRatio))"
                )
                scoreRow(label: "Building", value: score.buildingScore)
                Divider()
                scoreRow(label: "Total", value: score.totalScore, emphasized: true)

                Label(
                    score.isViable ? "Viable candidate" : "Not viable",
                    systemImage: score.isViable ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .foregroundStyle(score.isViable ? .green : .red)
            }
        }
    }

    private func scoreRow(label: String, value: CGFloat, detail: String? = nil, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(emphasized ? .subheadline.weight(.semibold) : .subheadline)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(scoreString(value))
                .font(emphasized ? .subheadline.weight(.semibold).monospacedDigit() : .subheadline.monospacedDigit())
        }
    }

    private func scoreString(_ value: CGFloat) -> String {
        String(format: "%.3f", value)
    }

    private func percentString(_ value: CGFloat) -> String {
        String(format: "%.1f%%", value * 100)
    }

    private func imagePreview(url: URL) -> some View {
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
                Link(url.absoluteString, destination: url)
                    .font(.subheadline)
            @unknown default:
                EmptyView()
            }
        }
    }

    private func pdfMarkdownSection(url: URL, extraction: PDFTextExtractionResult) -> some View {
        let markdown = pdfMarkdownDisplayMode == .filtered
            ? extraction.filteredText
            : extraction.fullText

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    isPDFMarkdownExpanded.toggle()
                } label: {
                    HStack {
                        Text("PDF Markdown")
                            .font(.headline)
                        Image(systemName: isPDFMarkdownExpanded ? "chevron.down" : "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                printMarkdownButton(markdown)
                copyMarkdownButton(markdown)
            }

            Picker("PDF markdown", selection: $pdfMarkdownDisplayMode) {
                Text("Filtered").tag(PDFMarkdownDisplayMode.filtered)
                Text("Full").tag(PDFMarkdownDisplayMode.full)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Link(url.absoluteString, destination: url)
                .font(.subheadline)

            if isPDFMarkdownExpanded {
                ScrollView {
                    Text(markdown)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 400)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
        .onChange(of: url) {
            pdfMarkdownDisplayMode = .filtered
            isPDFMarkdownExpanded = false
        }
    }

    private func linksSection(_ links: [ContentBlockLink]) -> some View {
        let displayedLinks = linksForDisplay(links)

        return detailSection(title: "Links (\(displayedLinks.count))") {
            Picker("Links", selection: $linkDisplayMode) {
                Text("Filtered").tag(LinkDisplayMode.filtered)
                Text("All").tag(LinkDisplayMode.all)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if displayedLinks.isEmpty {
                Text("No links found.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(displayedLinks.enumerated()), id: \.offset) { _, link in
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

    private func linksForDisplay(_ links: [ContentBlockLink]) -> [ContentBlockLink] {
        switch linkDisplayMode {
        case .all:
            return links
        case .filtered:
            let filtered = pageLinkFilter.filter(links: links)
            let filteredURLs = filtered.pdfURLs + filtered.crawlURLs
            return filteredURLs.map { url in
                links.first { link in
                    guard let normalized = URLNormalizer.normalize(link.url) else { return false }
                    return URLNormalizer.hash(normalized) == URLNormalizer.hash(url)
                } ?? ContentBlockLink(text: nil, url: url)
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
                LoadingView(text: "Processing images…")
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

    private func contentBlocksSection(_ page: LoadedPage) -> some View {
        let blocks = contentBlocksForDisplay(page)

        return detailSection(title: "Content Blocks (\(blocks.count))") {
            Picker("Content blocks", selection: $contentBlockDisplayMode) {
                Text("Deal").tag(ContentBlockDisplayMode.deal)
                Text("All").tag(ContentBlockDisplayMode.all)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if blocks.isEmpty {
                Text(contentBlockDisplayMode == .deal
                    ? "No deal content blocks found."
                    : "No content blocks found.")
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
        .onChange(of: page.url) {
            contentBlockDisplayMode = .deal
        }
    }

    private func contentBlocksForDisplay(_ page: LoadedPage) -> [ContentBlock] {
        switch contentBlockDisplayMode {
        case .deal:
            return page.dealContentBlocks
        case .all:
            return page.contentBlocks
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

    private func crawlDealValidationBanner(_ validation: ExperimentViewModel.CrawlDealValidation) -> some View {
        Label(validation.message, systemImage: validation.isAccepted ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(validation.isAccepted ? .green : .red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill((validation.isAccepted ? Color.green : Color.red).opacity(0.1))
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
