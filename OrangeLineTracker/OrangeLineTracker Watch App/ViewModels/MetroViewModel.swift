//
//  MetroViewModel.swift
//  OrangeLineTracker Watch App
//
//  Main ViewModel for coordinating metro data between services and views
//

import Foundation
import Combine
import WidgetKit

// MARK: - MetroViewModel

/// Main ViewModel for the OrangeLineTracker app
/// Coordinates between VTAService, StorageService, and TimeRuleService
/// - Validates: Requirements 1.2, 2.2, 3.1, 4.6, 5.1, 5.2, 5.3, 5.4, 5.5, 7.4
@MainActor
class MetroViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The currently selected station
    /// - Validates: Requirements 1.2, 7.4
    @Published var selectedStation: Station?
    
    /// The currently selected direction
    /// - Validates: Requirements 2.2, 7.4
    @Published var selectedDirection: Direction = .alumRock
    
    /// The list of arrival predictions for the selected station and direction
    /// - Validates: Requirements 3.1, 4.6
    @Published var predictions: [Prediction] = []
    
    /// Whether data is currently being loaded
    /// - Validates: Requirements 6.4
    @Published var isLoading: Bool = false
    
    /// Error message to display to the user, nil if no error
    /// - Validates: Requirements 5.1, 5.2, 5.3, 5.4
    @Published var errorMessage: String?
    
    /// Timestamp of the last successful data update
    @Published var lastUpdated: Date?
    
    // MARK: - Private Properties
    
    /// Service for fetching VTA predictions
    private let vtaService: VTAServiceProtocol
    
    /// Service for persisting user preferences
    private var storageService: StorageServiceProtocol
    
    /// Service for managing time-based rules
    private let timeRuleService: TimeRuleServiceProtocol
    
    /// Cached predictions for error recovery
    /// - Validates: Requirements 5.5
    private var cachedPredictions: [Prediction] = []
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Timer for periodic time rule checking
    /// Using nonisolated(unsafe) to allow access from deinit
    private nonisolated(unsafe) var timeRuleCheckTimer: Timer?
    
    /// Last applied rule ID to avoid redundant applications
    private var lastAppliedRuleId: UUID?
    
    // MARK: - Initialization
    
    /// Creates a new MetroViewModel instance
    /// - Parameters:
    ///   - vtaService: Service for fetching VTA predictions
    ///   - storageService: Service for persisting user preferences
    ///   - timeRuleService: Service for managing time-based rules
    init(
        vtaService: VTAServiceProtocol,
        storageService: StorageServiceProtocol,
        timeRuleService: TimeRuleServiceProtocol
    ) {
        self.vtaService = vtaService
        self.storageService = storageService
        self.timeRuleService = timeRuleService
        
        // Load saved preferences
        loadSavedPreferences()
        
        // Apply time rule if needed
        applyTimeRuleIfNeeded()
        
        // Start periodic time rule checking
        startTimeRuleCheckTimer()
    }
    
    deinit {
        // Directly invalidate timer here since deinit is nonisolated
        // and cannot call @MainActor isolated methods
        timeRuleCheckTimer?.invalidate()
        timeRuleCheckTimer = nil
    }
    
    // MARK: - Public Methods
    
    /// Selects a station and saves the preference
    /// - Parameter station: The station to select
    /// - Validates: Requirements 1.2, 1.4, 7.1
    func selectStation(_ station: Station) {
        selectedStation = station
        savePreferences()
        
        // Clear error and cached data when user makes a new selection
        errorMessage = nil
        cachedPredictions = []
        predictions = []
        
        // Notify widget of station change immediately
        WidgetCenter.shared.reloadAllTimelines()
        
        // Refresh predictions for the new station
        Task {
            await refreshPredictions()
        }
    }
    
    /// Selects a direction and saves the preference
    /// - Parameter direction: The direction to select
    /// - Validates: Requirements 2.2, 2.3, 7.2
    func selectDirection(_ direction: Direction) {
        selectedDirection = direction
        savePreferences()
        
        // Clear error and cached data when user makes a new selection
        errorMessage = nil
        cachedPredictions = []
        predictions = []
        
        // Notify widget of direction change immediately
        WidgetCenter.shared.reloadAllTimelines()
        
        // Refresh predictions for the new direction
        Task {
            await refreshPredictions()
        }
    }
    
    /// Refreshes predictions from the VTA API
    /// Implements error recovery by caching successful data
    /// - Validates: Requirements 3.1, 4.6, 5.1, 5.2, 5.3, 5.4, 5.5
    func refreshPredictions() async {
        // Ensure we have a selected station
        guard let station = selectedStation else {
            predictions = []
            errorMessage = nil
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Get the correct station ID for the selected direction
        let stationId = station.stationId(for: selectedDirection)
        
        do {
            // Fetch predictions from VTA API
            // Validates: Requirements 3.1 - fetch real-time arrival prediction data
            let newPredictions = try await vtaService.fetchPredictions(
                stationId: stationId,
                direction: selectedDirection
            )
            
            // Update predictions and cache
            predictions = newPredictions
            cachedPredictions = newPredictions
            lastUpdated = Date()
            errorMessage = nil
            
            // Update widget data
            let arrivalMinutes = newPredictions.first?.minutesUntilArrival
            storageService.updateWidgetData(arrivalMinutes: arrivalMinutes)
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch let error as VTAServiceError {
            // Handle VTA service errors
            // Validates: Requirements 5.1, 5.2, 5.3, 5.4
            handleError(error)
            
        } catch {
            // Handle unexpected errors
            handleError(.networkError(error.localizedDescription))
        }
        
        // Clear loading state
        isLoading = false
    }
    
    /// Applies time rule if one is active and enabled
    /// - Validates: Requirements 8.3, 8.5, 8.6, 8.7
    func applyTimeRuleIfNeeded() {
        print("MetroViewModel: Checking for active time rule...")
        
        // Check if there's an active time rule
        guard let activeRule = timeRuleService.getCurrentActiveRule() else {
            // No active rule, clear the last applied rule ID
            print("MetroViewModel: No active time rule found")
            lastAppliedRuleId = nil
            return
        }
        
        print("MetroViewModel: Found active rule '\(activeRule.name)' (id: \(activeRule.id))")
        
        // Skip if this rule was already applied (avoid redundant applications)
        if lastAppliedRuleId == activeRule.id {
            print("MetroViewModel: Rule '\(activeRule.name)' already applied, skipping")
            return
        }
        
        // Get the station for the rule
        guard let station = OrangeLineStations.station(byId: activeRule.stationId) else {
            print("MetroViewModel: Could not find station for rule")
            return
        }
        
        // Apply the rule's station and direction
        // Only update if different from current selection to avoid unnecessary refreshes
        let stationChanged = selectedStation?.id != station.id
        let directionChanged = selectedDirection != activeRule.direction
        
        print("MetroViewModel: Station changed: \(stationChanged), Direction changed: \(directionChanged)")
        
        if stationChanged || directionChanged {
            print("MetroViewModel: Applying rule '\(activeRule.name)' - Station: \(station.name), Direction: \(activeRule.direction)")
            
            selectedStation = station
            selectedDirection = activeRule.direction
            
            // Clear old predictions and widget data before fetching new data
            predictions = []
            cachedPredictions = []
            
            // Clear widget data to prevent showing stale data from old station
            storageService.updateWidgetData(arrivalMinutes: nil)
            
            // Save the new preferences
            savePreferences()
            
            // Record that this rule has been applied
            lastAppliedRuleId = activeRule.id
            
            // Notify widget of the change immediately (will show no data until API returns)
            WidgetCenter.shared.reloadAllTimelines()
            
            // Refresh predictions for the new settings
            // Validates: Requirements 8.5 - auto-refresh when time rule takes effect
            Task {
                await refreshPredictions()
            }
        } else {
            // Even if no change needed, record the rule as applied
            print("MetroViewModel: Rule '\(activeRule.name)' matches current settings, marking as applied")
            lastAppliedRuleId = activeRule.id
        }
    }
    
    // MARK: - Time Rule Timer
    
    /// Starts the periodic timer for checking time rules
    /// Checks every 30 minutes to see if a new rule should be applied
    /// (Time rules are typically set by hour, so 30 min interval is sufficient)
    private func startTimeRuleCheckTimer() {
        // Stop any existing timer
        stopTimeRuleCheckTimer()
        
        // Create a timer that fires every 30 minutes (1800 seconds)
        timeRuleCheckTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.applyTimeRuleIfNeeded()
            }
        }
        
        // Add to run loop to ensure it fires even when scrolling
        if let timer = timeRuleCheckTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    /// Stops the time rule check timer
    private func stopTimeRuleCheckTimer() {
        timeRuleCheckTimer?.invalidate()
        timeRuleCheckTimer = nil
    }
    
    /// Resets the last applied rule ID (call when user manually changes settings)
    func resetLastAppliedRule() {
        lastAppliedRuleId = nil
    }
    
    // MARK: - Private Methods
    
    /// Loads saved preferences from storage
    /// - Validates: Requirements 7.3, 7.4
    private func loadSavedPreferences() {
        // Load preferences from storage
        storageService.load()
        
        // Load saved station
        if let savedStation = storageService.selectedStation {
            selectedStation = savedStation
        }
        
        // Load saved direction
        if let savedDirection = storageService.selectedDirection {
            selectedDirection = savedDirection
        }
    }
    
    /// Saves current preferences to storage
    /// - Validates: Requirements 1.4, 2.3, 7.1, 7.2
    private func savePreferences() {
        storageService.selectedStation = selectedStation
        storageService.selectedDirection = selectedDirection
        storageService.save()
    }
    
    /// Handles VTA service errors with appropriate user messages
    /// Implements error recovery by preserving cached data
    /// - Parameter error: The VTAServiceError that occurred
    /// - Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5
    private func handleError(_ error: VTAServiceError) {
        // Set the error message for display
        errorMessage = error.errorDescription
        
        // Implement error recovery strategy
        // Validates: Requirements 5.5 - preserve last successful data as backup
        if !cachedPredictions.isEmpty {
            // Keep showing cached predictions when there's an error
            predictions = cachedPredictions
        } else {
            // No cached data available, clear predictions
            predictions = []
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns the first (next) prediction, if available
    var nextPrediction: Prediction? {
        predictions.first
    }
    
    /// Returns whether there are any predictions available
    var hasPredictions: Bool {
        !predictions.isEmpty
    }
    
    /// Returns whether there's an error to display
    var hasError: Bool {
        errorMessage != nil
    }
    
    /// Returns whether the cached data is being displayed (due to an error)
    var isShowingCachedData: Bool {
        hasError && hasPredictions
    }
    
    /// Returns a formatted string for the last updated time
    var lastUpdatedDisplay: String? {
        guard let lastUpdated = lastUpdated else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "更新于 \(formatter.string(from: lastUpdated))"
    }
    
    /// Returns the display text for the current station
    var stationDisplayName: String {
        selectedStation?.name ?? "选择站点"
    }
    
    /// Returns the short name for the current station (for complications)
    var stationShortName: String {
        selectedStation?.shortName ?? "--"
    }
}

// MARK: - Convenience Initializer

extension MetroViewModel {
    /// Creates a MetroViewModel with default services
    /// - Parameter apiKey: The 511.org API key
    convenience init(apiKey: String) {
        let storageService = StorageService()
        let vtaService = VTAService(apiKey: apiKey)
        let timeRuleService = TimeRuleService(storageService: storageService)
        
        self.init(
            vtaService: vtaService,
            storageService: storageService,
            timeRuleService: timeRuleService
        )
    }
}
