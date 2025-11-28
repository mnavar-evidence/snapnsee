import SwiftUI
import SwiftData

struct WatchlistView: View {
    @ObservedObject var watchlistManager = WatchlistManager.shared
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack {
                // Segmented control for Watching Now/To Watch/Watched
                Picker("Filter", selection: $selectedTab) {
                    Text("Watching (\(watchlistManager.watchingNowItems.count))").tag(0)
                    Text("To Watch (\(watchlistManager.toWatchItems.count))").tag(1)
                    Text("Watched (\(watchlistManager.watchedItems.count))").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if selectedTab == 0 {
                    // Watching Now items
                    if watchlistManager.watchingNowItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "play.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Not watching anything right now")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Scan a movie or show you're watching")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(watchlistManager.watchingNowItems, id: \.id) { item in
                                WatchlistItemRow(item: item)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            watchlistManager.remove(item: item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            watchlistManager.markAsWatched(item: item)
                                        } label: {
                                            Label("Finished", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                } else if selectedTab == 1 {
                    // To Watch items
                    if watchlistManager.toWatchItems.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(watchlistManager.toWatchItems, id: \.id) { item in
                                WatchlistItemRow(item: item)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            watchlistManager.remove(item: item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            watchlistManager.markAsWatched(item: item)
                                        } label: {
                                            Label("Watched", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                } else {
                    // Watched items
                    if watchlistManager.watchedItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No watched items yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(watchlistManager.watchedItems, id: \.id) { item in
                                WatchlistItemRow(item: item)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            watchlistManager.remove(item: item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            watchlistManager.markAsToWatch(item: item)
                                        } label: {
                                            Label("Watch Again", systemImage: "arrow.uturn.backward.circle.fill")
                                        }
                                        .tint(.orange)
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("My Watchlist")
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.and.film")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Your watchlist is empty")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Scan a movie or show and add it to your watchlist")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WatchlistItemRow: View {
    let item: WatchlistItem
    @Query private var preferences: [UserPreferences]
    @State private var providers: [String] = []
    @State private var isLoadingProviders = false

    var currentPreferences: UserPreferences? {
        preferences.first
    }

    var body: some View {
        HStack(spacing: 12) {
            // Poster
            if let posterPath = item.posterPath {
                AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(posterPath)")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                    case .failure(_), .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "film")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 90)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "film")
                            .foregroundColor(.gray)
                    )
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                if let releaseDate = item.releaseDate {
                    Text(releaseDate)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if let rating = item.voteAverage {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                // Provider badges
                if !providers.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(providers.prefix(3), id: \.self) { providerId in
                            if let service = StreamingService.allServices.first(where: { $0.id == providerId }) {
                                HStack(spacing: 2) {
                                    Image(systemName: service.logoName)
                                        .font(.system(size: 8))
                                    Text(service.name)
                                        .font(.system(size: 9))
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    Color(hex: service.color).opacity(
                                        currentPreferences?.hasService(service.id) == true ? 0.2 : 0.1
                                    )
                                )
                                .foregroundColor(Color(hex: service.color))
                                .cornerRadius(4)
                            }
                        }
                        if providers.count > 3 {
                            Text("+\(providers.count - 3)")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                    }
                } else if isLoadingProviders {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.5)
                        Text("Checking...")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Text("Added \(formatDate(item.addedAt))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Watched indicator
            if item.isWatched {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
        .task {
            // Fetch providers when row appears
            await fetchProviders()
        }
    }

    func fetchProviders() async {
        guard providers.isEmpty && !isLoadingProviders else { return }

        isLoadingProviders = true

        let availability = await ProvidersService.shared.fetchProviders(
            mediaId: item.id,
            mediaType: item.mediaType
        )

        switch availability {
        case .available(let providerList):
            providers = providerList
        case .loading, .unavailable, .unknown, .error:
            providers = []
        }

        isLoadingProviders = false
    }

    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInYesterday(date) {
            return "yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days < 7 {
                return "\(days) days ago"
            } else if days < 30 {
                let weeks = days / 7
                return "\(weeks) week\(weeks > 1 ? "s" : "") ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: date)
            }
        }
    }
}
