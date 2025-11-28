import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(0)

            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "list.and.film")
                }
                .badge(WatchlistManager.shared.unwatchedItems.count)
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .onAppear {
            // Setup WatchlistManager with modelContext
            WatchlistManager.shared.setup(modelContext: modelContext)
        }
    }
}
