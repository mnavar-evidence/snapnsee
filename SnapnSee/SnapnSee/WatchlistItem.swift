import Foundation
import SwiftData

enum WatchingStatus: String, Codable {
    case watchingNow = "watching_now"
    case toWatch = "to_watch"
    case watched = "watched"
}

@Model
class WatchlistItem {
    @Attribute(.unique) var id: String
    var mediaType: String
    var title: String
    var posterPath: String?
    var overview: String?
    var voteAverage: Double?
    var releaseDate: String?
    var addedAt: Date
    var watchedAt: Date?
    var statusRaw: String  // Store enum as string for SwiftData

    // Future sync fields (cloud-ready)
    var sourceProvider: String?
    var scanConfidence: Double?
    var userServices: [String]?
    var availableOn: [String]?  // Streaming providers

    init(
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
        self.id = id
        self.mediaType = mediaType
        self.title = title
        self.posterPath = posterPath
        self.overview = overview
        self.voteAverage = voteAverage
        self.releaseDate = releaseDate
        self.addedAt = Date()
        self.sourceProvider = sourceProvider
        self.scanConfidence = scanConfidence
        self.statusRaw = status.rawValue
    }

    var status: WatchingStatus {
        get {
            WatchingStatus(rawValue: statusRaw) ?? .toWatch
        }
        set {
            statusRaw = newValue.rawValue
            if newValue == .watched && watchedAt == nil {
                watchedAt = Date()
            }
        }
    }

    var isWatched: Bool {
        status == .watched
    }

    var isWatchingNow: Bool {
        status == .watchingNow
    }

    var isToWatch: Bool {
        status == .toWatch
    }

    func markAsWatched() {
        status = .watched
        watchedAt = Date()
    }

    func markAsWatchingNow() {
        status = .watchingNow
    }

    func markAsToWatch() {
        status = .toWatch
        watchedAt = nil
    }
}
