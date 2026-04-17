import UIKit
import SwiftUI
import UniformTypeIdentifiers
import UnlockKit

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        Task { @MainActor in
            let url = await extractSharedURL()
            presentUI(for: url)
        }
    }

    private func presentUI(for url: URL?) {
        let root = ShareRootView(
            url: url,
            onClose: { [weak self] in self?.finish() }
        )
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        host.didMove(toParent: self)
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func extractSharedURL() async -> URL? {
        guard
            let items = extensionContext?.inputItems as? [NSExtensionItem]
        else { return nil }
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if let url = await loadURL(from: provider) { return url }
            }
        }
        return nil
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        let type = UTType.url.identifier
        guard provider.hasItemConformingToTypeIdentifier(type) else { return nil }
        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data,
                          let str = String(data: data, encoding: .utf8),
                          let url = URL(string: str) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
