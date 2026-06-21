//Created by Alex Skorulis on 22/6/2026.

import CoreGraphics
import Foundation
import Testing
@testable import DealScraper

struct PDFColumnLayoutTests {

    @Test func detectSingleColumnWhenRunsShareXPosition() {
        let runs = [
            PDFTextRun(text: "Line 1", bounds: CGRect(x: 72, y: 700, width: 100, height: 12), fontSize: 12, isBold: false, isItalic: false),
            PDFTextRun(text: "Line 2", bounds: CGRect(x: 74, y: 680, width: 100, height: 12), fontSize: 12, isBold: false, isItalic: false),
        ]

        let layout = PDFColumnLayout.detect(from: runs, pageWidth: 612)

        #expect(layout.anchors.count == 1)
    }

    @Test func detectTwoColumnsWhenRunsAreHorizontallySeparated() {
        let runs = [
            PDFTextRun(text: "Left", bounds: CGRect(x: 72, y: 700, width: 80, height: 12), fontSize: 12, isBold: false, isItalic: false),
            PDFTextRun(text: "Right", bounds: CGRect(x: 320, y: 700, width: 80, height: 12), fontSize: 12, isBold: false, isItalic: false),
        ]

        let layout = PDFColumnLayout.detect(from: runs, pageWidth: 612)

        #expect(layout.anchors.count == 2)
        #expect(layout.index(for: runs[0]) == 0)
        #expect(layout.index(for: runs[1]) == 1)
    }
}
