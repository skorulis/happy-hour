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
        let allText = blocks.map(\.fullText).joined(separator: "\n")

        // Short day sections fold into the preceding "Specials" block.
        #expect(blocks.count == 1)
        #expect(blocks[0].title == "Specials")
        #expect(allText.contains("Monday"))
        #expect(allText.contains("Steak $20"))
        #expect(allText.contains("Tuesday"))
        #expect(allText.contains("Tacos $18"))
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

        // Both blocks are under the short-block limit, so MONDAY folds into HAPPY HOUR.
        #expect(blocks.count == 1)
        #expect(blocks[0].title == "HAPPY HOUR")
        #expect(blocks[0].text.contains("$7 beers"))
        #expect(blocks[0].text.contains("MONDAY"))
        #expect(blocks[0].text.contains("$20 steak"))
    }

    @Test func mergesShortFragmentedHeadings() throws {
        let html = """
        <html>
        <body>
          <main>
            <h2>OUR FOOD MENU</h2>
            <h2>H A P P Y&nbsp; &nbsp; H O U R</h2>
            <h3>5 P M - 7 P M</h3>
            <h4>D A I L Y</h4>
            <p><strong>HOURS</strong></p>
            <p>WEDNESDAY - SUNDAY</p>
            <p>4PM - LATE</p>
          </main>
        </body>
        </html>
        """

        let blocks = try grouper.group(html: html, pageURL: pageURL)
        let combined = blocks.map(\.fullText).joined(separator: "\n")

        #expect(blocks.count == 1)
        #expect(combined.contains("H A P P Y H O U R"))
        #expect(combined.contains("5 P M - 7 P M"))
        #expect(combined.contains("D A I L Y"))
        #expect(combined.contains("WEDNESDAY - SUNDAY"))
        #expect(combined.contains("4PM - LATE"))
        #expect(DealTextFilter().isValidDeal(combined))
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
        let allText = blocks.map(\.fullText).joined(separator: " ")

        // Short heading-only blocks fold into the preceding intro text.
        #expect(allText.contains("HAPPY HOUR"))
        #expect(allText.contains("4PM TO 6PM EVERYDAY"))
        #expect(allText.contains("$6 SELECTED TAP BEER"))
        #expect(allText.contains("Paddy's Markets"))
        #expect(allText.contains("STELLA SPECIAL"))
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
        let allText = blocks.map(\.fullText).joined(separator: " ")

        #expect(titles.contains("A Local Gem in the Heart of Surry Hills"))
        #expect(titles.contains("HAPPY HOUR"))
        // Short day headings fold into neighboring blocks but remain in the text.
        #expect(allText.contains("MONDAY"))
        #expect(allText.contains("TUESDAY"))
        #expect(allText.contains("WEDNESDAY"))
        #expect(allText.contains("THURSDAY"))
        #expect(allText.contains("FRIDAYS"))
        #expect(allText.contains("SATURDAY"))
        #expect(allText.contains("SUNDAY"))
        #expect(allText.contains("1870"))
        #expect(allText.contains("$7 Tap Beers"))
        #expect(allText.contains("$20 RUMP STEAK"))
        #expect(!allText.contains("hello@thestrawberry.com.au"))
        #expect(!allText.contains("Opening Hours"))
        #expect(!allText.contains("Home"))
    }
}
