import Foundation

public protocol UnlockStrategy: Sendable {
    var id: String { get }
    var label: String { get }
    func resolve(originalURL: URL) async throws -> UnlockResult
}
