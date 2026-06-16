//Created by Alex Skorulis on 15/6/2026.

import Foundation
import KnitMacros
import Knit

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
    private let venueLinkExtractor: VenueLinkExtractor
    private let imageValidator: CrawlImageValidator
    private let dealSourceRepository: DealSourceRepository
    private let venueRepository: VenueRepository
    private let venueLinksRepository: VenueLinksRepository

    @Resolvable<Resolver>
    init(
        pageLoader: WebPageLoader,
        extractor: DealSourceExtractor,
        venueLinkExtractor: VenueLinkExtractor,
        imageValidator: CrawlImageValidator,
        dealSourceRepository: DealSourceRepository,
        venueRepository: VenueRepository,
        venueLinksRepository: VenueLinksRepository
    ) {
        self.pageLoader = pageLoader
        self.extractor = extractor
        self.venueLinkExtractor = venueLinkExtractor
        self.imageValidator = imageValidator
        self.dealSourceRepository = dealSourceRepository
        self.venueRepository = venueRepository
        self.venueLinksRepository = venueLinksRepository
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
            print("Visiting \(pageURL)")
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

            let extraction: (sources: [DiscoveredSource], crawlLinks: [URL])
            do {
                extraction = try extractor.extract(page: loadedPage, baseURL: baseURL)
            } catch {
                if visited.count == 1 {
                    throw error
                }
                continue
            }

            for source in extraction.sources {
                var discovered = source
                if source.type == .webpage, source.url == loadedPage.normalizedURL, !loadedPage.contentBlocks.isEmpty {
                    discovered = DiscoveredSource(
                        url: source.url,
                        type: source.type,
                        hash: source.hash,
                        textPieces: .contentBlocks(loadedPage.contentBlocks)
                    )
                }
                discoveredByHash[discovered.hash] = discovered
            }

            if visited.count == 1 {
                let discoveredLinks = try venueLinkExtractor.extract(
                    html: loadedPage.html,
                    pageURL: loadedPage.normalizedURL,
                    baseURL: baseURL
                )
                try venueLinksRepository.setMissing(
                    venueId: venueId,
                    whatsOn: discoveredLinks.whatsOn?.absoluteString,
                    instagram: discoveredLinks.instagram?.absoluteString,
                    facebook: discoveredLinks.facebook?.absoluteString
                )
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
                if let textLines = await imageValidator.validateImage(url: source.url, hash: hash) {
                    validatedSources[hash] = DiscoveredSource(
                        url: source.url,
                        type: source.type,
                        hash: source.hash,
                        textPieces: .textLines(textLines)
                    )
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
                status: .new,
                date: now,
                textPieces: discovered.textPieces
            )
        }

        let newCount = try dealSourceRepository.upsert(sources: dealSources, forVenueId: venueId)
        try venueRepository.updateLastCrawlDate(venueId: venueId, date: now)

        onProgress(.completed(newCount: newCount))
        return newCount
    }
}
