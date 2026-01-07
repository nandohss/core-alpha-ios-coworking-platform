import Foundation

enum AppConfig {
    // Centralized API base URL (includes stage /pro)
    static let apiBaseURL: URL = {
        // If you need to switch environments, change only this line.
        // Example: dev -> 
        // return URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/dev")!
        return URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro")!
    }()
}
