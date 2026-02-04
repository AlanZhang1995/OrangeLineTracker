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
    static let isSmartRefreshEnabled = "isSmartRefreshEnabled"
    
    // Widget shared keys (简化版：直接存储当前显示的数据)
    static let widgetStationName = "widget_stationName"
    static let widgetStationShortName = "widget_stationShortName"
    static let widgetDirection = "widget_direction"
    static let widgetArrivalTimestamp = "widget_arrivalTimestamp"
    static let widgetLastUpdateTime = "widget_lastUpdateTime"
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
    
    /// Whether smart background refresh is enabled (vs random interval)
    var isSmartRefreshEnabled: Bool { get set }
    
    /// Cached arrival minutes for widget
    var cachedArrivalMinutes: Int? { get set }
    
    /// Last update time for widget staleness check
    var lastUpdateTime: Date? { get set }
    
    /// Saves all current preferences to persistent storage
    func save()
    
    /// Loads all preferences from persistent storage
    func load()
    
    /// Updates widget data in shared storage
    /// - Parameters:
    ///   - stationName: 当前显示的站点名称
    ///   - stationShortName: 当前显示的站点缩写
    ///   - direction: 当前显示的方向
    ///   - arrivalMinutes: 到站分钟数
    func updateWidgetData(stationName: String, stationShortName: String, direction: String, arrivalMinutes: Int?)
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
    
    /// Whether smart background refresh is enabled
    /// When true: uses smart refresh based on arrival time
    /// When false: uses random interval (10-20 minutes)
    var isSmartRefreshEnabled: Bool = true
    
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
        
        // Save smart refresh enabled state
        userDefaults.set(isSmartRefreshEnabled, forKey: StorageKeys.isSmartRefreshEnabled)
    }
    
    /// Updates widget data in shared storage
    /// 直接存储当前 ArrivalView 显示的数据，Widget 只需读取即可
    /// - Parameters:
    ///   - stationName: 当前显示的站点名称
    ///   - stationShortName: 当前显示的站点缩写
    ///   - direction: 当前显示的方向
    ///   - arrivalMinutes: 到站分钟数（nil 表示无数据）
    func updateWidgetData(stationName: String, stationShortName: String, direction: String, arrivalMinutes: Int?) {
        cachedArrivalMinutes = arrivalMinutes
        lastUpdateTime = Date()
        
        // 存储当前显示的站点和方向
        sharedDefaults?.set(stationName, forKey: StorageKeys.widgetStationName)
        sharedDefaults?.set(stationShortName, forKey: StorageKeys.widgetStationShortName)
        sharedDefaults?.set(direction, forKey: StorageKeys.widgetDirection)
        
        // 存储到站时间戳
        if let minutes = arrivalMinutes {
            let arrivalTimestamp = Date().addingTimeInterval(TimeInterval(minutes * 60))
            sharedDefaults?.set(arrivalTimestamp.timeIntervalSince1970, forKey: StorageKeys.widgetArrivalTimestamp)
        } else {
            sharedDefaults?.removeObject(forKey: StorageKeys.widgetArrivalTimestamp)
        }
        
        // 存储更新时间
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: StorageKeys.widgetLastUpdateTime)
        
        print("StorageService: 📱 Widget data updated - \(stationName) \(direction) \(arrivalMinutes ?? -1)min")
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
        
        // Load smart refresh enabled state (default to true if not set)
        if userDefaults.object(forKey: StorageKeys.isSmartRefreshEnabled) != nil {
            isSmartRefreshEnabled = userDefaults.bool(forKey: StorageKeys.isSmartRefreshEnabled)
        } else {
            isSmartRefreshEnabled = true
        }
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
        isSmartRefreshEnabled = true
    }
    
    /// Checks if there are any saved preferences
    var hasStoredPreferences: Bool {
        userDefaults.string(forKey: StorageKeys.selectedStationId) != nil ||
        userDefaults.string(forKey: StorageKeys.selectedDirection) != nil
    }
}

