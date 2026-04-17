import Foundation

public protocol HTTPClient: Sendable {
    func head(_ url: URL, timeout: TimeInterval, userAgent: String?) async throws -> HTTPResponse
    func get(_ url: URL, timeout: TimeInterval, userAgent: String?) async throws -> HTTPResponse
}

public struct HTTPResponse: Sendable {
    public let status: Int
    public let finalURL: URL
    public let headers: [String: String]
    public let body: Data

    public init(status: Int, finalURL: URL, headers: [String: String], body: Data) {
        self.status = status
        self.finalURL = finalURL
        self.headers = headers
        self.body = body
    }
}

public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func head(_ url: URL, timeout: TimeInterval, userAgent: String?) async throws -> HTTPResponse {
        try await perform(url: url, method: "HEAD", timeout: timeout, userAgent: userAgent)
    }

    public func get(_ url: URL, timeout: TimeInterval, userAgent: String?) async throws -> HTTPResponse {
        try await perform(url: url, method: "GET", timeout: timeout, userAgent: userAgent)
    }

    private func perform(url: URL, method: String, timeout: TimeInterval, userAgent: String?) async throws -> HTTPResponse {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method
        if let userAgent {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let headers = http.allHeaderFields.reduce(into: [String: String]()) { acc, pair in
            if let key = pair.key as? String, let value = pair.value as? String {
                acc[key.lowercased()] = value
            }
        }
        return HTTPResponse(
            status: http.statusCode,
            finalURL: http.url ?? url,
            headers: headers,
            body: data
        )
    }
}

public enum UserAgents {
    public static let desktopSafari =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
}
