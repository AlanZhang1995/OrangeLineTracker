//
//  MetroViewModelTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Unit tests for MetroViewModel
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Mock Storage Service for ViewModel Testing

class ViewModelMockStorageService: StorageServiceProtocol {
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
    
    func updateWidgetData(stationName: String, stationShortName: String, direction: String, arrivalMinutes: Int?, arrivalMinutes2: Int? = nil, arrivalMinutes3: Int? = nil) {
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

// MARK: - Mock Time Rule Service for ViewModel Testing

class ViewModelMockTimeRuleService: TimeRuleServiceProtocol {
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

// MARK: - MetroViewModel Initialization Tests

@MainActor
struct MetroViewModelInitializationTests {
    
    @Test func viewModelInitializesWithDefaultValues() {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        #expect(viewModel.selectedStation == nil)
        #expect(viewModel.selectedDirection == .alumRock)
        #expect(viewModel.predictions.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.lastUpdated == nil)
    }
    
    @Test func viewModelLoadsStoredPreferences() {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        // Set up stored preferences
        mockStorageService.selectedStation = OrangeLineStations.stations[5]
        mockStorageService.selectedDirection = .mountainView
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Validates: Requirements 7.3, 7.4 - load saved preferences
        #expect(viewModel.selectedStation?.id == OrangeLineStations.stations[5].id)
        #expect(viewModel.selectedDirection == .mountainView)
        #expect(mockStorageService.loadCallCount == 1)
    }
}


// MARK: - Station Selection Tests

@MainActor
struct MetroViewModelStationSelectionTests {
    
    @Test func selectStationUpdatesSelectedStation() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        let station = OrangeLineStations.stations[10]
        viewModel.selectStation(station)
        
        // Validates: Requirements 1.2 - set station as current selection
        #expect(viewModel.selectedStation?.id == station.id)
    }
    
    @Test func selectStationSavesPreference() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        let station = OrangeLineStations.stations[10]
        viewModel.selectStation(station)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Validates: Requirements 1.4, 7.1 - save selection
        #expect(mockStorageService.saveCallCount >= 1)
        #expect(mockStorageService.selectedStation?.id == station.id)
    }
    
    @Test func selectStationClearsErrorMessage() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Set an error first by selecting a station and triggering a failed refresh
        mockVTAService.mockError = .networkError("Test error")
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.errorMessage != nil)
        
        // Select a new station should clear the error
        mockVTAService.mockError = nil
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        viewModel.selectStation(OrangeLineStations.stations[5])
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.errorMessage == nil)
    }
}


// MARK: - Direction Selection Tests

@MainActor
struct MetroViewModelDirectionSelectionTests {
    
    @Test func selectDirectionUpdatesSelectedDirection() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectDirection(.mountainView)
        
        // Validates: Requirements 2.2 - set direction as current selection
        #expect(viewModel.selectedDirection == .mountainView)
    }
    
    @Test func selectDirectionSavesPreference() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectDirection(.mountainView)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Validates: Requirements 2.3, 7.2 - save selection
        #expect(mockStorageService.saveCallCount >= 1)
        #expect(mockStorageService.selectedDirection == .mountainView)
    }
}

// MARK: - Refresh Predictions Tests

@MainActor
struct MetroViewModelRefreshPredictionsTests {
    
    @Test func refreshPredictionsWithNoStationDoesNothing() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        await viewModel.refreshPredictions()
        
        #expect(viewModel.predictions.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(mockVTAService.fetchCallCount == 0)
    }
    
    @Test func refreshPredictionsFetchesFromService() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock"),
            Prediction(minutesUntilArrival: 15, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        // Validates: Requirements 3.1 - fetch real-time arrival prediction data
        #expect(mockVTAService.fetchCallCount == 1)
        #expect(viewModel.predictions.count == 2)
        #expect(viewModel.predictions[0].minutesUntilArrival == 5)
    }

    
    @Test func refreshPredictionsUpdatesLastUpdated() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        
        #expect(viewModel.lastUpdated == nil)
        
        await viewModel.refreshPredictions()
        
        #expect(viewModel.lastUpdated != nil)
    }
    
    @Test func refreshPredictionsSetsLoadingState() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        
        // After refresh completes, isLoading should be false
        await viewModel.refreshPredictions()
        
        // Validates: Requirements 6.4 - loading indicator
        #expect(viewModel.isLoading == false)
    }
    
    @Test func refreshPredictionsPassesCorrectParameters() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        let station = OrangeLineStations.stations[10]
        viewModel.selectedStation = station
        viewModel.selectedDirection = .mountainView
        
        await viewModel.refreshPredictions()
        
        // Station ID should be the westbound ID since direction is mountainView
        #expect(mockVTAService.lastRequestedStationId == station.stationId(for: .mountainView))
        #expect(mockVTAService.lastRequestedDirection == .mountainView)
    }
}


// MARK: - Error Handling Tests

@MainActor
struct MetroViewModelErrorHandlingTests {
    
    @Test func networkErrorSetsErrorMessage() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockError = .networkError("Connection failed")
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        // Validates: Requirements 5.1 - display network error
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("网络连接失败") == true)
    }
    
    @Test func apiErrorSetsErrorMessage() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockError = .apiError(500, "Internal Server Error")
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        // Validates: Requirements 5.2 - display API error
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("API 错误") == true)
    }
    
    @Test func noDataAvailableSetsErrorMessage() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockError = .noDataAvailable
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        // Validates: Requirements 5.3 - display no data message
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("暂无列车信息") == true)
    }
    
    @Test func invalidAPIKeySetsErrorMessage() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockError = .invalidAPIKey
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        // Validates: Requirements 5.4 - prompt user to check configuration
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("API 密钥无效") == true)
    }
}


// MARK: - Error Recovery Tests

@MainActor
struct MetroViewModelErrorRecoveryTests {
    
    @Test func errorRecoveryPreservesCachedData() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        // First, get successful predictions
        let initialPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock"),
            Prediction(minutesUntilArrival: 15, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        mockVTAService.mockPredictions = initialPredictions
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.predictions.count == 2)
        #expect(viewModel.errorMessage == nil)
        
        // Now simulate an error
        mockVTAService.mockError = .networkError("Connection lost")
        mockVTAService.mockPredictions = []
        
        await viewModel.refreshPredictions()
        
        // Validates: Requirements 5.5 - preserve last successful data as backup
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.predictions.count == 2) // Cached data preserved
        #expect(viewModel.predictions[0].minutesUntilArrival == 5)
    }
    
    @Test func errorWithNoCacheShowsEmptyPredictions() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockError = .networkError("Connection failed")
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.predictions.isEmpty)
    }
    
    @Test func successfulRefreshClearsError() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        // First, simulate an error
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
        
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.predictions.count == 1)
    }
}


// MARK: - Time Rule Tests

@MainActor
struct MetroViewModelTimeRuleTests {
    
    @Test func applyTimeRuleUpdatesStationAndDirection() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        // Set up an active time rule
        let targetStation = OrangeLineStations.stations[15]
        mockTimeRuleService.mockActiveRule = TimeRule(
            name: "Morning Commute",
            triggerTime: Date(),
            stationId: targetStation.id,
            direction: .mountainView,
            isEnabled: true
        )
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Mountain View")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Validates: Requirements 8.3 - auto-switch to rule's station and direction
        #expect(viewModel.selectedStation?.id == targetStation.id)
        #expect(viewModel.selectedDirection == .mountainView)
    }
    
    @Test func applyTimeRuleWithNoActiveRuleDoesNothing() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        // No active rule
        mockTimeRuleService.mockActiveRule = nil
        
        // Set initial values
        let initialStation = OrangeLineStations.stations[5]
        mockStorageService.selectedStation = initialStation
        mockStorageService.selectedDirection = .alumRock
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Validates: Requirements 8.7 - use manual selection when no rule active
        #expect(viewModel.selectedStation?.id == initialStation.id)
        #expect(viewModel.selectedDirection == .alumRock)
    }
    
    @Test func applyTimeRuleWithInvalidStationIdDoesNothing() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        // Set up a rule with invalid station ID
        mockTimeRuleService.mockActiveRule = TimeRule(
            name: "Invalid Rule",
            triggerTime: Date(),
            stationId: "invalid-station-id",
            direction: .mountainView,
            isEnabled: true
        )
        
        // Set initial values
        let initialStation = OrangeLineStations.stations[5]
        mockStorageService.selectedStation = initialStation
        mockStorageService.selectedDirection = .alumRock
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        // Should keep initial values since station ID is invalid
        #expect(viewModel.selectedStation?.id == initialStation.id)
        #expect(viewModel.selectedDirection == .alumRock)
    }
}


// MARK: - Computed Properties Tests

@MainActor
struct MetroViewModelComputedPropertiesTests {
    
    @Test func nextPredictionReturnsFirstPrediction() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock"),
            Prediction(minutesUntilArrival: 15, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.nextPrediction?.minutesUntilArrival == 5)
    }
    
    @Test func nextPredictionReturnsNilWhenEmpty() {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        #expect(viewModel.nextPrediction == nil)
    }
    
    @Test func hasPredictionsReturnsTrueWhenNotEmpty() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.hasPredictions == true)
    }
    
    @Test func hasPredictionsReturnsFalseWhenEmpty() {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        #expect(viewModel.hasPredictions == false)
    }
    
    @Test func hasErrorReturnsTrueWhenErrorMessageSet() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockError = .networkError("Test error")
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.hasError == true)
    }
    
    @Test func hasErrorReturnsFalseWhenNoError() {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        #expect(viewModel.hasError == false)
    }

    
    @Test func isShowingCachedDataReturnsTrueWhenErrorWithCachedData() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        // First get successful data
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        // Then simulate error
        mockVTAService.mockError = .networkError("Test error")
        mockVTAService.mockPredictions = []
        await viewModel.refreshPredictions()
        
        #expect(viewModel.isShowingCachedData == true)
    }
    
    @Test func stationDisplayNameReturnsStationName() {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        
        #expect(viewModel.stationDisplayName == "Mountain View")
    }
    
    @Test func stationDisplayNameReturnsDefaultWhenNoStation() {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        #expect(viewModel.stationDisplayName == "选择站点")
    }
    
    @Test func stationShortNameReturnsShortName() {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        
        #expect(viewModel.stationShortName == "MTV")
    }
    
    @Test func stationShortNameReturnsDefaultWhenNoStation() {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        #expect(viewModel.stationShortName == "--")
    }
    
    @Test func lastUpdatedDisplayReturnsFormattedTime() async {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        mockVTAService.mockPredictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        viewModel.selectedStation = OrangeLineStations.stations[0]
        await viewModel.refreshPredictions()
        
        #expect(viewModel.lastUpdatedDisplay != nil)
        #expect(viewModel.lastUpdatedDisplay?.contains("更新于") == true)
    }
    
    @Test func lastUpdatedDisplayReturnsNilWhenNeverUpdated() {
        let mockVTAService = MockVTAService()
        let mockStorageService = ViewModelMockStorageService()
        let mockTimeRuleService = ViewModelMockTimeRuleService()
        
        let viewModel = MetroViewModel(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService
        )
        
        #expect(viewModel.lastUpdatedDisplay == nil)
    }
}


// MARK: - Property 5: 到站时间格式化完整性测试

/// Property-based tests for arrival time formatting completeness
/// **Validates: Property 5**
struct ArrivalTimeFormattingPropertyTests {
    
    // MARK: - Random Data Generators
    
    /// Generates a random minutes value for arrival time
    /// - Returns: A random Int? (nil for arriving, or 0-120 minutes)
    private func randomMinutesUntilArrival() -> Int? {
        let choice = Int.random(in: 0...10)
        if choice == 0 {
            return nil // Arriving now
        } else if choice == 1 {
            return 0 // Zero minutes
        } else if choice == 2 {
            return 1 // One minute
        } else {
            return Int.random(in: 2...120)
        }
    }
    
    /// Generates a random arrival status
    /// - Returns: A random ArrivalStatus
    private func randomArrivalStatus() -> ArrivalStatus {
        ArrivalStatus.allCases.randomElement()!
    }
    
    /// Generates a random destination name
    /// - Returns: A random destination string
    private func randomDestination() -> String {
        let destinations = [
            "Mountain View",
            "Alum Rock",
            "Milpitas",
            "Great America",
            "Baypointe",
            "Tasman",
            "Berryessa",
            "Santa Clara",
            "San Jose Diridon"
        ]
        return destinations.randomElement()!
    }
    
    /// Generates a random vehicle ID
    /// - Returns: A random vehicle ID string or nil
    private func randomVehicleId() -> String? {
        if Bool.random() {
            return "VEH-\(Int.random(in: 1000...9999))"
        }
        return nil
    }
    
    /// Generates a random Prediction with valid data
    /// - Returns: A randomly generated Prediction
    private func randomPrediction() -> Prediction {
        Prediction(
            minutesUntilArrival: randomMinutesUntilArrival(),
            arrivalStatus: randomArrivalStatus(),
            destination: randomDestination(),
            vehicleId: randomVehicleId(),
            timestamp: Date()
        )
    }
    
    // MARK: - Property 5: 到站时间格式化完整性
    
    /// **Validates: Property 5**
    /// For any valid Prediction object, the formatted display string should contain:
    /// - Arrival time (minutes or status text like "即将到站", "进站中")
    /// - Destination station name
    @Test func property5_formattedArrivalTimeContainsTimeAndDestination() {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let prediction = randomPrediction()
            
            // Get the full display text
            let fullDisplayText = prediction.fullDisplayText
            
            // Verify the formatted string contains the destination
            #expect(fullDisplayText.contains(prediction.destination),
                   "Full display text '\(fullDisplayText)' should contain destination '\(prediction.destination)'")
            
            // Verify the formatted string contains time information
            let containsTimeInfo = containsArrivalTimeInfo(fullDisplayText, prediction: prediction)
            #expect(containsTimeInfo,
                   "Full display text '\(fullDisplayText)' should contain arrival time information")
            
            // Verify the arrow separator is present (indicating both time and destination)
            #expect(fullDisplayText.contains("→"),
                   "Full display text '\(fullDisplayText)' should contain arrow separator")
        }
    }
    
    /// **Validates: Property 5**
    /// For any Prediction with arriving status, the formatted string should show "即将到站"
    @Test func property5_arrivingStatusShowsCorrectText() {
        for _ in 0..<100 {
            let destination = randomDestination()
            let prediction = Prediction(
                minutesUntilArrival: nil,
                arrivalStatus: .arriving,
                destination: destination
            )
            
            let fullDisplayText = prediction.fullDisplayText
            
            // Should contain "即将到站" for arriving status
            #expect(fullDisplayText.contains("即将到站"),
                   "Arriving prediction should show '即将到站', got '\(fullDisplayText)'")
            
            // Should contain destination
            #expect(fullDisplayText.contains(destination),
                   "Full display text should contain destination '\(destination)'")
        }
    }
    
    /// **Validates: Property 5**
    /// For any Prediction with boarding status, the formatted string should show "进站中"
    @Test func property5_boardingStatusShowsCorrectText() {
        for _ in 0..<100 {
            let destination = randomDestination()
            let prediction = Prediction(
                minutesUntilArrival: nil,
                arrivalStatus: .boarding,
                destination: destination
            )
            
            let fullDisplayText = prediction.fullDisplayText
            
            // Should contain "进站中" for boarding status
            #expect(fullDisplayText.contains("进站中"),
                   "Boarding prediction should show '进站中', got '\(fullDisplayText)'")
            
            // Should contain destination
            #expect(fullDisplayText.contains(destination),
                   "Full display text should contain destination '\(destination)'")
        }
    }
    
    /// **Validates: Property 5**
    /// For any Prediction with scheduled status and minutes > 1, the formatted string should show "X 分钟"
    @Test func property5_scheduledStatusWithMinutesShowsMinutes() {
        for _ in 0..<100 {
            let minutes = Int.random(in: 2...120)
            let destination = randomDestination()
            let prediction = Prediction(
                minutesUntilArrival: minutes,
                arrivalStatus: .scheduled,
                destination: destination
            )
            
            let fullDisplayText = prediction.fullDisplayText
            
            // Should contain the minutes value
            #expect(fullDisplayText.contains("\(minutes) 分钟"),
                   "Scheduled prediction with \(minutes) minutes should show '\(minutes) 分钟', got '\(fullDisplayText)'")
            
            // Should contain destination
            #expect(fullDisplayText.contains(destination),
                   "Full display text should contain destination '\(destination)'")
        }
    }
    
    /// **Validates: Property 5**
    /// For any Prediction with 0 or 1 minutes, the formatted string should show "即将到站"
    @Test func property5_zeroOrOneMinuteShowsArriving() {
        for _ in 0..<100 {
            let minutes = Int.random(in: 0...1)
            let destination = randomDestination()
            let prediction = Prediction(
                minutesUntilArrival: minutes,
                arrivalStatus: .scheduled,
                destination: destination
            )
            
            let fullDisplayText = prediction.fullDisplayText
            
            // For 0 minutes, should show "即将到站"
            if minutes <= 0 {
                #expect(fullDisplayText.contains("即将到站"),
                       "Prediction with \(minutes) minutes should show '即将到站', got '\(fullDisplayText)'")
            }
            
            // Should contain destination
            #expect(fullDisplayText.contains(destination),
                   "Full display text should contain destination '\(destination)'")
        }
    }
    
    /// **Validates: Property 5**
    /// The English formatted string should also contain time and destination
    @Test func property5_englishFormattedStringContainsTimeAndDestination() {
        for _ in 0..<100 {
            let prediction = randomPrediction()
            
            // Get the English full display text
            let fullDisplayTextEnglish = prediction.fullDisplayTextEnglish
            
            // Verify the formatted string contains the destination
            #expect(fullDisplayTextEnglish.contains(prediction.destination),
                   "English display text '\(fullDisplayTextEnglish)' should contain destination '\(prediction.destination)'")
            
            // Verify the formatted string contains time information
            let containsTimeInfo = containsEnglishArrivalTimeInfo(fullDisplayTextEnglish, prediction: prediction)
            #expect(containsTimeInfo,
                   "English display text '\(fullDisplayTextEnglish)' should contain arrival time information")
            
            // Verify the arrow separator is present
            #expect(fullDisplayTextEnglish.contains("→"),
                   "English display text '\(fullDisplayTextEnglish)' should contain arrow separator")
        }
    }
    
    /// **Validates: Property 5**
    /// For any valid Prediction, arrivalTimeDisplay should return a non-empty string
    @Test func property5_arrivalTimeDisplayIsNeverEmpty() {
        for _ in 0..<100 {
            let prediction = randomPrediction()
            
            let arrivalTimeDisplay = prediction.arrivalTimeDisplay
            
            #expect(!arrivalTimeDisplay.isEmpty,
                   "arrivalTimeDisplay should never be empty")
        }
    }
    
    /// **Validates: Property 5**
    /// For any valid Prediction, fullDisplayText should be longer than arrivalTimeDisplay
    /// (because it includes destination)
    @Test func property5_fullDisplayTextIncludesMoreThanJustTime() {
        for _ in 0..<100 {
            let prediction = randomPrediction()
            
            let arrivalTimeDisplay = prediction.arrivalTimeDisplay
            let fullDisplayText = prediction.fullDisplayText
            
            #expect(fullDisplayText.count > arrivalTimeDisplay.count,
                   "fullDisplayText '\(fullDisplayText)' should be longer than arrivalTimeDisplay '\(arrivalTimeDisplay)'")
        }
    }
    
    /// **Validates: Property 5**
    /// For delayed status predictions, the formatted string should contain time info and destination
    @Test func property5_delayedStatusContainsTimeAndDestination() {
        for _ in 0..<100 {
            let minutes = Int.random(in: 2...60)
            let destination = randomDestination()
            let prediction = Prediction(
                minutesUntilArrival: minutes,
                arrivalStatus: .delayed,
                destination: destination
            )
            
            let fullDisplayText = prediction.fullDisplayText
            
            // Should contain minutes or status text
            let containsTimeInfo = fullDisplayText.contains("\(minutes) 分钟") || 
                                   fullDisplayText.contains("延误")
            #expect(containsTimeInfo,
                   "Delayed prediction should show time info, got '\(fullDisplayText)'")
            
            // Should contain destination
            #expect(fullDisplayText.contains(destination),
                   "Full display text should contain destination '\(destination)'")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Checks if the display text contains arrival time information
    private func containsArrivalTimeInfo(_ text: String, prediction: Prediction) -> Bool {
        // Check for status text
        if text.contains("即将到站") || text.contains("进站中") || 
           text.contains("按计划") || text.contains("延误") {
            return true
        }
        
        // Check for minutes format "X 分钟"
        if text.contains("分钟") {
            return true
        }
        
        return false
    }
    
    /// Checks if the English display text contains arrival time information
    private func containsEnglishArrivalTimeInfo(_ text: String, prediction: Prediction) -> Bool {
        // Check for status text
        if text.contains("Arriving") || text.contains("Boarding") || 
           text.contains("Scheduled") || text.contains("Delayed") {
            return true
        }
        
        // Check for minutes format "X min"
        if text.contains("min") {
            return true
        }
        
        return false
    }
}


// MARK: - Property 6: 错误恢复数据保留测试

/// Property-based tests for error recovery data retention
/// **Validates: Property 6**
@MainActor
struct ErrorRecoveryDataRetentionPropertyTests {
    
    // MARK: - Random Data Generators
    
    /// Generates a random minutes value for arrival time
    /// - Returns: A random Int? (nil for arriving, or 0-120 minutes)
    private func randomMinutesUntilArrival() -> Int? {
        let choice = Int.random(in: 0...10)
        if choice == 0 {
            return nil // Arriving now
        } else if choice == 1 {
            return 0 // Zero minutes
        } else if choice == 2 {
            return 1 // One minute
        } else {
            return Int.random(in: 2...120)
        }
    }
    
    /// Generates a random arrival status
    /// - Returns: A random ArrivalStatus
    private func randomArrivalStatus() -> ArrivalStatus {
        ArrivalStatus.allCases.randomElement()!
    }
    
    /// Generates a random destination name
    /// - Returns: A random destination string
    private func randomDestination() -> String {
        let destinations = [
            "Mountain View",
            "Alum Rock",
            "Milpitas",
            "Great America",
            "Baypointe",
            "Tasman",
            "Berryessa",
            "Santa Clara",
            "San Jose Diridon"
        ]
        return destinations.randomElement()!
    }
    
    /// Generates a random vehicle ID
    /// - Returns: A random vehicle ID string or nil
    private func randomVehicleId() -> String? {
        if Bool.random() {
            return "VEH-\(Int.random(in: 1000...9999))"
        }
        return nil
    }
    
    /// Generates a random Prediction with valid data
    /// - Returns: A randomly generated Prediction
    private func randomPrediction() -> Prediction {
        Prediction(
            minutesUntilArrival: randomMinutesUntilArrival(),
            arrivalStatus: randomArrivalStatus(),
            destination: randomDestination(),
            vehicleId: randomVehicleId(),
            timestamp: Date()
        )
    }
    
    /// Generates a random list of predictions
    /// - Parameter count: Number of predictions to generate (1-5)
    /// - Returns: An array of randomly generated Predictions
    private func randomPredictions(count: Int? = nil) -> [Prediction] {
        let predictionCount = count ?? Int.random(in: 1...5)
        return (0..<predictionCount).map { _ in randomPrediction() }
    }
    
    /// Generates a random VTAServiceError
    /// - Returns: A random VTAServiceError
    private func randomError() -> VTAServiceError {
        let errors: [VTAServiceError] = [
            .networkError("Connection failed"),
            .networkError("Timeout"),
            .networkError("No internet connection"),
            .apiError(500, "Internal Server Error"),
            .apiError(503, "Service Unavailable"),
            .apiError(429, "Too Many Requests"),
            .invalidAPIKey,
            .noDataAvailable,
            .parsingError("Invalid JSON format")
        ]
        return errors.randomElement()!
    }
    
    /// Selects a random station from the Orange Line
    /// - Returns: A random Station
    private func randomStation() -> Station {
        OrangeLineStations.stations.randomElement()!
    }
    
    // MARK: - Property 6: 错误恢复数据保留
    
    /// **Validates: Property 6**
    /// For any successfully fetched prediction data, when subsequent requests fail,
    /// the previously fetched data should still be available for display.
    @Test func property6_cachedDataPreservedOnError() async {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            // Generate random initial predictions
            let initialPredictions = randomPredictions()
            mockVTAService.mockPredictions = initialPredictions
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            // Select a random station
            viewModel.selectedStation = randomStation()
            
            // First, get successful predictions
            await viewModel.refreshPredictions()
            
            // Verify initial data was loaded
            #expect(viewModel.predictions.count == initialPredictions.count,
                   "Initial predictions should be loaded")
            #expect(viewModel.errorMessage == nil,
                   "No error should be present after successful fetch")
            
            // Now simulate an error
            let error = randomError()
            mockVTAService.mockError = error
            mockVTAService.mockPredictions = []
            
            await viewModel.refreshPredictions()
            
            // Verify cached data is preserved
            #expect(viewModel.predictions.count == initialPredictions.count,
                   "Cached predictions should be preserved when request fails")
            
            // Verify error message is set
            #expect(viewModel.errorMessage != nil,
                   "Error message should be set when request fails")
            
            // Verify isShowingCachedData returns true
            #expect(viewModel.isShowingCachedData == true,
                   "isShowingCachedData should return true when showing cached data with error")
        }
    }
    
    /// **Validates: Property 6**
    /// For any error type, cached predictions should be preserved
    @Test func property6_allErrorTypesPreserveCachedData() async {
        let allErrors: [VTAServiceError] = [
            .networkError("Connection failed"),
            .apiError(500, "Internal Server Error"),
            .invalidAPIKey,
            .noDataAvailable,
            .parsingError("Invalid JSON")
        ]
        
        for error in allErrors {
            // Run multiple iterations for each error type
            for _ in 0..<20 {
                let mockVTAService = MockVTAService()
                let mockStorageService = ViewModelMockStorageService()
                let mockTimeRuleService = ViewModelMockTimeRuleService()
                
                // Generate random initial predictions
                let initialPredictions = randomPredictions()
                mockVTAService.mockPredictions = initialPredictions
                
                let viewModel = MetroViewModel(
                    vtaService: mockVTAService,
                    storageService: mockStorageService,
                    timeRuleService: mockTimeRuleService
                )
                
                viewModel.selectedStation = randomStation()
                
                // Get successful predictions first
                await viewModel.refreshPredictions()
                
                let cachedCount = viewModel.predictions.count
                
                // Simulate the specific error
                mockVTAService.mockError = error
                mockVTAService.mockPredictions = []
                
                await viewModel.refreshPredictions()
                
                // Verify cached data is preserved for this error type
                #expect(viewModel.predictions.count == cachedCount,
                       "Cached predictions should be preserved for error: \(error)")
                #expect(viewModel.errorMessage != nil,
                       "Error message should be set for error: \(error)")
            }
        }
    }
    
    /// **Validates: Property 6**
    /// Cached data should be preserved across multiple consecutive failures
    @Test func property6_cachedDataPreservedAcrossMultipleFailures() async {
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            // Generate random initial predictions
            let initialPredictions = randomPredictions()
            mockVTAService.mockPredictions = initialPredictions
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            viewModel.selectedStation = randomStation()
            
            // Get successful predictions first
            await viewModel.refreshPredictions()
            
            let cachedCount = viewModel.predictions.count
            
            // Simulate multiple consecutive failures
            let failureCount = Int.random(in: 2...5)
            for _ in 0..<failureCount {
                mockVTAService.mockError = randomError()
                mockVTAService.mockPredictions = []
                
                await viewModel.refreshPredictions()
                
                // Verify cached data is still preserved after each failure
                #expect(viewModel.predictions.count == cachedCount,
                       "Cached predictions should be preserved across multiple failures")
                #expect(viewModel.isShowingCachedData == true,
                       "isShowingCachedData should remain true across multiple failures")
            }
        }
    }
    
    /// **Validates: Property 6**
    /// The prediction content should remain unchanged when cached
    @Test func property6_cachedPredictionContentUnchanged() async {
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            // Generate random initial predictions
            let initialPredictions = randomPredictions()
            mockVTAService.mockPredictions = initialPredictions
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            viewModel.selectedStation = randomStation()
            
            // Get successful predictions first
            await viewModel.refreshPredictions()
            
            // Store the prediction details for comparison
            let originalPredictionIds = viewModel.predictions.map { $0.id }
            let originalMinutes = viewModel.predictions.map { $0.minutesUntilArrival }
            let originalDestinations = viewModel.predictions.map { $0.destination }
            
            // Simulate an error
            mockVTAService.mockError = randomError()
            mockVTAService.mockPredictions = []
            
            await viewModel.refreshPredictions()
            
            // Verify the cached prediction content is unchanged
            let cachedPredictionIds = viewModel.predictions.map { $0.id }
            let cachedMinutes = viewModel.predictions.map { $0.minutesUntilArrival }
            let cachedDestinations = viewModel.predictions.map { $0.destination }
            
            #expect(cachedPredictionIds == originalPredictionIds,
                   "Cached prediction IDs should match original")
            #expect(cachedMinutes == originalMinutes,
                   "Cached prediction minutes should match original")
            #expect(cachedDestinations == originalDestinations,
                   "Cached prediction destinations should match original")
        }
    }
    
    /// **Validates: Property 6**
    /// When there's no cached data and an error occurs, predictions should be empty
    @Test func property6_noCachedDataShowsEmptyOnError() async {
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            // Start with an error (no successful fetch first)
            mockVTAService.mockError = randomError()
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            viewModel.selectedStation = randomStation()
            
            // Try to fetch predictions (will fail)
            await viewModel.refreshPredictions()
            
            // Verify predictions are empty when there's no cached data
            #expect(viewModel.predictions.isEmpty,
                   "Predictions should be empty when there's no cached data and request fails")
            #expect(viewModel.errorMessage != nil,
                   "Error message should be set")
            #expect(viewModel.isShowingCachedData == false,
                   "isShowingCachedData should be false when there's no cached data")
        }
    }
    
    /// **Validates: Property 6**
    /// Successful refresh after error should clear error and update data
    @Test func property6_successfulRefreshAfterErrorClearsErrorAndUpdatesData() async {
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            // Generate initial predictions
            let initialPredictions = randomPredictions()
            mockVTAService.mockPredictions = initialPredictions
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            viewModel.selectedStation = randomStation()
            
            // Get successful predictions first
            await viewModel.refreshPredictions()
            
            // Simulate an error
            mockVTAService.mockError = randomError()
            mockVTAService.mockPredictions = []
            
            await viewModel.refreshPredictions()
            
            #expect(viewModel.errorMessage != nil,
                   "Error message should be set after failure")
            #expect(viewModel.isShowingCachedData == true,
                   "Should be showing cached data")
            
            // Now simulate successful refresh with new data
            let newPredictions = randomPredictions()
            mockVTAService.mockError = nil
            mockVTAService.mockPredictions = newPredictions
            
            await viewModel.refreshPredictions()
            
            // Verify error is cleared and new data is shown
            #expect(viewModel.errorMessage == nil,
                   "Error message should be cleared after successful refresh")
            #expect(viewModel.predictions.count == newPredictions.count,
                   "New predictions should replace cached data")
            #expect(viewModel.isShowingCachedData == false,
                   "isShowingCachedData should be false after successful refresh")
        }
    }
}


// MARK: - Property 7: 加载状态一致性测试

/// Property-based tests for loading state consistency
/// **Validates: Property 7**
@MainActor
struct LoadingStateConsistencyPropertyTests {
    
    // MARK: - Random Data Generators
    
    /// Generates a random minutes value for arrival time
    /// - Returns: A random Int? (nil for arriving, or 0-120 minutes)
    private func randomMinutesUntilArrival() -> Int? {
        let choice = Int.random(in: 0...10)
        if choice == 0 {
            return nil // Arriving now
        } else if choice == 1 {
            return 0 // Zero minutes
        } else if choice == 2 {
            return 1 // One minute
        } else {
            return Int.random(in: 2...120)
        }
    }
    
    /// Generates a random arrival status
    /// - Returns: A random ArrivalStatus
    private func randomArrivalStatus() -> ArrivalStatus {
        ArrivalStatus.allCases.randomElement()!
    }
    
    /// Generates a random destination name
    /// - Returns: A random destination string
    private func randomDestination() -> String {
        let destinations = [
            "Mountain View",
            "Alum Rock",
            "Milpitas",
            "Great America",
            "Baypointe",
            "Tasman",
            "Berryessa",
            "Santa Clara",
            "San Jose Diridon"
        ]
        return destinations.randomElement()!
    }
    
    /// Generates a random vehicle ID
    /// - Returns: A random vehicle ID string or nil
    private func randomVehicleId() -> String? {
        if Bool.random() {
            return "VEH-\(Int.random(in: 1000...9999))"
        }
        return nil
    }
    
    /// Generates a random Prediction with valid data
    /// - Returns: A randomly generated Prediction
    private func randomPrediction() -> Prediction {
        Prediction(
            minutesUntilArrival: randomMinutesUntilArrival(),
            arrivalStatus: randomArrivalStatus(),
            destination: randomDestination(),
            vehicleId: randomVehicleId(),
            timestamp: Date()
        )
    }
    
    /// Generates a random list of predictions
    /// - Parameter count: Number of predictions to generate (1-5)
    /// - Returns: An array of randomly generated Predictions
    private func randomPredictions(count: Int? = nil) -> [Prediction] {
        let predictionCount = count ?? Int.random(in: 1...5)
        return (0..<predictionCount).map { _ in randomPrediction() }
    }
    
    /// Generates a random VTAServiceError
    /// - Returns: A random VTAServiceError
    private func randomError() -> VTAServiceError {
        let errors: [VTAServiceError] = [
            .networkError("Connection failed"),
            .networkError("Timeout"),
            .networkError("No internet connection"),
            .apiError(500, "Internal Server Error"),
            .apiError(503, "Service Unavailable"),
            .apiError(429, "Too Many Requests"),
            .invalidAPIKey,
            .noDataAvailable,
            .parsingError("Invalid JSON format")
        ]
        return errors.randomElement()!
    }
    
    /// Selects a random station from the Orange Line
    /// - Returns: A random Station
    private func randomStation() -> Station {
        OrangeLineStations.stations.randomElement()!
    }
    
    // MARK: - Property 7: 加载状态一致性
    
    /// **Validates: Property 7**
    /// isLoading should be false before any refresh operation starts
    @Test func property7_isLoadingFalseBeforeRefresh() async {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            // Before any refresh, isLoading should be false
            #expect(viewModel.isLoading == false,
                   "isLoading should be false before refresh starts")
        }
    }
    
    /// **Validates: Property 7**
    /// isLoading should be false after successful refresh completes
    @Test func property7_isLoadingFalseAfterSuccessfulRefresh() async {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            // Generate random predictions
            let predictions = randomPredictions()
            mockVTAService.mockPredictions = predictions
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            // Select a random station
            viewModel.selectedStation = randomStation()
            
            // Perform refresh
            await viewModel.refreshPredictions()
            
            // After refresh completes, isLoading should be false
            #expect(viewModel.isLoading == false,
                   "isLoading should be false after successful refresh completes")
            
            // Data should be available
            #expect(viewModel.predictions.count == predictions.count,
                   "Predictions should be available after successful refresh")
        }
    }
    
    /// **Validates: Property 7**
    /// isLoading should be false after failed refresh completes
    @Test func property7_isLoadingFalseAfterFailedRefresh() async {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            // Set up error
            mockVTAService.mockError = randomError()
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            // Select a random station
            viewModel.selectedStation = randomStation()
            
            // Perform refresh (will fail)
            await viewModel.refreshPredictions()
            
            // After refresh completes (even with error), isLoading should be false
            #expect(viewModel.isLoading == false,
                   "isLoading should be false after failed refresh completes")
            
            // Error message should be set
            #expect(viewModel.errorMessage != nil,
                   "Error message should be set after failed refresh")
        }
    }
    
    /// **Validates: Property 7**
    /// Loading state transitions should be consistent across multiple refreshes
    @Test func property7_loadingStateConsistentAcrossMultipleRefreshes() async {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            // Select a random station
            viewModel.selectedStation = randomStation()
            
            // Perform multiple refreshes with random success/failure
            let refreshCount = Int.random(in: 2...5)
            for _ in 0..<refreshCount {
                // Randomly decide if this refresh succeeds or fails
                if Bool.random() {
                    mockVTAService.mockError = nil
                    mockVTAService.mockPredictions = randomPredictions()
                } else {
                    mockVTAService.mockError = randomError()
                    mockVTAService.mockPredictions = []
                }
                
                // Before refresh, isLoading should be false
                #expect(viewModel.isLoading == false,
                       "isLoading should be false before each refresh")
                
                // Perform refresh
                await viewModel.refreshPredictions()
                
                // After refresh, isLoading should be false
                #expect(viewModel.isLoading == false,
                       "isLoading should be false after each refresh completes")
            }
        }
    }
    
    /// **Validates: Property 7**
    /// When isLoading is false and there's data, hasPredictions should be true
    @Test func property7_dataAvailableWhenNotLoadingWithData() async {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            // Generate random predictions
            let predictions = randomPredictions()
            mockVTAService.mockPredictions = predictions
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            // Select a random station
            viewModel.selectedStation = randomStation()
            
            // Perform refresh
            await viewModel.refreshPredictions()
            
            // When isLoading is false and we have data
            if !viewModel.isLoading && !viewModel.predictions.isEmpty {
                // hasPredictions should be true
                #expect(viewModel.hasPredictions == true,
                       "hasPredictions should be true when not loading and data is available")
                
                // nextPrediction should be available
                #expect(viewModel.nextPrediction != nil,
                       "nextPrediction should be available when not loading and data is available")
            }
        }
    }
    
    /// **Validates: Property 7**
    /// When isLoading is false and there's an error, hasError should be true
    @Test func property7_errorStateConsistentWhenNotLoading() async {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            // Set up error
            mockVTAService.mockError = randomError()
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            // Select a random station
            viewModel.selectedStation = randomStation()
            
            // Perform refresh (will fail)
            await viewModel.refreshPredictions()
            
            // When isLoading is false and there's an error
            if !viewModel.isLoading && viewModel.errorMessage != nil {
                // hasError should be true
                #expect(viewModel.hasError == true,
                       "hasError should be true when not loading and error message is set")
            }
        }
    }
    
    /// **Validates: Property 7**
    /// Loading state should be false when no station is selected
    @Test func property7_isLoadingFalseWhenNoStationSelected() async {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            // Don't select a station
            viewModel.selectedStation = nil
            
            // Perform refresh
            await viewModel.refreshPredictions()
            
            // isLoading should be false
            #expect(viewModel.isLoading == false,
                   "isLoading should be false when no station is selected")
            
            // Predictions should be empty
            #expect(viewModel.predictions.isEmpty,
                   "Predictions should be empty when no station is selected")
            
            // No error should be set
            #expect(viewModel.errorMessage == nil,
                   "No error should be set when no station is selected")
        }
    }
    
    /// **Validates: Property 7**
    /// Loading state transitions should be consistent for all error types
    @Test func property7_loadingStateConsistentForAllErrorTypes() async {
        let allErrors: [VTAServiceError] = [
            .networkError("Connection failed"),
            .apiError(500, "Internal Server Error"),
            .invalidAPIKey,
            .noDataAvailable,
            .parsingError("Invalid JSON")
        ]
        
        for error in allErrors {
            // Run multiple iterations for each error type
            for _ in 0..<20 {
                let mockVTAService = MockVTAService()
                let mockStorageService = ViewModelMockStorageService()
                let mockTimeRuleService = ViewModelMockTimeRuleService()
                
                mockVTAService.mockError = error
                
                let viewModel = MetroViewModel(
                    vtaService: mockVTAService,
                    storageService: mockStorageService,
                    timeRuleService: mockTimeRuleService
                )
                
                // Select a random station
                viewModel.selectedStation = randomStation()
                
                // Before refresh
                #expect(viewModel.isLoading == false,
                       "isLoading should be false before refresh for error: \(error)")
                
                // Perform refresh
                await viewModel.refreshPredictions()
                
                // After refresh
                #expect(viewModel.isLoading == false,
                       "isLoading should be false after refresh for error: \(error)")
                #expect(viewModel.errorMessage != nil,
                       "Error message should be set for error: \(error)")
            }
        }
    }
    
    /// **Validates: Property 7**
    /// Loading state should be consistent when switching between success and failure
    @Test func property7_loadingStateConsistentWhenSwitchingBetweenSuccessAndFailure() async {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            // Select a random station
            viewModel.selectedStation = randomStation()
            
            // First, successful refresh
            mockVTAService.mockError = nil
            mockVTAService.mockPredictions = randomPredictions()
            
            await viewModel.refreshPredictions()
            
            #expect(viewModel.isLoading == false,
                   "isLoading should be false after successful refresh")
            #expect(viewModel.hasPredictions == true,
                   "Should have predictions after successful refresh")
            
            // Then, failed refresh
            mockVTAService.mockError = randomError()
            mockVTAService.mockPredictions = []
            
            await viewModel.refreshPredictions()
            
            #expect(viewModel.isLoading == false,
                   "isLoading should be false after failed refresh")
            #expect(viewModel.hasError == true,
                   "Should have error after failed refresh")
            
            // Then, successful refresh again
            mockVTAService.mockError = nil
            mockVTAService.mockPredictions = randomPredictions()
            
            await viewModel.refreshPredictions()
            
            #expect(viewModel.isLoading == false,
                   "isLoading should be false after second successful refresh")
            #expect(viewModel.hasError == false,
                   "Error should be cleared after successful refresh")
            #expect(viewModel.hasPredictions == true,
                   "Should have predictions after second successful refresh")
        }
    }
    
    /// **Validates: Property 7**
    /// UI state indicators should be mutually consistent with loading state
    @Test func property7_uiStateIndicatorsConsistentWithLoadingState() async {
        // Run 100 iterations with random data
        for _ in 0..<100 {
            let mockVTAService = MockVTAService()
            let mockStorageService = ViewModelMockStorageService()
            let mockTimeRuleService = ViewModelMockTimeRuleService()
            
            // Randomly decide if this refresh succeeds or fails
            let shouldSucceed = Bool.random()
            if shouldSucceed {
                mockVTAService.mockError = nil
                mockVTAService.mockPredictions = randomPredictions()
            } else {
                mockVTAService.mockError = randomError()
                mockVTAService.mockPredictions = []
            }
            
            let viewModel = MetroViewModel(
                vtaService: mockVTAService,
                storageService: mockStorageService,
                timeRuleService: mockTimeRuleService
            )
            
            // Select a random station
            viewModel.selectedStation = randomStation()
            
            // Perform refresh
            await viewModel.refreshPredictions()
            
            // After refresh completes, verify UI state consistency
            #expect(viewModel.isLoading == false,
                   "isLoading should be false after refresh")
            
            // If successful, should have data and no error
            if shouldSucceed {
                #expect(viewModel.hasPredictions == true,
                       "Should have predictions after successful refresh")
                #expect(viewModel.hasError == false,
                       "Should not have error after successful refresh")
                #expect(viewModel.isShowingCachedData == false,
                       "Should not be showing cached data after successful refresh")
            } else {
                // If failed, should have error
                #expect(viewModel.hasError == true,
                       "Should have error after failed refresh")
            }
        }
    }
}
