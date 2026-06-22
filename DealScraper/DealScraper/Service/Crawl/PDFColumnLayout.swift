//Created by Alex Skorulis on 22/6/2026.

import CoreGraphics
import Foundation

struct PDFColumnLayout: Equatable, Sendable {
    let anchors: [CGFloat]
    let gutter: CGFloat?

    static func detect(from runs: [PDFTextRun], pageWidth: CGFloat) -> PDFColumnLayout {
        guard !runs.isEmpty else {
            return PDFColumnLayout(anchors: [pageWidth / 2], gutter: nil)
        }

        let sortedMinX = runs.map(\.bounds.minX).sorted()
        let gapThreshold = max(50, pageWidth * 0.12)

        var clusters: [[CGFloat]] = [[sortedMinX[0]]]
        for x in sortedMinX.dropFirst() {
            if x - clusters[clusters.count - 1].last! > gapThreshold {
                clusters.append([x])
            } else {
                clusters[clusters.count - 1].append(x)
            }
        }

        let anchors = clusters.map { values in
            let sorted = values.sorted()
            let middle = sorted.count / 2
            if sorted.count.isMultiple(of: 2) {
                return (sorted[middle - 1] + sorted[middle]) / 2
            }
            return sorted[middle]
        }

        if anchors.count == 3 {
            let middleAnchor = anchors[1]
            if middleAnchor > pageWidth * 0.4, middleAnchor < pageWidth * 0.6 {
                return twoColumnLayout(left: anchors[0], right: anchors[2], gapThreshold: gapThreshold)
            }
        }

        if anchors.count == 2 {
            return twoColumnLayout(left: anchors[0], right: anchors[1], gapThreshold: gapThreshold)
        }

        return PDFColumnLayout(anchors: anchors, gutter: nil)
    }

    func index(for run: PDFTextRun) -> Int {
        if let gutter {
            return run.bounds.minX < gutter ? 0 : 1
        }

        let x = run.bounds.minX
        return anchors.enumerated().min(by: {
            abs($0.element - x) < abs($1.element - x)
        })?.offset ?? 0
    }

    private static func twoColumnLayout(
        left: CGFloat,
        right: CGFloat,
        gapThreshold: CGFloat
    ) -> PDFColumnLayout {
        PDFColumnLayout(anchors: [left, right], gutter: right - gapThreshold)
    }
}
