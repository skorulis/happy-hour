//Created by Alex Skorulis on 23/6/2026.

import ASKCore
import Foundation

struct SitemapExtractionResult: Sendable {
    let webpageURLs: [URL]
    let imageURLs: [URL]
    let pdfURLs: [URL]

    static let empty = SitemapExtractionResult(webpageURLs: [], imageURLs: [], pdfURLs: [])
}

@MainActor
final class SiteMapExtractor: HTTPService {

    private static let safariUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    private static let maxSitemapFetches = 50

    private let pageLinkFilter: PageLinkFilter

    init(
        pageLinkFilter: PageLinkFilter = PageLinkFilter(),
        urlSession: URLSessionProtocol = URLSession(configuration: .default),
        logger: HTTPLogger? = nil
    ) {
        self.pageLinkFilter = pageLinkFilter
        super.init(baseURL: nil, logger: logger, urlSession: urlSession)
    }

    override func modify(request: inout URLRequest) throws {
        request.setValue(Self.safariUserAgent, forHTTPHeaderField: "User-Agent")
    }

    func extract(baseURL: URL) async -> SitemapExtractionResult {
        guard let sitemapURL = URL(string: "sitemap.xml", relativeTo: baseURL).flatMap({ URLNormalizer.normalize($0) })
        else {
            return .empty
        }

        var visitedSitemaps = Set<String>()
        var webpageURLs: [URL] = []
        var imageURLs: [URL] = []
        var pdfURLs: [URL] = []
        var seenLeafHashes = Set<String>()
        var fetchCount = 0

        await collect(
            from: sitemapURL,
            baseURL: baseURL,
            visitedSitemaps: &visitedSitemaps,
            webpageURLs: &webpageURLs,
            imageURLs: &imageURLs,
            pdfURLs: &pdfURLs,
            seenLeafHashes: &seenLeafHashes,
            fetchCount: &fetchCount
        )

        return SitemapExtractionResult(
            webpageURLs: webpageURLs,
            imageURLs: imageURLs,
            pdfURLs: pdfURLs
        )
    }

    private func collect(
        from sitemapURL: URL,
        baseURL: URL,
        visitedSitemaps: inout Set<String>,
        webpageURLs: inout [URL],
        imageURLs: inout [URL],
        pdfURLs: inout [URL],
        seenLeafHashes: inout Set<String>,
        fetchCount: inout Int
    ) async {
        let visitKey = URLNormalizer.hash(sitemapURL)
        guard visitedSitemaps.insert(visitKey).inserted else { return }
        guard fetchCount < Self.maxSitemapFetches else { return }

        fetchCount += 1
        guard let data = await fetchSitemapData(url: sitemapURL) else { return }

        let locations = SitemapXMLParser(data: data).parse()
        for location in locations {
            guard let url = URLNormalizer.resolve(location, relativeTo: sitemapURL) else { continue }
            guard URLNormalizer.isSameOrigin(url, as: baseURL) else { continue }

            if Self.isNestedSitemapURL(url) {
                await collect(
                    from: url,
                    baseURL: baseURL,
                    visitedSitemaps: &visitedSitemaps,
                    webpageURLs: &webpageURLs,
                    imageURLs: &imageURLs,
                    pdfURLs: &pdfURLs,
                    seenLeafHashes: &seenLeafHashes,
                    fetchCount: &fetchCount
                )
                continue
            }

            guard let normalized = URLNormalizer.normalize(url) else { continue }
            let hash = URLNormalizer.hash(normalized)
            guard seenLeafHashes.insert(hash).inserted else { continue }

            switch PageLinkFilter.sourceType(for: normalized) {
            case .image:
                imageURLs.append(normalized)
            case .pdf:
                guard pageLinkFilter.shouldInclude(ContentBlockLink(text: nil, url: normalized)) else { continue }
                pdfURLs.append(normalized)
            case .webpage:
                guard pageLinkFilter.shouldInclude(ContentBlockLink(text: nil, url: normalized)) else { continue }
                webpageURLs.append(normalized)
            }
        }
    }

    private func fetchSitemapData(url: URL) async -> Data? {
        let request = SitemapDownloadRequest(endpoint: url.absoluteString)
        do {
            let result = try await execute(request: request)
            guard (200 ... 299).contains(result.response.statusCode) else { return nil }
            return result.data.isEmpty ? nil : result.data
        } catch {
            return nil
        }
    }

    private static func isNestedSitemapURL(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        if path.hasSuffix(".xml") { return true }
        return url.lastPathComponent.lowercased().contains("sitemap")
    }
}

private final class SitemapXMLParser: NSObject, XMLParserDelegate {

    private let data: Data
    private var locations: [String] = []
    private var currentElement = ""
    private var currentText = ""

    init(data: Data) {
        self.data = data
    }

    func parse() -> [String] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return locations
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        if elementName == "loc" {
            currentText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "loc" {
            currentText += string
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "loc" {
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                locations.append(trimmed)
            }
        }
        currentElement = ""
    }
}

private struct SitemapDownloadResponse {
    let data: Data
    let response: HTTPURLResponse
}

private struct SitemapDownloadRequest: HTTPRequest {
    typealias ResponseType = SitemapDownloadResponse

    let endpoint: String
    let method: String = "GET"
    let body: Data? = nil
    let headers: [String: String] = [:]
    let params: [String: String] = [:]

    func decode(data: Data, response: URLResponse) throws -> SitemapDownloadResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CrawlPDFFetcherError.invalidResponse
        }
        return SitemapDownloadResponse(data: data, response: httpResponse)
    }
}
