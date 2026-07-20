//Created by Alex Skorulis on 19/6/2026.

import Foundation
@testable import DealScraper

extension ProcessedDealPayload {
    static func fixture(named name: String) throws -> ProcessedDealPayload {
        let bundle = Bundle(for: BundleToken.self)
        let resourceName = name.hasPrefix("processed-") ? name : "processed-\(name)"
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw TestError.missingFixture(resourceName)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ProcessedDealPayload.self, from: data)
    }
}

extension DealExtractionPayload {
    static func fixture(named name: String) throws -> DealExtractionPayload {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw TestError.missingFixture(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(DealExtractionPayload.self, from: data)
    }
}

private final class BundleToken {}

private enum TestError: Error {
    case missingFixture(String)
}
