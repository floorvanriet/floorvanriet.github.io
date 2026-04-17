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

    func testAlreadyArchivedShortCircuitsArchiveIs() async throws {
        let url = URL(string: "https://archive.ph/abc12")!
        let result = try await AlreadyArchivedStrategy().resolve(originalURL: url)
        XCTAssertEqual(result.resolvedURL, url)
        XCTAssertEqual(result.source, .archiveIs)
    }

    func testAlreadyArchivedSkipsNonArchiveHost() async {
        let url = URL(string: "https://www.nrc.nl/article")!
        do {
            _ = try await AlreadyArchivedStrategy().resolve(originalURL: url)
            XCTFail("should have thrown")
        } catch let failure as StrategyFailure {
            XCTAssertEqual(failure.strategyID, "already-archived")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}

final class ArchiveIsStrategyTests: XCTestCase {
    func testSuccessfulSnapshot() async throws {
        let original = URL(string: "https://www.nrc.nl/news/foo")!
        let client = StubHTTPClient(responses: [
            .init(
                status: 200,
                finalURL: URL(string: "https://archive.ph/abc12")!,
                body: Data("<html>snapshot</html>".utf8)
            )
        ])
        let result = try await ArchiveIsStrategy(client: client).resolve(originalURL: original)
        XCTAssertEqual(result.resolvedURL.absoluteString, "https://archive.ph/abc12")
        XCTAssertEqual(result.source, .archiveIs)
    }

    func testFailsWhenFinalURLIsLookupPage() async {
        let original = URL(string: "https://www.nrc.nl/news/foo")!
        let client = StubHTTPClient(responses: [
            .init(
                status: 200,
                finalURL: URL(string: "https://archive.is/newest/https://www.nrc.nl/news/foo")!,
                body: Data("<html>no results</html>".utf8)
            )
        ])
        do {
            _ = try await ArchiveIsStrategy(client: client).resolve(originalURL: original)
            XCTFail("should have thrown")
        } catch let failure as StrategyFailure {
            XCTAssertEqual(failure.strategyID, "archive.is")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testDetectsCloudflareChallenge() async {
        let original = URL(string: "https://www.nrc.nl/news/foo")!
        let client = StubHTTPClient(responses: [
            .init(
                status: 503,
                finalURL: URL(string: "https://archive.is/newest/foo")!,
                body: Data("Just a moment...".utf8)
            )
        ])
        do {
            _ = try await ArchiveIsStrategy(client: client).resolve(originalURL: original)
            XCTFail("should have thrown")
        } catch let failure as StrategyFailure {
            XCTAssertTrue(failure.message.contains("Cloudflare") || failure.message.contains("HTTP 503"))
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}

final class WaybackStrategyTests: XCTestCase {
    func testSuccessfulAvailability() async throws {
        let original = URL(string: "https://www.nrc.nl/article")!
        let json = """
        {"archived_snapshots":{"closest":{"available":true,"status":"200","url":"http://web.archive.org/web/20240101000000/https://www.nrc.nl/article","timestamp":"20240101000000"}}}
        """
        let client = StubHTTPClient(responses: [
            .init(
                status: 200,
                finalURL: URL(string: "https://archive.org/wayback/available?url=...")!,
                body: Data(json.utf8)
            )
        ])
        let result = try await WaybackStrategy(client: client).resolve(originalURL: original)
        XCTAssertEqual(result.source, .wayback)
        XCTAssertEqual(result.resolvedURL.scheme, "https")
        XCTAssertTrue(result.resolvedURL.absoluteString.contains("web.archive.org"))
    }

    func testEmptyAvailabilityFails() async {
        let original = URL(string: "https://www.nrc.nl/article")!
        let client = StubHTTPClient(responses: [
            .init(
                status: 200,
                finalURL: URL(string: "https://archive.org/wayback/available?url=...")!,
                body: Data("{\"archived_snapshots\":{}}".utf8)
            )
        ])
        do {
            _ = try await WaybackStrategy(client: client).resolve(originalURL: original)
            XCTFail("should have thrown")
        } catch let failure as StrategyFailure {
            XCTAssertEqual(failure.strategyID, "wayback")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}

// MARK: - Stubs

private struct AlwaysFailStrategy: UnlockStrategy {
    let id = "always-fail"
    let label = "Test…"
    func resolve(originalURL: URL) async throws -> UnlockResult {
        throw StrategyFailure(strategyID: id, message: "nope")
    }
}

private struct StubHTTPClient: HTTPClient {
    struct Response {
        let status: Int
        let finalURL: URL
        let body: Data
        let headers: [String: String]
        init(status: Int, finalURL: URL, body: Data, headers: [String: String] = [:]) {
            self.status = status
            self.finalURL = finalURL
            self.body = body
            self.headers = headers
        }
    }

    let responses: [Response]

    func head(_ url: URL, timeout: TimeInterval, userAgent: String?) async throws -> HTTPResponse {
        try respond()
    }

    func get(_ url: URL, timeout: TimeInterval, userAgent: String?) async throws -> HTTPResponse {
        try respond()
    }

    private func respond() throws -> HTTPResponse {
        guard let r = responses.first else { throw URLError(.badServerResponse) }
        return HTTPResponse(status: r.status, finalURL: r.finalURL, headers: r.headers, body: r.body)
    }
}
