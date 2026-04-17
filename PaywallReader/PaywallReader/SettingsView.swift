import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Volgorde en aan/uit van strategieën komt in Phase 3.")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Unlock-strategieën")
            }
        }
        .navigationTitle("Instellingen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
