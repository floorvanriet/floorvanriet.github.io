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
        // Phase 1 stub: wired in Phase 2.
        throw StrategyFailure(strategyID: id, message: "not implemented yet")
    }
}
