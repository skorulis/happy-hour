//Created by Alex Skorulis on 19/6/2026.

import Foundation
import Knit
import KnitMacros
import PDFKit

@MainActor
@Observable
final class ApprovalViewModel {

    enum PreviewState: Equatable {
        case idle
        case loading
        case ready(PreviewContent)
        case failed(String)
    }

    enum PreviewContent: Equatable {
        case image(URL)
        case pdf(PDFDocument)
        case webpage(URL)

        static func == (lhs: PreviewContent, rhs: PreviewContent) -> Bool {
            switch (lhs, rhs) {
            case let (.image(lhsURL), .image(rhsURL)):
                return lhsURL == rhsURL
            case let (.pdf(lhsDoc), .pdf(rhsDoc)):
                return lhsDoc.documentURL == rhsDoc.documentURL
            case let (.webpage(lhsURL), .webpage(rhsURL)):
                return lhsURL == rhsURL
            default:
                return false
            }
        }
    }

    private(set) var pendingSources: [DealSource] = []
    private(set) var venueNames: [Int64: String] = [:]
    private(set) var previewState: PreviewState = .idle

    private let dealSourceRepository: DealSourceRepository
    private let venueRepository: VenueRepository
    private let pdfFetcher: CrawlPDFFetcher
    private let experimentViewModel: ExperimentViewModel

    private var previewTask: Task<Void, Never>?

    @Resolvable<Resolver>
    init(
        dealSourceRepository: DealSourceRepository,
        venueRepository: VenueRepository,
        pdfFetcher: CrawlPDFFetcher,
        experimentViewModel: ExperimentViewModel
    ) {
        self.dealSourceRepository = dealSourceRepository
        self.venueRepository = venueRepository
        self.pdfFetcher = pdfFetcher
        self.experimentViewModel = experimentViewModel
    }

    var currentSource: DealSource? {
        pendingSources.first
    }

    var remainingCount: Int {
        pendingSources.count
    }

    var currentSourceURL: String? {
        guard let source = currentSource else { return nil }
        switch source.type {
        case .image, .pdf:
            return source.url
        case .webpage:
            return source.sourceURL
        }
    }

    func sendToExperiment() {
        guard let url = currentSourceURL else { return }
        experimentViewModel.load(urlString: url)
    }

    func load() {
        previewTask?.cancel()
        previewTask = nil

        do {
            pendingSources = try dealSourceRepository.findNew()
            venueNames = Dictionary(
                uniqueKeysWithValues: try venueRepository.all().compactMap { venue in
                    guard let id = venue.id else { return nil }
                    return (id, venue.name)
                }
            )
            loadPreview()
        } catch {
            pendingSources = []
            venueNames = [:]
            previewState = .failed(error.localizedDescription)
        }
    }

    func decide(status: DealStatus) {
        guard let source = currentSource, let id = source.id else { return }

        do {
            try dealSourceRepository.updateStatus(id: id, status: status)
            pendingSources.removeFirst()
            loadPreview()
        } catch {
            previewState = .failed(error.localizedDescription)
        }
    }

    private func loadPreview() {
        previewTask?.cancel()

        guard let source = currentSource else {
            previewState = .idle
            return
        }

        previewState = .loading

        previewTask = Task {
            await performLoadPreview(for: source)
        }
    }

    private func performLoadPreview(for source: DealSource) async {
        do {
            let content = try await loadPreviewContent(for: source)
            guard !Task.isCancelled else { return }
            previewState = .ready(content)
        } catch {
            guard !Task.isCancelled else { return }
            previewState = .failed(error.localizedDescription)
        }
    }

    private func loadPreviewContent(for source: DealSource) async throws -> PreviewContent {
        switch source.type {
        case .image:
            guard let url = URL(string: source.url) else {
                throw PreviewError.invalidURL
            }
            return .image(url)

        case .pdf:
            guard let url = URL(string: source.url) else {
                throw PreviewError.invalidURL
            }
            let hash = URLNormalizer.hash(url)
            let localURL = try await pdfFetcher.localFileURL(for: url, hash: hash)
            guard let document = PDFDocument(url: localURL) else {
                throw PreviewError.unreadablePDF
            }
            return .pdf(document)

        case .webpage:
            guard let url = URL(string: source.sourceURL) else {
                throw PreviewError.invalidURL
            }
            return .webpage(url)
        }
    }
}

private enum PreviewError: LocalizedError {
    case invalidURL
    case unreadablePDF

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The source URL is invalid."
        case .unreadablePDF:
            return "The PDF could not be opened."
        }
    }
}
