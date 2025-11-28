import Foundation

// MARK: - API Response Models

struct RecognitionResponse: Codable {
    let method: String?
    let extractedTitle: String?
    let identifiedMediaId: String
    let mediaType: String?
    let matchConfidence: Double
    let tmdbMatch: TMDBMatch

    enum CodingKeys: String, CodingKey {
        case method
        case extractedTitle = "extracted_title"
        case identifiedMediaId = "identified_media_id"
        case mediaType = "media_type"
        case matchConfidence = "match_confidence"
        case tmdbMatch = "tmdb_match"
    }
}

struct TMDBMatch: Codable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let voteAverage: Double?
    let voteCount: Int?
    let releaseDate: String?
    let firstAirDate: String?
    let posterPath: String?
    let backdropPath: String?
    let tagline: String?
    let runtime: Int?
    let genres: [Genre]?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case overview
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case tagline
        case runtime
        case genres
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
        case status
    }

    var displayTitle: String {
        return title ?? name ?? "Unknown"
    }

    var displayDate: String? {
        return releaseDate ?? firstAirDate
    }

    var displayRuntime: String? {
        if let runtime = runtime, runtime > 0 {
            let hours = runtime / 60
            let minutes = runtime % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
        return nil
    }
}

struct Genre: Codable {
    let id: Int
    let name: String
}

struct APIError: Codable {
    let detail: String
}
