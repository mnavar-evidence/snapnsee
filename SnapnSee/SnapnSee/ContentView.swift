import SwiftUI

struct ContentView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var recognitionResult: RecognitionResponse?
    @State private var errorMessage: String?
    @State private var showResult = false
    @State private var showError = false

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Logo and Title
                VStack(spacing: 10) {
                    Text("📸")
                        .font(.system(size: 80))

                    Text("SnapnSee")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("Snap the screen. Know the vibe.")
                        .font(.title3)
                        .italic()
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Preview Image
                if let image = capturedImage {
                    VStack(spacing: 15) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.3), radius: 10)

                        HStack(spacing: 15) {
                            // Retake Button
                            Button(action: {
                                capturedImage = nil
                            }) {
                                HStack {
                                    Image(systemName: "camera.rotate")
                                    Text("Retake")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(25)
                            }

                            // Analyze Button
                            Button(action: {
                                analyzeImage()
                            }) {
                                HStack {
                                    if isAnalyzing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "sparkles")
                                        Text("Analyze")
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(25)
                            }
                            .disabled(isAnalyzing)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
                    .padding(.horizontal)
                } else {
                    // Camera Button
                    Button(action: {
                        showCamera = true
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 50))

                            Text("Point Camera at TV")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.2))
                                .shadow(color: .black.opacity(0.2), radius: 10)
                        )
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()

                // Info Text
                Text("Point your camera at a Netflix screen\nto identify what's playing")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showCamera) {
            CustomCameraView(capturedImage: $capturedImage)
        }
        .sheet(isPresented: $showResult) {
            if let result = recognitionResult {
                ResultView(result: result, capturedImage: capturedImage)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }

    func analyzeImage() {
        guard let image = capturedImage else { return }

        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.recognizeImage(image)
                await MainActor.run {
                    self.recognitionResult = result
                    self.isAnalyzing = false
                    self.showResult = true
                }
            } catch {
                await MainActor.run {
                    self.isAnalyzing = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

// Extension to support hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
