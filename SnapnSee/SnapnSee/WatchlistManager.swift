import Foundation
import SwiftData

@MainActor
class WatchlistManager: ObservableObject {
    static let shared = WatchlistManager()

    @Published var items: [WatchlistItem] = []
    private var modelContext: ModelContext?

    private init() {}

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchItems()
    }

    func fetchItems() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<WatchlistItem>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )

        do {
            items = try context.fetch(descriptor)
        } catch {
            print("Error fetching watchlist: \(error)")
            items = []
        }
    }

    func add(
        id: String,
        mediaType: String,
        title: String,
        posterPath: String? = nil,
        overview: String? = nil,
        voteAverage: Double? = nil,
        releaseDate: String? = nil,
        sourceProvider: String? = nil,
        scanConfidence: Double? = nil,
        status: WatchingStatus = .toWatch
    ) {
        guard let context = modelContext else { return }

        // Check if already exists
        if isInWatchlist(id: id) {
            return
        }

        let item = WatchlistItem(
            id: id,
            mediaType: mediaType,
            title: title,
            posterPath: posterPath,
            overview: overview,
            voteAverage: voteAverage,
            releaseDate: releaseDate,
            sourceProvider: sourceProvider,
            scanConfidence: scanConfidence,
            status: status
        )

        context.insert(item)

        do {
            try context.save()
            fetchItems()
        } catch {
            print("Error saving watchlist item: \(error)")
        }
    }

    func remove(item: WatchlistItem) {
        guard let context = modelContext else { return }

        context.delete(item)

        do {
            try context.save()
            fetchItems()
        } catch {
            print("Error deleting watchlist item: \(error)")
        }
    }

    func markAsWatched(item: WatchlistItem) {
        guard let context = modelContext else { return }

        item.markAsWatched()

        do {
            try context.save()
            fetchItems()
        } catch {
            print("Error updating watchlist item: \(error)")
        }
    }

    func markAsToWatch(item: WatchlistItem) {
        guard let context = modelContext else { return }

        item.markAsToWatch()

        do {
            try context.save()
            fetchItems()
        } catch {
            print("Error updating watchlist item: \(error)")
        }
    }

    func markAsWatchingNow(item: WatchlistItem) {
        guard let context = modelContext else { return }

        item.markAsWatchingNow()

        do {
            try context.save()
            fetchItems()
        } catch {
            print("Error updating watchlist item: \(error)")
        }
    }

    func isInWatchlist(id: String) -> Bool {
        return items.contains { $0.id == id }
    }

    var unwatchedItems: [WatchlistItem] {
        items.filter { !$0.isWatched }
    }

    var watchedItems: [WatchlistItem] {
        items.filter { $0.isWatched }
    }

    var watchingNowItems: [WatchlistItem] {
        items.filter { $0.isWatchingNow }
    }

    var toWatchItems: [WatchlistItem] {
        items.filter { $0.isToWatch }
    }
}
