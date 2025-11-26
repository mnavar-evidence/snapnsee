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
    let releaseDate: String?
    let firstAirDate: String?
    let posterPath: String?
    let backdropPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case overview
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }

    var displayTitle: String {
        return title ?? name ?? "Unknown"
    }

    var displayDate: String? {
        return releaseDate ?? firstAirDate
    }
}

struct APIError: Codable {
    let detail: String
}
