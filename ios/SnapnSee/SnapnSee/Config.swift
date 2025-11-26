import Foundation

struct Config {
    // TODO: Update this to your Railway URL after deployment
    // Example: https://snapnsee-production.up.railway.app
    static let API_BASE_URL = "http://localhost:8000"

    static let API_RECOGNIZE_ENDPOINT = "\(API_BASE_URL)/api/v1/recognize"
}
