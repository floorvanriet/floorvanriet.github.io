import Foundation
import SwiftUI
import UnlockKit

@MainActor
final class ShareCoordinator: ObservableObject {
    struct LogEntry: Identifiable, Equatable {
        enum State: Equatable {
            case running
            case failed(String)
            case succeeded
        }
        let id = UUID()
        let strategyID: String
        let label: String
        var state: State
    }

    enum Phase: Equatable {
        case idle
        case running
        case resolved(UnlockResult)
        case failed
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var log: [LogEntry] = []

    private let chain: UnlockChain
    private var task: Task<Void, Never>?

    init(chain: UnlockChain) {
        self.chain = chain
    }

    func start(url: URL) {
        guard case .idle = phase else { return }
        phase = .running
        task = Task { [weak self] in
            guard let self else { return }
            for await event in self.chain.run(originalURL: url) {
                await self.apply(event)
            }
            if case .running = self.phase {
                // Stream ended without success or failure — treat as failed.
                self.phase = .failed
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    private func apply(_ event: UnlockProgress) {
        switch event {
        case .started(let id, let label):
            log.append(LogEntry(strategyID: id, label: label, state: .running))
        case .failed(let id, let message):
            if let idx = log.lastIndex(where: { $0.strategyID == id && $0.state == .running }) {
                log[idx].state = .failed(message)
            } else {
                log.append(LogEntry(strategyID: id, label: id, state: .failed(message)))
            }
        case .succeeded(let result):
            if let idx = log.lastIndex(where: { $0.state == .running }) {
                log[idx].state = .succeeded
            }
            phase = .resolved(result)
        }
    }
}
