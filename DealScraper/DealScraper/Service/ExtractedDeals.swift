//Created by Alexander Skorulis on 14/6/2026.

import FoundationModels

@Generable
struct ExtractedDeal {
    @Guide(description: "Products or offers in this promotion. Include price and item name together, e.g. '$10 cheeseburger' or 'Sunday roast $39'.")
    var products: [String]

    @Guide(description: "Weekdays using lowercase full names: monday, tuesday, wednesday, thursday, friday, saturday, sunday. Expand abbreviations like Tues to tuesday.")
    var days: [String]

    @Guide(description: "Time expressions as written on the poster, e.g. '4 PM' or '4 PM - 6 PM' or '11:30'. Include all times mentioned for this deal.")
    var times: [String]
}

@Generable
struct ExtractedDealsResponse {
    @Guide(description: "One entry per distinct promotion schedule. Combine all products sharing the same days and times into a single deal.")
    var deals: [ExtractedDeal]
}
