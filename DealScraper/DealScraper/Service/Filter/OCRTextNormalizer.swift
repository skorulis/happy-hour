//Created by Alex Skorulis on 13/7/2026.

import Foundation

/// Folds common OCR Latin/Cyrillic confusables so English regex matching stays reliable.
nonisolated enum OCRTextNormalizer {

    static func normalize(_ text: String) -> String {
        String(text.unicodeScalars.map { scalar in
            if let replacement = cyrillicLookalikes[scalar.value] {
                return Character(Unicode.Scalar(replacement)!)
            }
            return Character(scalar)
        })
    }

    /// Cyrillic letters Vision often substitutes for Latin lookalikes in English poster OCR.
    private static let cyrillicLookalikes: [UInt32: UInt32] = [
        0x0410: 0x41, // А → A
        0x0412: 0x42, // В → B
        0x0415: 0x45, // Е → E
        0x041A: 0x4B, // К → K
        0x041C: 0x4D, // М → M
        0x041D: 0x48, // Н → H
        0x041E: 0x4F, // О → O
        0x0420: 0x50, // Р → P
        0x0421: 0x43, // С → C
        0x0422: 0x54, // Т → T
        0x0425: 0x58, // Х → X
        0x0430: 0x61, // а → a
        0x0435: 0x65, // е → e
        0x043E: 0x6F, // о → o
        0x0440: 0x70, // р → p
        0x0441: 0x63, // с → c
        0x0442: 0x74, // т → t
        0x0443: 0x79, // у → y
        0x0445: 0x78, // х → x
        0x043D: 0x68, // н → h
    ]
}
