//Created by Alex Skorulis on 27/7/2026.

import Foundation

struct ParsedAddress: Equatable {
    let suburb: String
    let state: String
    let postcode: String
}

protocol AddressParser {
    func parse(from formattedAddress: String) -> ParsedAddress?
}
