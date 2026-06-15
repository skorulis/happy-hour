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
        case completed(blockCount: Int)
        case failed(message: String)
    }

    var urlString = "https://www.thestrawbs.com.au/"
    private(set) var state: State = .idle

    private let webPageLoader: WebPageLoader
    private let contentBlockGrouper: ContentBlockGrouper

    @Resolvable<Resolver>
    init(
        webPageLoader: WebPageLoader,
        contentBlockGrouper: ContentBlockGrouper
    ) {
        self.webPageLoader = webPageLoader
        self.contentBlockGrouper = contentBlockGrouper
    }

    func loadAndExtract() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .failed(message: "Please enter a URL.")
            return
        }

        guard let url = URL(string: trimmed), url.scheme != nil else {
            state = .failed(message: "Please enter a valid URL.")
            return
        }

        Task {
            await performLoad(url: url)
        }
    }

    private func performLoad(url: URL) async {
        state = .loading

        do {
            let page = try await webPageLoader.load(url: url)
            let blocks = try contentBlockGrouper.group(html: page.html, pageURL: page.url)

            print("Content blocks for \(page.url.absoluteString)")
            print(blocks.formattedConsoleOutput())

            state = .completed(blockCount: blocks.count)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
