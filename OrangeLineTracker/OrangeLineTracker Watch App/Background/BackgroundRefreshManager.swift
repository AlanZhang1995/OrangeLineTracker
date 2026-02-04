//
//  BackgroundRefreshManager.swift
//  OrangeLineTracker Watch App
//
//  Manages background refresh scheduling for watch complications
//  Uses WKApplicationRefreshBackgroundTask for periodic data updates
//

import Foundation
import WatchKit
import ClockKit
import WidgetKit

// MARK: - BackgroundRefreshManager

/// Manages background refresh scheduling and execution for watch complications
/// - Validates: Requirement 9.5 - periodic background updates for complication data
class BackgroundRefreshManager {
    
    // MARK: - Constants
    
    /// Default refresh interval: 15 minutes (watchOS background limitation)
    /// watchOS limits background refresh to approximately 15-minute intervals
    static let refreshInterval: TimeInterval = 15 * 60
    
    /// Minimum time between refresh attempts to avoid excessive scheduling
    private static let minimumRefreshInterval: TimeInterval = 60  // 1 minute minimum
    
    // MARK: - Smart Refresh Intervals (for foreground/active refresh)
    
    /// 智能刷新间隔配置（基于 15 分钟一班车的频率）
    /// - ≤ 5 分钟到站 → 1 分钟刷新（关键时刻，确保不错过车）
    /// - 6-10 分钟到站 → 3 分钟刷新
    /// - 11-15 分钟到站 → 5 分钟刷新
    /// - 16-20 分钟到站 → 8 分钟刷新
    /// - > 20 分钟到站 → 12 分钟刷新
    /// - 无数据/错误 → 3 分钟刷新（恢复模式）
    private static let criticalRefreshInterval: TimeInterval = 60       // 1 min (≤5 min arrival)
    private static let nearRefreshInterval: TimeInterval = 3 * 60       // 3 min (6-10 min arrival)
    private static let mediumRefreshInterval: TimeInterval = 5 * 60     // 5 min (11-15 min arrival)
    private static let farRefreshInterval: TimeInterval = 8 * 60        // 8 min (16-20 min arrival)
    private static let veryFarRefreshInterval: TimeInterval = 12 * 60   // 12 min (>20 min arrival)
    private static let recoveryRefreshInterval: TimeInterval = 3 * 60   // 3 min (no data/error)
    
    // MARK: - Random Refresh Interval (when smart refresh is disabled)
    
    /// 随机刷新间隔范围（15-60 分钟）
    private static let randomRefreshMinInterval: TimeInterval = 15 * 60  // 15 min
    private static let randomRefreshMaxInterval: TimeInterval = 60 * 60  // 60 min
    
    // MARK: - Service Hours (VTA Orange Line)
    
    /// 运营时间配置
    /// VTA Orange Line 运营时间约为 7:00 AM - 8:00 PM
    /// 夜间停运时段（8pm-7am）不刷新，节省电量
    private static let serviceStartHour = 7   // 7:00 AM
    private static let serviceEndHour = 20    // 8:00 PM
    
    // MARK: - Properties
    
    /// Shared instance for singleton access
    static let shared = BackgroundRefreshManager()
    
    /// VTA service for fetching predictions
    private let vtaService: VTAServiceProtocol
    
    /// Storage service for accessing user preferences
    private let storageService: StorageServiceProtocol
    
    /// Time rule service for checking active rules
    private let timeRuleService: TimeRuleServiceProtocol
    
    /// Complication controller for updating complications
    private let complicationController: ComplicationController
    
    /// Last successful refresh date
    private var lastRefreshDate: Date?
    
    /// Last known arrival minutes (for smart refresh calculation)
    private var lastKnownArrivalMinutes: Int?
    
    /// UserDefaults key for storing last refresh date
    private static let lastRefreshDateKey = "lastBackgroundRefreshDate"
    
    /// UserDefaults key for storing last known arrival minutes
    private static let lastArrivalMinutesKey = "lastKnownArrivalMinutes"
    
    // MARK: - Initialization
    
    /// Creates a BackgroundRefreshManager with default services
    init() {
        // Use API key from centralized configuration
        self.vtaService = VTAService(apiKey: APIConfig.vtaAPIKey)
        let storage = StorageService()
        self.storageService = storage
        self.timeRuleService = TimeRuleService(storageService: storage)
        self.complicationController = ComplicationController.shared
        loadLastRefreshDate()
    }
    
    /// Creates a BackgroundRefreshManager with custom services (for testing)
    /// - Parameters:
    ///   - vtaService: VTA service for fetching predictions
    ///   - storageService: Storage service for user preferences
    ///   - timeRuleService: Time rule service for checking active rules
    ///   - complicationController: Complication controller for updates
    init(
        vtaService: VTAServiceProtocol,
        storageService: StorageServiceProtocol,
        timeRuleService: TimeRuleServiceProtocol,
        complicationController: ComplicationController
    ) {
        self.vtaService = vtaService
        self.storageService = storageService
        self.timeRuleService = timeRuleService
        self.complicationController = complicationController
        loadLastRefreshDate()
    }
    
    // MARK: - Background Refresh Scheduling
    
    /// Schedules a background refresh task
    /// - Validates: Requirement 9.5 - schedule periodic background updates
    func scheduleBackgroundRefresh() {
        // Calculate the next refresh date
        let nextRefreshDate = calculateNextRefreshDate()
        
        // Format for logging
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let nextTimeStr = formatter.string(from: nextRefreshDate)
        let intervalMinutes = Int(nextRefreshDate.timeIntervalSinceNow / 60)
        
        // Schedule the background app refresh task
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: nextRefreshDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("BackgroundRefreshManager: ❌ Failed to schedule refresh - \(error.localizedDescription)")
            } else {
                print("BackgroundRefreshManager: ✅ Next refresh scheduled at \(nextTimeStr) (in ~\(intervalMinutes) min)")
            }
        }
    }
    
    /// Calculates the next appropriate refresh date
    /// - Returns: The date when the next refresh should occur
    private func calculateNextRefreshDate() -> Date {
        let now = Date()
        
        // 检查是否在夜间停运时段
        if isOutsideServiceHours(now) {
            // 计算下一个运营开始时间
            let nextServiceStart = calculateNextServiceStartTime(from: now)
            print("BackgroundRefreshManager: Outside service hours, scheduling for \(nextServiceStart)")
            return nextServiceStart
        }
        
        // 根据设置选择刷新间隔
        var mutableStorage = storageService
        mutableStorage.load()
        
        let effectiveInterval: TimeInterval
        if storageService.isSmartRefreshEnabled {
            // 智能刷新：根据到站时间计算间隔
            let smartInterval = calculateSmartRefreshInterval(arrivalMinutes: lastKnownArrivalMinutes)
            effectiveInterval = max(smartInterval, Self.minimumRefreshInterval)
            print("BackgroundRefreshManager: 🧠 Smart refresh enabled")
        } else {
            // 随机刷新：10-20 分钟随机间隔
            effectiveInterval = calculateRandomRefreshInterval()
            print("BackgroundRefreshManager: 🎲 Random refresh enabled")
        }
        
        // If we have a last refresh date, ensure minimum interval
        if let lastRefresh = lastRefreshDate {
            let timeSinceLastRefresh = now.timeIntervalSince(lastRefresh)
            
            if timeSinceLastRefresh < Self.minimumRefreshInterval {
                // Schedule for the effective interval from last refresh
                return lastRefresh.addingTimeInterval(effectiveInterval)
            }
        }
        
        // Schedule for the effective interval from now
        return now.addingTimeInterval(effectiveInterval)
    }
    
    /// 计算随机刷新间隔（10-20 分钟）
    /// - Returns: 随机间隔（秒）
    func calculateRandomRefreshInterval() -> TimeInterval {
        let interval = TimeInterval.random(in: Self.randomRefreshMinInterval...Self.randomRefreshMaxInterval)
        print("BackgroundRefreshManager: Random refresh interval = \(Int(interval/60)) min")
        return interval
    }
    
    // MARK: - Service Hours Check
    
    /// 检查当前时间是否在停运时段（8pm-7am）
    /// - Parameter date: 要检查的时间
    /// - Returns: true 表示在停运时段
    func isOutsideServiceHours(_ date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // 停运时段：20:00 (8pm) - 06:59 (7am前)
        // 即 hour >= 20 或 hour < 7
        return hour >= Self.serviceEndHour || hour < Self.serviceStartHour
    }
    
    /// 计算下一个运营开始时间
    /// - Parameter from: 起始时间
    /// - Returns: 下一个 7:00 AM
    private func calculateNextServiceStartTime(from date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = Self.serviceStartHour
        components.minute = 0
        components.second = 0
        
        // 如果当前时间已经过了今天的运营开始时间（即在 20:00-23:59），
        // 则下一个运营开始时间是明天 7:00
        if hour >= Self.serviceEndHour {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) {
                components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                components.hour = Self.serviceStartHour
                components.minute = 0
                components.second = 0
            }
        }
        
        return calendar.date(from: components) ?? date.addingTimeInterval(3600)
    }
    
    /// 根据到站时间计算智能刷新间隔
    /// - Parameter arrivalMinutes: 距离到站的分钟数，nil 表示无数据
    /// - Returns: 建议的刷新间隔（秒）
    /// - Note: 基于 15 分钟一班车的频率设计
    func calculateSmartRefreshInterval(arrivalMinutes: Int?) -> TimeInterval {
        guard let minutes = arrivalMinutes else {
            // 无数据时使用恢复模式间隔
            print("BackgroundRefreshManager: No arrival data, using recovery interval (3 min)")
            return Self.recoveryRefreshInterval
        }
        
        let interval: TimeInterval
        let description: String
        
        switch minutes {
        case ...5:
            // 关键时刻：≤ 5 分钟到站，1 分钟刷新
            interval = Self.criticalRefreshInterval
            description = "critical (≤5 min arrival)"
        case 6...10:
            // 临近：6-10 分钟到站，3 分钟刷新
            interval = Self.nearRefreshInterval
            description = "near (6-10 min arrival)"
        case 11...15:
            // 中等：11-15 分钟到站，5 分钟刷新
            interval = Self.mediumRefreshInterval
            description = "medium (11-15 min arrival)"
        case 16...20:
            // 较远：16-20 分钟到站，8 分钟刷新
            interval = Self.farRefreshInterval
            description = "far (16-20 min arrival)"
        default:
            // 很远：> 20 分钟到站，12 分钟刷新
            interval = Self.veryFarRefreshInterval
            description = "very far (>20 min arrival)"
        }
        
        print("BackgroundRefreshManager: Smart refresh interval = \(Int(interval/60)) min (\(description))")
        return interval
    }
    
    // MARK: - Background Task Handling
    
    /// Handles a background refresh task
    /// - Parameter task: The background task to handle
    /// - Validates: Requirement 9.5 - handle background refresh and update complication
    func handleBackgroundRefresh(_ task: WKRefreshBackgroundTask) {
        // Determine the type of background task
        switch task {
        case let refreshTask as WKApplicationRefreshBackgroundTask:
            handleApplicationRefreshTask(refreshTask)
            
        case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
            handleURLSessionRefreshTask(urlSessionTask)
            
        case let snapshotTask as WKSnapshotRefreshBackgroundTask:
            handleSnapshotRefreshTask(snapshotTask)
            
        default:
            // Unknown task type, mark as completed
            task.setTaskCompletedWithSnapshot(false)
        }
    }
    
    /// Handles an application refresh background task
    /// - Parameter task: The application refresh task
    private func handleApplicationRefreshTask(_ task: WKApplicationRefreshBackgroundTask) {
        // Schedule the next refresh before processing
        scheduleBackgroundRefresh()
        
        // Fetch new predictions and update complications
        Task {
            await performBackgroundDataRefresh()
            
            // Mark task as completed
            task.setTaskCompletedWithSnapshot(false)
        }
    }
    
    /// Handles a URL session refresh background task
    /// - Parameter task: The URL session refresh task
    private func handleURLSessionRefreshTask(_ task: WKURLSessionRefreshBackgroundTask) {
        // URL session tasks are handled by the system
        // We just need to mark them as completed
        task.setTaskCompletedWithSnapshot(false)
    }
    
    /// Handles a snapshot refresh background task
    /// - Parameter task: The snapshot refresh task
    private func handleSnapshotRefreshTask(_ task: WKSnapshotRefreshBackgroundTask) {
        // Update the snapshot with current data
        task.setTaskCompleted(
            restoredDefaultState: true,
            estimatedSnapshotExpiration: Date().addingTimeInterval(Self.refreshInterval),
            userInfo: nil
        )
    }
    
    // MARK: - Data Refresh
    
    /// Performs the background data refresh operation
    /// Fetches new predictions and updates the complication
    private func performBackgroundDataRefresh() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let nowStr = formatter.string(from: Date())
        print("BackgroundRefreshManager: 🔄 Background refresh started at \(nowStr)")
        
        // 检查是否在停运时段
        if isOutsideServiceHours() {
            print("BackgroundRefreshManager: 🌙 Outside service hours (8pm-7am), skipping refresh")
            // 更新 Widget 显示停运状态
            var mutableStorage = storageService
            mutableStorage.load()
            if let station = mutableStorage.selectedStation,
               let direction = mutableStorage.selectedDirection {
                let directionCode = direction == .alumRock ? "E" : "W"
                mutableStorage.updateWidgetData(
                    stationName: station.name,
                    stationShortName: station.shortName,
                    direction: directionCode,
                    arrivalMinutes: nil
                )
            }
            WidgetCenter.shared.reloadAllTimelines()
            
            // 更新 Complication 显示停运状态
            if let station = storageService.selectedStation,
               let direction = storageService.selectedDirection {
                updateComplicationData(ComplicationData.errorState(
                    stationShortName: station.shortName,
                    direction: direction
                ))
            }
            return
        }
        
        // Load user preferences
        var mutableStorage = storageService
        mutableStorage.load()
        
        // Apply time rule if needed (check for active rule and update station/direction)
        var station = storageService.selectedStation
        var direction = storageService.selectedDirection
        
        // Check if there's an active time rule that should override current settings
        if let activeRule = timeRuleService.getCurrentActiveRule(),
           let ruleStation = OrangeLineStations.station(byId: activeRule.stationId) {
            print("BackgroundRefreshManager: Applying time rule '\(activeRule.name)' - Station: \(ruleStation.name), Direction: \(activeRule.direction)")
            
            // Check if station/direction changed
            let stationChanged = station?.id != ruleStation.id
            let directionChanged = direction != activeRule.direction
            
            if stationChanged || directionChanged {
                // Clear old widget data before updating to new station
                let directionCode = activeRule.direction == .alumRock ? "E" : "W"
                mutableStorage.updateWidgetData(
                    stationName: ruleStation.name,
                    stationShortName: ruleStation.shortName,
                    direction: directionCode,
                    arrivalMinutes: nil
                )
                WidgetCenter.shared.reloadAllTimelines()
            }
            
            // Use the time rule's station and direction
            station = ruleStation
            direction = activeRule.direction
            
            // Update storage with the new settings from time rule
            mutableStorage.selectedStation = ruleStation
            mutableStorage.selectedDirection = activeRule.direction
            mutableStorage.save()
        } else {
            print("BackgroundRefreshManager: No active time rule, using saved preferences")
        }
        
        // Check if we have a selected station and direction
        guard let station = station,
              let direction = direction else {
            print("BackgroundRefreshManager: No station selected")
            // No station selected, update with error state
            updateComplicationData(ComplicationData.errorState())
            return
        }
        
        print("BackgroundRefreshManager: Fetching predictions for \(station.name) \(direction)")
        
        do {
            // Fetch predictions from VTA API
            let predictions = try await vtaService.fetchPredictions(
                stationId: station.id,
                direction: direction
            )
            
            // Get the first prediction (next arriving train)
            if let nextPrediction = predictions.first {
                print("BackgroundRefreshManager: 🚇 Got prediction - \(nextPrediction.minutesUntilArrival) min to arrival")
                
                // Create complication data from prediction
                let complicationData = ComplicationData.from(
                    prediction: nextPrediction,
                    station: station,
                    direction: direction
                )
                
                // Update the complication
                updateComplicationData(complicationData)
                
                // Also update widget shared data
                let directionCode = direction == .alumRock ? "E" : "W"
                mutableStorage.updateWidgetData(
                    stationName: station.name,
                    stationShortName: station.shortName,
                    direction: directionCode,
                    arrivalMinutes: nextPrediction.minutesUntilArrival
                )
                
                // Notify widget to reload with new data
                WidgetCenter.shared.reloadAllTimelines()
                
                // Record successful refresh
                recordSuccessfulRefresh()
                
                // 保存到站时间用于智能刷新计算
                lastKnownArrivalMinutes = nextPrediction.minutesUntilArrival
                saveLastArrivalMinutes()
            } else {
                print("BackgroundRefreshManager: ⚠️ No predictions available")
                // No predictions available
                updateComplicationData(ComplicationData.errorState(
                    stationShortName: station.shortName,
                    direction: direction
                ))
            }
        } catch {
            // Error fetching data - update with error state but preserve station info
            print("BackgroundRefreshManager: ❌ Error fetching predictions - \(error.localizedDescription)")
            updateComplicationData(ComplicationData.errorState(
                stationShortName: station.shortName,
                direction: direction
            ))
        }
    }
    
    // MARK: - Complication Updates
    
    /// Updates the complication with new data
    /// - Parameter data: The new complication data
    /// - Validates: Requirement 9.5 - update complication data
    func updateComplicationData(_ data: ComplicationData) {
        // Update the complication controller's data
        complicationController.updateComplicationData(data)
        
        // Request a timeline reload for all active complications
        reloadActiveComplications()
    }
    
    /// Reloads all active complications
    private func reloadActiveComplications() {
        let server = CLKComplicationServer.sharedInstance()
        
        guard let activeComplications = server.activeComplications else {
            return
        }
        
        for complication in activeComplications {
            server.reloadTimeline(for: complication)
        }
    }
    
    // MARK: - Refresh Tracking
    
    /// Records a successful refresh
    private func recordSuccessfulRefresh() {
        lastRefreshDate = Date()
        saveLastRefreshDate()
    }
    
    /// Saves the last refresh date to UserDefaults
    private func saveLastRefreshDate() {
        UserDefaults.standard.set(lastRefreshDate, forKey: Self.lastRefreshDateKey)
    }
    
    /// Loads the last refresh date from UserDefaults
    private func loadLastRefreshDate() {
        lastRefreshDate = UserDefaults.standard.object(forKey: Self.lastRefreshDateKey) as? Date
        loadLastArrivalMinutes()
    }
    
    /// Saves the last known arrival minutes to UserDefaults
    private func saveLastArrivalMinutes() {
        if let minutes = lastKnownArrivalMinutes {
            UserDefaults.standard.set(minutes, forKey: Self.lastArrivalMinutesKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.lastArrivalMinutesKey)
        }
    }
    
    /// Loads the last known arrival minutes from UserDefaults
    private func loadLastArrivalMinutes() {
        if UserDefaults.standard.object(forKey: Self.lastArrivalMinutesKey) != nil {
            lastKnownArrivalMinutes = UserDefaults.standard.integer(forKey: Self.lastArrivalMinutesKey)
        } else {
            lastKnownArrivalMinutes = nil
        }
    }
    
    /// Resets arrival minutes and reschedules background refresh
    /// Call this when user changes station or direction to ensure fresh data
    func resetAndReschedule() {
        print("BackgroundRefreshManager: 🔄 Station/direction changed, resetting and rescheduling")
        
        // Clear cached arrival minutes since they're no longer valid
        lastKnownArrivalMinutes = nil
        saveLastArrivalMinutes()
        
        // Reschedule background refresh with new settings
        scheduleBackgroundRefresh()
    }
    
    /// Returns the time since the last successful refresh
    var timeSinceLastRefresh: TimeInterval? {
        guard let lastRefresh = lastRefreshDate else {
            return nil
        }
        return Date().timeIntervalSince(lastRefresh)
    }
    
    /// Returns whether a refresh is needed based on the refresh interval
    var needsRefresh: Bool {
        guard let timeSince = timeSinceLastRefresh else {
            return true
        }
        return timeSince >= Self.refreshInterval
    }
}

// MARK: - WKExtensionDelegate Integration

/// Extension to help integrate BackgroundRefreshManager with WKExtensionDelegate
extension BackgroundRefreshManager {
    
    /// Call this method from applicationDidFinishLaunching to schedule initial refresh
    func applicationDidFinishLaunching() {
        scheduleBackgroundRefresh()
    }
    
    /// Call this method from applicationDidBecomeActive to refresh data
    func applicationDidBecomeActive() {
        // Refresh data when app becomes active if needed
        if needsRefresh {
            Task {
                await performBackgroundDataRefresh()
            }
        }
    }
    
    /// Call this method from handle(_ backgroundTasks:) to process background tasks
    func handleBackgroundTasks(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            handleBackgroundRefresh(task)
        }
    }
}
