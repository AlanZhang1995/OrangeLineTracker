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
    
    // Line-related keys (VTA All Lines support)
    // - Validates: Requirements 7.1, 7.4
    static let selectedLineId = "selectedLineId"
    static let favoriteLineIds = "favoriteLineIds"
    static let cachedLines = "cachedLines"
    static let dataVersion = "dataVersion"  // 用于迁移
    
    // Widget shared keys (简化版：直接存储当前显示的数据)
    static let widgetStationName = "widget_stationName"
    static let widgetStationShortName = "widget_stationShortName"
    static let widgetDirection = "widget_direction"
    static let widgetArrivalTimestamp1 = "widget_arrivalTimestamp1"  // 第一班车
    static let widgetArrivalTimestamp2 = "widget_arrivalTimestamp2"  // 第二班车
    static let widgetArrivalTimestamp3 = "widget_arrivalTimestamp3"  // 第三班车
    static let widgetLastUpdateTime = "widget_lastUpdateTime"
    
    // Widget line-related keys (VTA All Lines support)
    // - Validates: Requirements 9.1, 9.2, 9.3
    static let widgetLineId = "widget_lineId"
    static let widgetLineName = "widget_lineName"
    static let widgetLineColor = "widget_lineColor"  // Hex color string
}

// MARK: - App Group

/// App Group identifier for sharing data with widget
let appGroupIdentifier = "group.com.orangelinetracker"

// MARK: - StorageServiceProtocol

/// Current data version for migration tracking
/// - Version 1: Original Orange Line only
/// - Version 2: VTA All Lines support
private let currentDataVersion = 2

/// Protocol defining the storage service interface
/// - Validates: Requirements 1.4, 2.3, 7.1, 7.2, 7.3, 7.4
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
    
    // MARK: - Line-related Properties (VTA All Lines support)
    
    /// The currently selected line ID
    /// - Validates: Requirements 7.1
    var selectedLineId: String? { get set }
    
    /// The set of favorite line IDs
    /// - Validates: Requirements 7.4
    var favoriteLineIds: Set<String> { get set }
    
    /// Cached line data for offline access
    var cachedLines: [Line]? { get set }
    
    /// Saves all current preferences to persistent storage
    func save()
    
    /// Loads all preferences from persistent storage
    func load()
    
    /// Migrates data from v1 (Orange Line only) to v2 (All Lines) format if needed
    /// - Validates: Requirements 7.6, 7.7, 10.6
    func migrateFromV1IfNeeded()
    
    /// Updates widget data in shared storage
    /// - Parameters:
    ///   - stationName: 当前显示的站点名称
    ///   - stationShortName: 当前显示的站点缩写
    ///   - direction: 当前显示的方向
    ///   - arrivalMinutes: 第一班车到站分钟数
    ///   - arrivalMinutes2: 第二班车到站分钟数（可选）
    ///   - arrivalMinutes3: 第三班车到站分钟数（可选）
    ///   - lineId: 线路 ID（可选，默认 Orange）
    ///   - lineName: 线路名称（可选，默认 Orange Line）
    ///   - lineColor: 线路颜色 hex（可选，默认橙色）
    func updateWidgetData(stationName: String, stationShortName: String, direction: String, arrivalMinutes: Int?, arrivalMinutes2: Int?, arrivalMinutes3: Int?, lineId: String?, lineName: String?, lineColor: String?)
}

// MARK: - StorageService

/// Implementation of StorageServiceProtocol using UserDefaults
/// - Validates: Requirements 1.4, 2.3, 7.1, 7.2, 7.3, 7.4
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
    
    // MARK: - Line-related Properties (VTA All Lines support)
    
    /// The currently selected line ID
    /// - Validates: Requirements 7.1
    var selectedLineId: String?
    
    /// The set of favorite line IDs
    /// - Validates: Requirements 7.4
    var favoriteLineIds: Set<String> = []
    
    /// Cached line data for offline access
    var cachedLines: [Line]?
    
    // MARK: - Initialization
    
    /// Creates a new StorageService instance
    /// - Parameter userDefaults: The UserDefaults instance to use (defaults to .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - StorageServiceProtocol Methods
    
    /// Saves all current preferences to UserDefaults
    /// - Validates: Requirements 1.4, 2.3, 7.1, 7.2, 7.4
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
        
        // Save selected line ID
        // - Validates: Requirements 7.1
        if let lineId = selectedLineId {
            userDefaults.set(lineId, forKey: StorageKeys.selectedLineId)
        } else {
            userDefaults.removeObject(forKey: StorageKeys.selectedLineId)
        }
        
        // Save favorite line IDs
        // - Validates: Requirements 7.4
        let favoriteLineIdsArray = Array(favoriteLineIds)
        userDefaults.set(favoriteLineIdsArray, forKey: StorageKeys.favoriteLineIds)
        
        // Save cached lines
        if let lines = cachedLines, let encodedLines = try? JSONEncoder().encode(lines) {
            userDefaults.set(encodedLines, forKey: StorageKeys.cachedLines)
        } else {
            userDefaults.removeObject(forKey: StorageKeys.cachedLines)
        }
    }
    
    /// Updates widget data in shared storage
    /// 存储最多 3 班车的到站时间戳，Widget 可以自动切换到下一班车
    /// - Parameters:
    ///   - stationName: 当前显示的站点名称
    ///   - stationShortName: 当前显示的站点缩写
    ///   - direction: 当前显示的方向
    ///   - arrivalMinutes: 第一班车到站分钟数（nil 表示无数据）
    ///   - arrivalMinutes2: 第二班车到站分钟数（可选）
    ///   - arrivalMinutes3: 第三班车到站分钟数（可选）
    ///   - lineId: 线路 ID（可选，默认 Orange）
    ///   - lineName: 线路名称（可选，默认 Orange Line）
    ///   - lineColor: 线路颜色 hex（可选，默认橙色）
    func updateWidgetData(stationName: String, stationShortName: String, direction: String, arrivalMinutes: Int?, arrivalMinutes2: Int? = nil, arrivalMinutes3: Int? = nil, lineId: String? = nil, lineName: String? = nil, lineColor: String? = nil) {
        cachedArrivalMinutes = arrivalMinutes
        lastUpdateTime = Date()
        let now = Date()
        
        // 存储当前显示的站点和方向
        sharedDefaults?.set(stationName, forKey: StorageKeys.widgetStationName)
        sharedDefaults?.set(stationShortName, forKey: StorageKeys.widgetStationShortName)
        sharedDefaults?.set(direction, forKey: StorageKeys.widgetDirection)
        
        // 存储线路信息 (VTA All Lines support)
        // - Validates: Requirements 9.1, 9.2, 9.3
        sharedDefaults?.set(lineId ?? "Orange", forKey: StorageKeys.widgetLineId)
        sharedDefaults?.set(lineName ?? "Orange Line", forKey: StorageKeys.widgetLineName)
        sharedDefaults?.set(lineColor ?? "#FF8C00", forKey: StorageKeys.widgetLineColor)
        
        // 存储第一班车到站时间戳
        if let minutes = arrivalMinutes {
            let arrivalTimestamp = now.addingTimeInterval(TimeInterval(minutes * 60))
            sharedDefaults?.set(arrivalTimestamp.timeIntervalSince1970, forKey: StorageKeys.widgetArrivalTimestamp1)
        } else {
            sharedDefaults?.removeObject(forKey: StorageKeys.widgetArrivalTimestamp1)
        }
        
        // 存储第二班车到站时间戳
        if let minutes2 = arrivalMinutes2 {
            let arrivalTimestamp2 = now.addingTimeInterval(TimeInterval(minutes2 * 60))
            sharedDefaults?.set(arrivalTimestamp2.timeIntervalSince1970, forKey: StorageKeys.widgetArrivalTimestamp2)
        } else {
            sharedDefaults?.removeObject(forKey: StorageKeys.widgetArrivalTimestamp2)
        }
        
        // 存储第三班车到站时间戳
        if let minutes3 = arrivalMinutes3 {
            let arrivalTimestamp3 = now.addingTimeInterval(TimeInterval(minutes3 * 60))
            sharedDefaults?.set(arrivalTimestamp3.timeIntervalSince1970, forKey: StorageKeys.widgetArrivalTimestamp3)
        } else {
            sharedDefaults?.removeObject(forKey: StorageKeys.widgetArrivalTimestamp3)
        }
        
        // 存储更新时间
        sharedDefaults?.set(now.timeIntervalSince1970, forKey: StorageKeys.widgetLastUpdateTime)
        
        let train2Str = arrivalMinutes2.map { "\($0)" } ?? "-"
        let train3Str = arrivalMinutes3.map { "\($0)" } ?? "-"
        let lineStr = lineName ?? "Orange Line"
        print("StorageService: 📱 Widget data updated - \(lineStr) \(stationName) \(direction) trains: \(arrivalMinutes ?? -1)/\(train2Str)/\(train3Str) min")
    }
    
    /// Loads all preferences from UserDefaults
    /// - Validates: Requirements 7.1, 7.3, 7.4
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
        
        // Load selected line ID
        // - Validates: Requirements 7.1
        selectedLineId = userDefaults.string(forKey: StorageKeys.selectedLineId)
        
        // Load favorite line IDs
        // - Validates: Requirements 7.4
        if let favoriteLineIdsArray = userDefaults.stringArray(forKey: StorageKeys.favoriteLineIds) {
            favoriteLineIds = Set(favoriteLineIdsArray)
        } else {
            favoriteLineIds = []
        }
        
        // Load cached lines
        if let encodedLines = userDefaults.data(forKey: StorageKeys.cachedLines),
           let decodedLines = try? JSONDecoder().decode([Line].self, from: encodedLines) {
            cachedLines = decodedLines
        } else {
            cachedLines = nil
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Clears all stored preferences
    func clearAll() {
        userDefaults.removeObject(forKey: StorageKeys.selectedStationId)
        userDefaults.removeObject(forKey: StorageKeys.selectedDirection)
        userDefaults.removeObject(forKey: StorageKeys.timeRules)
        userDefaults.removeObject(forKey: StorageKeys.isTimeRuleEnabled)
        userDefaults.removeObject(forKey: StorageKeys.selectedLineId)
        userDefaults.removeObject(forKey: StorageKeys.favoriteLineIds)
        userDefaults.removeObject(forKey: StorageKeys.cachedLines)
        
        selectedStation = nil
        selectedDirection = nil
        timeRules = []
        isTimeRuleEnabled = false
        isSmartRefreshEnabled = true
        selectedLineId = nil
        favoriteLineIds = []
        cachedLines = nil
    }
    
    /// Checks if there are any saved preferences
    var hasStoredPreferences: Bool {
        userDefaults.string(forKey: StorageKeys.selectedStationId) != nil ||
        userDefaults.string(forKey: StorageKeys.selectedDirection) != nil
    }
    
    // MARK: - Data Migration
    
    /// Migrates data from v1 (Orange Line only) to v2 (All Lines) format if needed
    /// - Validates: Requirements 7.6, 7.7, 10.6
    func migrateFromV1IfNeeded() {
        let storedVersion = userDefaults.integer(forKey: StorageKeys.dataVersion)
        
        // If already at current version, no migration needed
        if storedVersion >= currentDataVersion {
            print("StorageService: ✅ Data already at version \(storedVersion), no migration needed")
            return
        }
        
        print("StorageService: 🔄 Migrating data from version \(storedVersion) to \(currentDataVersion)")
        
        // Migrate from v1 (or no version) to v2
        if storedVersion < 2 {
            migrateToV2()
        }
        
        // Update version number
        userDefaults.set(currentDataVersion, forKey: StorageKeys.dataVersion)
        print("StorageService: ✅ Migration complete, now at version \(currentDataVersion)")
    }
    
    /// Migrates from v1 to v2 format
    /// - Sets default lineId to "Orange Line" for existing users
    /// - Preserves existing station and direction selections
    /// - Validates: Requirements 7.6, 7.7, 10.6
    private func migrateToV2() {
        // Check if user has existing preferences (v1 data)
        let hasExistingStation = userDefaults.string(forKey: StorageKeys.selectedStationId) != nil
        let hasExistingDirection = userDefaults.string(forKey: StorageKeys.selectedDirection) != nil
        
        if hasExistingStation || hasExistingDirection {
            // User has v1 data - set default line to Orange Line
            if selectedLineId == nil {
                selectedLineId = "Orange Line"
                userDefaults.set("Orange Line", forKey: StorageKeys.selectedLineId)
                print("StorageService: 📦 Migrated existing user to Orange Line")
            }
        }
        
        // Note: Station and direction data remain unchanged
        // The existing selectedStationId and selectedDirection keys are still valid
        // because Orange Line stations use the same IDs in v2
    }
}

