import SwiftUI

struct ProgressPanel: View {
    let log: [ShareCoordinator.LogEntry]
    let originalURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let originalURL {
                Text(originalURL.absoluteString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .padding(.horizontal)
            }

            List(log) { entry in
                HStack(spacing: 12) {
                    statusIcon(for: entry.state)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.label)
                            .font(.body)
                        if case .failed(let message) = entry.state {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }
            .listStyle(.plain)
        }
        .padding(.top)
    }

    @ViewBuilder
    private func statusIcon(for state: ShareCoordinator.LogEntry.State) -> some View {
        switch state {
        case .running:
            ProgressView().controlSize(.small)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
        case .succeeded:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}
