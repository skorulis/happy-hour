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

    struct CrawlDealValidation: Equatable {
        let isAccepted: Bool
        let message: String
    }

    var urlString = "https://www.thestrawbs.com.au/"
    private(set) var state: State = .idle
    private(set) var crawlDealValidation: CrawlDealValidation?
    private(set) var validatedImages: [ImageValidationResult]?
    private(set) var isProcessingImages = false
    private(set) var rankedHeroImages: [RankedHeroImage]?
    private(set) var isFindingHero = false
    private(set) var heroImageScore: HeroImageScore?

    private let webPageLoaderFactory: WebPageLoaderFactory
    private let crawlImageValidator: CrawlImageValidator
    private let heroImageSelector: VenueHeroImageSelector
    private let imageFetcher: CrawlImageFetcher
    private let imageExtractor: DealImageExtractor
    private let pdfFetcher: CrawlPDFFetcher
    private let pdfTextExtractor: PDFTextExtractor

    @Resolvable<Resolver>
    init(
        webPageLoaderFactory: WebPageLoaderFactory,
        crawlImageValidator: CrawlImageValidator,
        heroImageSelector: VenueHeroImageSelector,
        imageFetcher: CrawlImageFetcher,
        imageExtractor: DealImageExtractor,
        pdfFetcher: CrawlPDFFetcher,
        pdfTextExtractor: PDFTextExtractor
    ) {
        self.webPageLoaderFactory = webPageLoaderFactory
        self.crawlImageValidator = crawlImageValidator
        self.heroImageSelector = heroImageSelector
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

    func findHero() {
        guard case let .loaded(.page(page)) = state else { return }

        Task {
            await performHeroRanking(urls: page.imageURLs)
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
        crawlDealValidation = nil
        validatedImages = nil
        rankedHeroImages = nil
        heroImageScore = nil
        isProcessingImages = false
        isFindingHero = false

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
            let webPageLoader = webPageLoaderFactory.make()
            let page = try await webPageLoader.load(url: url)
            crawlDealValidation = validateWebpageForCrawl(page)
            state = .loaded(.page(page))
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func loadImage(url: URL) async {
        do {
            let hash = URLNormalizer.hash(url)
            let localURL = try await imageFetcher.localFileURL(for: url, hash: hash)
            async let linesTask = imageExtractor.extractTexts(from: localURL)
            async let scoreTask = heroImageSelector.scoreHeroImage(url: url)
            let lines = try await linesTask
            heroImageScore = await scoreTask
            crawlDealValidation = await validateImageForCrawl(url: url)
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
            crawlDealValidation = validatePDFForCrawl(url: url)
            state = .loaded(.pdf(url: url, extraction: extraction))
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func validateWebpageForCrawl(_ page: LoadedPage) -> CrawlDealValidation {
        let count = page.dealContentBlocks.count
        if count > 0 {
            let blockLabel = count == 1 ? "block" : "blocks"
            return CrawlDealValidation(
                isAccepted: true,
                message: "Accepted by crawler — \(count) deal content \(blockLabel) found on this page."
            )
        }
        return CrawlDealValidation(
            isAccepted: false,
            message: "Rejected by crawler — no content blocks passed the deal text filter."
        )
    }

    private func validateImageForCrawl(url: URL) async -> CrawlDealValidation {
        if await crawlImageValidator.validateImage(url: url) != nil {
            return CrawlDealValidation(
                isAccepted: true,
                message: "Accepted by crawler — image meets size requirements and contains valid deal text."
            )
        }
        return CrawlDealValidation(
            isAccepted: false,
            message: "Rejected by crawler — image is too small, has no deal text, or matches an excluded URL pattern."
        )
    }

    private func validatePDFForCrawl(url: URL) -> CrawlDealValidation {
        let currentYear = Calendar.current.component(.year, from: Date())
        if let year = PDFVersionFilter.year(from: url), year < currentYear {
            return CrawlDealValidation(
                isAccepted: false,
                message: "Rejected by crawler — PDF appears to be from \(year) and outdated menus are skipped."
            )
        }
        return CrawlDealValidation(
            isAccepted: true,
            message: "Accepted by crawler — PDF contains deal-related text."
        )
    }

    private func performImageProcessing(urls: [URL]) async {
        isProcessingImages = true
        validatedImages = await crawlImageValidator.validateImages(urls: urls)
        isProcessingImages = false
    }

    private func performHeroRanking(urls: [URL]) async {
        isFindingHero = true
        rankedHeroImages = await heroImageSelector.rankHeroImages(from: urls)
        isFindingHero = false
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
