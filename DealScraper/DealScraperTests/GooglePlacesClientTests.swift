//Created by Alex Skorulis on 15/6/2026.

import ASKCore
import Foundation
import Testing
@testable import DealScraper

@MainActor
struct GooglePlacesClientTests {

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
          "formattedAddress": "123 George St, Sydney NSW 2000",
          "types": ["bar", "point_of_interest"]
        }
      ],
      "nextPageToken": "next-page-token"
    }
    """

    @Test func searchTextSendsPostWithApiKeyAndFieldMask() async throws {
        let captured = RequestCapture()

        let client = GooglePlacesClient { request in
            captured.request = request
            let responseData = Self.sampleResponse.data(using: .utf8)!
            return try JSONDecoder().decode(GooglePlacesSearchResponse.self, from: responseData)
        }

        let response = try await client.searchText(
            apiKey: "google-test-key",
            textQuery: "pubs in Sydney",
            includedType: "bar",
            regionCode: "AU"
        )

        let request = try #require(captured.request as? HTTPJSONRequest<GooglePlacesSearchResponse>)
        #expect(request.endpoint == "https://places.googleapis.com/v1/places:searchText")
        #expect(request.method == "POST")
        #expect(request.headers["X-Goog-Api-Key"] == "google-test-key")
        #expect(request.headers["X-Goog-FieldMask"] == GooglePlacesAPI.defaultFieldMask)

        let body = try #require(request.body)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["textQuery"] as? String == "pubs in Sydney")
        #expect(json["includedType"] as? String == "bar")
        #expect(json["regionCode"] as? String == "AU")
        #expect(json["pageSize"] as? Int == 20)

        #expect(response.places.count == 1)
        #expect(response.places.first?.id == "places/ChIJTest123")
        #expect(response.places.first?.displayName.text == "The Royal Pub")
        #expect(response.places.first?.location.latitude == -33.8688)
        #expect(response.nextPageToken == "next-page-token")
    }

    @Test func searchNearbySendsCircleRestriction() async throws {
        let captured = RequestCapture()

        let client = GooglePlacesClient { request in
            captured.request = request
            return GooglePlacesSearchResponse(places: [], nextPageToken: nil)
        }

        _ = try await client.searchNearby(
            apiKey: "google-test-key",
            latitude: -33.8688,
            longitude: 151.2093,
            radiusMeters: 1500,
            includedTypes: ["bar"]
        )

        let request = try #require(captured.request as? HTTPJSONRequest<GooglePlacesSearchResponse>)
        #expect(request.endpoint == "https://places.googleapis.com/v1/places:searchNearby")

        let body = try #require(request.body)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["includedTypes"] as? [String] == ["bar"])
        #expect(json["maxResultCount"] as? Int == 20)

        let locationRestriction = try #require(json["locationRestriction"] as? [String: Any])
        let circle = try #require(locationRestriction["circle"] as? [String: Any])
        let center = try #require(circle["center"] as? [String: Any])
        #expect(center["latitude"] as? Double == -33.8688)
        #expect(center["longitude"] as? Double == 151.2093)
        #expect(circle["radius"] as? Double == 1500)
    }

    @Test func throwsAPIErrorOnNonSuccessStatus() async throws {
        let client = GooglePlacesClient { _ in
            throw GooglePlacesAPI.Error.apiError(statusCode: 403, message: "API key not valid")
        }

        do {
            _ = try await client.searchText(
                apiKey: "bad-key",
                textQuery: "pubs in Sydney"
            )
            Issue.record("Expected API error")
        } catch let error as GooglePlacesAPI.Error {
            guard case let .apiError(statusCode, message) = error else {
                Issue.record("Unexpected error type: \(error)")
                return
            }
            #expect(statusCode == 403)
            #expect(message == "API key not valid")
        }
    }
}

private final class RequestCapture {
    var request: (any HTTPRequest)?
}
