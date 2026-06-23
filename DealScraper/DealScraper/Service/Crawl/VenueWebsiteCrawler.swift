//Created by Alex Skorulis on 15/6/2026.

import Foundation
import KnitMacros
import Knit

enum CrawlProgress: Sendable {
    case loadingPage(URL)
    case validatingImages(count: Int)
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
    
    private let pageLoader: WebPageLoader
    private let pageLinkFilter: PageLinkFilter
    private let venueLinkExtractor: VenueLinkExtractor
    private let imageValidator: CrawlImageValidator
    private let pdfValidator: PDFValidator
    private let imageDeduper: ImageDeduper
    private let dealAdvancedTextFilter: DealAdvancedTextFilter
    private let dealSourceRepository: DealSourceRepository
    private let venueRepository: VenueRepository
    private let venueLinksRepository: VenueLinksRepository
    
    @Resolvable<Resolver>
    init(
        pageLoader: WebPageLoader,
        pageLinkFilter: PageLinkFilter,
        venueLinkExtractor: VenueLinkExtractor,
        imageValidator: CrawlImageValidator,
        pdfValidator: PDFValidator,
        imageDeduper: ImageDeduper,
        dealAdvancedTextFilter: DealAdvancedTextFilter,
        dealSourceRepository: DealSourceRepository,
        venueRepository: VenueRepository,
        venueLinksRepository: VenueLinksRepository
    ) {
        self.pageLoader = pageLoader
        self.pageLinkFilter = pageLinkFilter
        self.venueLinkExtractor = venueLinkExtractor
        self.imageValidator = imageValidator
        self.pdfValidator = pdfValidator
        self.imageDeduper = imageDeduper
        self.dealAdvancedTextFilter = dealAdvancedTextFilter
        self.dealSourceRepository = dealSourceRepository
        self.venueRepository = venueRepository
        self.venueLinksRepository = venueLinksRepository
    }
    
    func crawl(
        venue: Venue,
        progress: ProgressMonitor<VenueCrawlResults> = .empty
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
        let maxPages = CrawlPolicy.maxPages(for: baseURL)
        
        var queue: [URL] = [baseURL]
        var visited = Set<String>()
        var visitedIdentities = Set<String>()
        var visitedPages: [URL] = []
        var discoveredImages = Set<URL>()
        var discoveredByURL: [URL: DiscoveredSource] = [:]
        var pdfURLs: Set<URL> = []
        var pdfSourceURLs: [URL: URL] = [:]
        
        while !queue.isEmpty, visited.count < maxPages {
            try Task.checkCancellation()

            let pageURL = queue.removeFirst()
            let visitKey = URLNormalizer.hash(pageURL)
            print("CRAWL: Visiting \(pageURL)")
            guard visited.insert(visitKey).inserted else { continue }
            visitedPages.append(pageURL)
            
            await progress("Loading \(pageURL)…")
            
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

            let identityKey = URLNormalizer.hash(loadedPage.normalizedURL)
            guard visitedIdentities.insert(identityKey).inserted else {
                print("CRAWL: Skipping duplicate canonical page \(pageURL) -> \(loadedPage.normalizedURL)")
                continue
            }

            if !loadedPage.dealContentBlocks.isEmpty {
                let source = DiscoveredSource(
                    url: loadedPage.normalizedURL,
                    sourceURL: loadedPage.normalizedURL,
                    type: .webpage,
                    textPieces: .contentBlocks(loadedPage.dealContentBlocks)
                )
                discoveredByURL[loadedPage.normalizedURL] = source
            }
            
            discoveredImages.formUnion(loadedPage.imageURLs)
            
            let imagesToCheck = discoveredImages.filter { visited.contains(URLNormalizer.hash($0)) }
            await progress("Checking \(imagesToCheck) images")
            visited.formUnion(imagesToCheck.map { URLNormalizer.hash($0)})
            
            let validations = await imageValidator.validateImages(urls: Array(imagesToCheck))
            var index = 0
            for validation in validations {
                index += 1
                await progress("Processing image \(index) of \(imagesToCheck.count)")
                discoveredByURL[validation.url] = DiscoveredSource(
                    url: validation.url,
                    sourceURL: loadedPage.normalizedURL,
                    type: .image,
                    imageDimensions: validation.dimensions,
                    textPieces: .textLines(validation.lines.map(\.text)),
                    imageFeaturePrint: validation.featurePrint
                )
            }
            
            let filtered = pageLinkFilter.filter(links: loadedPage.links)

            for pdfURL in filtered.pdfURLs {
                pdfURLs.insert(pdfURL)
                pdfSourceURLs[pdfURL] = loadedPage.normalizedURL
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
        
        await progress("Checking \(pdfURLs.count) PDFs")
        let pdfValidations = await pdfValidator.validatePDFs(urls: Array(pdfURLs))
        for validation in pdfValidations {
            discoveredByURL[validation.url] = DiscoveredSource(
                url: validation.url,
                sourceURL: pdfSourceURLs[validation.url] ?? baseURL,
                type: .pdf,
                textPieces: .textLines(
                    validation.text
                        .components(separatedBy: CharacterSet.newlines)
                        .filter { !$0.isEmpty }
                )
            )
        }

        let imageCount = discoveredByURL.values.filter { $0.type == .image}.count
        await progress("Deduping \(imageCount) images")
        discoveredByURL = imageDeduper.dedupe(validatedSources: discoveredByURL)
        discoveredByURL = await dealAdvancedTextFilter.filter(sources: discoveredByURL)
        
        await progress("Saving deal sources…")
        
        let now = Date()
        let dealSources = discoveredByURL.values.map { discovered in
            DealSource(
                venueId: venueId,
                url: discovered.url.absoluteString,
                sourceURL: discovered.sourceURL.absoluteString,
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
            imagesAnalyzed: discoveredImages.count,
            duration: Date().timeIntervalSince(startTime)
        )
        await progress.completed(results: results)
        return results
    }
}
