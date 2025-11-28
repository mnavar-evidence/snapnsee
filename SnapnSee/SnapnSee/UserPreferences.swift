import Foundation
import SwiftData

@Model
class UserPreferences {
    var selectedServices: [String]  // Provider IDs: ["netflix", "hulu", "hbo"]
    var country: String              // For TMDB providers API
    var notificationTime: Int        // Hour of day (0-23)
    var weeklyDigestEnabled: Bool
    var lastUpdated: Date

    init(
        selectedServices: [String] = [],
        country: String = "US",
        notificationTime: Int = 19,  // 7 PM
        weeklyDigestEnabled: Bool = true
    ) {
        self.selectedServices = selectedServices
        self.country = country
        self.notificationTime = notificationTime
        self.weeklyDigestEnabled = weeklyDigestEnabled
        self.lastUpdated = Date()
    }

    func toggleService(_ serviceId: String) {
        if selectedServices.contains(serviceId) {
            selectedServices.removeAll { $0 == serviceId }
        } else {
            selectedServices.append(serviceId)
        }
        lastUpdated = Date()
    }

    func hasService(_ serviceId: String) -> Bool {
        selectedServices.contains(serviceId)
    }

    var hasAnyServices: Bool {
        !selectedServices.isEmpty
    }
}

// Streaming service data
struct StreamingService: Identifiable {
    let id: String
    let name: String
    let logoName: String  // SF Symbol name
    let color: String     // Hex color

    static let allServices: [StreamingService] = [
        StreamingService(id: "netflix", name: "Netflix", logoName: "film.fill", color: "E50914"),
        StreamingService(id: "hulu", name: "Hulu", logoName: "play.tv.fill", color: "1CE783"),
        StreamingService(id: "hbo", name: "HBO Max", logoName: "h.square.fill", color: "B31CF8"),
        StreamingService(id: "disney", name: "Disney+", logoName: "sparkles.tv.fill", color: "113CCF"),
        StreamingService(id: "prime", name: "Prime Video", logoName: "amazonlogo", color: "00A8E1"),
        StreamingService(id: "apple", name: "Apple TV+", logoName: "appletv.fill", color: "000000"),
        StreamingService(id: "paramount", name: "Paramount+", logoName: "mountain.2.fill", color: "0064FF"),
        StreamingService(id: "peacock", name: "Peacock", logoName: "bird.fill", color: "000000"),
        StreamingService(id: "showtime", name: "Showtime", logoName: "s.square.fill", color: "D6182E"),
        StreamingService(id: "starz", name: "Starz", logoName: "star.fill", color: "000000"),
    ]
}
