//Created by Alexander Skorulis on 14/6/2026.

import FoundationModels

@Generable
struct ExtractedDeal {
    @Guide(description: "Exactly one input line that is the promotion headline. Must match an input line character-for-character. Do not combine, merge, reword, or change capitalization.")
    var title: String

    @Guide(description: "Input lines that are supporting detail for this deal. Each entry must match an input line character-for-character. Do not merge lines, paraphrase, or create new text.")
    var details: [String]

    @Guide(description: "Input line(s) that mention which days the deal applies to. Each entry must match an input line character-for-character. Do not normalize or rewrite day names.")
    var days: [String]

    @Guide(description: "Input line(s) that mention when the deal applies. Each entry must match an input line character-for-character. If no input line mentions a time, use exactly ['all day'].")
    var times: [String]
}

@Generable
struct ExtractedDealsResponse {
    @Guide(description: "One entry per distinct promotion schedule. Categorize input lines into each deal without rewriting them.")
    var deals: [ExtractedDeal]
}
