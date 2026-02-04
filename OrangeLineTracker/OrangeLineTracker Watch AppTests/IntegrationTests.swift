//
//  IntegrationTests.swift
//  OrangeLineTracker Watch AppTests
//
//  End-to-end integration tests for the OrangeLineTracker app
//  Tests the complete flow: Station selection → Direction selection → Data fetch → Display
//  Tests time rule automatic switching
//  Tests Complication display and update
//
//  **Validates: All Requirements**
//

import Foundation
import Testing
import ClockKit
@testable import OrangeLineTracker_Watch_App

// MARK: - Integration Test Mock Services

/// Mock storage service for integration testing with full state tracking
class IntegrationMockStorageService: StorageServiceProtocol {
    var selectedStation: Station?
    var selectedDirection: Direction?
    var timeRules: [TimeRule] = []
    var isTimeRuleEnabled: Bool = false
    var cachedArrivalMinutes: Int?
    var lastUpdateTime: Date?
    
    var saveCallCount = 0
    var loadCallCount = 0
    var updateWidgetDataCallCount = 0
    
    func save() {
        saveCallCount += 1
    }
    
    func load() {
        loadCallCount += 1
    }
    
    func updateWidgetData(arrivalMinutes: Int?) {
        updateWidgetDataCallCount += 1
        cachedArrivalMinutes = arrivalMinutes
        lastUpdateTime = Date()
    }
    
    func reset() {
        selectedStation = nil
        selectedDirection = nil
        timeRules = []
        isTimeRuleEnabled = false
        cachedArrivalMinutes = nil
        lastUpdateTime = nil
        saveCallCount = 0
        loadCallCount = 0
        updateWidgetDataCallCount = 0
    }
}


/// Mock time rule service for integration testing with configurable behavior
class IntegrationMockTimeRuleService: TimeRuleServiceProtocol {
    var mockActiveRule: TimeRule?
    var addedRules: [TimeRule] = []
    var updatedRules: [TimeRule] = []
    var deletedRules: [TimeRule] = []
    
    func getCurrentActiveRule() -> TimeRule? {
        return mockActiveRule
    }
    
    func shouldApplyRule(at date: Date) -> TimeRule? {
        return mockActiveRule
    }
    
    func addRule(_ rule: TimeRule) {
        addedRules.append(rule)
    }
    
    func updateRule(_ rule: TimeRule) {
        updatedRules.append(rule)
    }
    
    func deleteRule(_ rule: TimeRule) {
        deletedRules.append(rule)
    }
    
    func reset() {
        mockActiveRule = nil
        addedRules = []
        updatedRules = []
        deletedRules = []
    }
}

/// Mock VTA service for integration testing with configurable responses
class IntegrationMockVTAService: VTAServiceProtocol {
    var mockPredictions: [Prediction] = []
    var mockError: VTAServiceError?
    var lastRequestedStationId: String?
    var lastRequestedDirection: Direction?
    var fetchCallCount: Int = 0
    
    func fetchPredictions(
        stationId: String,
        direction: Direction
    ) async throws -> [Prediction] {
        fetchCallCount += 1
        lastRequestedStationId = stationId
        lastRequestedDirection = direction
        
        if let error = mockError {
            throw error
        }
        
        return mockPredictions
    }
    
    func reset() {
        mockPredictions = []
        mockError = nil
        lastRequestedStationId = nil
        lastRequestedDirection = nil
        fetchCallCount = 0
    }
}


// MARK: - End-to-End Flow Integration Tests

/// Tests the complete flow: Station selection → Direction selection → Data fetch → Display
/// **Validates: Requirements 1, 2, 3, 4, 5, 6, 7**
@MainActor
struct EndToEndFlowIntegrationTests {
    
    // MARK: - Complete User Flow Tests
    
    @Test func completeUserFlowFromStationSelectionToDisplay() async {
        // **Validates: Requirements 1.2, 2.2, 3.1, 4.1, 7.1, 7.2**
        // Test the complete flow: Station selection → Direction selection → Data fetch → Display
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        // Set up mock predictions
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock"),
            Prediction(minutesUntilArrival: 12, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        // Create ViewModel
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Step 1: Select a station
        // **Validates: Requirement 1.2 - set station as current selection**
        let selectedStation = OrangeLineStations.stations[12] // Great America
        viewModel.selectStation(selectedStation)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify station selection
        #expect(viewModel.selectedStation?.id == selectedStation.id)
        #expect(viewModel.selectedStation?.name == "Great America")
        
        // Step 2: Select a direction
        // **Validates: Requirement 2.2 - set direction as current selection**
        viewModel.selectDirection(.mountainView)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify direction selection
        #expect(viewModel.selectedDirection == .mountainView)
        
        // Step 3: Verify data was fetched
        // **Validates: Requirement 3.1 - fetch real-time arrival prediction data**
        #expect(mockVTAService.fetchCallCount >= 1)
        #expect(mockVTAService.lastRequestedStationId == selectedStation.id)
        #expect(mockVTAService.lastRequestedDirection == .mountainView)
        
        // Step 4: Verify predictions are displayed
        // **Validates: Requirement 4.1 - display next train arrival time**
        #expect(viewModel.predictions.count == 2)
        #expect(viewModel.nextPrediction?.minutesUntilArrival == 5)
        #expect(viewModel.hasPredictions == true)
        
        // Step 5: Verify preferences were saved
        // **Validates: Requirements 7.1, 7.2 - save selection**
        #expect(mockStorageService.saveCallCount >= 2)
        #expect(mockStorageService.selectedStation?.id == selectedStation.id)
        #expect(mockStorageService.selectedDirection == .mountainView)
    }
    
    @Test func userFlowWithPreloadedPreferences() async {
        // **Validates: Requirements 7.3, 7.4 - load saved preferences and display data**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        // Pre-load preferences
        mockStorageService.selectedStation = OrangeLineStations.stations[5] // Lockheed Martin
        mockStorageService.selectedDirection = .alumRock
        
        // Set up mock predictions
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 8, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        // Create ViewModel - should load preferences automatically
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Verify preferences were loaded
        // **Validates: Requirement 7.3 - auto-load saved station and direction**
        #expect(viewModel.selectedStation?.id == "70311")
        #expect(viewModel.selectedStation?.name == "Lockheed Martin")
        #expect(viewModel.selectedDirection == .alumRock)
        #expect(mockStorageService.loadCallCount == 1)
    }
    
    @Test func userFlowWithRefreshAction() async {
        // **Validates: Requirement 4.6 - manual refresh button**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        // Initial predictions
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 10, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.predictions[0].minutesUntilArrival == 10)
        let initialFetchCount = mockVTAService.fetchCallCount
        
        // Update mock predictions (simulating time passing)
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 7, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        // Manual refresh
        await viewModel.refreshPredictions()
        
        // Verify refresh occurred
        #expect(mockVTAService.fetchCallCount == initialFetchCount + 1)
        #expect(viewModel.predictions[0].minutesUntilArrival == 7)
        #expect(viewModel.lastUpdated != nil)
    }
}


// MARK: - Time Rule Automatic Switching Integration Tests

/// Tests time rule automatic switching functionality
/// **Validates: Requirements 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7**
@MainActor
struct TimeRuleAutomaticSwitchingIntegrationTests {
    
    @Test func timeRuleAutomaticallySwitchesStationAndDirection() async {
        // **Validates: Requirements 8.3, 8.5 - auto-switch to rule's station and direction**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        // Set up initial preferences (different from rule)
        mockStorageService.selectedStation = OrangeLineStations.stations[0] // Mountain View
        mockStorageService.selectedDirection = .alumRock
        
        // Set up an active time rule
        let targetStation = OrangeLineStations.stations[27] // Alum Rock
        mockTimeRuleService.mockActiveRule = TimeRule(
            name: "Evening Commute",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 30),
            stationId: targetStation.id,
            direction: .mountainView,
            isEnabled: true
        )
        
        // Set up mock predictions for the new station
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 6, arrivalStatus: .scheduled, destination: "Mountain View")
        ]
        
        // Create ViewModel - should apply time rule
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Verify time rule was applied
        // **Validates: Requirement 8.3 - auto-switch to rule's station and direction**
        #expect(viewModel.selectedStation?.id == targetStation.id)
        #expect(viewModel.selectedStation?.name == "Alum Rock")
        #expect(viewModel.selectedDirection == .mountainView)
        
        // Verify data was fetched for the new station
        // **Validates: Requirement 8.5 - auto-refresh when time rule takes effect**
        #expect(mockVTAService.lastRequestedStationId == targetStation.id)
        #expect(mockVTAService.lastRequestedDirection == .mountainView)
    }
    
    @Test func timeRuleDisabledUsesManualSelection() async {
        // **Validates: Requirements 8.6, 8.7 - use manual selection when rules disabled**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        // Set up manual preferences
        let manualStation = OrangeLineStations.stations[10] // Reamwood
        mockStorageService.selectedStation = manualStation
        mockStorageService.selectedDirection = .alumRock
        mockStorageService.isTimeRuleEnabled = false // Disabled
        
        // No active rule when disabled
        mockTimeRuleService.mockActiveRule = nil
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 4, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        // Create ViewModel
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Verify manual selection is used
        // **Validates: Requirement 8.7 - use manual selection when rules disabled**
        #expect(viewModel.selectedStation?.id == manualStation.id)
        #expect(viewModel.selectedDirection == .alumRock)
    }
    
    @Test func timeRuleWithInvalidStationIdFallsBackToManual() async {
        // **Validates: Graceful handling of invalid time rule configuration**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        // Set up manual preferences
        let manualStation = OrangeLineStations.stations[5]
        mockStorageService.selectedStation = manualStation
        mockStorageService.selectedDirection = .alumRock
        
        // Set up a rule with invalid station ID
        mockTimeRuleService.mockActiveRule = TimeRule(
            name: "Invalid Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 8, minute: 0),
            stationId: "invalid-station-id",
            direction: .mountainView,
            isEnabled: true
        )
        
        // Create ViewModel
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Should fall back to manual selection
        #expect(viewModel.selectedStation?.id == manualStation.id)
        #expect(viewModel.selectedDirection == .alumRock)
    }
    
    @Test func timeRuleViewModelIntegrationWithStorage() async {
        // **Validates: Requirements 8.1, 8.2, 8.4 - time rule CRUD operations**
        
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        // Create a new rule
        let newRule = viewModel.createRule(
            name: "Morning Commute",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: OrangeLineStations.stations[0].id,
            direction: .alumRock,
            isEnabled: true
        )
        
        // Verify rule was added
        // **Validates: Requirement 8.2 - save rule's trigger time, station, and direction**
        #expect(mockTimeRuleService.addedRules.count == 1)
        #expect(mockTimeRuleService.addedRules[0].name == "Morning Commute")
        #expect(mockTimeRuleService.addedRules[0].stationId == "70261")
        #expect(mockTimeRuleService.addedRules[0].direction == .alumRock)
        
        // Update the rule
        var updatedRule = newRule
        updatedRule.name = "Updated Morning Commute"
        viewModel.updateRule(updatedRule)
        
        // Verify rule was updated
        #expect(mockTimeRuleService.updatedRules.count == 1)
        #expect(mockTimeRuleService.updatedRules[0].name == "Updated Morning Commute")
        
        // Delete the rule
        viewModel.deleteRule(updatedRule)
        
        // Verify rule was deleted
        #expect(mockTimeRuleService.deletedRules.count == 1)
    }
    
    @Test func timeRuleGlobalEnableDisableIntegration() async {
        // **Validates: Requirement 8.6 - enable/disable time rule feature**
        
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        mockStorageService.isTimeRuleEnabled = false
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        // Enable time rules
        viewModel.setGlobalTimeRuleEnabled(true)
        
        #expect(viewModel.isTimeRuleEnabled == true)
        #expect(mockStorageService.isTimeRuleEnabled == true)
        #expect(mockStorageService.saveCallCount >= 1)
        
        // Disable time rules
        viewModel.setGlobalTimeRuleEnabled(false)
        
        #expect(viewModel.isTimeRuleEnabled == false)
        #expect(mockStorageService.isTimeRuleEnabled == false)
    }
}


// MARK: - Complication Display and Update Integration Tests

/// Tests Complication display and update functionality
/// **Validates: Requirements 9.1, 9.2, 9.3, 9.5, 9.6, 9.7**
struct ComplicationDisplayIntegrationTests {
    
    @Test func complicationDisplaysArrivalTimeFromPrediction() {
        // **Validates: Requirements 9.2, 9.6 - display arrival time and station abbreviation**
        
        let station = OrangeLineStations.stations[12] // Great America
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        // Create complication data from prediction
        let complicationData = ComplicationData.from(
            prediction: prediction,
            station: station,
            direction: .alumRock
        )
        
        // Verify complication data
        // **Validates: Requirement 9.6 - display station abbreviation**
        #expect(complicationData.stationShortName == "GAM")
        
        // **Validates: Requirement 9.2 - display arrival time**
        #expect(complicationData.minutesUntilArrival == 5)
        #expect(complicationData.displayText == "5m")
        #expect(complicationData.fullDisplayText == "GAM 5m")
    }
    
    @Test func complicationDisplaysArrivingStatus() {
        // **Validates: Requirement 9.2 - display "ARR" for arriving trains**
        
        let station = OrangeLineStations.stations[0] // Mountain View
        let prediction = Prediction(
            minutesUntilArrival: nil,
            arrivalStatus: .arriving,
            destination: "Alum Rock"
        )
        
        let complicationData = ComplicationData.from(
            prediction: prediction,
            station: station,
            direction: .alumRock
        )
        
        #expect(complicationData.displayText == "ARR")
        #expect(complicationData.fullDisplayText == "MTV ARR")
    }
    
    @Test func complicationDisplaysErrorStateWhenNoData() {
        // **Validates: Requirement 9.7 - show "--" when no data available**
        
        let errorData = ComplicationData.errorState()
        
        #expect(errorData.isErrorState == true)
        #expect(errorData.stationShortName == "--")
        #expect(errorData.displayText == "--")
    }
    
    @Test func complicationControllerCreatesTemplatesForAllFamilies() {
        // **Validates: Requirement 9.3 - support multiple complication sizes**
        
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        // Test all supported families
        for family in controller.supportedComplicationFamilies {
            let template = controller.createTemplate(for: family, with: data)
            #expect(template != nil, "Template should be created for family: \(family)")
        }
    }
    
    @Test func complicationControllerUpdatesData() {
        // **Validates: Requirement 9.5 - update arrival time data**
        
        let controller = ComplicationController()
        
        // Initial data
        let initialData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 10,
            direction: .alumRock
        )
        controller.updateComplicationData(initialData)
        
        #expect(controller.currentData == initialData)
        
        // Updated data
        let updatedData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 7,
            direction: .alumRock
        )
        controller.updateComplicationData(updatedData)
        
        #expect(controller.currentData == updatedData)
        #expect(controller.currentData?.minutesUntilArrival == 7)
    }
    
    @Test func complicationShowsStaleIndicatorForOldData() {
        // **Validates: Requirement 9.7 - show stale indicator for cached data**
        
        // Create data that is 10 minutes old (stale)
        let staleData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: Date().addingTimeInterval(-10 * 60) // 10 minutes ago
        )
        
        // Verify data is stale
        #expect(staleData.isStale() == true)
        
        // Verify stale indicator is shown
        #expect(staleData.displayTextWithStaleIndicator().hasPrefix("⚠") == true)
        #expect(staleData.fullDisplayTextWithStaleIndicator().hasPrefix("⚠") == true)
    }
    
    @Test func complicationHandlesNetworkErrorWithCachedData() {
        // **Validates: Requirement 9.7 - show cached data on network error**
        
        let controller = ComplicationController()
        
        // Cached data
        let cachedData = ComplicationData(
            stationShortName: "GAM",
            minutesUntilArrival: 8,
            direction: .mountainView,
            lastUpdated: Date().addingTimeInterval(-10 * 60) // 10 minutes ago (stale)
        )
        
        // Simulate network error
        let error = NSError(domain: "test", code: -1, userInfo: nil)
        let result = controller.createNetworkErrorComplicationData(
            cachedData: cachedData,
            error: error
        )
        
        // Should return cached data
        #expect(result == cachedData)
        #expect(result.isStale() == true)
    }
    
    @Test func complicationHandlesNetworkErrorWithoutCachedData() {
        // **Validates: Requirement 9.7 - show "--" when no cached data**
        
        let controller = ComplicationController()
        
        // Simulate network error with no cached data
        let error = NSError(domain: "test", code: -1, userInfo: nil)
        let result = controller.createNetworkErrorComplicationData(
            cachedData: nil,
            error: error
        )
        
        // Should return error state
        #expect(result.isErrorState == true)
        #expect(result.stationShortName == "--")
    }
    
    @Test func complicationTimelineEntryCreation() {
        // **Validates: Requirements 9.2, 9.3 - create timeline entries**
        
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "BRY",
            minutesUntilArrival: 3,
            direction: .mountainView
        )
        controller.currentData = data
        
        // Test timeline entry creation for all families
        for family in controller.supportedComplicationFamilies {
            let entry = controller.getCurrentTimelineEntrySync(for: family)
            #expect(entry != nil, "Timeline entry should be created for family: \(family)")
        }
    }
}


// MARK: - Error Handling Integration Tests

/// Tests error handling across the complete flow
/// **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5**
@MainActor
struct ErrorHandlingIntegrationTests {
    
    @Test func networkErrorDisplaysMessageAndPreservesCachedData() async {
        // **Validates: Requirements 5.1, 5.5 - display error and preserve cached data**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        // First, get successful data
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock"),
            Prediction(minutesUntilArrival: 12, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        // Verify initial data
        #expect(viewModel.predictions.count == 2)
        #expect(viewModel.errorMessage == nil)
        
        // Simulate network error
        mockVTAService.mockError = .networkError("Connection lost")
        mockVTAService.mockPredictions = []
        
        await viewModel.refreshPredictions()
        
        // **Validates: Requirement 5.1 - display network error**
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("网络连接失败") == true)
        
        // **Validates: Requirement 5.5 - preserve cached data**
        #expect(viewModel.predictions.count == 2)
        #expect(viewModel.isShowingCachedData == true)
    }
    
    @Test func apiErrorDisplaysMessage() async {
        // **Validates: Requirement 5.2 - display API error**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        mockVTAService.mockError = .apiError(500, "Internal Server Error")
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("API 错误") == true)
    }
    
    @Test func noDataAvailableDisplaysMessage() async {
        // **Validates: Requirement 5.3 - display "暂无列车信息"**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        mockVTAService.mockError = .noDataAvailable
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("暂无列车信息") == true)
    }
    
    @Test func invalidAPIKeyDisplaysMessage() async {
        // **Validates: Requirement 5.4 - prompt user to check configuration**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        mockVTAService.mockError = .invalidAPIKey
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("API 密钥无效") == true)
    }
    
    @Test func errorRecoveryOnSuccessfulRefresh() async {
        // **Validates: Error recovery when subsequent request succeeds**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        // First, simulate error
        mockVTAService.mockError = .networkError("Connection failed")
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.errorMessage != nil)
        
        // Now simulate successful refresh
        mockVTAService.mockError = nil
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        await viewModel.refreshPredictions()
        
        // Error should be cleared
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.predictions.count == 1)
        #expect(viewModel.hasError == false)
    }
}


// MARK: - Data Flow Integration Tests

/// Tests data flow between components
/// **Validates: Requirements 1, 2, 3, 4, 7, 9**
@MainActor
struct DataFlowIntegrationTests {
    
    @Test func dataFlowsFromViewModelToComplication() async {
        // **Validates: Data flows correctly from ViewModel to Complication**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        let station = OrangeLineStations.stations[12] // Great America
        viewModel.selectStation(station)
        viewModel.selectDirection(.alumRock)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify ViewModel has data
        #expect(viewModel.hasPredictions == true)
        #expect(viewModel.nextPrediction != nil)
        
        // Create complication data from ViewModel state
        let complicationData = ComplicationData.from(
            prediction: viewModel.nextPrediction,
            station: viewModel.selectedStation,
            direction: viewModel.selectedDirection
        )
        
        // Verify complication data matches ViewModel
        #expect(complicationData.stationShortName == station.shortName)
        #expect(complicationData.minutesUntilArrival == 5)
        #expect(complicationData.direction == .alumRock)
    }
    
    @Test func stationSelectionTriggersDataFetch() async {
        // **Validates: Station selection triggers automatic data fetch**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 8, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        let initialFetchCount = mockVTAService.fetchCallCount
        
        // Select a station
        viewModel.selectStation(OrangeLineStations.stations[5])
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify data was fetched
        #expect(mockVTAService.fetchCallCount > initialFetchCount)
        #expect(viewModel.hasPredictions == true)
    }
    
    @Test func directionChangeTriggersDataFetch() async {
        // **Validates: Direction change triggers automatic data fetch**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 8, arrivalStatus: .scheduled, destination: "Mountain View")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[10]
        await viewModel.refreshPredictions()
        
        let fetchCountAfterInitial = mockVTAService.fetchCallCount
        
        // Change direction
        viewModel.selectDirection(.mountainView)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify data was fetched with new direction
        #expect(mockVTAService.fetchCallCount > fetchCountAfterInitial)
        #expect(mockVTAService.lastRequestedDirection == .mountainView)
    }
    
    @Test func preferencePersistenceAcrossViewModelInstances() async {
        // **Validates: Requirements 7.1, 7.2, 7.3 - preferences persist across instances**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        // First ViewModel instance - set preferences
        let viewModel1 = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        let selectedStation = OrangeLineStations.stations[15] // Baypointe
        viewModel1.selectStation(selectedStation)
        viewModel1.selectDirection(.mountainView)
        
        // Wait for save
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify preferences were saved
        #expect(mockStorageService.selectedStation?.id == selectedStation.id)
        #expect(mockStorageService.selectedDirection == .mountainView)
        
        // Second ViewModel instance - should load preferences
        let viewModel2 = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Verify preferences were loaded
        #expect(viewModel2.selectedStation?.id == selectedStation.id)
        #expect(viewModel2.selectedDirection == .mountainView)
    }
}


// MARK: - Station and Direction Display Integration Tests

/// Tests station and direction display across the system
/// **Validates: Requirements 1.3, 1.5, 2.1, 2.4**
struct StationDirectionDisplayIntegrationTests {
    
    @Test func stationsAreOrderedGeographically() {
        // **Validates: Requirement 1.3 - stations ordered from Mountain View to Alum Rock**
        
        let stations = OrangeLineStations.stations
        
        // Verify first station is Mountain View
        #expect(stations.first?.name == "Mountain View")
        #expect(stations.first?.order == 0)
        
        // Verify last station is Alum Rock
        #expect(stations.last?.name == "Alum Rock")
        #expect(stations.last?.order == 28)
        
        // Verify all stations are in order
        for i in 0..<stations.count - 1 {
            #expect(stations[i].order < stations[i + 1].order)
        }
    }
    
    @Test func stationDisplaysFullName() {
        // **Validates: Requirement 1.5 - display station's full name**
        
        let station = OrangeLineStations.stations[12] // Great America
        
        #expect(station.name == "Great America")
        #expect(station.name.count > 0)
    }
    
    @Test func directionOptionsAreAvailable() {
        // **Validates: Requirement 2.1 - two direction options available**
        
        let directions = Direction.allCases
        
        #expect(directions.count == 2)
        #expect(directions.contains(.mountainView))
        #expect(directions.contains(.alumRock))
    }
    
    @Test func directionDisplayNameIsCorrect() {
        // **Validates: Requirement 2.4 - clear direction identification**
        
        #expect(Direction.mountainView.displayName == "Mountain View")
        #expect(Direction.alumRock.displayName == "Alum Rock")
    }
    
    @Test func directionIdMapsCorrectly() {
        // **Validates: Direction ID maps correctly for API calls**
        
        #expect(Direction.mountainView.directionId == "IB")
        #expect(Direction.alumRock.directionId == "OB")
    }
}

// MARK: - Arrival Status Display Integration Tests

/// Tests arrival status display across the system
/// **Validates: Requirements 4.2, 4.3, 4.4, 4.5**
struct ArrivalStatusDisplayIntegrationTests {
    
    @Test func arrivalTimeDisplaysInMinutes() {
        // **Validates: Requirement 4.2 - display arrival time in minutes**
        
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        #expect(prediction.minutesUntilArrival == 5)
        #expect(prediction.arrivalTimeDisplay.contains("5") == true)
    }
    
    @Test func arrivingStatusDisplaysCorrectly() {
        // **Validates: Requirement 4.3 - display "即将到站" for arriving trains**
        
        let prediction = Prediction(
            minutesUntilArrival: nil,
            arrivalStatus: .arriving,
            destination: "Alum Rock"
        )
        
        #expect(prediction.arrivalStatus == .arriving)
        #expect(prediction.arrivalTimeDisplay.contains("即将到站") == true)
    }
    
    @Test func boardingStatusDisplaysCorrectly() {
        // **Validates: Requirement 4.4 - display "进站中" for boarding trains**
        
        let prediction = Prediction(
            minutesUntilArrival: nil,
            arrivalStatus: .boarding,
            destination: "Alum Rock"
        )
        
        #expect(prediction.arrivalStatus == .boarding)
        #expect(prediction.arrivalTimeDisplay.contains("进站中") == true)
    }
    
    @Test func destinationIsDisplayed() {
        // **Validates: Requirement 4.5 - display train's destination**
        
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        #expect(prediction.destination == "Alum Rock")
    }
    
    @Test func complicationDataDisplaysArrivalStatus() {
        // **Validates: Complication displays arrival status correctly**
        
        // Scheduled train
        let scheduledData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        #expect(scheduledData.displayText == "5m")
        
        // Arriving train
        let arrivingData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: nil,
            direction: .alumRock
        )
        #expect(arrivingData.displayText == "ARR")
    }
}


// MARK: - Complete System Integration Tests

/// Tests the complete system integration across all components
/// **Validates: All Requirements**
@MainActor
struct CompleteSystemIntegrationTests {
    
    @Test func completeSystemFlowWithTimeRuleAndComplication() async {
        // **Validates: Complete system integration - all requirements**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        // Set up time rule
        let morningStation = OrangeLineStations.stations[0] // Mountain View
        mockTimeRuleService.mockActiveRule = TimeRule(
            name: "Morning Commute",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: morningStation.id,
            direction: .alumRock,
            isEnabled: true
        )
        
        // Set up predictions
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 3, arrivalStatus: .scheduled, destination: "Alum Rock"),
            Prediction(minutesUntilArrival: 10, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        // Create ViewModel
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Wait for time rule to be applied
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Verify time rule was applied
        #expect(viewModel.selectedStation?.id == morningStation.id)
        #expect(viewModel.selectedDirection == .alumRock)
        
        // Verify predictions were fetched
        #expect(viewModel.hasPredictions == true)
        #expect(viewModel.nextPrediction?.minutesUntilArrival == 3)
        
        // Create complication data
        let complicationData = ComplicationData.from(
            prediction: viewModel.nextPrediction,
            station: viewModel.selectedStation,
            direction: viewModel.selectedDirection
        )
        
        // Verify complication data
        #expect(complicationData.stationShortName == "MTV")
        #expect(complicationData.minutesUntilArrival == 3)
        #expect(complicationData.displayText == "3m")
        
        // Update complication controller
        let complicationController = ComplicationController()
        complicationController.updateComplicationData(complicationData)
        
        // Verify complication controller has data
        #expect(complicationController.currentData == complicationData)
        
        // Verify templates can be created
        for family in complicationController.supportedComplicationFamilies {
            let template = complicationController.createTemplate(for: family, with: complicationData)
            #expect(template != nil)
        }
    }
    
    @Test func systemHandlesErrorGracefully() async {
        // **Validates: System handles errors gracefully across all components**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        // First, get successful data
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[12]
        await viewModel.refreshPredictions()
        
        // Create complication data from successful fetch
        let successData = ComplicationData.from(
            prediction: viewModel.nextPrediction,
            station: viewModel.selectedStation,
            direction: viewModel.selectedDirection
        )
        
        let complicationController = ComplicationController()
        complicationController.updateComplicationData(successData)
        
        // Now simulate error
        mockVTAService.mockError = .networkError("Connection lost")
        mockVTAService.mockPredictions = []
        
        await viewModel.refreshPredictions()
        
        // ViewModel should show error but preserve cached data
        #expect(viewModel.hasError == true)
        #expect(viewModel.hasPredictions == true) // Cached data preserved
        
        // Complication should handle error gracefully
        let errorData = complicationController.createNetworkErrorComplicationData(
            cachedData: successData,
            error: NSError(domain: "test", code: -1, userInfo: nil)
        )
        
        // Should return cached data (now stale)
        #expect(errorData.stationShortName == successData.stationShortName)
        #expect(errorData.isStale() == true)
    }
    
    @Test func systemSupportsMultipleStationSwitches() async {
        // **Validates: System handles multiple station switches correctly**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Switch through multiple stations
        let stationsToTest = [
            OrangeLineStations.stations[0],  // Mountain View
            OrangeLineStations.stations[12], // Great America
            OrangeLineStations.stations[27]  // Alum Rock
        ]
        
        for station in stationsToTest {
            mockVTAService.mockPredictions = [
                Prediction(
                    minutesUntilArrival: station.order + 1,
                    arrivalStatus: .scheduled,
                    destination: "Test"
                )
            ]
            
            viewModel.selectStation(station)
            
            // Wait for async operations
            try? await Task.sleep(nanoseconds: 150_000_000)
            
            // Verify correct station is selected
            #expect(viewModel.selectedStation?.id == station.id)
            
            // Verify correct station was requested from API (uses eastbound ID for default alumRock direction)
            #expect(mockVTAService.lastRequestedStationId == station.stationId(for: .alumRock))
            
            // Verify predictions match
            #expect(viewModel.nextPrediction?.minutesUntilArrival == station.order + 1)
        }
    }
    
    @Test func systemSupportsDirectionSwitching() async {
        // **Validates: System handles direction switching correctly**
        
        let mockVTAService = IntegrationMockVTAService()
        let mockStorageService = IntegrationMockStorageService()
        let mockTimeRuleService = IntegrationMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[14] // Champion
        
        // Test both directions
        for direction in Direction.allCases {
            mockVTAService.mockPredictions = [
                Prediction(
                    minutesUntilArrival: 5,
                    arrivalStatus: .scheduled,
                    destination: direction.displayName
                )
            ]
            
            viewModel.selectDirection(direction)
            
            // Wait for async operations
            try? await Task.sleep(nanoseconds: 150_000_000)
            
            // Verify correct direction is selected
            #expect(viewModel.selectedDirection == direction)
            
            // Verify correct direction was requested from API
            #expect(mockVTAService.lastRequestedDirection == direction)
            
            // Verify predictions have correct destination
            #expect(viewModel.nextPrediction?.destination == direction.displayName)
        }
    }
}

