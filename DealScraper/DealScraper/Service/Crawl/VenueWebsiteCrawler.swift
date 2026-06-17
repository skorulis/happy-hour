//Created by Alex Skorulis on 15/6/2026.

import Foundation
import KnitMacros
import Knit

enum CrawlProgress: Sendable {
    case loadingPage(URL)
    case validatingImage(URL)
    case saving
    case completed(VenueCrawlResults)
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
    private let pageLinkFilter: PageLinkFilter
    private let venueLinkExtractor: VenueLinkExtractor
    private let imageValidator: CrawlImageValidator
    private let imageDeduper: ImageDeduper
    private let dealSourceRepository: DealSourceRepository
    private let venueRepository: VenueRepository
    private let venueLinksRepository: VenueLinksRepository
    
    @Resolvable<Resolver>
    init(
        pageLoader: WebPageLoader,
        pageLinkFilter: PageLinkFilter,
        venueLinkExtractor: VenueLinkExtractor,
        imageValidator: CrawlImageValidator,
        imageDeduper: ImageDeduper,
        dealSourceRepository: DealSourceRepository,
        venueRepository: VenueRepository,
        venueLinksRepository: VenueLinksRepository
    ) {
        self.pageLoader = pageLoader
        self.pageLinkFilter = pageLinkFilter
        self.venueLinkExtractor = venueLinkExtractor
        self.imageValidator = imageValidator
        self.imageDeduper = imageDeduper
        self.dealSourceRepository = dealSourceRepository
        self.venueRepository = venueRepository
        self.venueLinksRepository = venueLinksRepository
    }
    
    func crawl(
        venue: Venue,
        onProgress: @escaping @Sendable (CrawlProgress) -> Void = { _ in }
    ) async throws -> VenueCrawlResults {
        guard let websiteUri = venue.websiteUri,
              let startURL = URL(string: websiteUri),
              let baseURL = URLNormalizer.normalize(startURL)
        else {
            throw VenueWebsiteCrawlerError.missingWebsite
        }
        
        guard let venueId = venue.id else {
            throw VenueWebsiteCrawlerError.missingVenueID
        }
        
        let startTime = Date()
        
        var queue: [URL] = [baseURL]
        var visited = Set<String>()
        var visitedPages: [URL] = []
        var imagesAnalyzed = 0
        var discoveredByURL: [URL: DiscoveredSource] = [:]
        
        while !queue.isEmpty, visited.count < Self.maxPages {
            let pageURL = queue.removeFirst()
            let visitKey = URLNormalizer.hash(pageURL)
            print("CRAWL: Visiting \(pageURL)")
            guard visited.insert(visitKey).inserted else { continue }
            visitedPages.append(pageURL)
            
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
            
            print("CRAWL: Loaded. Blocks: \(loadedPage.contentBlocks.count). Images: \(loadedPage.imageURLs.count)")
            
            if !loadedPage.dealContentBlocks.isEmpty {
                let source = DiscoveredSource(
                    url: loadedPage.normalizedURL,
                    type: .webpage,
                    textPieces: .contentBlocks(loadedPage.dealContentBlocks)
                )
                discoveredByURL[loadedPage.normalizedURL] = source
            }
            
            for imageURL in loadedPage.imageURLs {
                imagesAnalyzed += 1
                onProgress(.validatingImage(imageURL))
                let hash = URLNormalizer.hash(imageURL)
                if let validation = await imageValidator.validateImage(url: imageURL, hash: hash) {
                    discoveredByURL[imageURL] = DiscoveredSource(
                        url: imageURL,
                        type: .image,
                        imageDimensions: validation.dimensions,
                        textPieces: .textLines(validation.lines.map(\.text))
                    )
                }
            }
            
            let filtered = pageLinkFilter.filter(links: loadedPage.links)

            for pdfURL in filtered.pdfURLs {
                discoveredByURL[pdfURL] = DiscoveredSource(url: pdfURL, type: .pdf)
            }

            for link in filtered.crawlURLs {
                guard URLNormalizer.isSameOrigin(link, as: baseURL) else { continue }
                guard let normalized = URLNormalizer.normalize(link) else { continue }
                let linkKey = URLNormalizer.hash(normalized)
                guard !visited.contains(linkKey) else { continue }
                if !queue.contains(where: { URLNormalizer.hash($0) == linkKey }) {
                    queue.append(normalized)
                }
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
        }
        
        discoveredByURL = imageDeduper.dedupe(validatedSources: discoveredByURL)
        
        onProgress(.saving)
        
        let now = Date()
        let dealSources = discoveredByURL.values.map { discovered in
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
        
        let results = VenueCrawlResults(
            dealsFound: newCount,
            visitedPages: visitedPages,
            imagesAnalyzed: imagesAnalyzed,
            duration: Date().timeIntervalSince(startTime)
        )
        onProgress(.completed(results))
        return results
    }
}
