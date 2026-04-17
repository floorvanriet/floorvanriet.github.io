import Foundation

public struct ArchiveIsStrategy: UnlockStrategy {
    public let id = "archive.is"
    public let label = "Proberen archive.is…"

    private let client: HTTPClient
    private let timeout: TimeInterval
    private let host: String

    public init(
        client: HTTPClient = URLSessionHTTPClient(),
        timeout: TimeInterval = 5,
        host: String = "archive.is"
    ) {
        self.client = client
        self.timeout = timeout
        self.host = host
    }

    public func resolve(originalURL: URL) async throws -> UnlockResult {
        guard let lookup = URL(string: "https://\(host)/newest/\(originalURL.absoluteString)") else {
            throw StrategyFailure(strategyID: id, message: "kon lookup-URL niet maken")
        }

        let response: HTTPResponse
        do {
            response = try await client.get(lookup, timeout: timeout, userAgent: UserAgents.desktopSafari)
        } catch {
            throw StrategyFailure(strategyID: id, message: "netwerkfout: \(error.localizedDescription)")
        }

        guard response.status == 200 else {
            throw StrategyFailure(strategyID: id, message: "HTTP \(response.status)")
        }

        if looksLikeCloudflareChallenge(response) {
            throw StrategyFailure(strategyID: id, message: "Cloudflare-challenge, overslaan")
        }

        guard isSnapshotURL(response.finalURL) else {
            throw StrategyFailure(strategyID: id, message: "geen snapshot beschikbaar")
        }

        return UnlockResult(
            originalURL: originalURL,
            resolvedURL: response.finalURL,
            source: .archiveIs
        )
    }

    private func isSnapshotURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        let isArchiveHost = host == "archive.is"
            || host == "archive.ph"
            || host == "archive.today"
            || host.hasSuffix(".archive.is")
            || host.hasSuffix(".archive.ph")
        guard isArchiveHost else { return false }

        let path = url.path
        // Reject the lookup endpoints — a real snapshot has a short hash path
        // like /abc12 or a dated path like /2024-01-31/…
        if path.hasPrefix("/newest/") { return false }
        if path.hasPrefix("/search") { return false }
        if path.hasPrefix("/submit") { return false }
        if path == "/" || path.isEmpty { return false }
        return true
    }

    private func looksLikeCloudflareChallenge(_ response: HTTPResponse) -> Bool {
        if response.status == 403 || response.status == 503 {
            return true
        }
        guard let body = String(data: response.body, encoding: .utf8) else { return false }
        let markers = [
            "cf-browser-verification",
            "cf_chl_opt",
            "Just a moment",
            "Attention Required! | Cloudflare"
        ]
        return markers.contains(where: { body.contains($0) })
    }
}
