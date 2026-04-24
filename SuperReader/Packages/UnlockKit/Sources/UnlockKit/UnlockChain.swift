import Foundation

public struct UnlockChain: Sendable {
    public let strategies: [any UnlockStrategy]

    public init(strategies: [any UnlockStrategy]) {
        self.strategies = strategies
    }

    /// Default MVP chain: already-archived short-circuit → archive.is → Wayback → direct.
    public static func mvp(client: HTTPClient = URLSessionHTTPClient()) -> UnlockChain {
        from(settings: .default, client: client)
    }

    /// Builds a chain from persisted settings. `DirectStrategy` is always
    /// appended as the guaranteed last-resort fallback.
    public static func from(
        settings: UnlockSettings,
        client: HTTPClient = URLSessionHTTPClient()
    ) -> UnlockChain {
        var built: [any UnlockStrategy] = []
        for entry in settings.entries where entry.enabled {
            switch entry.id {
            case "already-archived": built.append(AlreadyArchivedStrategy())
            case "archive.is": built.append(ArchiveIsStrategy(client: client))
            case "wayback": built.append(WaybackStrategy(client: client))
            default: break
            }
        }
        built.append(DirectStrategy())
        return UnlockChain(strategies: built)
    }

    /// Streams progress updates. Stops on the first successful strategy.
    public func run(originalURL: URL) -> AsyncStream<UnlockProgress> {
        AsyncStream { continuation in
            let task = Task {
                var failures: [StrategyFailure] = []
                for strategy in strategies {
                    if Task.isCancelled { break }
                    continuation.yield(.started(strategyID: strategy.id, label: strategy.label))
                    do {
                        let result = try await strategy.resolve(originalURL: originalURL)
                        continuation.yield(.succeeded(result))
                        continuation.finish()
                        return
                    } catch let failure as StrategyFailure {
                        failures.append(failure)
                        continuation.yield(.failed(strategyID: failure.strategyID, message: failure.message))
                    } catch {
                        let failure = StrategyFailure(strategyID: strategy.id, message: error.localizedDescription)
                        failures.append(failure)
                        continuation.yield(.failed(strategyID: failure.strategyID, message: failure.message))
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
