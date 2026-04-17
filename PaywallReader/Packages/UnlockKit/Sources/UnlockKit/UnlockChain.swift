import Foundation

public struct UnlockChain: Sendable {
    public let strategies: [any UnlockStrategy]

    public init(strategies: [any UnlockStrategy]) {
        self.strategies = strategies
    }

    /// Default MVP chain: archive.is → Wayback → direct (SFSafariViewController reader).
    public static func mvp(client: HTTPClient = URLSessionHTTPClient()) -> UnlockChain {
        UnlockChain(strategies: [
            ArchiveIsStrategy(client: client),
            WaybackStrategy(client: client),
            DirectStrategy()
        ])
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
