import SwiftUI
import UnlockKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: UnlockSettings

    private let store: SettingsStore

    init(store: SettingsStore = UserDefaultsSettingsStore()) {
        self.store = store
        self.settings = store.load()
    }

    func toggle(_ id: String, enabled: Bool) {
        guard let idx = settings.entries.firstIndex(where: { $0.id == id }) else { return }
        settings.entries[idx].enabled = enabled
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        settings.entries.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    func resetToDefaults() {
        settings = .default
        persist()
    }

    private func persist() {
        store.save(settings)
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.editMode) private var editMode

    var body: some View {
        Form {
            Section {
                List {
                    ForEach(viewModel.settings.entries) { entry in
                        Toggle(
                            UnlockSettings.displayLabel(for: entry.id),
                            isOn: Binding(
                                get: { entry.enabled },
                                set: { viewModel.toggle(entry.id, enabled: $0) }
                            )
                        )
                    }
                    .onMove(perform: viewModel.move)
                }
            } header: {
                Text("Strategieën")
            } footer: {
                Text("De strategieën worden in deze volgorde geprobeerd. De reader-fallback op de originele URL is altijd actief als laatste.")
            }

            Section {
                Button("Terug naar standaard", role: .destructive) {
                    viewModel.resetToDefaults()
                }
            }
        }
        .navigationTitle("Instellingen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
