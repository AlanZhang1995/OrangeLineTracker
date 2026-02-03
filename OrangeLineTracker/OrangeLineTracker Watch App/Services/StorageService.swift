//
//  StorageService.swift
//  OrangeLineTracker Watch App
//
//  Storage service for persisting user preferences using UserDefaults
//

import Foundation

// MARK: - Storage Keys

/// Keys used for UserDefaults storage
enum StorageKeys {
    static let selectedStationId = "selectedStationId"
    static let selectedDirection = "selectedDirection"
    static let timeRules = "timeRules"
    static let isTimeRuleEnabled = "isTimeRuleEnabled"
}

// MARK: - StorageServiceProtocol

/// Protocol defining the storage service interface
/// - Validates: Requirements 1.4, 2.3, 7.1, 7.2, 7.3
protocol StorageServiceProtocol: AnyObject {
    /// The currently selected station
    var selectedStation: Station? { get set }
    
    /// The currently selected direction
    var selectedDirection: Direction? { get set }
    
    /// The list of time rules configured by the user
    var timeRules: [TimeRule] { get set }
    
    /// Whether time rule functionality is enabled
    var isTimeRuleEnabled: Bool { get set }
    
    /// Saves all current preferences to persistent storage
    func save()
    
    /// Loads all preferences from persistent storage
    func load()
}

// MARK: - StorageService

/// Implementation of StorageServiceProtocol using UserDefaults
/// - Validates: Requirements 1.4, 2.3, 7.1, 7.2, 7.3
class StorageService: StorageServiceProtocol {
    
    // MARK: - Properties
    
    /// The UserDefaults instance used for storage
    private let userDefaults: UserDefaults
    
    /// The currently selected station
    /// - Validates: Requirements 1.4, 7.1
    var selectedStation: Station?
    
    /// The currently selected direction
    /// - Validates: Requirements 2.3, 7.2
    var selectedDirection: Direction?
    
    /// The list of time rules configured by the user
    /// - Validates: Requirements 7.3
    var timeRules: [TimeRule] = []
    
    /// Whether time rule functionality is enabled
    /// - Validates: Requirements 8.6
    var isTimeRuleEnabled: Bool = false
    
    // MARK: - Initialization
    
    /// Creates a new StorageService instance
    /// - Parameter userDefaults: The UserDefaults instance to use (defaults to .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - StorageServiceProtocol Methods
    
    /// Saves all current preferences to UserDefaults
    /// - Validates: Requirements 1.4, 2.3, 7.1, 7.2
    func save() {
        // Save selected station ID
        if let station = selectedStation {
            userDefaults.set(station.id, forKey: StorageKeys.selectedStationId)
        } else {
            userDefaults.removeObject(forKey: StorageKeys.selectedStationId)
        }
        
        // Save selected direction
        if let direction = selectedDirection {
            userDefaults.set(direction.rawValue, forKey: StorageKeys.selectedDirection)
        } else {
            userDefaults.removeObject(forKey: StorageKeys.selectedDirection)
        }
        
        // Save time rules
        if let encodedRules = try? JSONEncoder().encode(timeRules) {
            userDefaults.set(encodedRules, forKey: StorageKeys.timeRules)
        }
        
        // Save time rule enabled state
        userDefaults.set(isTimeRuleEnabled, forKey: StorageKeys.isTimeRuleEnabled)
    }
    
    /// Loads all preferences from UserDefaults
    /// - Validates: Requirements 7.3
    func load() {
        // Load selected station
        if let stationId = userDefaults.string(forKey: StorageKeys.selectedStationId) {
            selectedStation = OrangeLineStations.station(byId: stationId)
        } else {
            selectedStation = nil
        }
        
        // Load selected direction
        if let directionRawValue = userDefaults.string(forKey: StorageKeys.selectedDirection),
           let direction = Direction(rawValue: directionRawValue) {
            selectedDirection = direction
        } else {
            selectedDirection = nil
        }
        
        // Load time rules
        if let encodedRules = userDefaults.data(forKey: StorageKeys.timeRules),
           let decodedRules = try? JSONDecoder().decode([TimeRule].self, from: encodedRules) {
            timeRules = decodedRules
        } else {
            timeRules = []
        }
        
        // Load time rule enabled state
        isTimeRuleEnabled = userDefaults.bool(forKey: StorageKeys.isTimeRuleEnabled)
    }
    
    // MARK: - Convenience Methods
    
    /// Clears all stored preferences
    func clearAll() {
        userDefaults.removeObject(forKey: StorageKeys.selectedStationId)
        userDefaults.removeObject(forKey: StorageKeys.selectedDirection)
        userDefaults.removeObject(forKey: StorageKeys.timeRules)
        userDefaults.removeObject(forKey: StorageKeys.isTimeRuleEnabled)
        
        selectedStation = nil
        selectedDirection = nil
        timeRules = []
        isTimeRuleEnabled = false
    }
    
    /// Checks if there are any saved preferences
    var hasStoredPreferences: Bool {
        userDefaults.string(forKey: StorageKeys.selectedStationId) != nil ||
        userDefaults.string(forKey: StorageKeys.selectedDirection) != nil
    }
}
