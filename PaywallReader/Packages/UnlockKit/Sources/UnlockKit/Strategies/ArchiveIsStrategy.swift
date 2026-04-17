import Foundation

public struct ArchiveIsStrategy: UnlockStrategy {
    public let id = "archive.is"
    public let label = "Proberen archive.is…"

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
