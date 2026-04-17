import SwiftUI

struct ShareRootView: View {
    let url: URL?
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "newspaper")
                    .font(.system(size: 42))
                    .foregroundStyle(.tint)
                Text("Hallo vanuit PaywallReader")
                    .font(.headline)
                if let url {
                    Text(url.absoluteString)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal)
                } else {
                    Text("Geen URL ontvangen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("PaywallReader")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit", action: onClose)
                }
            }
        }
    }
}

#Preview {
    ShareRootView(url: URL(string: "https://www.nrc.nl/artikel"), onClose: {})
}
