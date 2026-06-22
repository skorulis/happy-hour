//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Testing
@testable import DealScraper

struct ContentBlockGrouperTests {

    private let grouper = ContentBlockGrouper()
    private let pageURL = URL(string: "https://www.thestrawbs.com.au/")!

    @Test func stripsNavAndFooter() throws {
        let html = """
        <html>
        <body>
          <nav><a href="/menu">Menu</a></nav>
          <main>
            <h2>About Us</h2>
            <p>Welcome to our pub.</p>
          </main>
          <footer><p>Contact Us - hello@example.com</p></footer>
        </body>
        </html>
        """

        let blocks = try grouper.group(html: html, pageURL: pageURL)

        let allText = blocks.map { "\($0.title ?? "") \($0.text)" }.joined(separator: " ")
        #expect(allText.contains("About Us"))
        #expect(allText.contains("Welcome to our pub"))
        #expect(!allText.contains("Menu"))
        #expect(!allText.contains("Contact Us"))
    }

    @Test func splitsOnHeadings() throws {
        let html = """
        <html>
        <body>
          <main>
            <h2>Specials</h2>
            <h3>Monday</h3>
            <p>Steak $20</p>
            <h3>Tuesday</h3>
            <p>Tacos $18</p>
          </main>
        </body>
        </html>
        """

        let blocks = try grouper.group(html: html, pageURL: pageURL)
        let titles = blocks.compactMap(\.title)

        #expect(titles == ["Specials", "Monday", "Tuesday"])
        #expect(blocks[1].text.contains("Steak $20"))
        #expect(blocks[2].text.contains("Tacos $18"))
    }

    @Test func capturesLinksInBlock() throws {
        let html = """
        <html>
        <body>
          <main>
            <h2>Book</h2>
            <p>Reserve your table.</p>
            <a href="/bookings">Book now</a>
          </main>
        </body>
        </html>
        """

        let blocks = try grouper.group(html: html, pageURL: pageURL)

        #expect(blocks.count == 1)
        #expect(blocks[0].title == "Book")
        #expect(blocks[0].text.contains("Reserve your table"))
        #expect(blocks[0].links.count == 1)
        #expect(blocks[0].links[0].text == "Book now")
        #expect(blocks[0].links[0].url.absoluteString == "https://www.thestrawbs.com.au/bookings")
    }

    @Test func handlesUppercaseSubheadings() throws {
        let html = """
        <html>
        <body>
          <main>
            <p>HAPPY HOUR</p>
            <p>$7 beers</p>
            <p>MONDAY</p>
            <p>$20 steak</p>
          </main>
        </body>
        </html>
        """

        let blocks = try grouper.group(html: html, pageURL: pageURL)
        let titles = blocks.compactMap(\.title)

        #expect(titles == ["HAPPY HOUR", "MONDAY"])
        #expect(blocks[0].text.contains("$7 beers"))
        #expect(blocks[1].text.contains("$20 steak"))
    }

    @Test func wixInfoMemberStructure() throws {
        let html = """
        <html>
        <body>
          <div id="PAGES_CONTAINER">
            <div>
              <div class="info-member info-element-title" data-hook="item-title">
                <span>HAPPY HOUR</span>
              </div>
              <div class="info-member info-element-description" data-hook="item-description">
                <span>$7 Tap Beers, Wines &amp; Spirits. $7.50 Craft Beers &amp; $10.50 Pints!</span>
                <span>MON to FRI....4pm-6pm</span>
              </div>
            </div>
          </div>
        </body>
        </html>
        """

        let blocks = try grouper.group(html: html, pageURL: pageURL)
        let happyHour = blocks.first { $0.title == "HAPPY HOUR" }

        #expect(happyHour != nil)
        #expect(happyHour?.text.contains("$7 Tap Beers") == true)
        #expect(happyHour?.text.contains("MON to FRI") == true)
    }

    @Test func wixGalleryJSONFallbackFillsMissingDescription() throws {
        let html = """
        <html>
        <body>
          <main>
            <div class="info-member info-element-title" data-hook="item-title">
              <span>HAPPY HOUR</span>
            </div>
            <div class="info-member info-element-description" data-hook="item-description"></div>
            <script type="application/json">
            {"items":[{"description":"$7 Tap Beers, Wines & Spirits. $7.50 Craft Beers & $10.50 Pints!\\nMON to FRI....4pm-6pm ","title":"HAPPY HOUR"}]}
            </script>
          </main>
        </body>
        </html>
        """

        let blocks = try grouper.group(html: html, pageURL: pageURL)
        let happyHour = blocks.first { $0.title == "HAPPY HOUR" }

        #expect(happyHour != nil)
        #expect(happyHour?.text.contains("$7 Tap Beers") == true)
        #expect(happyHour?.text.contains("MON to FRI") == true)
    }

    @Test func elementorPageUsesContentRootNotNestedArticles() throws {
        let html = """
        <html>
        <body>
          <header><nav><a href="/">HOME</a></nav></header>
          <div id="content" class="site-content">
            <div data-elementor-type="single" class="elementor elementor-location-single">
              <p>Nestled above Sydney's famous Paddy's Markets.</p>
              <h4>HAPPY HOUR</h4>
              <h2>4PM TO 6PM EVERYDAY</h2>
              <h2>$6 SELECTED TAP BEER, HOUSE WINE &amp; SPIRITS</h2>
              <h1>WHAT'S ON</h1>
              <article class="elementor-post elementor-grid-item">
                <h3><a href="/whatson/stella-special/">STELLA SPECIAL</a></h3>
                <p>Indulge in a delightful treat at our pub with our</p>
              </article>
            </div>
          </div>
          <footer><p>Contact us</p></footer>
        </body>
        </html>
        """

        let pageURL = URL(string: "https://www.marketcitytavernsydney.com.au/")!
        let blocks = try grouper.group(html: html, pageURL: pageURL)
        let titles = blocks.compactMap(\.title)
        let allText = blocks.map { "\($0.title ?? "") \($0.text)" }.joined(separator: " ")

        #expect(titles.contains("HAPPY HOUR"))
        #expect(titles.contains("4PM TO 6PM EVERYDAY"))
        #expect(allText.contains("$6 SELECTED TAP BEER"))
        #expect(allText.contains("Paddy's Markets"))
        #expect(titles.contains("STELLA SPECIAL"))
        #expect(!allText.contains("HOME"))
        #expect(!allText.contains("Contact us"))
    }

    @Test func thestrawbsFixture() throws {
        let html = """
        <html>
        <body>
          <div id="SITE_HEADER">
            <nav>
              <a href="/">Home</a>
              <a href="/menu">Menu</a>
            </nav>
          </div>
          <div id="PAGES_CONTAINER">
            <h2>A Local Gem in the Heart of Surry Hills</h2>
            <p>Right in the heart of Surry Hills, The Strawberry has been serving locals since 1870.</p>
            <p>HAPPY HOUR</p>
            <p>$7 Tap Beers, Wines &amp; Spirits. MON to FRI....4pm-6pm</p>
            <p>MONDAY</p>
            <p>$20 RUMP STEAK</p>
            <p>TUESDAY</p>
            <p>TACOS</p>
            <p>For $18 you pick from Grilled Chicken, Pulled Beef &amp; Fish Tacos</p>
            <p>WEDNESDAY</p>
            <p>$18 Schnitzels</p>
            <p>THURSDAY</p>
            <p>CURRY SPECIAL</p>
            <p>FRIDAYS</p>
            <p>TRAD FRIDAYS</p>
            <p>SATURDAY</p>
            <p>$13 COCKTAIL HAPPY HOUR</p>
            <p>SUNDAY</p>
            <p>Sip $10 SPRITZ all day, every Sunday at The Strawberry</p>
          </div>
          <div id="SITE_FOOTER">
            <h3>Contact Us</h3>
            <p>hello@thestrawberry.com.au</p>
            <h3>Opening Hours</h3>
            <p>Monday to Saturday: 9am - 6am</p>
          </div>
        </body>
        </html>
        """

        let blocks = try grouper.group(html: html, pageURL: pageURL)
        let titles = blocks.compactMap(\.title)

        #expect(titles.contains("A Local Gem in the Heart of Surry Hills"))
        #expect(titles.contains("HAPPY HOUR"))
        #expect(titles.contains("MONDAY"))
        #expect(titles.contains("TUESDAY"))
        #expect(titles.contains("WEDNESDAY"))
        #expect(titles.contains("THURSDAY"))
        #expect(titles.contains("FRIDAYS"))
        #expect(titles.contains("SATURDAY"))
        #expect(titles.contains("SUNDAY"))

        let allText = blocks.map { "\($0.title ?? "") \($0.text)" }.joined(separator: " ")
        #expect(allText.contains("1870"))
        #expect(allText.contains("$7 Tap Beers"))
        #expect(allText.contains("$20 RUMP STEAK"))
        #expect(!allText.contains("hello@thestrawberry.com.au"))
        #expect(!allText.contains("Opening Hours"))
        #expect(!allText.contains("Home"))
    }
}
