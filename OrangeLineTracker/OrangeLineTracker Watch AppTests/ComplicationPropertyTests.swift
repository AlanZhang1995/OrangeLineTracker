//
//  ComplicationPropertyTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Property-based tests for Complication content integrity
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Property 11: Complication 内容完整性测试

/// Property-based tests for Complication content integrity
/// **Feature: orange-line-tracker, Property 11: Complication 内容完整性**
/// **Validates: Requirements 9.2, 9.6**
struct ComplicationContentIntegrityPropertyTests {
    
    // MARK: - Test Data Generators
    
    /// Generates a random station from the Orange Line stations
    private func randomStation() -> Station {
        OrangeLineStations.stations.randomElement()!
    }
    
    /// Generates a random direction
    private func randomDirection() -> Direction {
        Direction.allCases.randomElement()!
    }
    
    /// Generates a random valid minutes until arrival
    /// Returns nil for "arriving" state, or a positive integer for scheduled arrivals
    private func randomMinutesUntilArrival() -> Int? {
        // 30% chance of nil (arriving now)
        // 70% chance of positive minutes (1-120)
        if Int.random(in: 0..<10) < 3 {
            return nil
        }
        return Int.random(in: 1...120)
    }
    
    /// Generates a random ComplicationData with valid station and arrival time
    private func randomComplicationData() -> ComplicationData {
        let station = randomStation()
        let minutes = randomMinutesUntilArrival()
        let direction = randomDirection()
        
        return ComplicationData(
            stationShortName: station.shortName,
            minutesUntilArrival: minutes,
            direction: direction,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Property 11 Tests
    
    /// Property 11: Complication fullDisplayText always contains station short name
    /// **Validates: Requirements 9.2, 9.6**
    /// **Feature: orange-line-tracker, Property 11**
    @Test("Property 11: fullDisplayText contains station short name - 100 iterations")
    func fullDisplayTextContainsStationShortName() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            let station = randomStation()
            let minutes = randomMinutesUntilArrival()
            let direction = randomDirection()
            
            let data = ComplicationData(
                stationShortName: station.shortName,
                minutesUntilArrival: minutes,
                direction: direction,
                lastUpdated: Date()
            )
            
            // Property: fullDisplayText must contain the station short name
            #expect(
                data.fullDisplayText.contains(station.shortName),
                "Iteration \(iteration): fullDisplayText '\(data.fullDisplayText)' should contain station short name '\(station.shortName)'"
            )
        }
    }
    
    /// Property 11: Complication fullDisplayText always contains arrival time indicator
    /// **Validates: Requirements 9.2, 9.6**
    /// **Feature: orange-line-tracker, Property 11**
    @Test("Property 11: fullDisplayText contains arrival time - 100 iterations")
    func fullDisplayTextContainsArrivalTime() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            let station = randomStation()
            let minutes = randomMinutesUntilArrival()
            let direction = randomDirection()
            
            let data = ComplicationData(
                stationShortName: station.shortName,
                minutesUntilArrival: minutes,
                direction: direction,
                lastUpdated: Date()
            )
            
            // Property: fullDisplayText must contain arrival time indicator
            // Either "ARR" for arriving, or "{minutes}m" for scheduled
            let containsArrivalInfo: Bool
            if let mins = minutes, mins > 0 {
                containsArrivalInfo = data.fullDisplayText.contains("\(mins)m")
            } else {
                containsArrivalInfo = data.fullDisplayText.contains("ARR")
            }
            
            #expect(
                containsArrivalInfo,
                "Iteration \(iteration): fullDisplayText '\(data.fullDisplayText)' should contain arrival time (minutes=\(String(describing: minutes)))"
            )
        }
    }
    
    /// Property 11: Complication displayText always contains arrival time indicator
    /// **Validates: Requirements 9.2, 9.6**
    /// **Feature: orange-line-tracker, Property 11**
    @Test("Property 11: displayText contains arrival time - 100 iterations")
    func displayTextContainsArrivalTime() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            let minutes = randomMinutesUntilArrival()
            let station = randomStation()
            let direction = randomDirection()
            
            let data = ComplicationData(
                stationShortName: station.shortName,
                minutesUntilArrival: minutes,
                direction: direction,
                lastUpdated: Date()
            )
            
            // Property: displayText must be either "ARR" or "{minutes}m"
            let isValidDisplayText: Bool
            if let mins = minutes, mins > 0 {
                isValidDisplayText = data.displayText == "\(mins)m"
            } else {
                isValidDisplayText = data.displayText == "ARR"
            }
            
            #expect(
                isValidDisplayText,
                "Iteration \(iteration): displayText '\(data.displayText)' should be valid arrival time format (minutes=\(String(describing: minutes)))"
            )
        }
    }
    
    /// Property 11: Combined test - fullDisplayText contains both station and arrival time
    /// **Validates: Requirements 9.2, 9.6**
    /// **Feature: orange-line-tracker, Property 11**
    @Test("Property 11: fullDisplayText contains both station and arrival time - 100 iterations")
    func fullDisplayTextContainsBothStationAndArrivalTime() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            let data = randomComplicationData()
            
            // Property 1: Must contain station short name
            let containsStation = data.fullDisplayText.contains(data.stationShortName)
            
            // Property 2: Must contain arrival time indicator
            let containsArrivalInfo: Bool
            if let mins = data.minutesUntilArrival, mins > 0 {
                containsArrivalInfo = data.fullDisplayText.contains("\(mins)m")
            } else {
                containsArrivalInfo = data.fullDisplayText.contains("ARR")
            }
            
            #expect(
                containsStation && containsArrivalInfo,
                "Iteration \(iteration): fullDisplayText '\(data.fullDisplayText)' should contain both station '\(data.stationShortName)' and arrival time"
            )
        }
    }
    
    /// Property 11: All Orange Line stations produce valid complication content
    /// **Validates: Requirements 9.2, 9.6**
    /// **Feature: orange-line-tracker, Property 11**
    @Test("Property 11: All stations produce valid complication content")
    func allStationsProduceValidComplicationContent() {
        // Test all 29 stations with random arrival times
        for station in OrangeLineStations.stations {
            // Test each station multiple times with different arrival times
            for _ in 1...4 {
                let minutes = randomMinutesUntilArrival()
                let direction = randomDirection()
                
                let data = ComplicationData(
                    stationShortName: station.shortName,
                    minutesUntilArrival: minutes,
                    direction: direction,
                    lastUpdated: Date()
                )
                
                // Verify station short name is in fullDisplayText
                #expect(
                    data.fullDisplayText.contains(station.shortName),
                    "Station '\(station.name)' (\(station.shortName)): fullDisplayText '\(data.fullDisplayText)' should contain short name"
                )
                
                // Verify arrival time is in fullDisplayText
                let containsArrivalInfo: Bool
                if let mins = minutes, mins > 0 {
                    containsArrivalInfo = data.fullDisplayText.contains("\(mins)m")
                } else {
                    containsArrivalInfo = data.fullDisplayText.contains("ARR")
                }
                
                #expect(
                    containsArrivalInfo,
                    "Station '\(station.name)': fullDisplayText '\(data.fullDisplayText)' should contain arrival time"
                )
            }
        }
    }
    
    /// Property 11: Various arrival time values produce valid complication content
    /// **Validates: Requirements 9.2, 9.6**
    /// **Feature: orange-line-tracker, Property 11**
    @Test("Property 11: Various arrival times produce valid content - 100 iterations")
    func variousArrivalTimesProduceValidContent() {
        // Test specific edge cases and random values
        let testMinutes: [Int?] = [
            nil,    // Arriving
            0,      // Zero minutes (should show ARR)
            1,      // 1 minute
            5,      // 5 minutes
            15,     // 15 minutes
            30,     // 30 minutes
            60,     // 1 hour
            120     // 2 hours
        ]
        
        // Test each specific value with random stations
        for minutes in testMinutes {
            for _ in 1...10 {
                let station = randomStation()
                let direction = randomDirection()
                
                let data = ComplicationData(
                    stationShortName: station.shortName,
                    minutesUntilArrival: minutes,
                    direction: direction,
                    lastUpdated: Date()
                )
                
                // Verify content integrity
                #expect(
                    data.fullDisplayText.contains(station.shortName),
                    "Minutes=\(String(describing: minutes)): fullDisplayText '\(data.fullDisplayText)' should contain station '\(station.shortName)'"
                )
                
                // Verify arrival time format
                let expectedArrivalText: String
                if let mins = minutes, mins > 0 {
                    expectedArrivalText = "\(mins)m"
                } else {
                    expectedArrivalText = "ARR"
                }
                
                #expect(
                    data.fullDisplayText.contains(expectedArrivalText),
                    "Minutes=\(String(describing: minutes)): fullDisplayText '\(data.fullDisplayText)' should contain '\(expectedArrivalText)'"
                )
            }
        }
    }
    
    /// Property 11: Both directions produce valid complication content
    /// **Validates: Requirements 9.2, 9.6**
    /// **Feature: orange-line-tracker, Property 11**
    @Test("Property 11: Both directions produce valid content - 100 iterations")
    func bothDirectionsProduceValidContent() {
        // Test both directions with random data
        for direction in Direction.allCases {
            for _ in 1...50 {
                let station = randomStation()
                let minutes = randomMinutesUntilArrival()
                
                let data = ComplicationData(
                    stationShortName: station.shortName,
                    minutesUntilArrival: minutes,
                    direction: direction,
                    lastUpdated: Date()
                )
                
                // Verify content integrity for both directions
                #expect(
                    data.fullDisplayText.contains(station.shortName),
                    "Direction=\(direction): fullDisplayText '\(data.fullDisplayText)' should contain station '\(station.shortName)'"
                )
                
                let containsArrivalInfo: Bool
                if let mins = minutes, mins > 0 {
                    containsArrivalInfo = data.fullDisplayText.contains("\(mins)m")
                } else {
                    containsArrivalInfo = data.fullDisplayText.contains("ARR")
                }
                
                #expect(
                    containsArrivalInfo,
                    "Direction=\(direction): fullDisplayText '\(data.fullDisplayText)' should contain arrival time"
                )
            }
        }
    }
}

// MARK: - Additional Property 11 Tests for displayTextWithDirection

/// Additional property tests for displayTextWithDirection
/// **Feature: orange-line-tracker, Property 11: Complication 内容完整性**
struct ComplicationDisplayTextWithDirectionPropertyTests {
    
    /// Generates a random station from the Orange Line stations
    private func randomStation() -> Station {
        OrangeLineStations.stations.randomElement()!
    }
    
    /// Generates a random direction
    private func randomDirection() -> Direction {
        Direction.allCases.randomElement()!
    }
    
    /// Generates a random valid minutes until arrival
    private func randomMinutesUntilArrival() -> Int? {
        if Int.random(in: 0..<10) < 3 {
            return nil
        }
        return Int.random(in: 1...120)
    }
    
    /// Property 11: displayTextWithDirection contains station short name
    /// **Validates: Requirements 9.2, 9.6**
    /// **Feature: orange-line-tracker, Property 11**
    @Test("Property 11: displayTextWithDirection contains station - 100 iterations")
    func displayTextWithDirectionContainsStation() {
        for iteration in 1...100 {
            let station = randomStation()
            let minutes = randomMinutesUntilArrival()
            let direction = randomDirection()
            
            let data = ComplicationData(
                stationShortName: station.shortName,
                minutesUntilArrival: minutes,
                direction: direction,
                lastUpdated: Date()
            )
            
            #expect(
                data.displayTextWithDirection.contains(station.shortName),
                "Iteration \(iteration): displayTextWithDirection '\(data.displayTextWithDirection)' should contain station '\(station.shortName)'"
            )
        }
    }
    
    /// Property 11: displayTextWithDirection contains arrival time
    /// **Validates: Requirements 9.2, 9.6**
    /// **Feature: orange-line-tracker, Property 11**
    @Test("Property 11: displayTextWithDirection contains arrival time - 100 iterations")
    func displayTextWithDirectionContainsArrivalTime() {
        for iteration in 1...100 {
            let station = randomStation()
            let minutes = randomMinutesUntilArrival()
            let direction = randomDirection()
            
            let data = ComplicationData(
                stationShortName: station.shortName,
                minutesUntilArrival: minutes,
                direction: direction,
                lastUpdated: Date()
            )
            
            let containsArrivalInfo: Bool
            if let mins = minutes, mins > 0 {
                containsArrivalInfo = data.displayTextWithDirection.contains("\(mins)m")
            } else {
                containsArrivalInfo = data.displayTextWithDirection.contains("ARR")
            }
            
            #expect(
                containsArrivalInfo,
                "Iteration \(iteration): displayTextWithDirection '\(data.displayTextWithDirection)' should contain arrival time"
            )
        }
    }
}

// MARK: - Property 12: Complication 错误状态显示测试

/// Property-based tests for Complication error state display
/// **Feature: orange-line-tracker, Property 12: Complication 错误状态显示**
/// **Validates: Requirement 9.7**
///
/// Property 12: 对于任意数据获取失败的情况，Complication 应该显示 "--" 或错误指示符，
/// 而不是崩溃或显示过期数据而不标识。
struct ComplicationErrorStateDisplayPropertyTests {
    
    // MARK: - Test Data Generators
    
    /// Generates a random station from the Orange Line stations
    private func randomStation() -> Station {
        OrangeLineStations.stations.randomElement()!
    }
    
    /// Generates a random direction
    private func randomDirection() -> Direction {
        Direction.allCases.randomElement()!
    }
    
    /// Generates a random valid minutes until arrival (1-120)
    private func randomMinutesUntilArrival() -> Int {
        Int.random(in: 1...120)
    }
    
    /// Generates a random stale timestamp (older than 5 minutes)
    private func randomStaleTimestamp() -> Date {
        // Generate timestamp between 5 and 60 minutes ago
        let minutesAgo = Int.random(in: 6...60)
        return Date().addingTimeInterval(-Double(minutesAgo * 60))
    }
    
    /// Generates a random fresh timestamp (within 5 minutes)
    private func randomFreshTimestamp() -> Date {
        // Generate timestamp between 0 and 4 minutes ago
        let minutesAgo = Int.random(in: 0...4)
        return Date().addingTimeInterval(-Double(minutesAgo * 60))
    }
    
    /// Generates a random error type for testing
    private func randomError() -> Error {
        let errors: [Error] = [
            NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]),
            NSError(domain: "NetworkError", code: -1001, userInfo: [NSLocalizedDescriptionKey: "The request timed out."]),
            NSError(domain: "APIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Internal Server Error"]),
            NSError(domain: "APIError", code: 503, userInfo: [NSLocalizedDescriptionKey: "Service Unavailable"]),
            NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        ]
        return errors.randomElement()!
    }
    
    // MARK: - Property 12 Tests: Error State Display
    
    /// Property 12: Error state (station name is "--" or empty) should display "--"
    /// **Validates: Requirement 9.7**
    /// **Feature: orange-line-tracker, Property 12**
    @Test("Property 12: Error state displays '--' - 100 iterations")
    func errorStateDisplaysDash() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            // Create error state data
            let errorData = ComplicationData.errorState()
            
            // Property: Error state displayText must be "--"
            #expect(
                errorData.displayText == "--",
                "Iteration \(iteration): Error state displayText should be '--', got '\(errorData.displayText)'"
            )
            
            // Property: Error state isErrorState must be true
            #expect(
                errorData.isErrorState == true,
                "Iteration \(iteration): Error state isErrorState should be true"
            )
            
            // Property: Error state should not crash when accessing display properties
            _ = errorData.fullDisplayText
            _ = errorData.displayTextWithDirection
            _ = errorData.detailedDisplayText
            _ = errorData.displayTextWithStaleIndicator()
            _ = errorData.fullDisplayTextWithStaleIndicator()
        }
    }
    
    /// Property 12: Empty station name should be treated as error state and display "--"
    /// **Validates: Requirement 9.7**
    /// **Feature: orange-line-tracker, Property 12**
    @Test("Property 12: Empty station name displays '--' - 100 iterations")
    func emptyStationNameDisplaysDash() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            let minutes = randomMinutesUntilArrival()
            let direction = randomDirection()
            
            // Create data with empty station name
            let data = ComplicationData(
                stationShortName: "",
                minutesUntilArrival: minutes,
                direction: direction,
                lastUpdated: Date()
            )
            
            // Property: Empty station name should be treated as error state
            #expect(
                data.isErrorState == true,
                "Iteration \(iteration): Empty station name should be error state"
            )
            
            // Property: displayText should be "--" for error state
            #expect(
                data.displayText == "--",
                "Iteration \(iteration): Empty station name displayText should be '--', got '\(data.displayText)'"
            )
        }
    }
    
    /// Property 12: Stale data (older than 5 minutes) should show stale indicator "⚠"
    /// **Validates: Requirement 9.7**
    /// **Feature: orange-line-tracker, Property 12**
    @Test("Property 12: Stale data shows stale indicator - 100 iterations")
    func staleDataShowsStaleIndicator() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            let station = randomStation()
            let minutes = randomMinutesUntilArrival()
            let direction = randomDirection()
            let staleTimestamp = randomStaleTimestamp()
            
            // Create stale data
            let staleData = ComplicationData(
                stationShortName: station.shortName,
                minutesUntilArrival: minutes,
                direction: direction,
                lastUpdated: staleTimestamp
            )
            
            // Property: Stale data should be identified as stale
            #expect(
                staleData.isStale() == true,
                "Iteration \(iteration): Data with timestamp \(staleTimestamp) should be stale"
            )
            
            // Property: Stale data displayTextWithStaleIndicator should contain "⚠"
            let displayWithIndicator = staleData.displayTextWithStaleIndicator()
            #expect(
                displayWithIndicator.contains("⚠"),
                "Iteration \(iteration): Stale data displayTextWithStaleIndicator '\(displayWithIndicator)' should contain '⚠'"
            )
            
            // Property: Stale data fullDisplayTextWithStaleIndicator should contain "⚠"
            let fullDisplayWithIndicator = staleData.fullDisplayTextWithStaleIndicator()
            #expect(
                fullDisplayWithIndicator.contains("⚠"),
                "Iteration \(iteration): Stale data fullDisplayTextWithStaleIndicator '\(fullDisplayWithIndicator)' should contain '⚠'"
            )
        }
    }
    
    /// Property 12: Fresh data should NOT show stale indicator
    /// **Validates: Requirement 9.7**
    /// **Feature: orange-line-tracker, Property 12**
    @Test("Property 12: Fresh data does not show stale indicator - 100 iterations")
    func freshDataDoesNotShowStaleIndicator() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            let station = randomStation()
            let minutes = randomMinutesUntilArrival()
            let direction = randomDirection()
            let freshTimestamp = randomFreshTimestamp()
            
            // Create fresh data
            let freshData = ComplicationData(
                stationShortName: station.shortName,
                minutesUntilArrival: minutes,
                direction: direction,
                lastUpdated: freshTimestamp
            )
            
            // Property: Fresh data should NOT be identified as stale
            #expect(
                freshData.isStale() == false,
                "Iteration \(iteration): Data with timestamp \(freshTimestamp) should not be stale"
            )
            
            // Property: Fresh data displayTextWithStaleIndicator should NOT contain "⚠"
            let displayWithIndicator = freshData.displayTextWithStaleIndicator()
            #expect(
                !displayWithIndicator.contains("⚠"),
                "Iteration \(iteration): Fresh data displayTextWithStaleIndicator '\(displayWithIndicator)' should not contain '⚠'"
            )
        }
    }
    
    /// Property 12: Network error with cached data should show stale indicator
    /// **Validates: Requirement 9.7**
    /// **Feature: orange-line-tracker, Property 12**
    @Test("Property 12: Network error with cached data shows stale indicator - 100 iterations")
    func networkErrorWithCachedDataShowsStaleIndicator() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            let station = randomStation()
            let minutes = randomMinutesUntilArrival()
            let direction = randomDirection()
            let staleTimestamp = randomStaleTimestamp()
            let error = randomError()
            
            // Create cached data that is now stale
            let cachedData = ComplicationData(
                stationShortName: station.shortName,
                minutesUntilArrival: minutes,
                direction: direction,
                lastUpdated: staleTimestamp
            )
            
            // Simulate network error with cached data
            let controller = ComplicationController()
            let resultData = controller.createNetworkErrorComplicationData(
                cachedData: cachedData,
                error: error
            )
            
            // Property: Result should be the cached data (not error state)
            #expect(
                resultData.stationShortName == station.shortName,
                "Iteration \(iteration): Network error with cache should return cached station '\(station.shortName)', got '\(resultData.stationShortName)'"
            )
            
            // Property: Cached data should be stale and show indicator
            #expect(
                resultData.isStale() == true,
                "Iteration \(iteration): Cached data should be stale after network error"
            )
            
            // Property: Display should show stale indicator
            let displayWithIndicator = resultData.displayTextWithStaleIndicator()
            #expect(
                displayWithIndicator.contains("⚠"),
                "Iteration \(iteration): Network error cached data should show stale indicator, got '\(displayWithIndicator)'"
            )
        }
    }
    
    /// Property 12: Network error without cached data should show "--"
    /// **Validates: Requirement 9.7**
    /// **Feature: orange-line-tracker, Property 12**
    @Test("Property 12: Network error without cached data shows '--' - 100 iterations")
    func networkErrorWithoutCachedDataShowsDash() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            let error = randomError()
            
            // Simulate network error without cached data
            let controller = ComplicationController()
            let resultData = controller.createNetworkErrorComplicationData(
                cachedData: nil,
                error: error
            )
            
            // Property: Result should be error state
            #expect(
                resultData.isErrorState == true,
                "Iteration \(iteration): Network error without cache should return error state"
            )
            
            // Property: displayText should be "--"
            #expect(
                resultData.displayText == "--",
                "Iteration \(iteration): Network error without cache displayText should be '--', got '\(resultData.displayText)'"
            )
            
            // Property: stationShortName should be "--"
            #expect(
                resultData.stationShortName == "--",
                "Iteration \(iteration): Network error without cache stationShortName should be '--', got '\(resultData.stationShortName)'"
            )
        }
    }
    
    /// Property 12: Error state should never crash when accessing any display property
    /// **Validates: Requirement 9.7**
    /// **Feature: orange-line-tracker, Property 12**
    @Test("Property 12: Error state never crashes on display access - 100 iterations")
    func errorStateNeverCrashesOnDisplayAccess() {
        // Run 100 iterations with various error states
        for iteration in 1...100 {
            let direction = randomDirection()
            
            // Test various error state configurations
            let errorStates: [ComplicationData] = [
                ComplicationData.errorState(),
                ComplicationData.errorState(stationShortName: "--"),
                ComplicationData.errorState(direction: direction),
                ComplicationData(stationShortName: "", minutesUntilArrival: nil, direction: direction),
                ComplicationData(stationShortName: "--", minutesUntilArrival: nil, direction: direction),
                ComplicationData(stationShortName: "--", minutesUntilArrival: 5, direction: direction)
            ]
            
            for (index, errorData) in errorStates.enumerated() {
                // Property: All display properties should be accessible without crashing
                let displayText = errorData.displayText
                let fullDisplayText = errorData.fullDisplayText
                let displayWithDirection = errorData.displayTextWithDirection
                let detailedDisplayText = errorData.detailedDisplayText
                let displayWithStale = errorData.displayTextWithStaleIndicator()
                let fullDisplayWithStale = errorData.fullDisplayTextWithStaleIndicator()
                let detailedWithStale = errorData.detailedDisplayTextWithStaleIndicator()
                let displayWithDirectionAndStale = errorData.displayTextWithDirectionAndStaleIndicator()
                
                // Property: Display text should not be empty
                #expect(
                    !displayText.isEmpty,
                    "Iteration \(iteration), case \(index): displayText should not be empty"
                )
                
                // Property: Full display text should not be empty
                #expect(
                    !fullDisplayText.isEmpty,
                    "Iteration \(iteration), case \(index): fullDisplayText should not be empty"
                )
                
                // Property: Error state should show "--" in display
                if errorData.isErrorState {
                    #expect(
                        displayText == "--",
                        "Iteration \(iteration), case \(index): Error state displayText should be '--', got '\(displayText)'"
                    )
                }
            }
        }
    }
    
    /// Property 12: All Orange Line stations with error conditions produce valid error display
    /// **Validates: Requirement 9.7**
    /// **Feature: orange-line-tracker, Property 12**
    @Test("Property 12: All stations handle error conditions correctly")
    func allStationsHandleErrorConditionsCorrectly() {
        // Test all 29 stations with error conditions
        for station in OrangeLineStations.stations {
            for direction in Direction.allCases {
                // Test 1: Error state for this station
                let errorData = ComplicationData.errorState(
                    stationShortName: "--",
                    direction: direction
                )
                
                #expect(
                    errorData.isErrorState == true,
                    "Station '\(station.name)': Error state should be identified"
                )
                
                #expect(
                    errorData.displayText == "--",
                    "Station '\(station.name)': Error state displayText should be '--'"
                )
                
                // Test 2: Stale data for this station
                let staleData = ComplicationData(
                    stationShortName: station.shortName,
                    minutesUntilArrival: 5,
                    direction: direction,
                    lastUpdated: Date().addingTimeInterval(-10 * 60) // 10 minutes ago
                )
                
                #expect(
                    staleData.isStale() == true,
                    "Station '\(station.name)': Stale data should be identified"
                )
                
                let staleDisplay = staleData.displayTextWithStaleIndicator()
                #expect(
                    staleDisplay.contains("⚠"),
                    "Station '\(station.name)': Stale data should show indicator, got '\(staleDisplay)'"
                )
            }
        }
    }
    
    /// Property 12: Various stale ages produce correct stale indicator behavior
    /// **Validates: Requirement 9.7**
    /// **Feature: orange-line-tracker, Property 12**
    @Test("Property 12: Various stale ages produce correct behavior - 100 iterations")
    func variousStaleAgesProduceCorrectBehavior() {
        // Test specific age thresholds and random values
        // Note: isStale() uses > (greater than), so exactly 5 minutes is NOT stale
        // We avoid testing exact boundary (5 minutes) due to timing precision issues
        let testAgesInMinutes: [Int] = [
            0,    // Just now - fresh
            1,    // 1 minute ago - fresh
            2,    // 2 minutes ago - fresh
            3,    // 3 minutes ago - fresh
            4,    // 4 minutes ago - fresh
            // Skip 5 minutes - boundary condition with timing precision issues
            6,    // 6 minutes ago - stale
            10,   // 10 minutes ago - stale
            15,   // 15 minutes ago - stale
            30,   // 30 minutes ago - stale
            60    // 1 hour ago - stale
        ]
        
        for ageInMinutes in testAgesInMinutes {
            for _ in 1...10 {
                let station = randomStation()
                let minutes = randomMinutesUntilArrival()
                let direction = randomDirection()
                // Add a small buffer to avoid timing precision issues
                let timestamp = Date().addingTimeInterval(-Double(ageInMinutes * 60) - 0.5)
                
                let data = ComplicationData(
                    stationShortName: station.shortName,
                    minutesUntilArrival: minutes,
                    direction: direction,
                    lastUpdated: timestamp
                )
                
                // Default stale threshold is 5 minutes (300 seconds)
                // isStale() returns true when age > 5 minutes
                let expectedStale = ageInMinutes >= 6  // 6+ minutes is definitely stale
                
                #expect(
                    data.isStale() == expectedStale,
                    "Age \(ageInMinutes)m: isStale() should be \(expectedStale), got \(data.isStale())"
                )
                
                let displayWithIndicator = data.displayTextWithStaleIndicator()
                if expectedStale {
                    #expect(
                        displayWithIndicator.contains("⚠"),
                        "Age \(ageInMinutes)m: Stale data should show indicator, got '\(displayWithIndicator)'"
                    )
                } else {
                    #expect(
                        !displayWithIndicator.contains("⚠"),
                        "Age \(ageInMinutes)m: Fresh data should not show indicator, got '\(displayWithIndicator)'"
                    )
                }
            }
        }
    }
    
    /// Property 12: Custom stale threshold works correctly
    /// **Validates: Requirement 9.7**
    /// **Feature: orange-line-tracker, Property 12**
    @Test("Property 12: Custom stale threshold works correctly - 100 iterations")
    func customStaleThresholdWorksCorrectly() {
        // Run 100 iterations with random data
        for iteration in 1...100 {
            let station = randomStation()
            let minutes = randomMinutesUntilArrival()
            let direction = randomDirection()
            
            // Create data that is 3 minutes old
            let timestamp = Date().addingTimeInterval(-3 * 60)
            let data = ComplicationData(
                stationShortName: station.shortName,
                minutesUntilArrival: minutes,
                direction: direction,
                lastUpdated: timestamp
            )
            
            // With default 5 minute threshold, should NOT be stale
            #expect(
                data.isStale() == false,
                "Iteration \(iteration): 3-minute-old data should not be stale with default threshold"
            )
            
            // With 2 minute threshold, should BE stale
            #expect(
                data.isStale(maxAge: 2 * 60) == true,
                "Iteration \(iteration): 3-minute-old data should be stale with 2-minute threshold"
            )
            
            // Display with custom threshold should show indicator
            let displayWithCustomThreshold = data.displayTextWithStaleIndicator(maxAge: 2 * 60)
            #expect(
                displayWithCustomThreshold.contains("⚠"),
                "Iteration \(iteration): Custom threshold stale data should show indicator, got '\(displayWithCustomThreshold)'"
            )
        }
    }
}
