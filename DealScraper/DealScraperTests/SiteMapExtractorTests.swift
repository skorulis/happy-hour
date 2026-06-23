//Created by Alex Skorulis on 23/6/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

private func sitemapXMLResponse(data: Data, url: URL) -> (Data, URLResponse) {
    (
        data,
        HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/xml"]
        )!
    )
}

@MainActor
struct SiteMapExtractorTests {

    private let baseURL = URL(string: "https://www.kegandbrew.com.au")!

    @Test func parsesSitemapIndexAndNestedUrlset() async throws {
        let indexXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <sitemap>
            <loc>https://www.kegandbrew.com.au/pages-sitemap.xml</loc>
          </sitemap>
        </sitemapindex>
        """.data(using: .utf8)!

        let pagesXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <url><loc>https://www.kegandbrew.com.au/happyhour</loc></url>
          <url><loc>https://www.kegandbrew.com.au/contact</loc></url>
        </urlset>
        """.data(using: .utf8)!

        let extractor = SiteMapExtractor(
            urlSession: FakeURLSession { request in
                let url = try #require(request.url)
                switch url.lastPathComponent {
                case "sitemap.xml":
                    return sitemapXMLResponse(data: indexXML, url: url)
                case "pages-sitemap.xml":
                    return sitemapXMLResponse(data: pagesXML, url: url)
                default:
                    Issue.record("Unexpected URL: \(url)")
                    throw CrawlPDFFetcherError.invalidResponse
                }
            }
        )

        let result = await extractor.extract(baseURL: baseURL)

        #expect(result.webpageURLs.count == 1)
        #expect(result.webpageURLs[0].path == "/happyhour")
        #expect(result.imageURLs.isEmpty)
        #expect(result.pdfURLs.isEmpty)
    }

    @Test func classifiesImagesAndWebpages() async throws {
        let sitemapXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <url><loc>https://www.kegandbrew.com.au/happyhour</loc></url>
          <url><loc>https://www.kegandbrew.com.au/media/promo.jpg</loc></url>
        </urlset>
        """.data(using: .utf8)!

        let extractor = SiteMapExtractor(
            urlSession: FakeURLSession { request in
                let url = try #require(request.url)
                return sitemapXMLResponse(data: sitemapXML, url: url)
            }
        )

        let result = await extractor.extract(baseURL: baseURL)

        #expect(result.webpageURLs.count == 1)
        #expect(result.webpageURLs[0].path == "/happyhour")
        #expect(result.imageURLs.count == 1)
        #expect(result.imageURLs[0].path == "/media/promo.jpg")
    }

    @Test func skipsCrossOriginURLs() async throws {
        let sitemapXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <url><loc>https://www.kegandbrew.com.au/happyhour</loc></url>
          <url><loc>https://other.example.com/happyhour</loc></url>
        </urlset>
        """.data(using: .utf8)!

        let extractor = SiteMapExtractor(
            urlSession: FakeURLSession { request in
                let url = try #require(request.url)
                return sitemapXMLResponse(data: sitemapXML, url: url)
            }
        )

        let result = await extractor.extract(baseURL: baseURL)

        #expect(result.webpageURLs.count == 1)
        #expect(result.webpageURLs[0].host() == "www.kegandbrew.com.au")
    }

    @Test func filtersWebpagesWithPageLinkFilter() async throws {
        let sitemapXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <url><loc>https://www.kegandbrew.com.au/happyhour</loc></url>
          <url><loc>https://www.kegandbrew.com.au/contact</loc></url>
        </urlset>
        """.data(using: .utf8)!

        let extractor = SiteMapExtractor(
            urlSession: FakeURLSession { request in
                let url = try #require(request.url)
                return sitemapXMLResponse(data: sitemapXML, url: url)
            }
        )

        let result = await extractor.extract(baseURL: baseURL)

        #expect(result.webpageURLs.map(\.path) == ["/happyhour"])
    }

    @Test func returnsEmptyOnFetchFailure() async {
        let extractor = SiteMapExtractor(
            urlSession: FakeURLSession { request in
                let url = try #require(request.url)
                return (
                    Data(),
                    HTTPURLResponse(
                        url: url,
                        statusCode: 404,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                )
            }
        )

        let result = await extractor.extract(baseURL: baseURL)

        #expect(result.webpageURLs.isEmpty)
        #expect(result.imageURLs.isEmpty)
        #expect(result.pdfURLs.isEmpty)
    }

    @Test func deduplicatesURLs() async throws {
        let sitemapXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <url><loc>https://www.kegandbrew.com.au/happyhour</loc></url>
          <url><loc>https://www.kegandbrew.com.au/happyhour/</loc></url>
        </urlset>
        """.data(using: .utf8)!

        let extractor = SiteMapExtractor(
            urlSession: FakeURLSession { request in
                let url = try #require(request.url)
                return sitemapXMLResponse(data: sitemapXML, url: url)
            }
        )

        let result = await extractor.extract(baseURL: baseURL)

        #expect(result.webpageURLs.count == 1)
    }
}
