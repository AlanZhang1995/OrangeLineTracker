//
//  APIConfig.swift
//  OrangeLineTracker Watch App
//
//  Centralized API configuration
//

import Foundation

/// API configuration for the app
/// Replace the placeholder API key with your actual 511.org API key
enum APIConfig {
    /// 511.org API key
    /// Get your free API key at: https://511.org/open-data/token
    static let vtaAPIKey = "cfc3474b-61e1-48f4-a177-0c8b8cb27cca"
    
    /// Whether the API key has been configured
    static var isConfigured: Bool {
        !vtaAPIKey.isEmpty
    }
}
