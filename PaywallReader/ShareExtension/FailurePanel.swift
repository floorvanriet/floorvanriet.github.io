import SwiftUI

struct FailurePanel: View {
    let originalURL: URL?
    let log: [ShareCoordinator.LogEntry]
    let onOpenOriginal: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 42))
                .foregroundStyle(.orange)

            Text("Kon geen snapshot vinden")
                .font(.headline)

            if !log.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(log) { entry in
                        if case .failed(let message) = entry.state {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.label).font(.subheadline)
                                    Text(message).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 10) {
                if originalURL != nil {
                    Button(action: onOpenOriginal) {
                        Label("Open origineel in reader", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button("Sluit", action: onClose)
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
