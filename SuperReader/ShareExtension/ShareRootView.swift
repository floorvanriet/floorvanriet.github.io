import SwiftUI
import UnlockKit

struct ShareRootView: View {
    let url: URL?
    let onClose: () -> Void

    @StateObject private var coordinator: ShareCoordinator
    @State private var fallbackURL: URL?

    init(url: URL?, onClose: @escaping () -> Void) {
        self.url = url
        self.onClose = onClose
        let settings = UserDefaultsSettingsStore().load()
        let chain = UnlockChain.from(settings: settings)
        _coordinator = StateObject(wrappedValue: ShareCoordinator(chain: chain))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("SuperReader")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuleer") {
                            coordinator.cancel()
                            onClose()
                        }
                    }
                }
        }
        .task {
            guard let url else { return }
            coordinator.start(url: url)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let fallbackURL {
            SafariView(url: fallbackURL, entersReaderIfAvailable: true)
                .ignoresSafeArea()
        } else {
            switch coordinator.phase {
            case .idle, .running:
                ProgressPanel(log: coordinator.log, originalURL: url)
            case .resolved(let result):
                SafariView(url: result.resolvedURL, entersReaderIfAvailable: true)
                    .ignoresSafeArea()
            case .failed:
                FailurePanel(
                    originalURL: url,
                    log: coordinator.log,
                    onOpenOriginal: {
                        if let url { fallbackURL = url }
                    },
                    onClose: onClose
                )
            }
        }
    }
}
