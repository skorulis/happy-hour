//Created by Alex Skorulis on 29/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct VenueTests {

    @Test func needsCrawlHeroImageSelectionWhenMissingOrEmpty() {
        #expect(makeVenue(heroImage: nil).needsCrawlHeroImageSelection)
        #expect(makeVenue(heroImage: "").needsCrawlHeroImageSelection)
        #expect(makeVenue(heroImage: "   ").needsCrawlHeroImageSelection)
    }

    @Test func needsCrawlHeroImageSelectionWhenLegacyFileURL() {
        let local = URL(fileURLWithPath: "/tmp/DealScraper/hero-images/1.jpg")
        #expect(makeVenue(heroImage: local.absoluteString).needsCrawlHeroImageSelection)
    }

    @Test func needsCrawlHeroImageSelectionIsFalseForRemoteURL() {
        #expect(
            makeVenue(heroImage: "https://example.com/hero.jpg")
                .needsCrawlHeroImageSelection == false
        )
    }

    private func makeVenue(heroImage: String?) -> Venue {
        Venue(
            googleMapId: "places/ChIJHero",
            name: "Hero Pub",
            lat: -33.8688,
            lng: 151.2093,
            heroImage: heroImage,
            json: "{}"
        )
    }
}
