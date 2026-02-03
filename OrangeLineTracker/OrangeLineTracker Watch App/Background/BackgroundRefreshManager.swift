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

// MARK: - BackgroundRefreshManager

/// Manages background refresh scheduling and execution for watch complications
/// - Validates: Requirement 9.5 - periodic background updates for complication data
class BackgroundRefreshManager {
    
    // MARK: - Constants
    
    /// Refresh interval: 15 minutes (watchOS limitation)
    /// watchOS limits background refresh to approximately 15-minute intervals
    static let refreshInterval: TimeInterval = 15 * 60
    
    /// Minimum time between refresh attempts to avoid excessive scheduling
    private static let minimumRefreshInterval: TimeInterval = 10 * 60
    
    // MARK: - Properties
    
    /// Shared instance for singleton access
    static let shared = BackgroundRefreshManager()
    
    /// VTA service for fetching predictions
    private let vtaService: VTAServiceProtocol
    
    /// Storage service for accessing user preferences
    private let storageService: StorageServiceProtocol
    
    /// Complication controller for updating complications
    private let complicationController: ComplicationController
    
    /// Last successful refresh date
    private var lastRefreshDate: Date?
    
    /// UserDefaults key for storing last refresh date
    private static let lastRefreshDateKey = "lastBackgroundRefreshDate"
    
    // MARK: - Initialization
    
    /// Creates a BackgroundRefreshManager with default services
    init() {
        // Use default API key - in production, this should be loaded from configuration
        self.vtaService = VTAService(apiKey: "YOUR_API_KEY")
        self.storageService = StorageService()
        self.complicationController = ComplicationController.shared
        loadLastRefreshDate()
    }
    
    /// Creates a BackgroundRefreshManager with custom services (for testing)
    /// - Parameters:
    ///   - vtaService: VTA service for fetching predictions
    ///   - storageService: Storage service for user preferences
    ///   - complicationController: Complication controller for updates
    init(
        vtaService: VTAServiceProtocol,
        storageService: StorageServiceProtocol,
        complicationController: ComplicationController
    ) {
        self.vtaService = vtaService
        self.storageService = storageService
        self.complicationController = complicationController
        loadLastRefreshDate()
    }
    
    // MARK: - Background Refresh Scheduling
    
    /// Schedules a background refresh task
    /// - Validates: Requirement 9.5 - schedule periodic background updates
    func scheduleBackgroundRefresh() {
        // Calculate the next refresh date
        let nextRefreshDate = calculateNextRefreshDate()
        
        // Schedule the background app refresh task
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: nextRefreshDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("BackgroundRefreshManager: Failed to schedule refresh - \(error.localizedDescription)")
            } else {
                print("BackgroundRefreshManager: Scheduled refresh for \(nextRefreshDate)")
            }
        }
    }
    
    /// Calculates the next appropriate refresh date
    /// - Returns: The date when the next refresh should occur
    private func calculateNextRefreshDate() -> Date {
        let now = Date()
        
        // If we have a last refresh date, ensure minimum interval
        if let lastRefresh = lastRefreshDate {
            let timeSinceLastRefresh = now.timeIntervalSince(lastRefresh)
            
            if timeSinceLastRefresh < Self.minimumRefreshInterval {
                // Schedule for the minimum interval from last refresh
                return lastRefresh.addingTimeInterval(Self.refreshInterval)
            }
        }
        
        // Schedule for the standard interval from now
        return now.addingTimeInterval(Self.refreshInterval)
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
        // Load user preferences
        var mutableStorage = storageService
        mutableStorage.load()
        
        // Check if we have a selected station and direction
        guard let station = storageService.selectedStation,
              let direction = storageService.selectedDirection else {
            // No station selected, update with error state
            updateComplicationData(ComplicationData.errorState())
            return
        }
        
        do {
            // Fetch predictions from VTA API
            let predictions = try await vtaService.fetchPredictions(
                stationId: station.id,
                direction: direction
            )
            
            // Get the first prediction (next arriving train)
            if let nextPrediction = predictions.first {
                // Create complication data from prediction
                let complicationData = ComplicationData.from(
                    prediction: nextPrediction,
                    station: station,
                    direction: direction
                )
                
                // Update the complication
                updateComplicationData(complicationData)
                
                // Record successful refresh
                recordSuccessfulRefresh()
            } else {
                // No predictions available
                updateComplicationData(ComplicationData.errorState(
                    stationShortName: station.shortName,
                    direction: direction
                ))
            }
        } catch {
            // Error fetching data - update with error state but preserve station info
            print("BackgroundRefreshManager: Error fetching predictions - \(error.localizedDescription)")
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
