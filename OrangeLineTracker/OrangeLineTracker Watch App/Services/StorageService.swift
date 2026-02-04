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
    
    // Widget shared keys
    static let selectedStationName = "selectedStationName"
    static let selectedStationShortName = "selectedStationShortName"
    static let cachedArrivalMinutes = "cachedArrivalMinutes"
    static let lastUpdateTime = "lastUpdateTime"
    static let arrivalTimestamp = "arrivalTimestamp"  // 到站时间戳，用于本地倒计时
    static let widgetTimeRules = "widgetTimeRules"  // Widget 用的时间规则
}

// MARK: - App Group

/// App Group identifier for sharing data with widget
let appGroupIdentifier = "group.com.orangelinetracker"

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
    
    /// Cached arrival minutes for widget
    var cachedArrivalMinutes: Int? { get set }
    
    /// Last update time for widget staleness check
    var lastUpdateTime: Date? { get set }
    
    /// Saves all current preferences to persistent storage
    func save()
    
    /// Loads all preferences from persistent storage
    func load()
    
    /// Updates widget data in shared storage
    func updateWidgetData(arrivalMinutes: Int?)
}

// MARK: - StorageService

/// Implementation of StorageServiceProtocol using UserDefaults
/// - Validates: Requirements 1.4, 2.3, 7.1, 7.2, 7.3
class StorageService: StorageServiceProtocol {
    
    // MARK: - Properties
    
    /// The UserDefaults instance used for storage
    private let userDefaults: UserDefaults
    
    /// Shared UserDefaults for widget communication
    private let sharedDefaults: UserDefaults?
    
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
    
    /// Cached arrival minutes for widget
    var cachedArrivalMinutes: Int?
    
    /// Last update time for widget staleness check
    var lastUpdateTime: Date?
    
    // MARK: - Initialization
    
    /// Creates a new StorageService instance
    /// - Parameter userDefaults: The UserDefaults instance to use (defaults to .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - StorageServiceProtocol Methods
    
    /// Saves all current preferences to UserDefaults
    /// - Validates: Requirements 1.4, 2.3, 7.1, 7.2
    func save() {
        // Save selected station ID
        if let station = selectedStation {
            userDefaults.set(station.id, forKey: StorageKeys.selectedStationId)
            // Also save to shared defaults for widget
            sharedDefaults?.set(station.name, forKey: StorageKeys.selectedStationName)
            sharedDefaults?.set(station.shortName, forKey: StorageKeys.selectedStationShortName)
            print("StorageService: 💾 Saved station to widget: \(station.name) (\(station.shortName))")
        } else {
            userDefaults.removeObject(forKey: StorageKeys.selectedStationId)
            sharedDefaults?.removeObject(forKey: StorageKeys.selectedStationName)
            sharedDefaults?.removeObject(forKey: StorageKeys.selectedStationShortName)
            print("StorageService: 💾 Cleared station from widget")
        }
        
        // Save selected direction
        if let direction = selectedDirection {
            userDefaults.set(direction.rawValue, forKey: StorageKeys.selectedDirection)
            // Also save to shared defaults for widget
            sharedDefaults?.set(direction.rawValue, forKey: StorageKeys.selectedDirection)
            print("StorageService: 💾 Saved direction to widget: \(direction.rawValue)")
        } else {
            userDefaults.removeObject(forKey: StorageKeys.selectedDirection)
            sharedDefaults?.removeObject(forKey: StorageKeys.selectedDirection)
            print("StorageService: 💾 Cleared direction from widget")
        }
        
        // Clear cached arrival data when station/direction changes
        // This forces widget to show new station info immediately
        sharedDefaults?.removeObject(forKey: StorageKeys.cachedArrivalMinutes)
        sharedDefaults?.removeObject(forKey: StorageKeys.arrivalTimestamp)
        
        // Save time rules
        if let encodedRules = try? JSONEncoder().encode(timeRules) {
            userDefaults.set(encodedRules, forKey: StorageKeys.timeRules)
        }
        
        // Save time rule enabled state
        userDefaults.set(isTimeRuleEnabled, forKey: StorageKeys.isTimeRuleEnabled)
        
        // Sync time rules to widget shared defaults
        syncTimeRulesToWidget()
    }
    
    /// Syncs time rules to widget shared defaults
    private func syncTimeRulesToWidget() {
        // Convert TimeRule to WidgetTimeRule format
        let widgetRules = timeRules.map { rule -> WidgetTimeRule in
            let station = OrangeLineStations.station(byId: rule.stationId)
            return WidgetTimeRule(
                id: rule.id,
                name: rule.name,
                triggerHour: rule.triggerHour,
                triggerMinute: rule.triggerMinute,
                stationId: rule.stationId,
                stationName: station?.name ?? "--",
                stationShortName: station?.shortName ?? "--",
                direction: rule.direction.rawValue,
                isEnabled: rule.isEnabled
            )
        }
        
        if let encodedRules = try? JSONEncoder().encode(widgetRules) {
            sharedDefaults?.set(encodedRules, forKey: StorageKeys.timeRules)
        }
        sharedDefaults?.set(isTimeRuleEnabled, forKey: StorageKeys.isTimeRuleEnabled)
    }
    
    /// Updates widget data in shared storage
    /// Stores arrival timestamp for local countdown calculation
    func updateWidgetData(arrivalMinutes: Int?) {
        cachedArrivalMinutes = arrivalMinutes
        lastUpdateTime = Date()
        
        if let minutes = arrivalMinutes {
            sharedDefaults?.set(minutes, forKey: StorageKeys.cachedArrivalMinutes)
            // 存储到站时间戳，Widget 可以根据当前时间动态计算倒计时
            let arrivalTimestamp = Date().addingTimeInterval(TimeInterval(minutes * 60))
            sharedDefaults?.set(arrivalTimestamp.timeIntervalSince1970, forKey: StorageKeys.arrivalTimestamp)
        } else {
            sharedDefaults?.removeObject(forKey: StorageKeys.cachedArrivalMinutes)
            sharedDefaults?.removeObject(forKey: StorageKeys.arrivalTimestamp)
        }
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: StorageKeys.lastUpdateTime)
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


// MARK: - Widget Time Rule

/// Simplified TimeRule structure for Widget (to avoid circular dependencies)
struct WidgetTimeRule: Codable {
    let id: UUID
    let name: String
    let triggerHour: Int
    let triggerMinute: Int
    let stationId: String
    let stationName: String
    let stationShortName: String
    let direction: String
    let isEnabled: Bool
}
