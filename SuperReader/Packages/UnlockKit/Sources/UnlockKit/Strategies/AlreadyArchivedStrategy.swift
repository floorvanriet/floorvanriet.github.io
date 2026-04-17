import Foundation

/// Short-circuit: if the shared URL is already an archive-link we show it
/// directly instead of walking the whole chain.
public struct AlreadyArchivedStrategy: UnlockStrategy {
    public let id = "already-archived"
    public let label = "Controleren op archive-link…"

    public init() {}

    public func resolve(originalURL: URL) async throws -> UnlockResult {
        guard let host = originalURL.host?.lowercased() else {
            throw StrategyFailure(strategyID: id, message: "ongeldige URL")
        }

        if host == "archive.is"
            || host == "archive.ph"
            || host == "archive.today"
            || host.hasSuffix(".archive.is")
            || host.hasSuffix(".archive.ph")
        {
            return UnlockResult(originalURL: originalURL, resolvedURL: originalURL, source: .archiveIs)
        }

        if host == "web.archive.org" {
            return UnlockResult(originalURL: originalURL, resolvedURL: originalURL, source: .wayback)
        }

        throw StrategyFailure(strategyID: id, message: "geen archive-link")
    }
}
