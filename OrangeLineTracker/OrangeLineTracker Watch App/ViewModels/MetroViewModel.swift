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
/// - Validates: Requirements 1.2, 2.2, 3.1, 4.3, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 7.4
@MainActor
class MetroViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The currently selected line
    /// - Validates: Requirements 4.3, 7.1
    @Published var selectedLine: Line?
    
    /// The currently selected station
    /// - Validates: Requirements 1.2, 7.4
    @Published var selectedStation: Station?
    
    /// The currently selected direction (backward compatible)
    /// - Validates: Requirements 2.2, 7.4
    @Published var selectedDirection: Direction = .alumRock
    
    /// The currently selected direction ID (for multi-line support)
    /// - Validates: Requirements 5.2, 5.3, 5.4
    @Published var selectedDirectionId: String = "E"
    
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
    
    /// All available lines for selection
    /// - Validates: Requirements 4.3
    @Published var allLines: [Line] = []
    
    // MARK: - Private Properties
    
    /// Service for fetching VTA predictions
    private let vtaService: VTAServiceProtocol
    
    /// Service for persisting user preferences
    private var _storageService: StorageServiceProtocol
    
    /// Public access to storage service for settings
    var storageService: StorageServiceProtocol {
        get { _storageService }
        set { _storageService = newValue }
    }
    
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
        self._storageService = storageService
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
    
    /// Selects a line and clears station selection if switching to a different line
    /// - Parameter line: The line to select
    /// - Validates: Requirements 4.3, 4.5, 7.1
    func selectLine(_ line: Line) {
        // Check if we're switching to a different line
        let isNewLine = selectedLine?.id != line.id
        
        selectedLine = line
        
        // Clear station selection when switching lines
        // Validates: Requirements 4.5 - clear station selection when switching lines
        if isNewLine {
            selectedStation = nil
            predictions = []
            cachedPredictions = []
            errorMessage = nil
            
            // Set default direction to the first direction of the new line
            if let firstDirection = line.directions.first {
                selectedDirectionId = firstDirection.id
                // Update backward-compatible direction if applicable
                updateBackwardCompatibleDirection(from: firstDirection.id)
            }
        }
        
        // Save the line selection
        storageService.selectedLineId = line.id
        storageService.save()
        
        // Notify widget of line change
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Loads all available lines from the API
    /// - Validates: Requirements 4.3
    func loadAllLines() async {
        do {
            let lines = try await vtaService.fetchAllLines()
            allLines = lines
            
            // Cache lines for offline access
            storageService.cachedLines = lines
            storageService.save()
            
            // Restore selected line if it exists
            if let selectedLineId = storageService.selectedLineId,
               let line = lines.first(where: { $0.id == selectedLineId }) {
                selectedLine = line
            }
            
            print("MetroViewModel: ✅ Loaded \(lines.count) lines")
        } catch {
            print("MetroViewModel: ❌ Failed to load lines: \(error)")
            
            // Try to use cached data
            if let cachedLines = storageService.cachedLines {
                allLines = cachedLines
                print("MetroViewModel: 📦 Using cached lines (\(cachedLines.count) lines)")
            }
        }
    }
    
    /// Selects a station and saves the preference
    /// Validates that the station belongs to the current line
    /// - Parameter station: The station to select
    /// - Validates: Requirements 1.2, 1.4, 4.3, 7.1
    func selectStation(_ station: Station) {
        // Validate station belongs to current line (if a line is selected)
        // Validates: Requirements 4.3 - validate station belongs to current line
        if let currentLine = selectedLine {
            guard station.lineId == currentLine.id else {
                print("MetroViewModel: ⚠️ Station \(station.name) does not belong to line \(currentLine.name)")
                return
            }
        }
        
        selectedStation = station
        savePreferences()
        
        // Clear error and cached data when user makes a new selection
        errorMessage = nil
        cachedPredictions = []
        predictions = []
        
        // Notify widget of station change immediately
        WidgetCenter.shared.reloadAllTimelines()
        
        // Reset background refresh schedule for new station
        BackgroundRefreshManager.shared.resetAndReschedule()
        
        // Refresh predictions for the new station
        Task {
            await refreshPredictions()
        }
    }
    
    /// Selects a direction and saves the preference (backward compatible)
    /// - Parameter direction: The direction to select
    /// - Validates: Requirements 2.2, 2.3, 7.2
    func selectDirection(_ direction: Direction) {
        selectedDirection = direction
        selectedDirectionId = direction.directionId
        savePreferences()
        
        // Clear error and cached data when user makes a new selection
        errorMessage = nil
        cachedPredictions = []
        predictions = []
        
        // Notify widget of direction change immediately
        WidgetCenter.shared.reloadAllTimelines()
        
        // Reset background refresh schedule for new direction
        BackgroundRefreshManager.shared.resetAndReschedule()
        
        // Refresh predictions for the new direction
        Task {
            await refreshPredictions()
        }
    }
    
    /// Selects a direction by ID (for multi-line support)
    /// - Parameter directionId: The direction ID to select (e.g., "E", "W", "N", "S")
    /// - Validates: Requirements 5.2, 5.3, 5.4
    func selectDirection(byId directionId: String) {
        selectedDirectionId = directionId
        updateBackwardCompatibleDirection(from: directionId)
        savePreferences()
        
        // Clear error and cached data when user makes a new selection
        errorMessage = nil
        cachedPredictions = []
        predictions = []
        
        // Notify widget of direction change immediately
        WidgetCenter.shared.reloadAllTimelines()
        
        // Reset background refresh schedule for new direction
        BackgroundRefreshManager.shared.resetAndReschedule()
        
        // Refresh predictions for the new direction
        Task {
            await refreshPredictions()
        }
    }
    
    /// Updates the backward-compatible Direction enum from a direction ID
    /// - Parameter directionId: The direction ID (e.g., "E", "W", "N", "S")
    private func updateBackwardCompatibleDirection(from directionId: String) {
        switch directionId {
        case "E":
            selectedDirection = .alumRock
        case "W":
            selectedDirection = .mountainView
        default:
            // For non-Orange Line directions, default to alumRock
            // This maintains backward compatibility
            selectedDirection = .alumRock
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
        
        // Determine the line ID to use
        let lineId = selectedLine?.id ?? "Orange"
        
        // Get the correct station ID for the selected direction
        // Use the new platformId method for multi-line support, fall back to backward-compatible method
        let stationId: String
        if let platformId = station.platformId(for: selectedDirectionId) {
            stationId = platformId
        } else {
            // Backward compatibility: use the old method for Orange Line
            stationId = station.stationId(for: selectedDirection)
        }
        
        // Get direction display text
        let directionText: String
        if let line = selectedLine,
           let direction = line.directions.first(where: { $0.id == selectedDirectionId }) {
            directionText = "→\(direction.headsign)"
        } else {
            directionText = selectedDirection == .alumRock ? "→东(Alum Rock)" : "←西(Mountain View)"
        }
        
        print("MetroViewModel: 🔄 Refreshing predictions for \(station.name) \(directionText) on \(lineId)")
        
        do {
            // Fetch predictions from VTA API using the new multi-line method
            // Validates: Requirements 3.1 - fetch real-time arrival prediction data
            let newPredictions = try await vtaService.fetchPredictions(
                lineId: lineId,
                stationId: stationId,
                directionId: selectedDirectionId
            )
            
            // Update predictions and cache
            predictions = newPredictions
            cachedPredictions = newPredictions
            lastUpdated = Date()
            errorMessage = nil
            
            // Update widget data (传递前 3 班车的到站时间)
            let arrivalMinutes = newPredictions.first?.minutesUntilArrival
            let arrivalMinutes2 = newPredictions.count > 1 ? newPredictions[1].minutesUntilArrival : nil
            let arrivalMinutes3 = newPredictions.count > 2 ? newPredictions[2].minutesUntilArrival : nil
            
            if let minutes = arrivalMinutes {
                let train2Str = arrivalMinutes2.map { "\($0)" } ?? "-"
                let train3Str = arrivalMinutes3.map { "\($0)" } ?? "-"
                print("MetroViewModel: ✅ Got \(newPredictions.count) predictions for \(station.shortName) \(directionText), trains: \(minutes)/\(train2Str)/\(train3Str) min")
            } else {
                print("MetroViewModel: ⚠️ No predictions available for \(station.shortName) \(directionText)")
            }
            
            storageService.updateWidgetData(
                stationName: station.name,
                stationShortName: station.shortName,
                direction: selectedDirectionId,
                arrivalMinutes: arrivalMinutes,
                arrivalMinutes2: arrivalMinutes2,
                arrivalMinutes3: arrivalMinutes3,
                lineId: selectedLine?.id,
                lineName: selectedLine?.name,
                lineColor: selectedLine?.colorHex
            )
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch let error as VTAServiceError {
            // Handle VTA service errors
            // Validates: Requirements 5.1, 5.2, 5.3, 5.4
            print("MetroViewModel: ❌ Error fetching predictions for \(station.shortName) \(directionText): \(error.localizedDescription)")
            handleError(error)
            
        } catch {
            // Handle unexpected errors
            print("MetroViewModel: ❌ Unexpected error for \(station.shortName) \(directionText): \(error.localizedDescription)")
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
        // First try to find in the current line's stations, then fall back to Orange Line
        var station: Station?
        if let currentLine = selectedLine {
            station = currentLine.stations.first { $0.id == activeRule.stationId || $0.platformIds.values.contains(activeRule.stationId) }
        }
        if station == nil {
            station = OrangeLineStations.station(byId: activeRule.stationId)
        }
        
        guard let station = station else {
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
            selectedDirectionId = activeRule.direction.directionId
            
            // Clear old predictions and widget data before fetching new data
            predictions = []
            cachedPredictions = []
            
            // Clear widget data to prevent showing stale data from old station
            storageService.updateWidgetData(
                stationName: station.name,
                stationShortName: station.shortName,
                direction: selectedDirectionId,
                arrivalMinutes: nil,
                arrivalMinutes2: nil,
                arrivalMinutes3: nil,
                lineId: selectedLine?.id,
                lineName: selectedLine?.name,
                lineColor: selectedLine?.colorHex
            )
            
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
        
        // Load saved line
        if let savedLineId = storageService.selectedLineId {
            // Try to find the line from cached lines or default lines
            if let cachedLines = storageService.cachedLines,
               let line = cachedLines.first(where: { $0.id == savedLineId }) {
                selectedLine = line
            } else {
                // Create a default Orange Line if no cached lines
                // This will be replaced when lines are loaded from the API
                if savedLineId == "Orange" {
                    selectedLine = Line(
                        id: "Orange",
                        name: "Orange Line",
                        shortName: "OL",
                        type: .lightRail,
                        colorHex: "#F7931E",
                        directions: [
                            LineDirection(id: "E", headsign: "Alum Rock"),
                            LineDirection(id: "W", headsign: "Mountain View")
                        ],
                        stations: OrangeLineStations.stations
                    )
                }
            }
        }
        
        // Load saved station
        if let savedStation = storageService.selectedStation {
            selectedStation = savedStation
        }
        
        // Load saved direction
        if let savedDirection = storageService.selectedDirection {
            selectedDirection = savedDirection
            selectedDirectionId = savedDirection.directionId
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
    
    /// Returns the display name for the current line
    var lineDisplayName: String {
        selectedLine?.name ?? "选择线路"
    }
    
    /// Returns the short name for the current line (for complications)
    var lineShortName: String {
        selectedLine?.shortName ?? "--"
    }
    
    /// Returns the color hex for the current line
    var lineColorHex: String {
        selectedLine?.colorHex ?? "#F7931E"  // Default to Orange Line color
    }
    
    /// Returns the directions for the current line
    var lineDirections: [LineDirection] {
        selectedLine?.directions ?? [
            LineDirection(id: "E", headsign: "Alum Rock"),
            LineDirection(id: "W", headsign: "Mountain View")
        ]
    }
    
    /// Returns the current direction's headsign (terminal station name)
    /// - Validates: Requirements 5.2 - use terminal station name as direction identifier
    var currentDirectionHeadsign: String {
        if let line = selectedLine,
           let direction = line.directions.first(where: { $0.id == selectedDirectionId }) {
            return direction.headsign
        }
        return selectedDirection.displayName
    }
    
    /// Returns the stations for the current line, sorted by order
    /// - Validates: Requirements 4.2 - stations in geographic order
    var lineStations: [Station] {
        if let line = selectedLine {
            return line.stations.sorted { $0.order < $1.order }
        }
        return OrangeLineStations.stations
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
