//Created by Alex Skorulis on 15/7/2026.

import CryptoKit
import Foundation

enum AWSS3SigV4 {

    static let algorithm = "AWS4-HMAC-SHA256"
    static let service = "s3"
    static let region = "auto"

    struct SignedRequest {
        let url: URL
        let method: String
        let headers: [String: String]
        let body: Data
    }

    static func signPUT(
        url: URL,
        body: Data,
        contentType: String,
        cacheControl: String,
        accessKeyId: String,
        secretAccessKey: String,
        date: Date = Date()
    ) throws -> SignedRequest {
        guard let host = url.host else {
            throw URLError(.badURL)
        }

        let amzDate = amzDateString(date)
        let dateStamp = String(amzDate.prefix(8))
        let payloadHash = sha256Hex(body)
        let canonicalURI = canonicalURIPath(url)

        var headers: [String: String] = [
            "host": host,
            "content-type": contentType,
            "cache-control": cacheControl,
            "x-amz-content-sha256": payloadHash,
            "x-amz-date": amzDate,
        ]

        let signedHeaderNames = headers.keys.sorted()
        let signedHeaders = signedHeaderNames.joined(separator: ";")
        let canonicalHeaders = signedHeaderNames
            .map { "\($0):\((headers[$0] ?? "").trimmingCharacters(in: .whitespacesAndNewlines))" }
            .joined(separator: "\n") + "\n"

        let canonicalRequest = [
            "PUT",
            canonicalURI,
            "", // empty query string
            canonicalHeaders,
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")

        let credentialScope = "\(dateStamp)/\(region)/\(service)/aws4_request"
        let stringToSign = [
            algorithm,
            amzDate,
            credentialScope,
            sha256Hex(Data(canonicalRequest.utf8)),
        ].joined(separator: "\n")

        let signingKey = deriveSigningKey(
            secret: secretAccessKey,
            dateStamp: dateStamp
        )
        let signature = hmacHex(key: signingKey, data: Data(stringToSign.utf8))

        headers["authorization"] = [
            "\(algorithm) Credential=\(accessKeyId)/\(credentialScope)",
            "SignedHeaders=\(signedHeaders)",
            "Signature=\(signature)",
        ].joined(separator: ", ")

        return SignedRequest(url: url, method: "PUT", headers: headers, body: body)
    }

    private static func canonicalURIPath(_ url: URL) -> String {
        let path = url.path.isEmpty ? "/" : url.path
        return path.split(separator: "/", omittingEmptySubsequences: false)
            .map { segment -> String in
                let raw = String(segment)
                if raw.isEmpty { return "" }
                return percentEncode(raw)
            }
            .joined(separator: "/")
    }

    /// AWS-style percent encoding (URI encode, leave unreserved chars).
    private static func percentEncode(_ string: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }

    private static func deriveSigningKey(secret: String, dateStamp: String) -> SymmetricKey {
        let kDate = hmac(key: Data("AWS4\(secret)".utf8), data: Data(dateStamp.utf8))
        let kRegion = hmac(key: kDate, data: Data(region.utf8))
        let kService = hmac(key: kRegion, data: Data(service.utf8))
        return SymmetricKey(data: hmac(key: kService, data: Data("aws4_request".utf8)))
    }

    private static func hmac(key: Data, data: Data) -> Data {
        hmac(key: SymmetricKey(data: key), data: data)
    }

    private static func hmac(key: SymmetricKey, data: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: data, using: key))
    }

    private static func hmacHex(key: SymmetricKey, data: Data) -> String {
        HMAC<SHA256>.authenticationCode(for: data, using: key)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func amzDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter.string(from: date)
    }
}
