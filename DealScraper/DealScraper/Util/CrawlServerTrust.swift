// Created by Alex Skorulis on 27/7/2026.

import Foundation
import Security

/// Trust handling for pub/venue website crawling.
/// Many venues have misconfigured SSL (expired, hostname mismatch, wrong cert).
/// Browsers often still reach a working host after redirects; strict clients fail on the bad hop.
enum CrawlServerTrust {

    /// Session for fetching pub-website resources (images, PDFs, sitemaps).
    static let urlSession: URLSession = {
        URLSession(
            configuration: .default,
            delegate: AcceptingServerTrustDelegate.shared,
            delegateQueue: nil
        )
    }()

    static func handleAuthenticationChallenge(
        _ challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Hostname mismatches / expired certs need exceptions applied to the trust
        // object — passing URLCredential(trust:) alone is not enough for WKWebView.
        let exceptions = SecTrustCopyExceptions(trust)
        SecTrustSetExceptions(trust, exceptions)
        completionHandler(.useCredential, URLCredential(trust: trust))
    }

    static func isCertificateError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorServerCertificateUntrusted,
                 NSURLErrorServerCertificateHasBadDate,
                 NSURLErrorServerCertificateHasUnknownRoot,
                 NSURLErrorServerCertificateNotYetValid,
                 NSURLErrorClientCertificateRejected,
                 NSURLErrorClientCertificateRequired,
                 NSURLErrorSecureConnectionFailed:
                return true
            default:
                break
            }
        }

        let message = error.localizedDescription.lowercased()
        return message.contains("certificate") || message.contains("ssl") || message.contains("secure connection")
    }

    /// `https://www.example.com/path` → `https://example.com/path` for hosts whose
    /// cert only covers the apex (common on shared WordPress hosting).
    static func wwwStrippedURL(from url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host,
              host.hasPrefix("www."),
              host.count > 4
        else {
            return nil
        }
        components.host = String(host.dropFirst(4))
        return components.url
    }
}

private final class AcceptingServerTrustDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    static let shared = AcceptingServerTrustDelegate()

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        CrawlServerTrust.handleAuthenticationChallenge(challenge, completionHandler: completionHandler)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        CrawlServerTrust.handleAuthenticationChallenge(challenge, completionHandler: completionHandler)
    }
}
