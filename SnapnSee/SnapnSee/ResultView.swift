import SwiftUI

struct ResultView: View {
    let result: RecognitionResponse
    let capturedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Captured Image
                    if let image = capturedImage {
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

                        if let date = result.tmdbMatch.displayDate {
                            Text(date)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
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

                    // Rating
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
                            }
                        }
                        .padding(.horizontal)
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
