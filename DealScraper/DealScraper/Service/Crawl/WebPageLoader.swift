//Created by Alex Skorulis on 15/6/2026.

import Foundation
import Knit
import KnitMacros
import WebKit

struct LoadedPage: Sendable {
    let url: URL
    let html: String
    let markdown: String?
    let imageURLs: [URL]
    let contentBlocks: [ContentBlock]
    let links: [ContentBlockLink]
    let emails: Set<String>
    
    var normalizedURL: URL {
        URLNormalizer.normalize(url) ?? url
    }

    var dealContentBlocks: [ContentBlock] {
        guard !DealTextFilter.isExpiredPage(html) else { return [] }
        let filter = DealTextFilter()
        return contentBlocks.filter {
            filter.isValidDeal($0.fullText)
        }
    }
    
    var contentHash: String {
        dealContentBlocks.map { $0.fullText }.joined(separator: "\n")
    }
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

struct WebPageLoaderFactory {
    let resolver: Resolver
    
    func make() -> WebPageLoader {
        WebPageLoader.make(resolver: resolver)
    }
}

@MainActor
final class WebPageLoader: NSObject {

    nonisolated private static let defaultTimeout: TimeInterval = 30
    nonisolated private static let safariUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    nonisolated private static let scrollHeightScript =
        "Math.max(document.body ? document.body.scrollHeight : 0, document.documentElement ? document.documentElement.scrollHeight : 0)"

    private static let clickCarouselsScript = """
    (function() {
        var clicks = 0;
        var selectors = [
            '[aria-label*="Next"]',
            '[aria-label*="next"]',
            '[data-hook*="next"]',
            'button[class*="next"]'
        ];
        for (var s = 0; s < selectors.length; s++) {
            var buttons = document.querySelectorAll(selectors[s]);
            for (var b = 0; b < buttons.length; b++) {
                var button = buttons[b];
                for (var i = 0; i < 10; i++) {
                    if (typeof button.click === 'function') {
                        button.click();
                        clicks++;
                    }
                }
            }
        }
        return clicks;
    })()
    """

    private static let clickLoadMoreScript = """
    (function() {
        var clicks = 0;
        var elements = document.querySelectorAll('button, a, [role="button"]');
        for (var i = 0; i < elements.length; i++) {
            var element = elements[i];
            var text = (element.textContent || '').toLowerCase();
            if (text.indexOf('load more') !== -1 && typeof element.click === 'function') {
                element.click();
                clicks++;
            }
        }
        return clicks;
    })()
    """

    private static let liveImageURLsScript = """
    (function() {
        var urls = [];
        var images = document.querySelectorAll('img');
        for (var i = 0; i < images.length; i++) {
            var image = images[i];
            if (image.currentSrc) {
                urls.push(image.currentSrc);
            }
            if (image.src) {
                urls.push(image.src);
            }
            var srcset = image.getAttribute('srcset') || image.getAttribute('srcSet');
            if (srcset) {
                var parts = srcset.split(',');
                for (var p = 0; p < parts.length; p++) {
                    var url = parts[p].trim().split(/\\s+/)[0];
                    if (url) {
                        urls.push(url);
                    }
                }
            }
        }
        return JSON.stringify(urls);
    })()
    """

    private static let resourceTimingImageURLsScript = """
    (function() {
        var urls = [];
        var imagePattern = /\\.(jpe?g|png|gif|webp|svg|avif|bmp|ico)(\\?|#|$)/i;
        var entries = performance.getEntriesByType('resource');
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i];
            var url = entry.name;
            if (!url || url.indexOf('data:') === 0) {
                continue;
            }
            if (entry.initiatorType === 'img' || imagePattern.test(url)) {
                urls.push(url);
            }
        }
        return JSON.stringify(urls);
    })()
    """

    private static let wixStaticImagePattern = try! NSRegularExpression(
        pattern: #"https://static\.wixstatic\.com/media/[^\s"'<>]+"#,
        options: .caseInsensitive
    )

    private let contentBlockGrouper: ContentBlockGrouper
    private let pageLinkExtractor: PageLinkExtractor
    private let canonicalURLExtractor: CanonicalURLExtractor
    private let webMarkdownGenerator: WebMarkdownGenerator
    private let webView: WKWebView
    private var loadContinuation: CheckedContinuation<Void, Error>?

    @Resolvable<Resolver>
    init(
        contentBlockGrouper: ContentBlockGrouper,
        pageLinkExtractor: PageLinkExtractor,
        canonicalURLExtractor: CanonicalURLExtractor,
        webMarkdownGenerator: WebMarkdownGenerator
    ) {
        self.contentBlockGrouper = contentBlockGrouper
        self.pageLinkExtractor = pageLinkExtractor
        self.canonicalURLExtractor = canonicalURLExtractor
        self.webMarkdownGenerator = webMarkdownGenerator
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

        try await preparePage()

        let resolvedHTML = try await extractHTML()
        guard !resolvedHTML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WebPageLoaderError.emptyContent
        }

        guard let finalURL = webView.url else {
            throw WebPageLoaderError.emptyContent
        }
        
        let effectiveURL = (try? canonicalURLExtractor.extract(html: resolvedHTML, pageURL: finalURL))
            ?? URLNormalizer.normalize(finalURL)
            ?? finalURL
        print("LOADER: Final URL: \(finalURL), effective URL: \(effectiveURL)")

        let imageURLs = harvestImageURLs(
            html: resolvedHTML,
            liveDOMURLs: await harvestLiveImageURLStrings(),
            resourceTimingURLs: await harvestResourceTimingImageURLStrings()
        )
        let contentBlocks = (try? contentBlockGrouper.group(html: resolvedHTML, pageURL: effectiveURL)) ?? []
        let links = (try? pageLinkExtractor.extract(html: resolvedHTML, pageURL: effectiveURL)) ?? []
        let markdown = try? await webMarkdownGenerator.markdown(from: resolvedHTML)
        let emails = EmailExtractor().extract(from: resolvedHTML)

        return LoadedPage(
            url: effectiveURL,
            html: resolvedHTML,
            markdown: markdown,
            imageURLs: imageURLs,
            contentBlocks: contentBlocks,
            links: links,
            emails: emails
        )
    }

    private func preparePage() async throws {
        try await Task.sleep(for: .seconds(1))

        let scrollHeight = try await evaluateJavaScriptNumber(Self.scrollHeightScript)
        var y: Double = 0
        while y < scrollHeight {
            try await evaluateJavaScriptVoid("window.scrollTo(0, \(Int(y)))")
            try await Task.sleep(for: .milliseconds(150))
            y += 400
        }

        try await evaluateJavaScriptVoid("window.scrollTo(0, \(Int(scrollHeight)))")
        try await Task.sleep(for: .milliseconds(300))
        try await evaluateJavaScriptVoid("window.scrollTo(0, 0)")
        try await Task.sleep(for: .milliseconds(500))

        _ = try await evaluateJavaScriptNumber(Self.clickCarouselsScript)
        _ = try await evaluateJavaScriptNumber(Self.clickLoadMoreScript)
        try await Task.sleep(for: .milliseconds(500))
    }

    private func performLoad(url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            loadContinuation = continuation
            webView.load(URLRequest(url: url))
        }
    }

    private func extractHTML() async throws -> String {
        let result: String = try await evaluateJavaScript("document.documentElement.outerHTML")
        return result
    }

    private func harvestLiveImageURLStrings() async -> [String] {
        await evaluateJavaScriptStringArray(Self.liveImageURLsScript)
    }

    private func harvestResourceTimingImageURLStrings() async -> [String] {
        await evaluateJavaScriptStringArray(Self.resourceTimingImageURLsScript)
    }

    private func evaluateJavaScriptStringArray(_ script: String) async -> [String] {
        guard let json: String = try? await evaluateJavaScript(script),
              let data = json.data(using: .utf8),
              let strings = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }
        return strings
    }

    private func harvestImageURLs(html: String, liveDOMURLs: [String], resourceTimingURLs: [String]) -> [URL] {
        var urlStrings = Set(liveDOMURLs)
        urlStrings.formUnion(resourceTimingURLs)
        let range = NSRange(html.startIndex..., in: html)
        Self.wixStaticImagePattern.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
            guard let match, let matchRange = Range(match.range, in: html) else { return }
            urlStrings.insert(String(html[matchRange]))
        }
        return urlStrings.compactMap { URL(string: $0) }
    }

    private func evaluateJavaScriptVoid(_ script: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            webView.evaluateJavaScript(script) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }

    private func evaluateJavaScriptNumber(_ script: String) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            webView.evaluateJavaScript(script) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let number = result as? NSNumber {
                    continuation.resume(returning: number.doubleValue)
                    return
                }
                continuation.resume(returning: 0)
            }
        }
    }

    private func evaluateJavaScript<T>(_ script: String) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            webView.evaluateJavaScript(script) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let value = result as? T {
                    continuation.resume(returning: value)
                    return
                }

                if T.self == String.self, let value = result as? NSString {
                    continuation.resume(returning: value as String as! T)
                    return
                }

                continuation.resume(throwing: WebPageLoaderError.emptyContent)
            }
        }
    }

    private func cancelPendingLoad() {
        print("LOADER: Cancelling pending load")
        guard let continuation = loadContinuation else {
            webView.stopLoading()
            return
        }
        loadContinuation = nil
        webView.stopLoading()
        continuation.resume(throwing: WebPageLoaderError.timeout)
    }

    private func finishLoad(with result: Result<Void, Error>) {
        guard let continuation = loadContinuation else {
            print("LOADER: Finished without continuation")
            return
        }
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
