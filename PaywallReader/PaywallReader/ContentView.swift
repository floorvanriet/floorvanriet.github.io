import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label {
                        Text("Deel een artikel-URL vanuit Safari of een andere app naar **PaywallReader** om de paywall te proberen te omzeilen.")
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                } header: {
                    Text("Hoe gebruik je de extension")
                } footer: {
                    Text("Activeer de extension eenmalig via het deelmenu → \"Bewerken\" → PaywallReader.")
                }

                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Instellingen", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("PaywallReader")
        }
    }
}

#Preview {
    ContentView()
}
