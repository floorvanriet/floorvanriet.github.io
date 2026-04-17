import Foundation

public struct UnlockResult: Sendable, Equatable {
    public enum Source: String, Sendable, Equatable {
        case archiveIs = "archive.is"
        case wayback = "web.archive.org"
        case direct = "direct"
        case original = "original"
    }

    public let originalURL: URL
    public let resolvedURL: URL
    public let source: Source

    public init(originalURL: URL, resolvedURL: URL, source: Source) {
        self.originalURL = originalURL
        self.resolvedURL = resolvedURL
        self.source = source
    }
}

public enum UnlockError: Error, Equatable, Sendable {
    case invalidURL
    case offline
    case timeout
    case allStrategiesFailed([StrategyFailure])
    case cancelled
}

public struct StrategyFailure: Error, Equatable, Sendable {
    public let strategyID: String
    public let message: String

    public init(strategyID: String, message: String) {
        self.strategyID = strategyID
        self.message = message
    }
}

public enum UnlockProgress: Sendable, Equatable {
    case started(strategyID: String, label: String)
    case failed(strategyID: String, message: String)
    case succeeded(UnlockResult)
}
