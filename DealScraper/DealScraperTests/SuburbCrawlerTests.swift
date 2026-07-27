//Created by Alex Skorulis on 1/7/2026.

import ASKCore
import Foundation
import GRDB
import Knit
import Testing
@testable import DealScraper

struct SuburbCrawlerTests {

    private static let sampleResponse = """
    {
      "places": [
        {
          "id": "places/ChIJTest123",
          "displayName": {
            "text": "The Royal Pub",
            "languageCode": "en"
          },
          "location": {
            "latitude": -33.8688,
            "longitude": 151.2093
          },
          "formattedAddress": "123 King St, Newtown NSW 2042",
          "websiteUri": "https://theroyalpub.example.com",
          "types": ["bar", "point_of_interest"]
        },
        {
          "id": "places/ChIJTest456",
          "displayName": {
            "text": "Another Pub",
            "languageCode": "en"
          },
          "location": {
            "latitude": -33.8700,
            "longitude": 151.2100
          },
          "formattedAddress": "456 King St, Newtown NSW 2042",
          "websiteUri": "https://anotherpub.example.com",
          "types": ["bar", "point_of_interest"]
        }
      ],
      "nextPageToken": null
    }
    """

    @Test func searchQueryIncludesNameAndPostcode() {
        let suburb = Suburb(name: "Newtown", postcode: "2042", state: "NSW")
        #expect(SuburbCrawler.searchQuery(for: suburb) == "pubs in Newtown 2042")
    }

    @Test func searchQueryOmitsMissingPostcode() {
        let suburb = Suburb(name: "Newtown", postcode: nil, state: "NSW")
        #expect(SuburbCrawler.searchQuery(for: suburb) == "pubs in Newtown")
    }

    @Test @MainActor func crawlSavesVenuesAndUpdatesLastCrawlDate() async throws {
        let store = SQLStore.inMemory()
        let suburbId = try Self.insertSuburb(
            Suburb(name: "Newtown", postcode: "2042", state: "NSW"),
            in: store
        )

        let suburbRepository = SuburbRepository(store: store)
        let venueRepository = VenueRepository(store: store)
        let countryRepository = CountryRepository(store: store)
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        apiKeyStore.googlePlacesAPIKey = "google-test-key"

        var capturedQuery: String?
        var capturedRegionCode: String?
        let client = GooglePlacesClient { request in
            let body = try #require((request as? HTTPJSONRequest<GooglePlacesSearchResponse>)?.body)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            capturedQuery = json["textQuery"] as? String
            capturedRegionCode = json["regionCode"] as? String

            let responseData = Self.sampleResponse.data(using: .utf8)!
            return try JSONDecoder().decode(GooglePlacesSearchResponse.self, from: responseData)
        }

        let crawler = SuburbCrawler(
            googlePlacesClient: client,
            venueRepository: venueRepository,
            suburbRepository: suburbRepository,
            countryRepository: countryRepository,
            apiKeyStore: apiKeyStore
        )

        let suburb = try #require(try suburbRepository.find(id: suburbId))
        let results = try await crawler.crawl(suburb: suburb)

        #expect(capturedQuery == "pubs in Newtown 2042")
        #expect(capturedRegionCode == "AU")
        #expect(results.venuesFound == 2)
        #expect(results.newVenues == 2)
        #expect(results.droppedVenues == 0)

        let venues = try venueRepository.all()
        #expect(venues.count == 2)
        #expect(venues.allSatisfy { $0.suburbId == suburbId })

        let updatedSuburb = try #require(try suburbRepository.find(id: suburbId))
        #expect(updatedSuburb.lastCrawlDate != nil)
    }

    @Test @MainActor func crawlUsesNewZealandRegionCode() async throws {
        let store = SQLStore.inMemory()
        let nzId = try await #require(
            try store.dbQueue.read { db in
                try Country
                    .filter(Column("iso3") == Country.newZealand.iso3)
                    .fetchOne(db)?
                    .id
            }
        )
        let suburbId = try Self.insertSuburb(
            Suburb(
                countryId: nzId,
                name: "Fernhill",
                postcode: "9300",
                state: "Otago"
            ),
            in: store
        )

        let suburbRepository = SuburbRepository(store: store)
        let venueRepository = VenueRepository(store: store)
        let countryRepository = CountryRepository(store: store)
        let assembler = DealScraperAssembly.testing()
        let apiKeyStore = assembler.resolver.apiKeyStore()
        apiKeyStore.googlePlacesAPIKey = "google-test-key"

        var capturedRegionCode: String?
        let client = GooglePlacesClient { request in
            let body = try #require((request as? HTTPJSONRequest<GooglePlacesSearchResponse>)?.body)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            capturedRegionCode = json["regionCode"] as? String

            let responseData = Self.sampleResponse.data(using: .utf8)!
            return try JSONDecoder().decode(GooglePlacesSearchResponse.self, from: responseData)
        }

        let crawler = SuburbCrawler(
            googlePlacesClient: client,
            venueRepository: venueRepository,
            suburbRepository: suburbRepository,
            countryRepository: countryRepository,
            apiKeyStore: apiKeyStore
        )

        let suburb = try #require(try suburbRepository.find(id: suburbId))
        _ = try await crawler.crawl(suburb: suburb)

        #expect(capturedRegionCode == "NZ")
    }

    private static func insertSuburb(_ suburb: Suburb, in store: SQLStore) throws -> Int64 {
        try store.dbQueue.write { db in
            var mutable = suburb
            try mutable.insert(db)
            return try #require(mutable.id)
        }
    }
}
