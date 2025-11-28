import SwiftUI
import SwiftData

@main
struct SnapnSeeApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [WatchlistItem.self, UserPreferences.self])
    }
}
