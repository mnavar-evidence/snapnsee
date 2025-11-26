import Foundation
import UIKit

class APIService {
    static let shared = APIService()

    private init() {}

    func recognizeImage(_ image: UIImage) async throws -> RecognitionResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIServiceError.invalidImage
        }

        guard let url = URL(string: Config.API_RECOGNIZE_ENDPOINT) else {
            throw APIServiceError.invalidURL
        }

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 200 {
            let decoder = JSONDecoder()
            let result = try decoder.decode(RecognitionResponse.self, from: data)
            return result
        } else if httpResponse.statusCode == 404 {
            let decoder = JSONDecoder()
            if let errorResponse = try? decoder.decode(APIError.self, from: data) {
                throw APIServiceError.notFound(errorResponse.detail)
            }
            throw APIServiceError.notFound("Could not identify the media")
        } else {
            throw APIServiceError.serverError(httpResponse.statusCode)
        }
    }
}

enum APIServiceError: LocalizedError {
    case invalidImage
    case invalidURL
    case invalidResponse
    case notFound(String)
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .notFound(let message):
            return message
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}
