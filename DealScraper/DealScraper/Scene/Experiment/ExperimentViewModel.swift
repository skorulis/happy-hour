//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros

@MainActor
@Observable
final class ExperimentViewModel {

    enum State {
        case idle
        case loadingContentBlocks
        case loadingPageLinks
        case completedBlocks(count: Int)
        case completedLinks(count: Int)
        case failed(message: String)
    }

    var urlString = "https://www.thestrawbs.com.au/"
    private(set) var state: State = .idle

    private let webPageLoader: WebPageLoader
    private let contentBlockGrouper: ContentBlockGrouper
    private let pageLinkExtractor: PageLinkExtractor

    @Resolvable<Resolver>
    init(
        webPageLoader: WebPageLoader,
        contentBlockGrouper: ContentBlockGrouper,
        pageLinkExtractor: PageLinkExtractor
    ) {
        self.webPageLoader = webPageLoader
        self.contentBlockGrouper = contentBlockGrouper
        self.pageLinkExtractor = pageLinkExtractor
    }

    func loadAndExtract() {
        guard let url = validatedURL() else { return }

        Task {
            await performContentBlockExtraction(url: url)
        }
    }

    func loadAndExtractLinks() {
        guard let url = validatedURL() else { return }

        Task {
            await performPageLinkExtraction(url: url)
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

    private func performContentBlockExtraction(url: URL) async {
        state = .loadingContentBlocks

        do {
            let page = try await webPageLoader.load(url: url)
            let blocks = try contentBlockGrouper.group(html: page.html, pageURL: page.url)

            print("Content blocks for \(page.url.absoluteString)")
            print(blocks.formattedConsoleOutput())

            state = .completedBlocks(count: blocks.count)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    private func performPageLinkExtraction(url: URL) async {
        state = .loadingPageLinks

        do {
            let page = try await webPageLoader.load(url: url)
            let links = try pageLinkExtractor.extract(html: page.html, pageURL: page.url)

            print("Page links for \(page.url.absoluteString)")
            print(links.formattedConsoleOutput())

            state = .completedLinks(count: links.count)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
