//Created by Alex Skorulis on 15/6/2026.

import Foundation

enum CrawlProgress: Sendable {
    case loadingPage(URL)
    case validatingImage(URL)
    case saving
    case completed(newCount: Int)
    case failed(message: String)
}

enum VenueWebsiteCrawlerError: LocalizedError {
    case missingWebsite
    case missingVenueID

    var errorDescription: String? {
        switch self {
        case .missingWebsite:
            return "This venue does not have a website URL."
        case .missingVenueID:
            return "This venue has not been saved with a database ID."
        }
    }
}

@MainActor
final class VenueWebsiteCrawler {

    private static let maxPages = 8

    private let pageLoader: WebPageLoader
    private let extractor: DealSourceExtractor
    private let imageValidator: CrawlImageValidator
    private let dealSourceRepository: DealSourceRepository
    private let venueRepository: VenueRepository

    init(
        pageLoader: WebPageLoader,
        extractor: DealSourceExtractor = DealSourceExtractor(),
        imageValidator: CrawlImageValidator,
        dealSourceRepository: DealSourceRepository,
        venueRepository: VenueRepository
    ) {
        self.pageLoader = pageLoader
        self.extractor = extractor
        self.imageValidator = imageValidator
        self.dealSourceRepository = dealSourceRepository
        self.venueRepository = venueRepository
    }

    func crawl(
        venue: Venue,
        onProgress: @escaping @Sendable (CrawlProgress) -> Void = { _ in }
    ) async throws -> Int {
        guard let websiteUri = venue.websiteUri,
              let startURL = URL(string: websiteUri),
              let baseURL = URLNormalizer.normalize(startURL)
        else {
            throw VenueWebsiteCrawlerError.missingWebsite
        }

        guard let venueId = venue.id else {
            throw VenueWebsiteCrawlerError.missingVenueID
        }

        var queue: [URL] = [baseURL]
        var visited = Set<String>()
        var discoveredByHash: [String: DiscoveredSource] = [:]

        while !queue.isEmpty, visited.count < Self.maxPages {
            let pageURL = queue.removeFirst()
            let visitKey = URLNormalizer.hash(pageURL)
            guard visited.insert(visitKey).inserted else { continue }

            onProgress(.loadingPage(pageURL))

            let loadedPage: LoadedPage
            do {
                loadedPage = try await pageLoader.load(url: pageURL)
            } catch {
                if visited.count == 1 {
                    throw error
                }
                continue
            }

            let normalizedPageURL = URLNormalizer.normalize(loadedPage.url) ?? loadedPage.url

            let extraction: (sources: [DiscoveredSource], crawlLinks: [URL])
            do {
                extraction = try extractor.extract(
                    html: loadedPage.html,
                    pageURL: normalizedPageURL,
                    baseURL: baseURL,
                    harvestedImageURLs: loadedPage.imageURLs
                )
            } catch {
                if visited.count == 1 {
                    throw error
                }
                continue
            }

            for source in extraction.sources {
                discoveredByHash[source.hash] = source
            }

            for link in extraction.crawlLinks {
                guard URLNormalizer.isSameOrigin(link, as: baseURL) else { continue }
                guard let normalized = URLNormalizer.normalize(link) else { continue }
                let linkKey = URLNormalizer.hash(normalized)
                guard !visited.contains(linkKey) else { continue }
                if !queue.contains(where: { URLNormalizer.hash($0) == linkKey }) {
                    queue.append(normalized)
                }
            }
        }

        var validatedSources: [String: DiscoveredSource] = [:]
        for (hash, source) in discoveredByHash {
            if source.type == .image {
                onProgress(.validatingImage(source.url))
                let isRelevant = await imageValidator.isRelevantImage(url: source.url, hash: hash)
                if isRelevant {
                    validatedSources[hash] = source
                }
            } else {
                validatedSources[hash] = source
            }
        }

        onProgress(.saving)

        let now = Date()
        let dealSources = validatedSources.values.map { discovered in
            DealSource(
                venueId: venueId,
                url: discovered.url.absoluteString,
                type: discovered.type,
                hash: discovered.hash,
                status: .new,
                date: now
            )
        }

        let newCount = try dealSourceRepository.upsert(sources: dealSources, forVenueId: venueId)
        try venueRepository.updateLastCrawlDate(venueId: venueId, date: now)

        onProgress(.completed(newCount: newCount))
        return newCount
    }
}
