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

    private let webPageLoader: WebPageLoader

    @Resolvable<Resolver>
    init(webPageLoader: WebPageLoader) {
        self.webPageLoader = webPageLoader
    }

    func loadPage() {
        guard let url = validatedURL() else { return }

        Task {
            await performLoad(url: url)
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

        do {
            let page = try await webPageLoader.load(url: url)
            state = .loaded(page)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
