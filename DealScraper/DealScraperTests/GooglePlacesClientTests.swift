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
          "websiteUri": "https://theroyalpub.example.com",
          "types": ["bar", "point_of_interest"],
          "rating": 4.5,
          "regularOpeningHours": {
            "openNow": true,
            "weekdayDescriptions": [
              "Monday: 11:00 AM – 10:00 PM",
              "Tuesday: 11:00 AM – 10:00 PM",
              "Wednesday: 11:00 AM – 10:00 PM",
              "Thursday: 11:00 AM – 11:00 PM",
              "Friday: 11:00 AM – 11:00 PM",
              "Saturday: 10:00 AM – 11:00 PM",
              "Sunday: 10:00 AM – 10:00 PM"
            ],
            "periods": [
              {
                "open": { "day": 1, "hour": 11, "minute": 0 },
                "close": { "day": 1, "hour": 22, "minute": 0 }
              }
            ]
          }
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
        #expect(request.headers["X-Goog-FieldMask"] == GooglePlacesAPI.textSearchFieldMask)

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
        #expect(response.places.first?.websiteUri == "https://theroyalpub.example.com")
        #expect(response.places.first?.rating == 4.5)
        #expect(response.places.first?.regularOpeningHours?.openNow == true)
        #expect(response.places.first?.regularOpeningHours?.weekdayDescriptions?.count == 7)
        #expect(response.places.first?.regularOpeningHours?.periods?.first?.open?.hour == 11)
        #expect(response.nextPageToken == "next-page-token")
    }

    @Test func fieldMaskIncludesRegularOpeningHours() {
        #expect(GooglePlacesAPI.placeFieldMask.contains("places.regularOpeningHours"))
        #expect(GooglePlacesAPI.textSearchFieldMask.contains("places.regularOpeningHours"))
        #expect(GooglePlacesAPI.nearbySearchFieldMask.contains("places.regularOpeningHours"))
    }

    @Test func fieldMaskIncludesBusinessStatus() {
        #expect(GooglePlacesAPI.placeFieldMask.contains("places.businessStatus"))
        #expect(GooglePlacesAPI.textSearchFieldMask.contains("places.businessStatus"))
        #expect(GooglePlacesAPI.nearbySearchFieldMask.contains("places.businessStatus"))
    }

    @Test func fieldMaskIncludesRating() {
        #expect(GooglePlacesAPI.placeFieldMask.contains("places.rating"))
        #expect(GooglePlacesAPI.textSearchFieldMask.contains("places.rating"))
        #expect(GooglePlacesAPI.nearbySearchFieldMask.contains("places.rating"))
    }

    @Test func searchTextAllPagesFetchesSubsequentPages() async throws {
        var capturedRequests: [any HTTPRequest] = []

        let client = GooglePlacesClient { request in
            capturedRequests.append(request)
            let httpRequest = try #require(request as? HTTPJSONRequest<GooglePlacesSearchResponse>)
            let body = try #require(httpRequest.body)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            let pageToken = json["pageToken"] as? String

            switch pageToken {
            case nil:
                return GooglePlacesSearchResponse(
                    places: [Self.samplePlace(id: "places/page-1")],
                    nextPageToken: "token-2"
                )
            case "token-2":
                return GooglePlacesSearchResponse(
                    places: [Self.samplePlace(id: "places/page-2")],
                    nextPageToken: "token-3"
                )
            case "token-3":
                return GooglePlacesSearchResponse(
                    places: [Self.samplePlace(id: "places/page-3")],
                    nextPageToken: nil
                )
            default:
                Issue.record("Unexpected page token: \(pageToken ?? "nil")")
                return GooglePlacesSearchResponse(places: [], nextPageToken: nil)
            }
        }

        let response = try await client.searchTextAllPages(
            apiKey: "google-test-key",
            textQuery: "pubs in Sydney",
            includedType: "bar",
            regionCode: "AU"
        )

        #expect(capturedRequests.count == 3)
        #expect(response.places.count == 3)
        #expect(response.places.map(\.id) == ["places/page-1", "places/page-2", "places/page-3"])
        #expect(response.nextPageToken == nil)

        let firstBody = try #require(
            (capturedRequests[0] as? HTTPJSONRequest<GooglePlacesSearchResponse>)?.body
        )
        let firstJSON = try #require(JSONSerialization.jsonObject(with: firstBody) as? [String: Any])
        #expect(firstJSON["pageToken"] == nil || firstJSON["pageToken"] is NSNull)

        let secondBody = try #require(
            (capturedRequests[1] as? HTTPJSONRequest<GooglePlacesSearchResponse>)?.body
        )
        let secondJSON = try #require(JSONSerialization.jsonObject(with: secondBody) as? [String: Any])
        #expect(secondJSON["pageToken"] as? String == "token-2")

        let thirdBody = try #require(
            (capturedRequests[2] as? HTTPJSONRequest<GooglePlacesSearchResponse>)?.body
        )
        let thirdJSON = try #require(JSONSerialization.jsonObject(with: thirdBody) as? [String: Any])
        #expect(thirdJSON["pageToken"] as? String == "token-3")
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
        #expect(request.headers["X-Goog-FieldMask"] == GooglePlacesAPI.nearbySearchFieldMask)
        #expect(request.headers["X-Goog-FieldMask"]?.contains("nextPageToken") == false)

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

private extension GooglePlacesClientTests {
    static func samplePlace(id: String) -> GooglePlace {
        GooglePlace(
            id: id,
            displayName: .init(text: "The Royal Pub", languageCode: "en"),
            location: .init(latitude: -33.8688, longitude: 151.2093),
            formattedAddress: "123 George St, Sydney NSW 2000",
            websiteUri: "https://theroyalpub.example.com",
            types: ["bar", "point_of_interest"]
        )
    }
}

private final class RequestCapture {
    var request: (any HTTPRequest)?
}
