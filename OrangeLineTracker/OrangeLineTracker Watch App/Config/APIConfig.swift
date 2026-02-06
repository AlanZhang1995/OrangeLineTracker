//
//  APIConfig.swift
//  OrangeLineTracker Watch App
//
//  Centralized API configuration with round-robin key rotation
//

import Foundation

/// API configuration for the app with round-robin key rotation
/// Each 511.org API key has a rate limit of 60 requests/hour
/// Using multiple keys allows for more frequent API calls
enum APIConfig {
    /// Array of 511.org API keys for rotation
    /// Get your free API keys at: https://511.org/open-data/token
    /// Each key has 60 requests/hour limit
    private static let apiKeys: [String] = [
        "cfc3474b-61e1-48f4-a177-0c8b8cb27cca",  // Key 1
        "4f7220e9-7145-4278-b63c-fdfe3e656dee",
        "fbcf9721-bef4-4dfe-9be7-4f1a5133bb47",
        "737ee8d9-f818-4b38-9c13-94f8b01ef32e",
        "ee1f3214-9bd1-4994-be36-a718074f6404"
    ]
    
    /// Current index for round-robin rotation
    private static var currentIndex: Int = 0
    
    /// Get the next API key (round-robin rotation)
    /// Each call returns the next key in sequence
    static var vtaAPIKey: String {
        guard !apiKeys.isEmpty else { return "" }
        let key = apiKeys[currentIndex]
        currentIndex = (currentIndex + 1) % apiKeys.count
        if apiKeys.count > 1 {
            print("APIConfig: 🔑 Using key #\(currentIndex == 0 ? apiKeys.count : currentIndex)/\(apiKeys.count)")
        }
        return key
    }
    
    /// Number of available API keys
    static var keyCount: Int {
        apiKeys.count
    }
    
    /// Whether the API key has been configured
    static var isConfigured: Bool {
        !apiKeys.isEmpty && !apiKeys[0].isEmpty
    }
}
