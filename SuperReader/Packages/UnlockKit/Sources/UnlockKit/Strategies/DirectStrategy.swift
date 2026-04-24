import Foundation

/// Fallback strategy that simply returns the original URL. Consumers are
/// expected to render this via `SFSafariViewController` with reader mode.
public struct DirectStrategy: UnlockStrategy {
    public let id = "direct"
    public let label = "Origineel openen in reader…"

    public init() {}

    public func resolve(originalURL: URL) async throws -> UnlockResult {
        UnlockResult(originalURL: originalURL, resolvedURL: originalURL, source: .original)
    }
}
