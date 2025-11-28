import Foundation

// Backend Provider Response Model
struct ProviderResponse: Codable {
    let available: Bool
    let providers: [String]
    let country: String
    let link: String?
}

// Provider availability result
enum ProviderAvailability {
    case loading
    case available([String])  // Provider IDs: ["netflix", "hulu"]
    case unavailable
    case unknown              // No data available
    case error(String)
}

class ProvidersService {
    static let shared = ProvidersService()

    // Cache: [mediaId: (providers, timestamp)]
    private var cache: [String: (providers: [String], timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 7 * 24 * 60 * 60  // 7 days

    private init() {}

    // Fetch providers for a media item from our backend
    func fetchProviders(mediaId: String, mediaType: String, country: String = "US") async -> ProviderAvailability {
        // Check cache first
        if let cached = getCachedProviders(mediaId: mediaId) {
            return .available(cached)
        }

        // Build URL to our backend
        let endpoint = "/api/v1/providers/\(mediaType)/\(mediaId)?country=\(country)"
        guard let url = URL(string: "\(Config.API_BASE_URL)\(endpoint)") else {
            return .error("Invalid URL")
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .error("Invalid response")
            }

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    return .unavailable
                }
                return .error("HTTP \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let providerResponse = try decoder.decode(ProviderResponse.self, from: data)

            if !providerResponse.available || providerResponse.providers.isEmpty {
                return .unavailable
            }

            // Cache the result
            cacheProviders(mediaId: mediaId, providers: providerResponse.providers)

            return .available(providerResponse.providers)

        } catch {
            print("Error fetching providers: \(error)")
            return .unknown
        }
    }

    // Cache management
    private func getCachedProviders(mediaId: String) -> [String]? {
        guard let cached = cache[mediaId] else { return nil }

        // Check if cache is still valid
        let age = Date().timeIntervalSince(cached.timestamp)
        if age < cacheExpiration {
            return cached.providers
        } else {
            // Cache expired, remove it
            cache.removeValue(forKey: mediaId)
            return nil
        }
    }

    private func cacheProviders(mediaId: String, providers: [String]) {
        cache[mediaId] = (providers: providers, timestamp: Date())
    }

    // Clear cache (for testing or manual refresh)
    func clearCache() {
        cache.removeAll()
    }
}
