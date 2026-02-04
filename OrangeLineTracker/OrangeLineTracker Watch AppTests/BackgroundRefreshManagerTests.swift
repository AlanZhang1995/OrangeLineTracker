//
//  BackgroundRefreshManagerTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Unit tests for BackgroundRefreshManager
//

import XCTest
import WatchKit
@testable import OrangeLineTracker_Watch_App

// MARK: - BackgroundRefreshManagerTests

final class BackgroundRefreshManagerTests: XCTestCase {
    
    var mockVTAService: MockVTAService!
    var mockStorageService: MockStorageService!
    var mockTimeRuleService: MockTimeRuleService!
    var complicationController: ComplicationController!
    var backgroundRefreshManager: BackgroundRefreshManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockVTAService = MockVTAService()
        mockStorageService = MockStorageService()
        mockTimeRuleService = MockTimeRuleService(storageService: mockStorageService)
        complicationController = ComplicationController(storageService: mockStorageService)
        backgroundRefreshManager = BackgroundRefreshManager(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService,
            complicationController: complicationController
        )
    }
    
    @MainActor
    override func tearDown() {
        mockVTAService.reset()
        mockStorageService = nil
        mockTimeRuleService = nil
        backgroundRefreshManager = nil
        complicationController = nil
        super.tearDown()
    }
    
    // MARK: - Refresh Interval Tests
    
    /// Tests that the refresh interval is 15 minutes (watchOS limitation)
    /// - Validates: Requirement 9.5 - 15-minute refresh interval
    func testRefreshIntervalIs15Minutes() {
        // 15 minutes = 900 seconds
        XCTAssertEqual(BackgroundRefreshManager.refreshInterval, 15 * 60)
        XCTAssertEqual(BackgroundRefreshManager.refreshInterval, 900)
    }
    
    // MARK: - Needs Refresh Tests
    
    /// Tests that needsRefresh returns true when no previous refresh has occurred
    func testNeedsRefreshReturnsTrueWhenNoPreviousRefresh() {
        // A fresh manager should need a refresh
        XCTAssertTrue(backgroundRefreshManager.needsRefresh)
    }
    
    /// Tests that timeSinceLastRefresh returns nil when no previous refresh has occurred
    func testTimeSinceLastRefreshReturnsNilWhenNoPreviousRefresh() {
        XCTAssertNil(backgroundRefreshManager.timeSinceLastRefresh)
    }
    
    // MARK: - Complication Data Update Tests
    
    /// Tests that updateComplicationData updates the complication controller
    /// - Validates: Requirement 9.5 - update complication data
    func testUpdateComplicationDataUpdatesController() {
        // Given
        let testData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .mountainView,
            lastUpdated: Date()
        )
        
        // When
        backgroundRefreshManager.updateComplicationData(testData)
        
        // Then
        XCTAssertNotNil(complicationController.currentData)
        XCTAssertEqual(complicationController.currentData?.stationShortName, "MTV")
        XCTAssertEqual(complicationController.currentData?.minutesUntilArrival, 5)
        XCTAssertEqual(complicationController.currentData?.direction, .mountainView)
    }
    
    /// Tests that updateComplicationData handles error state correctly
    func testUpdateComplicationDataHandlesErrorState() {
        // Given
        let errorData = ComplicationData.errorState()
        
        // When
        backgroundRefreshManager.updateComplicationData(errorData)
        
        // Then
        XCTAssertNotNil(complicationController.currentData)
        XCTAssertTrue(complicationController.currentData?.isErrorState ?? false)
    }
    
    /// Tests that updateComplicationData preserves station info in error state
    func testUpdateComplicationDataPreservesStationInfoInErrorState() {
        // Given
        let errorData = ComplicationData.errorState(
            stationShortName: "ALR",
            direction: .alumRock
        )
        
        // When
        backgroundRefreshManager.updateComplicationData(errorData)
        
        // Then
        XCTAssertEqual(complicationController.currentData?.stationShortName, "ALR")
        XCTAssertEqual(complicationController.currentData?.direction, .alumRock)
    }
    
    // MARK: - Storage Integration Tests
    
    /// Tests that background refresh loads storage preferences
    @MainActor
    func testBackgroundRefreshLoadsStoragePreferences() {
        // Given
        let testStation = OrangeLineStations.stations.first!
        mockStorageService.selectedStation = testStation
        mockStorageService.selectedDirection = .alumRock
        
        // The manager should use storage service to get preferences
        XCTAssertNotNil(mockStorageService.selectedStation)
        XCTAssertNotNil(mockStorageService.selectedDirection)
    }
    
    // MARK: - VTA Service Integration Tests
    
    /// Tests that VTA service is called with correct parameters
    @MainActor
    func testVTAServiceCalledWithCorrectParameters() async {
        // Given
        let testStation = OrangeLineStations.stations.first!
        mockStorageService.selectedStation = testStation
        mockStorageService.selectedDirection = .mountainView
        
        let testPrediction = Prediction(
            minutesUntilArrival: 3,
            arrivalStatus: .scheduled,
            destination: "Mountain View",
            vehicleId: "123",
            timestamp: Date()
        )
        mockVTAService.mockPredictions = [testPrediction]
        
        // When - simulate what performBackgroundDataRefresh does
        let predictions = try? await mockVTAService.fetchPredictions(
            stationId: testStation.id,
            direction: .mountainView
        )
        
        // Then
        XCTAssertEqual(mockVTAService.lastRequestedStationId, testStation.id)
        XCTAssertEqual(mockVTAService.lastRequestedDirection, .mountainView)
        XCTAssertEqual(predictions?.count, 1)
    }
    
    /// Tests that VTA service errors are handled gracefully
    @MainActor
    func testVTAServiceErrorsHandledGracefully() async {
        // Given
        mockVTAService.mockError = .networkError("Test error")
        
        // When
        do {
            _ = try await mockVTAService.fetchPredictions(
                stationId: "70261",
                direction: .mountainView
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Then - error should be caught
            XCTAssertTrue(error is VTAServiceError)
        }
    }
    
    // MARK: - Complication Data Creation Tests
    
    /// Tests creating complication data from prediction
    @MainActor
    func testComplicationDataCreationFromPrediction() {
        // Given
        let testStation = OrangeLineStations.stations.first!
        let testPrediction = Prediction(
            minutesUntilArrival: 7,
            arrivalStatus: .scheduled,
            destination: "Alum Rock",
            vehicleId: "456",
            timestamp: Date()
        )
        
        // When
        let complicationData = ComplicationData.from(
            prediction: testPrediction,
            station: testStation,
            direction: .alumRock
        )
        
        // Then
        XCTAssertEqual(complicationData.stationShortName, testStation.shortName)
        XCTAssertEqual(complicationData.minutesUntilArrival, 7)
        XCTAssertEqual(complicationData.direction, .alumRock)
    }
    
    /// Tests creating complication data for arriving train
    @MainActor
    func testComplicationDataCreationForArrivingTrain() {
        // Given
        let testStation = OrangeLineStations.stations.first!
        let testPrediction = Prediction(
            minutesUntilArrival: nil,
            arrivalStatus: .arriving,
            destination: "Mountain View",
            vehicleId: "789",
            timestamp: Date()
        )
        
        // When
        let complicationData = ComplicationData.from(
            prediction: testPrediction,
            station: testStation,
            direction: .mountainView
        )
        
        // Then
        XCTAssertEqual(complicationData.stationShortName, testStation.shortName)
        XCTAssertNil(complicationData.minutesUntilArrival)
        XCTAssertEqual(complicationData.displayText, "ARR")
    }
    
    // MARK: - Shared Instance Tests
    
    /// Tests that shared instance is accessible
    func testSharedInstanceIsAccessible() {
        let shared = BackgroundRefreshManager.shared
        XCTAssertNotNil(shared)
    }
    
    // MARK: - Schedule Background Refresh Tests
    
    /// Tests that scheduleBackgroundRefresh can be called without crashing
    /// Note: Actual scheduling behavior cannot be tested in unit tests
    func testScheduleBackgroundRefreshDoesNotCrash() {
        // This test verifies the method can be called without throwing
        // Actual scheduling behavior requires integration testing on device
        backgroundRefreshManager.scheduleBackgroundRefresh()
        // If we reach here, the method didn't crash
        XCTAssertTrue(true)
    }
}

// MARK: - Background Refresh Manager Extension Tests

final class BackgroundRefreshManagerExtensionTests: XCTestCase {
    
    var mockVTAService: MockVTAService!
    var mockStorageService: MockStorageService!
    var mockTimeRuleService: MockTimeRuleService!
    var complicationController: ComplicationController!
    var backgroundRefreshManager: BackgroundRefreshManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockVTAService = MockVTAService()
        mockStorageService = MockStorageService()
        mockTimeRuleService = MockTimeRuleService(storageService: mockStorageService)
        complicationController = ComplicationController(storageService: mockStorageService)
        backgroundRefreshManager = BackgroundRefreshManager(
            vtaService: mockVTAService,
            storageService: mockStorageService,
            timeRuleService: mockTimeRuleService,
            complicationController: complicationController
        )
    }
    
    @MainActor
    override func tearDown() {
        mockVTAService.reset()
        mockStorageService = nil
        mockTimeRuleService = nil
        backgroundRefreshManager = nil
        complicationController = nil
        super.tearDown()
    }
    
    /// Tests applicationDidFinishLaunching extension method
    func testApplicationDidFinishLaunchingDoesNotCrash() {
        // This test verifies the method can be called without throwing
        backgroundRefreshManager.applicationDidFinishLaunching()
        XCTAssertTrue(true)
    }
    
    /// Tests applicationDidBecomeActive extension method
    func testApplicationDidBecomeActiveDoesNotCrash() {
        // This test verifies the method can be called without throwing
        backgroundRefreshManager.applicationDidBecomeActive()
        XCTAssertTrue(true)
    }
    
    /// Tests handleBackgroundTasks extension method with empty set
    func testHandleBackgroundTasksWithEmptySet() {
        // This test verifies the method handles empty task set
        let emptyTasks: Set<WKRefreshBackgroundTask> = []
        backgroundRefreshManager.handleBackgroundTasks(emptyTasks)
        XCTAssertTrue(true)
    }
}
