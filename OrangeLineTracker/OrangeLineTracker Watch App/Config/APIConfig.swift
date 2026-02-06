//
//  APIConfig.swift
//  OrangeLineTracker Watch App
//
//  Centralized API configuration with user API key support
//

import Foundation

/// API configuration for the app
/// Supports user-provided API key with fallback to built-in keys
/// Get your free API key at: https://511.org/open-data/token
enum APIConfig {
    
    /// Storage key for user's custom API key
    private static let userAPIKeyStorageKey = "userAPIKey"
    
    /// App Group identifier for sharing with widget
    private static let appGroupIdentifier = "group.com.orangelinetracker"
    
    /// Fallback API keys (used when user hasn't provided their own key)
    /// These are shared among all users who don't configure their own key
    private static let fallbackKeys: [String] = [
        "cfc3474b-61e1-48f4-a177-0c8b8cb27cca",
        "4f7220e9-7145-4278-b63c-fdfe3e656dee",
        "fbcf9721-bef4-4dfe-9be7-4f1a5133bb47",
        "737ee8d9-f818-4b38-9c13-94f8b01ef32e",
        "ee1f3214-9bd1-4994-be36-a718074f6404"
    ]
    
    /// Current index for round-robin rotation of fallback keys
    private static var currentFallbackIndex: Int = 0
    
    /// UserDefaults for storing user's API key
    private static var userDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
    
    // MARK: - User API Key Management
    
    /// Get the user's custom API key (if set)
    static var userAPIKey: String? {
        get {
            let key = userDefaults.string(forKey: userAPIKeyStorageKey)
            return (key?.isEmpty ?? true) ? nil : key
        }
        set {
            if let key = newValue, !key.isEmpty {
                userDefaults.set(key, forKey: userAPIKeyStorageKey)
            } else {
                userDefaults.removeObject(forKey: userAPIKeyStorageKey)
            }
        }
    }
    
    /// Whether the user has configured their own API key
    static var hasUserAPIKey: Bool {
        userAPIKey != nil
    }
    
    /// Validate if a string looks like a valid 511.org API key
    /// 511.org API keys are UUIDs (36 characters with dashes)
    static func isValidAPIKeyFormat(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (36 chars)
        let uuidRegex = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
        return trimmed.range(of: uuidRegex, options: .regularExpression) != nil
    }
    
    // MARK: - API Key Access
    
    /// Get the API key to use for requests
    /// Returns user's key if set, otherwise rotates through fallback keys
    static var vtaAPIKey: String {
        // Prefer user's API key if available
        if let userKey = userAPIKey {
            return userKey
        }
        
        // Fall back to round-robin rotation of built-in keys
        guard !fallbackKeys.isEmpty else { return "" }
        let key = fallbackKeys[currentFallbackIndex]
        currentFallbackIndex = (currentFallbackIndex + 1) % fallbackKeys.count
        return key
    }
    
    /// Number of available fallback API keys
    static var fallbackKeyCount: Int {
        fallbackKeys.count
    }
    
    /// Whether the API is configured (either user key or fallback keys available)
    static var isConfigured: Bool {
        hasUserAPIKey || !fallbackKeys.isEmpty
    }
    
    /// Clear the user's custom API key
    static func clearUserAPIKey() {
        userAPIKey = nil
    }
}
