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
        var discoveredByURL: [URL: DiscoveredSource] = [:]
        
        while !queue.isEmpty, visited.count < Self.maxPages {
            let pageURL = queue.removeFirst()
            let visitKey = URLNormalizer.hash(pageURL)
            print("CRAWL: Visiting \(pageURL)")
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
            
            let extraction: (sources: [DiscoveredSource], crawlLinks: [URL])
            do {
                extraction = try extractor.extract(page: loadedPage, baseURL: baseURL)
            } catch {
                if visited.count == 1 {
                    throw error
                }
                continue
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
        
        discoveredByURL = dedupeImages(validatedSources: discoveredByURL)
        
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
        
        onProgress(.completed(newCount: newCount))
        return newCount
    }
    
    private func dedupeImages(validatedSources: [URL: DiscoveredSource]) -> [URL: DiscoveredSource] {
        var result: [URL: DiscoveredSource] = [:]
        var imageHashesByText: [String: URL] = [:]

        for (hash, source) in validatedSources {
            guard source.type == .image else {
                result[hash] = source
                continue
            }

            guard let textKey = normalizedTextKey(from: source.textPieces), !textKey.isEmpty else {
                result[hash] = source
                continue
            }

            guard let existingHash = imageHashesByText[textKey], let existing = result[existingHash] else {
                imageHashesByText[textKey] = hash
                result[hash] = source
                continue
            }

            if shouldPreferImage(candidate: source, over: existing) {
                result.removeValue(forKey: existingHash)
                result[hash] = source
                imageHashesByText[textKey] = hash
            }
        }

        return result
    }

    private func normalizedTextKey(from textPieces: DealSourceTextPieces?) -> String? {
        guard let textPieces else { return nil }
        let lines: [String]
        switch textPieces {
        case let .textLines(textLines):
            lines = textLines
        case let .contentBlocks(blocks):
            lines = blocks.map(\.text)
        }

        let normalized = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()

        return normalized
    }

    private func shouldPreferImage(candidate: DiscoveredSource, over existing: DiscoveredSource) -> Bool {
        let candidateArea = imageArea(candidate.imageDimensions)
        let existingArea = imageArea(existing.imageDimensions)
        return candidateArea > existingArea
    }

    private func imageArea(_ dimensions: CGSize?) -> CGFloat {
        guard let dimensions else { return 0 }
        return dimensions.width * dimensions.height
    }
}
