//Created by Alex Skorulis on 23/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct ContactEmailSelectorTests {

    private let selector = ContactEmailSelector()

    @Test func returnsNilWhenEmpty() {
        #expect(selector.select(from: []) == nil)
    }

    @Test func selectsSingleEmail() {
        #expect(selector.select(from: ["hello@example.com"]) == "hello@example.com")
    }

    @Test func ignoresReservationsPrefix() {
        #expect(
            selector.select(from: [
                "reservations@venue.com",
                "hello@venue.com",
            ]) == "hello@venue.com"
        )
    }

    @Test func ignoresResDotPrefix() {
        #expect(
            selector.select(from: [
                "res.bookings@venue.com",
                "info@venue.com",
            ]) == "info@venue.com"
        )
    }

    @Test func ignoresPrefixesCaseInsensitively() {
        #expect(
            selector.select(from: [
                "Reservations@venue.com",
                "RES.team@venue.com",
            ]) == nil
        )
    }

    @Test func returnsNilWhenOnlyIgnoredEmailsRemain() {
        #expect(
            selector.select(from: [
                "reservations@venue.com",
                "res.desk@venue.com",
            ]) == nil
        )
    }

    @Test func picksDeterministicBestAmongCandidates() {
        #expect(
            selector.select(from: [
                "zebra@venue.com",
                "alpha@venue.com",
                "reservations@venue.com",
            ]) == "alpha@venue.com"
        )
    }
}
