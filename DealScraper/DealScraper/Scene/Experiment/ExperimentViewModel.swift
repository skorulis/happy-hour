//Created by Alex Skorulis on 15/6/2026.

import AppKit
import Foundation
import Knit
import KnitMacros
import Markdown

@MainActor
@Observable
final class ExperimentViewModel {

    enum LoadedContent {
        case page(LoadedPage)
        case image(url: URL, lines: [ExtractedTextLine])
        case pdf(url: URL, extraction: PDFTextExtractionResult)
    }

    enum State {
        case idle
        case loading(message: String)
        case loaded(LoadedContent)
        case failed(message: String)
    }

    var urlString = "https://www.thestrawbs.com.au/"
    private(set) var state: State = .idle
    private(set) var validatedImages: [ImageValidationResult]?
    private(set) var isProcessingImages = false

    private let webPageLoader: WebPageLoader
    private let crawlImageValidator: CrawlImageValidator
    private let imageFetcher: CrawlImageFetcher
    private let imageExtractor: DealImageExtractor
    private let pdfFetcher: CrawlPDFFetcher
    private let pdfTextExtractor: PDFTextExtractor

    @Resolvable<Resolver>
    init(
        webPageLoader: WebPageLoader,
        crawlImageValidator: CrawlImageValidator,
        imageFetcher: CrawlImageFetcher,
        imageExtractor: DealImageExtractor,
        pdfFetcher: CrawlPDFFetcher,
        pdfTextExtractor: PDFTextExtractor
    ) {
        self.webPageLoader = webPageLoader
        self.crawlImageValidator = crawlImageValidator
        self.imageFetcher = imageFetcher
        self.imageExtractor = imageExtractor
        self.pdfFetcher = pdfFetcher
        self.pdfTextExtractor = pdfTextExtractor
    }

    func loadPage() {
        guard let url = validatedURL() else { return }

        Task {
            await performLoad(url: url)
        }
    }

    func load(urlString: String) {
        self.urlString = urlString
        loadPage()
    }

    func processImages() {
        guard case let .loaded(.page(page)) = state else { return }

        Task {
            await performImageProcessing(urls: page.imageURLs)
        }
    }

    private func validatedURL() -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .failed(message: "Please enter a URL.")
            return nil
        }

        guard let url = URL(string: trimmed), url.scheme != nil else {
            state = .failed(message: "Please enter a valid URL.")
            return nil
        }

        return url
    }

    private func performLoad(url: URL) async {
        validatedImages = nil
        isProcessingImages = false

        switch PageLinkFilter.sourceType(for: url) {
        case .webpage:
            state = .loading(message: "Loading page…")
            await loadWebpage(url: url)
        case .image:
            state = .loading(message: "Running OCR…")
            await loadImage(url: url)
        case .pdf:
            state = .loading(message: "Extracting PDF text…")
            await loadPDF(url: url)
        }
    }

    private func loadWebpage(url: URL) async {
        do {
            let page = try await webPageLoader.load(url: url)
            state = .loaded(.page(page))
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func loadImage(url: URL) async {
        do {
            let hash = URLNormalizer.hash(url)
            let localURL = try await imageFetcher.localFileURL(for: url, hash: hash)
            let lines = try await imageExtractor.extractTexts(from: localURL)
            state = .loaded(.image(url: url, lines: lines))
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func loadPDF(url: URL) async {
        do {
            let hash = URLNormalizer.hash(url)
            let localURL = try await pdfFetcher.localFileURL(for: url, hash: hash)
            guard let extraction = pdfTextExtractor.extractText(from: localURL) else {
                state = .failed(message: "No deal-related text could be extracted from the PDF.")
                return
            }
            state = .loaded(.pdf(url: url, extraction: extraction))
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func performImageProcessing(urls: [URL]) async {
        isProcessingImages = true
        validatedImages = await crawlImageValidator.validateImages(urls: urls)
        isProcessingImages = false
    }
    
    func copyMarkdownToClipboard(_ markdown: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
    }

    func printMarkdownDocument(_ markdown: String) {
        let document = Document(parsing: markdown)
        print(document.debugDescription())
    }
}
