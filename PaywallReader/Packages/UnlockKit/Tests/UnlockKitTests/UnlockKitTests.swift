import XCTest
@testable import UnlockKit

final class UnlockChainTests: XCTestCase {
    func testDirectStrategyAlwaysSucceeds() async throws {
        let url = URL(string: "https://example.com/article")!
        let result = try await DirectStrategy().resolve(originalURL: url)
        XCTAssertEqual(result.originalURL, url)
        XCTAssertEqual(result.resolvedURL, url)
        XCTAssertEqual(result.source, .original)
    }

    func testChainFallsThroughToDirect() async throws {
        let url = URL(string: "https://example.com/article")!
        let chain = UnlockChain(strategies: [AlwaysFailStrategy(), DirectStrategy()])
        var events: [UnlockProgress] = []
        for await event in chain.run(originalURL: url) {
            events.append(event)
        }
        guard case .succeeded(let result) = events.last else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(result.source, .original)
        XCTAssertTrue(events.contains(where: {
            if case .failed(let id, _) = $0 { return id == "always-fail" }
            return false
        }))
    }
}

private struct AlwaysFailStrategy: UnlockStrategy {
    let id = "always-fail"
    let label = "Test…"
    func resolve(originalURL: URL) async throws -> UnlockResult {
        throw StrategyFailure(strategyID: id, message: "nope")
    }
}
