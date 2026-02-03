//
//  ComplicationDataTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Unit tests for ComplicationData model
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - ComplicationData Model Tests

struct ComplicationDataModelTests {
    
    // MARK: - Structure Tests
    
    @Test func complicationDataHasRequiredProperties() {
        // Validates: Requirements 9.2, 9.6
        let timestamp = Date()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: timestamp
        )
        
        #expect(data.stationShortName == "MTV")
        #expect(data.minutesUntilArrival == 5)
        #expect(data.direction == .alumRock)
        #expect(data.lastUpdated == timestamp)
    }
    
    @Test func complicationDataAllowsNilMinutesUntilArrival() {
        // nil indicates train is arriving now
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: nil,
            direction: .mountainView
        )
        
        #expect(data.minutesUntilArrival == nil)
    }
    
    @Test func complicationDataConformsToEquatable() {
        let timestamp = Date()
        
        let data1 = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: timestamp
        )
        
        let data2 = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: timestamp
        )
        
        let data3 = ComplicationData(
            stationShortName: "ALR",
            minutesUntilArrival: 10,
            direction: .mountainView,
            lastUpdated: timestamp
        )
        
        #expect(data1 == data2)
        #expect(data1 != data3)
    }
    
    @Test func complicationDataConformsToCodable() throws {
        let timestamp = Date()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: timestamp
        )
        
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(data)
        
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(ComplicationData.self, from: encodedData)
        
        #expect(decodedData == data)
    }
    
    @Test func complicationDataCodableRoundTripWithNilMinutes() throws {
        let data = ComplicationData(
            stationShortName: "GAM",
            minutesUntilArrival: nil,
            direction: .mountainView
        )
        
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(data)
        
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(ComplicationData.self, from: encodedData)
        
        #expect(decodedData.minutesUntilArrival == nil)
        #expect(decodedData.stationShortName == "GAM")
        #expect(decodedData.direction == .mountainView)
    }
    
    // MARK: - displayText Tests
    
    @Test func displayTextShowsMinutesWithSuffix() {
        // Validates: Requirement 9.2
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        #expect(data.displayText == "5m")
    }
    
    @Test func displayTextShowsARRForNilMinutes() {
        // Validates: Requirement 9.2 - arriving trains
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: nil,
            direction: .alumRock
        )
        
        #expect(data.displayText == "ARR")
    }
    
    @Test func displayTextShowsARRForZeroMinutes() {
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 0,
            direction: .alumRock
        )
        
        #expect(data.displayText == "ARR")
    }
    
    @Test func displayTextShowsARRForNegativeMinutes() {
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: -1,
            direction: .alumRock
        )
        
        #expect(data.displayText == "ARR")
    }
    
    @Test func displayTextShowsLargeMinutesValue() {
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 120,
            direction: .alumRock
        )
        
        #expect(data.displayText == "120m")
    }
    
    @Test func displayTextShowsDashForErrorState() {
        // Validates: Requirement 9.7 - show "--" for error state
        let data = ComplicationData.errorState()
        
        #expect(data.displayText == "--")
    }
    
    @Test func displayTextShowsDashForEmptyStationName() {
        // Validates: Requirement 9.7 - show "--" for error state
        let data = ComplicationData(
            stationShortName: "",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        #expect(data.displayText == "--")
    }
    
    // MARK: - displayTextWithStaleIndicator Tests
    
    @Test func displayTextWithStaleIndicatorShowsNormalForFreshData() {
        // Validates: Requirement 9.7
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: Date()
        )
        
        #expect(data.displayTextWithStaleIndicator() == "5m")
    }
    
    @Test func displayTextWithStaleIndicatorShowsWarningForStaleData() {
        // Validates: Requirement 9.7 - show stale indicator for cached data
        let oldTimestamp = Date().addingTimeInterval(-6 * 60) // 6 minutes ago
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: oldTimestamp
        )
        
        #expect(data.displayTextWithStaleIndicator() == "⚠5m")
    }
    
    @Test func displayTextWithStaleIndicatorUsesCustomMaxAge() {
        // Validates: Requirement 9.7
        let timestamp = Date().addingTimeInterval(-3 * 60) // 3 minutes ago
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: timestamp
        )
        
        // With default 5 minute max age, should not show warning
        #expect(data.displayTextWithStaleIndicator() == "5m")
        
        // With 2 minute max age, should show warning
        #expect(data.displayTextWithStaleIndicator(maxAge: 2 * 60) == "⚠5m")
    }
    
    // MARK: - fullDisplayText Tests
    
    @Test func fullDisplayTextIncludesStationAndTime() {
        // Validates: Requirements 9.2, 9.6
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        #expect(data.fullDisplayText == "MTV 5m")
    }
    
    @Test func fullDisplayTextWithArrivingTrain() {
        // Validates: Requirements 9.2, 9.6
        let data = ComplicationData(
            stationShortName: "GAM",
            minutesUntilArrival: nil,
            direction: .mountainView
        )
        
        #expect(data.fullDisplayText == "GAM ARR")
    }
    
    @Test func fullDisplayTextContainsStationShortName() {
        // Validates: Requirement 9.6 - station name abbreviation
        let data = ComplicationData(
            stationShortName: "BRY",
            minutesUntilArrival: 10,
            direction: .alumRock
        )
        
        #expect(data.fullDisplayText.contains("BRY"))
    }
    
    @Test func fullDisplayTextContainsArrivalTime() {
        // Validates: Requirement 9.2 - arrival time
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 15,
            direction: .alumRock
        )
        
        #expect(data.fullDisplayText.contains("15m"))
    }
    
    @Test func fullDisplayTextShowsDashForErrorState() {
        // Validates: Requirement 9.7 - show "--" for error state
        let data = ComplicationData.errorState()
        
        #expect(data.fullDisplayText == "-- --")
    }
    
    // MARK: - fullDisplayTextWithStaleIndicator Tests
    
    @Test func fullDisplayTextWithStaleIndicatorShowsNormalForFreshData() {
        // Validates: Requirement 9.7
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: Date()
        )
        
        #expect(data.fullDisplayTextWithStaleIndicator() == "MTV 5m")
    }
    
    @Test func fullDisplayTextWithStaleIndicatorShowsWarningForStaleData() {
        // Validates: Requirement 9.7 - show stale indicator for cached data
        let oldTimestamp = Date().addingTimeInterval(-6 * 60) // 6 minutes ago
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: oldTimestamp
        )
        
        #expect(data.fullDisplayTextWithStaleIndicator() == "⚠MTV 5m")
    }
    
    // MARK: - displayTextWithDirection Tests
    
    @Test func displayTextWithDirectionShowsAlumRockDirection() {
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        #expect(data.displayTextWithDirection == "MTV→ALR 5m")
    }
    
    @Test func displayTextWithDirectionShowsMountainViewDirection() {
        let data = ComplicationData(
            stationShortName: "ALR",
            minutesUntilArrival: 8,
            direction: .mountainView
        )
        
        #expect(data.displayTextWithDirection == "ALR→MTV 8m")
    }
    
    @Test func displayTextWithDirectionShowsDashForErrorState() {
        // Validates: Requirement 9.7 - show "--" for error state
        let data = ComplicationData.errorState()
        
        #expect(data.displayTextWithDirection == "-- --")
    }
    
    // MARK: - displayTextWithDirectionAndStaleIndicator Tests
    
    @Test func displayTextWithDirectionAndStaleIndicatorShowsNormalForFreshData() {
        // Validates: Requirement 9.7
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: Date()
        )
        
        #expect(data.displayTextWithDirectionAndStaleIndicator() == "MTV→ALR 5m")
    }
    
    @Test func displayTextWithDirectionAndStaleIndicatorShowsWarningForStaleData() {
        // Validates: Requirement 9.7 - show stale indicator for cached data
        let oldTimestamp = Date().addingTimeInterval(-6 * 60) // 6 minutes ago
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: oldTimestamp
        )
        
        #expect(data.displayTextWithDirectionAndStaleIndicator() == "⚠MTV→ALR 5m")
    }
    
    // MARK: - detailedDisplayText Tests
    
    @Test func detailedDisplayTextShowsMinutesWithFullSuffix() {
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        #expect(data.detailedDisplayText == "5 min")
    }
    
    @Test func detailedDisplayTextShowsArrivingForNilMinutes() {
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: nil,
            direction: .alumRock
        )
        
        #expect(data.detailedDisplayText == "Arriving")
    }
    
    @Test func detailedDisplayTextShowsArrivingForZeroMinutes() {
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 0,
            direction: .alumRock
        )
        
        #expect(data.detailedDisplayText == "Arriving")
    }
    
    @Test func detailedDisplayTextShowsDashForErrorState() {
        // Validates: Requirement 9.7 - show "--" for error state
        let data = ComplicationData.errorState()
        
        #expect(data.detailedDisplayText == "--")
    }
    
    // MARK: - detailedDisplayTextWithStaleIndicator Tests
    
    @Test func detailedDisplayTextWithStaleIndicatorShowsNormalForFreshData() {
        // Validates: Requirement 9.7
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: Date()
        )
        
        #expect(data.detailedDisplayTextWithStaleIndicator() == "5 min")
    }
    
    @Test func detailedDisplayTextWithStaleIndicatorShowsWarningForStaleData() {
        // Validates: Requirement 9.7 - show stale indicator for cached data
        let oldTimestamp = Date().addingTimeInterval(-6 * 60) // 6 minutes ago
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: oldTimestamp
        )
        
        #expect(data.detailedDisplayTextWithStaleIndicator() == "⚠5 min")
    }
    
    // MARK: - Data Freshness Tests
    
    @Test func isStaleReturnsFalseForFreshData() {
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: Date()
        )
        
        #expect(data.isStale() == false)
    }
    
    @Test func isStaleReturnsTrueForOldData() {
        let oldTimestamp = Date().addingTimeInterval(-6 * 60) // 6 minutes ago
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: oldTimestamp
        )
        
        #expect(data.isStale() == true)
    }
    
    @Test func isStaleUsesCustomMaxAge() {
        let timestamp = Date().addingTimeInterval(-3 * 60) // 3 minutes ago
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: timestamp
        )
        
        // With default 5 minute max age, should not be stale
        #expect(data.isStale() == false)
        
        // With 2 minute max age, should be stale
        #expect(data.isStale(maxAge: 2 * 60) == true)
    }
    
    @Test func dataAgeReturnsCorrectValue() {
        let timestamp = Date().addingTimeInterval(-60) // 1 minute ago
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: timestamp
        )
        
        // Data age should be approximately 60 seconds (allow some tolerance)
        #expect(data.dataAge >= 59 && data.dataAge <= 62)
    }
    
    // MARK: - Error State Tests
    
    @Test func errorStateCreatesDataWithDashStationName() {
        // Validates: Requirement 9.7
        let errorData = ComplicationData.errorState()
        
        #expect(errorData.stationShortName == "--")
        #expect(errorData.minutesUntilArrival == nil)
    }
    
    @Test func errorStateWithCustomStationName() {
        let errorData = ComplicationData.errorState(stationShortName: "ERR")
        
        #expect(errorData.stationShortName == "ERR")
    }
    
    @Test func errorStateWithCustomDirection() {
        let errorData = ComplicationData.errorState(direction: .mountainView)
        
        #expect(errorData.direction == .mountainView)
    }
    
    @Test func noDataDisplayTextIsDash() {
        // Validates: Requirement 9.7
        #expect(ComplicationData.noDataDisplayText == "--")
    }
    
    @Test func isErrorStateReturnsTrueForDashStationName() {
        let errorData = ComplicationData.errorState()
        
        #expect(errorData.isErrorState == true)
    }
    
    @Test func isErrorStateReturnsTrueForEmptyStationName() {
        let data = ComplicationData(
            stationShortName: "",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        #expect(data.isErrorState == true)
    }
    
    @Test func isErrorStateReturnsFalseForValidData() {
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        #expect(data.isErrorState == false)
    }
    
    // MARK: - Factory Method Tests
    
    @Test func fromPredictionCreatesCorrectData() {
        let station = Station(id: "70261", name: "Mountain View", shortName: "MTV", order: 0)
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        let data = ComplicationData.from(
            prediction: prediction,
            station: station,
            direction: .alumRock
        )
        
        #expect(data.stationShortName == "MTV")
        #expect(data.minutesUntilArrival == 5)
        #expect(data.direction == .alumRock)
    }
    
    @Test func fromPredictionWithArrivingStatusSetsNilMinutes() {
        let station = Station(id: "70261", name: "Mountain View", shortName: "MTV", order: 0)
        let prediction = Prediction(
            minutesUntilArrival: 1,
            arrivalStatus: .arriving,
            destination: "Alum Rock"
        )
        
        let data = ComplicationData.from(
            prediction: prediction,
            station: station,
            direction: .alumRock
        )
        
        #expect(data.minutesUntilArrival == nil)
        #expect(data.displayText == "ARR")
    }
    
    @Test func fromPredictionWithBoardingStatusSetsNilMinutes() {
        let station = Station(id: "70261", name: "Mountain View", shortName: "MTV", order: 0)
        let prediction = Prediction(
            minutesUntilArrival: 0,
            arrivalStatus: .boarding,
            destination: "Alum Rock"
        )
        
        let data = ComplicationData.from(
            prediction: prediction,
            station: station,
            direction: .alumRock
        )
        
        #expect(data.minutesUntilArrival == nil)
        #expect(data.displayText == "ARR")
    }
    
    @Test func fromOptionalPredictionReturnsErrorStateForNilPrediction() {
        let station = Station(id: "70261", name: "Mountain View", shortName: "MTV", order: 0)
        
        let data = ComplicationData.from(
            prediction: nil,
            station: station,
            direction: .alumRock
        )
        
        #expect(data.isErrorState == true)
    }
    
    @Test func fromOptionalPredictionReturnsErrorStateForNilStation() {
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        let data = ComplicationData.from(
            prediction: prediction,
            station: nil,
            direction: .alumRock
        )
        
        #expect(data.isErrorState == true)
    }
    
    @Test func fromOptionalPredictionReturnsValidDataForValidInputs() {
        let station = Station(id: "70261", name: "Mountain View", shortName: "MTV", order: 0)
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        let data = ComplicationData.from(
            prediction: prediction,
            station: station,
            direction: .alumRock
        )
        
        #expect(data.isErrorState == false)
        #expect(data.stationShortName == "MTV")
        #expect(data.minutesUntilArrival == 5)
    }
    
    // MARK: - Edge Cases
    
    @Test func complicationDataWithAllStationShortNames() {
        // Test with various station short names
        let shortNames = ["MTV", "WSM", "MDF", "NASA", "GAM", "ALR"]
        
        for shortName in shortNames {
            let data = ComplicationData(
                stationShortName: shortName,
                minutesUntilArrival: 5,
                direction: .alumRock
            )
            
            #expect(data.fullDisplayText.contains(shortName))
        }
    }
    
    @Test func complicationDataWithBothDirections() {
        let dataAlumRock = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        let dataMountainView = ComplicationData(
            stationShortName: "ALR",
            minutesUntilArrival: 5,
            direction: .mountainView
        )
        
        #expect(dataAlumRock.direction == .alumRock)
        #expect(dataMountainView.direction == .mountainView)
    }
    
    @Test func complicationDataDefaultLastUpdatedIsNow() {
        let beforeCreation = Date()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        let afterCreation = Date()
        
        #expect(data.lastUpdated >= beforeCreation)
        #expect(data.lastUpdated <= afterCreation)
    }
}
