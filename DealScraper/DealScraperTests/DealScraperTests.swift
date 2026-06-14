//  Created by Alexander Skorulis on 14/6/2026.

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

    @Test func hiveBarHappyHourPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "hive_bar_happy_hour")

        let texts = try await DealImageExtractor().extractTexts(from: imageURL)
        let combined = texts.joined(separator: " ").lowercased()

        #expect(!texts.isEmpty)
        #expect(combined.contains("happy hour"))
        #expect(combined.contains("hive"))
        #expect(combined.contains("schooner") || combined.contains("reckless") || combined.contains("pale ale"))
        #expect(combined.contains("tues") || combined.contains("thurs"))
        #expect(combined.contains("4pm") || combined.contains("4 pm"))
    }

    @Test func kurrajongRoastPosterExtractsExpectedText() async throws {
        let imageURL = try getURL(name: "kurrajon_roast")

        let texts = try await DealImageExtractor().extractTexts(from: imageURL)
        let combined = texts.joined(separator: " ").lowercased()

        #expect(!texts.isEmpty)
        #expect(combined.contains("sunday roast"))
        #expect(combined.contains("$39"))
        #expect(combined.contains("kurrajong") || combined.contains("kurrajon"))
        #expect(combined.contains("11:30"))
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
