//Created by Alex Skorulis on 15/6/2026.

import Foundation
import WebKit

struct LoadedPage: Sendable {
    let url: URL
    let html: String
}

enum WebPageLoaderError: LocalizedError {
    case timeout
    case navigationFailed(String)
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "The page took too long to load."
        case let .navigationFailed(message):
            return "Failed to load page: \(message)"
        case .emptyContent:
            return "The page returned no content."
        }
    }
}

@MainActor
final class WebPageLoader: NSObject {

    private static let defaultTimeout: TimeInterval = 15
    private static let safariUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    private let webView: WKWebView
    private var loadContinuation: CheckedContinuation<Void, Error>?

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1280, height: 720), configuration: configuration)
        webView.customUserAgent = Self.safariUserAgent
        webView.isHidden = true

        super.init()
        webView.navigationDelegate = self
    }

    func load(url: URL, timeout: TimeInterval = defaultTimeout) async throws -> LoadedPage {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                try await self.performLoad(url: url)
            }
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                await self.cancelPendingLoad()
                throw WebPageLoaderError.timeout
            }

            defer { group.cancelAll() }

            try await group.next()
            group.cancelAll()
        }

        let html = try await extractHTML()
        guard !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WebPageLoaderError.emptyContent
        }

        guard let finalURL = webView.url else {
            throw WebPageLoaderError.emptyContent
        }

        return LoadedPage(url: finalURL, html: html)
    }

    private func performLoad(url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            loadContinuation = continuation
            webView.load(URLRequest(url: url))
        }
    }

    private func extractHTML() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            webView.evaluateJavaScript("document.documentElement.outerHTML") { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let html = result as? String else {
                    continuation.resume(throwing: WebPageLoaderError.emptyContent)
                    return
                }

                continuation.resume(returning: html)
            }
        }
    }

    private func cancelPendingLoad() {
        loadContinuation = nil
        webView.stopLoading()
    }

    private func finishLoad(with result: Result<Void, Error>) {
        guard let continuation = loadContinuation else { return }
        loadContinuation = nil
        continuation.resume(with: result)
    }
}

extension WebPageLoader: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishLoad(with: .success(()))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finishLoad(with: .failure(WebPageLoaderError.navigationFailed(error.localizedDescription)))
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        finishLoad(with: .failure(WebPageLoaderError.navigationFailed(error.localizedDescription)))
    }
}
