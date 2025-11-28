import SwiftUI

struct ResultView: View {
    let result: RecognitionResponse
    let capturedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var watchlistManager = WatchlistManager.shared
    @State private var showAddedFeedback = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Poster Image (from TMDB)
                    if let posterPath = result.tmdbMatch.posterPath {
                        AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 250)
                                    .cornerRadius(12)
                                    .shadow(radius: 8)
                            case .failure(_):
                                if let capturedImg = capturedImage {
                                    Image(uiImage: capturedImg)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .cornerRadius(12)
                                }
                            case .empty:
                                ProgressView()
                                    .frame(height: 350)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }

                    // Title
                    VStack(spacing: 8) {
                        Text(result.tmdbMatch.displayTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        // Tagline
                        if let tagline = result.tmdbMatch.tagline, !tagline.isEmpty {
                            Text("\"\(tagline)\"")
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if let date = result.tmdbMatch.displayDate {
                            Text(date)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    // Genres
                    if let genres = result.tmdbMatch.genres, !genres.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(genres, id: \.id) { genre in
                                    Text(genre.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.7))
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Action Buttons
                    if !isInWatchlist {
                        HStack(spacing: 12) {
                            // Watching Now Button
                            Button(action: markAsWatchingNow) {
                                VStack(spacing: 4) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                    Text("Watching Now")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.red]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(radius: 4)
                            }

                            // Add to Watchlist Button
                            Button(action: addToWatchlist) {
                                VStack(spacing: 4) {
                                    Image(systemName: "bookmark.circle.fill")
                                        .font(.title2)
                                    Text("Watch Later")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(radius: 4)
                            }
                        }
                        .padding(.horizontal)
                        .opacity(showAddedFeedback ? 0.6 : 1.0)
                    } else {
                        // Already added indicator
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                            Text("Added to your list")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Confidence Badge
                    HStack {
                        Text("Match Confidence")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Spacer()

                        Text("\(Int(result.matchConfidence * 100))%")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(confidenceColor(result.matchConfidence))
                            .cornerRadius(20)
                    }
                    .padding(.horizontal)

                    // Method
                    if let method = result.method {
                        HStack {
                            Text("Detection Method")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Spacer()

                            Text(method == "text_extraction" ? "📝 Text Recognition" : "👁️ Visual Match")
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                    }

                    Divider()
                        .padding(.horizontal)

                    // Rating & Runtime/Seasons
                    VStack(spacing: 12) {
                        // Rating with vote count
                        if let rating = result.tmdbMatch.voteAverage {
                            HStack {
                                Text("Rating")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f/10", rating))
                                        .font(.headline)

                                    if let voteCount = result.tmdbMatch.voteCount {
                                        Text("(\(formatVoteCount(voteCount)) votes)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Runtime (for movies) or Seasons/Episodes (for TV)
                        if let runtime = result.tmdbMatch.displayRuntime {
                            HStack {
                                Text("Runtime")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .foregroundColor(.blue)
                                    Text(runtime)
                                        .font(.headline)
                                }
                            }
                            .padding(.horizontal)
                        } else if let seasons = result.tmdbMatch.numberOfSeasons,
                                  let episodes = result.tmdbMatch.numberOfEpisodes {
                            HStack {
                                Text("Series Info")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: "tv")
                                        .foregroundColor(.blue)
                                    Text("\(seasons) Season\(seasons > 1 ? "s" : "") • \(episodes) Episodes")
                                        .font(.headline)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Status (for TV shows)
                        if let status = result.tmdbMatch.status, result.mediaType == "tv" {
                            HStack {
                                Text("Status")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Spacer()

                                Text(status)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(statusColor(status))
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Overview
                    if let overview = result.tmdbMatch.overview, !overview.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Overview")
                                .font(.headline)
                                .padding(.horizontal)

                            Text(overview)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }

                    // Media Info
                    VStack(spacing: 12) {
                        InfoRow(label: "Media ID", value: result.identifiedMediaId)

                        if let mediaType = result.mediaType {
                            InfoRow(label: "Type", value: mediaType.capitalized)
                        }

                        if let extractedTitle = result.extractedTitle {
                            InfoRow(label: "Extracted Text", value: extractedTitle)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("🎬 Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    func confidenceColor(_ confidence: Double) -> Color {
        if confidence > 0.9 {
            return .green
        } else if confidence > 0.7 {
            return .orange
        } else {
            return .red
        }
    }

    func formatVoteCount(_ count: Int) -> String {
        if count >= 1000 {
            let thousands = Double(count) / 1000.0
            return String(format: "%.1fK", thousands)
        }
        return "\(count)"
    }

    func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "returning series", "in production":
            return .green
        case "ended", "canceled", "cancelled":
            return .red
        default:
            return .gray
        }
    }

    var isInWatchlist: Bool {
        watchlistManager.isInWatchlist(id: result.identifiedMediaId)
    }

    func addToWatchlist() {
        guard !isInWatchlist else { return }

        watchlistManager.add(
            id: result.identifiedMediaId,
            mediaType: result.mediaType ?? "unknown",
            title: result.tmdbMatch.displayTitle,
            posterPath: result.tmdbMatch.posterPath,
            overview: result.tmdbMatch.overview,
            voteAverage: result.tmdbMatch.voteAverage,
            releaseDate: result.tmdbMatch.displayDate,
            sourceProvider: nil, // Future: detect from scan
            scanConfidence: result.matchConfidence,
            status: .toWatch
        )

        // Show feedback
        showAddedFeedback = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Reset feedback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showAddedFeedback = false
        }
    }

    func markAsWatchingNow() {
        guard !isInWatchlist else { return }

        watchlistManager.add(
            id: result.identifiedMediaId,
            mediaType: result.mediaType ?? "unknown",
            title: result.tmdbMatch.displayTitle,
            posterPath: result.tmdbMatch.posterPath,
            overview: result.tmdbMatch.overview,
            voteAverage: result.tmdbMatch.voteAverage,
            releaseDate: result.tmdbMatch.displayDate,
            sourceProvider: nil, // Future: detect from scan
            scanConfidence: result.matchConfidence,
            status: .watchingNow
        )

        // Show feedback
        showAddedFeedback = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Reset feedback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showAddedFeedback = false
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
    }
}
