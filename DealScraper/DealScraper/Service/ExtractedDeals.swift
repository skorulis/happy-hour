//Created by Alexander Skorulis on 14/6/2026.

import FoundationModels

@Generable
struct ExtractedDeal {
    @Guide(description: "Short headline or name for this promotion, e.g. 'Happy Hour', 'Ten Dollar Cheeseburger Tuesdays', or 'Sunday Roast'. Prefer large text on the poster.")
    var title: String

    @Guide(description: "Each line of supporting detail that belongs to this deal. A single promotion often spans multiple lines — put every distinct line here, such as prices, items, sizes, or conditions. Include price and item together when written that way, e.g. '$10 cheeseburger' or '$8 schooners of pale ale'.")
    var details: [String]

    @Guide(description: "Weekdays using lowercase full names: monday, tuesday, wednesday, thursday, friday, saturday, sunday. Expand abbreviations like Tues to tuesday.")
    var days: [String]

    @Guide(description: "Time expressions as written on the poster, e.g. '4 PM' or '4 PM - 6 PM' or '11:30'. Include all times mentioned for this deal.")
    var times: [String]
}

@Generable
struct ExtractedDealsResponse {
    @Guide(description: "One entry per distinct promotion schedule. Combine all detail lines sharing the same days and times into a single deal.")
    var deals: [ExtractedDeal]
}
