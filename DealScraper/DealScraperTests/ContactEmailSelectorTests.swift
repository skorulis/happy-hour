//Created by Alex Skorulis on 23/7/2026.

import Foundation
import Testing
@testable import DealScraper

struct ContactEmailSelectorTests {

    private let selector = ContactEmailSelector()

    @Test func returnsNilWhenEmpty() {
        #expect(selector.select(from: [:]) == nil)
    }

    @Test func selectsSingleEmail() {
        #expect(selector.select(from: ["hello@example.com": 1]) == "hello@example.com")
    }

    @Test func ignoresReservationsPrefix() {
        #expect(
            selector.select(from: [
                "reservations@venue.com": 5,
                "hello@venue.com": 1,
            ]) == "hello@venue.com"
        )
    }

    @Test func ignoresResDotPrefix() {
        #expect(
            selector.select(from: [
                "res.bookings@venue.com": 3,
                "info@venue.com": 1,
            ]) == "info@venue.com"
        )
    }

    @Test func ignoresPrefixesCaseInsensitively() {
        #expect(
            selector.select(from: [
                "Reservations@venue.com": 2,
                "RES.team@venue.com": 2,
            ]) == nil
        )
    }

    @Test func returnsNilWhenOnlyIgnoredEmailsRemain() {
        #expect(
            selector.select(from: [
                "reservations@venue.com": 1,
                "res.desk@venue.com": 1,
            ]) == nil
        )
    }

    @Test func selectsMostCommonPassingEmail() {
        #expect(
            selector.select(from: [
                "zebra@venue.com": 1,
                "alpha@venue.com": 4,
                "reservations@venue.com": 10,
            ]) == "alpha@venue.com"
        )
    }

    @Test func breaksTiesLexicographically() {
        #expect(
            selector.select(from: [
                "zebra@venue.com": 2,
                "alpha@venue.com": 2,
            ]) == "alpha@venue.com"
        )
    }

    @Test func prefersHigherRankedPrefixOverHigherCount() {
        #expect(
            selector.select(from: [
                "hello@venue.com": 10,
                "admin@venue.com": 1,
            ]) == "admin@venue.com"
        )
    }

    @Test func prefersHigherRankedPrefixCaseInsensitively() {
        #expect(
            selector.select(from: [
                "info@venue.com": 5,
                "Admin@venue.com": 1,
            ]) == "Admin@venue.com"
        )
    }

    @Test func prefersRankedPrefixOverUnranked() {
        #expect(
            selector.select(from: [
                "hello@venue.com": 3,
                "contact@venue.com": 1,
            ]) == "contact@venue.com"
        )
    }

    @Test func breaksEqualRankByCount() {
        #expect(
            selector.select(from: [
                "info@venue.com": 1,
                "contact@venue.com": 3,
            ]) == "contact@venue.com"
        )
    }
}
