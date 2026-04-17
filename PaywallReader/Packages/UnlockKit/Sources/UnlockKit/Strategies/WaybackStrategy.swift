import Foundation

public struct WaybackStrategy: UnlockStrategy {
    public let id = "wayback"
    public let label = "Wayback Machine…"

    private let client: HTTPClient
    private let timeout: TimeInterval

    public init(client: HTTPClient = URLSessionHTTPClient(), timeout: TimeInterval = 5) {
        self.client = client
        self.timeout = timeout
    }

    public func resolve(originalURL: URL) async throws -> UnlockResult {
        var components = URLComponents(string: "https://archive.org/wayback/available")!
        components.queryItems = [URLQueryItem(name: "url", value: originalURL.absoluteString)]
        guard let lookup = components.url else {
            throw StrategyFailure(strategyID: id, message: "kon availability-URL niet maken")
        }

        let response: HTTPResponse
        do {
            response = try await client.get(lookup, timeout: timeout, userAgent: nil)
        } catch {
            throw StrategyFailure(strategyID: id, message: "netwerkfout: \(error.localizedDescription)")
        }

        guard response.status == 200 else {
            throw StrategyFailure(strategyID: id, message: "HTTP \(response.status)")
        }

        let payload: WaybackAvailability
        do {
            payload = try JSONDecoder().decode(WaybackAvailability.self, from: response.body)
        } catch {
            throw StrategyFailure(strategyID: id, message: "JSON-fout: \(error.localizedDescription)")
        }

        guard
            let snapshot = payload.archived_snapshots?.closest,
            snapshot.available == true,
            snapshot.status == "200",
            let resolved = URL(string: snapshot.url)
        else {
            throw StrategyFailure(strategyID: id, message: "geen bruikbare snapshot")
        }

        return UnlockResult(
            originalURL: originalURL,
            resolvedURL: upgradeToHTTPS(resolved),
            source: .wayback
        )
    }

    private func upgradeToHTTPS(_ url: URL) -> URL {
        guard url.scheme == "http" else { return url }
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        comps?.scheme = "https"
        return comps?.url ?? url
    }
}

private struct WaybackAvailability: Decodable {
    let archived_snapshots: Snapshots?

    struct Snapshots: Decodable {
        let closest: Snapshot?
    }

    struct Snapshot: Decodable {
        let available: Bool?
        let status: String?
        let url: String
        let timestamp: String?
    }
}
