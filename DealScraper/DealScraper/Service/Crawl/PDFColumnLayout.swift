//Created by Alex Skorulis on 22/6/2026.

import CoreGraphics
import Foundation

struct PDFColumnLayout: Equatable, Sendable {
    let anchors: [CGFloat]

    static func detect(from runs: [PDFTextRun], pageWidth: CGFloat) -> PDFColumnLayout {
        guard !runs.isEmpty else {
            return PDFColumnLayout(anchors: [pageWidth / 2])
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

        return PDFColumnLayout(anchors: anchors)
    }

    func index(for run: PDFTextRun) -> Int {
        let x = run.bounds.midX
        return anchors.enumerated().min(by: {
            abs($0.element - x) < abs($1.element - x)
        })?.offset ?? 0
    }
}
