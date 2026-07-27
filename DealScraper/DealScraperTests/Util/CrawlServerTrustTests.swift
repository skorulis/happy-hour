// Created by Alex Skorulis on 27/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct CrawlServerTrustTests {

    @Test func wwwStrippedURLRemovesWWWPrefix() {
        let url = URL(string: "https://www.treehousewanaka.nz/menu")!
        let stripped = CrawlServerTrust.wwwStrippedURL(from: url)

        #expect(stripped?.absoluteString == "https://treehousewanaka.nz/menu")
    }

    @Test func wwwStrippedURLReturnsNilWithoutWWW() {
        let url = URL(string: "https://treehousewanaka.nz/")!
        #expect(CrawlServerTrust.wwwStrippedURL(from: url) == nil)
    }

    @Test func isCertificateErrorDetectsNSURLError() {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorServerCertificateUntrusted,
            userInfo: [NSLocalizedDescriptionKey: "The certificate for this server is invalid."]
        )
        #expect(CrawlServerTrust.isCertificateError(error))
    }

    @Test func isCertificateErrorDetectsMessage() {
        let error = WebPageLoaderError.navigationFailed(
            "The certificate for this server is invalid. You might be connecting to a server that is pretending to be 'www.treehousewanaka.nz'."
        )
        #expect(CrawlServerTrust.isCertificateError(error))
    }
}
