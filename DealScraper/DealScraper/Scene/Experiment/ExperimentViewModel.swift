//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class ExperimentViewModel {

    enum State {
        case idle
        case loading
        case loaded(LoadedPage)
        case failed(message: String)
    }

    var urlString = "https://www.thestrawbs.com.au/"
    private(set) var state: State = .idle
    private(set) var validatedImages: [ImageValidationResult]?
    private(set) var isProcessingImages = false

    private let webPageLoader: WebPageLoader
    private let crawlImageValidator: CrawlImageValidator

    @Resolvable<Resolver>
    init(webPageLoader: WebPageLoader, crawlImageValidator: CrawlImageValidator) {
        self.webPageLoader = webPageLoader
        self.crawlImageValidator = crawlImageValidator
    }

    func loadPage() {
        guard let url = validatedURL() else { return }

        Task {
            await performLoad(url: url)
        }
    }

    func processImages() {
        guard case let .loaded(page) = state else { return }

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
        state = .loading
        validatedImages = nil
        isProcessingImages = false

        do {
            let page = try await webPageLoader.load(url: url)
            state = .loaded(page)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func performImageProcessing(urls: [URL]) async {
        isProcessingImages = true
        validatedImages = await crawlImageValidator.validateImages(urls: urls)
        isProcessingImages = false
    }
}
