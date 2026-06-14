//
//  DealScraperTests.swift
//  DealScraperTests
//
//  Created by Alexander Skorulis on 14/6/2026.
//

import Foundation
import Testing
@testable import DealScraper

private final class BundleToken {}

struct DealScraperTests {

    @Test func hiveCheeseburgerPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "hive_$10_cheese_burger")

        let texts = try await DealImageExtractor().extractTexts(from: imageURL)
        
        print(texts)
        
        let combined = texts.joined(separator: " ").lowercased()

        #expect(!texts.isEmpty)
        #expect(combined.contains("ten dollar"))
        #expect(combined.contains("cheeseburger"))
        #expect(combined.contains("tues"))
        #expect(combined.contains("dine in"))
        #expect(combined.contains("hive") || combined.contains("thehivebar"))
    }
    
    private func getURL(name: String, extension ext: String = "jpeg") throws -> URL {
        let bundle = Bundle(for: BundleToken.self)
        guard let imageURL = bundle.url(forResource: name, withExtension: ext) else {
            throw TestError.missingImage(name)
        }
        return imageURL
    }

}

private enum TestError: Error {
    case missingImage(String)
    
    fileprivate var localizedDescription: String {
        switch self {
        case .missingImage:
            return "Could not load image"
        }
    }
}
