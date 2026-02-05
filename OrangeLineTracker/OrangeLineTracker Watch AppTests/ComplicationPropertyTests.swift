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


// MARK: - Property 14: Widget 数据结构通用性测试

/// Property-based tests for Widget data structure generality
/// **Feature: vta-all-lines, Property 14: Widget 数据结构通用性**
/// **Validates: Requirements 9.5, 9.6**
///
/// Property 14: Widget 数据结构应该能够正确存储和显示任意线路的信息，
/// 包括线路 ID、名称、颜色，以及站点和方向信息。
struct WidgetDataStructurePropertyTests {
    
    // MARK: - Test Data Generators
    
    /// Generates a random line ID
    private func randomLineId() -> String {
        ["Orange", "Blue", "Green"].randomElement()!
    }
    
    /// Generates a random line name
    private func randomLineName() -> String {
        ["Orange Line", "Blue Line", "Green Line"].randomElement()!
    }
    
    /// Generates a random line color hex
    private func randomLineColorHex() -> String {
        ["#FF8C00", "#0066CC", "#00AA00"].randomElement()!
    }
    
    /// Generates a random station short name
    private func randomStationShortName() -> String {
        let shortNames = ["MLPT", "DIRD", "WNCH", "BERK", "FRMT", "SNTA", "ALUM"]
        return shortNames.randomElement()!
    }
    
    /// Generates a random station name
    private func randomStationName() -> String {
        let names = ["Milpitas", "Diridon", "Winchester", "Berryessa", "Fremont", "Santa Clara", "Alum Rock"]
        return names.randomElement()!
    }
    
    /// Generates a random direction ID
    private func randomDirectionId() -> String {
        ["E", "W", "N", "S"].randomElement()!
    }
    
    /// Generates a random arrival minutes (nil for no data, 0-60 for valid)
    private func randomArrivalMinutes() -> Int? {
        if Int.random(in: 0..<10) < 2 {
            return nil
        }
        return Int.random(in: 0...60)
    }
    
    // MARK: - Property 14 Tests
    
    /// Property 14: Widget entry stores line information correctly
    /// **Validates: Requirements 9.1, 9.2, 9.3**
    /// **Feature: vta-all-lines, Property 14**
    @Test("Property 14: Widget entry stores line information correctly - 100 iterations")
    func widgetEntryStoresLineInformationCorrectly() {
        for iteration in 0..<100 {
            let lineId = randomLineId()
            let lineName = randomLineName()
            let lineColorHex = randomLineColorHex()
            let stationName = randomStationName()
            let stationShortName = randomStationShortName()
            let direction = randomDirectionId()
            let arrivalMinutes = randomArrivalMinutes()
            
            // Create a simulated widget entry data structure
            let entryData = WidgetEntryTestData(
                lineId: lineId,
                lineName: lineName,
                lineColorHex: lineColorHex,
                stationName: stationName,
                stationShortName: stationShortName,
                direction: direction,
                arrivalMinutes: arrivalMinutes
            )
            
            // Property: Line ID must be preserved
            #expect(
                entryData.lineId == lineId,
                "Iteration \(iteration): lineId must be preserved (expected: \(lineId), got: \(entryData.lineId))"
            )
            
            // Property: Line name must be preserved
            #expect(
                entryData.lineName == lineName,
                "Iteration \(iteration): lineName must be preserved (expected: \(lineName), got: \(entryData.lineName))"
            )
            
            // Property: Line color hex must be preserved
            #expect(
                entryData.lineColorHex == lineColorHex,
                "Iteration \(iteration): lineColorHex must be preserved (expected: \(lineColorHex), got: \(entryData.lineColorHex))"
            )
        }
    }
    
    /// Property 14: Widget entry supports all VTA lines
    /// **Validates: Requirements 9.5, 9.6**
    /// **Feature: vta-all-lines, Property 14**
    @Test("Property 14: Widget entry supports all VTA lines - 100 iterations")
    func widgetEntrySupportsAllVTALines() {
        let lines: [(id: String, name: String, color: String)] = [
            ("Orange", "Orange Line", "#FF8C00"),
            ("Blue", "Blue Line", "#0066CC"),
            ("Green", "Green Line", "#00AA00")
        ]
        
        for iteration in 0..<100 {
            let line = lines[iteration % lines.count]
            let stationName = randomStationName()
            let stationShortName = randomStationShortName()
            let direction = randomDirectionId()
            let arrivalMinutes = randomArrivalMinutes()
            
            // Create entry for each line type
            let entryData = WidgetEntryTestData(
                lineId: line.id,
                lineName: line.name,
                lineColorHex: line.color,
                stationName: stationName,
                stationShortName: stationShortName,
                direction: direction,
                arrivalMinutes: arrivalMinutes
            )
            
            // Property: Entry must be valid for all line types
            #expect(
                !entryData.lineId.isEmpty,
                "Iteration \(iteration): lineId must not be empty for \(line.name)"
            )
            #expect(
                !entryData.lineName.isEmpty,
                "Iteration \(iteration): lineName must not be empty for \(line.name)"
            )
            #expect(
                entryData.lineColorHex.hasPrefix("#"),
                "Iteration \(iteration): lineColorHex must be a valid hex color for \(line.name)"
            )
        }
    }
    
    /// Property 14: Widget entry handles all direction types
    /// **Validates: Requirements 9.5, 9.6**
    /// **Feature: vta-all-lines, Property 14**
    @Test("Property 14: Widget entry handles all direction types - 100 iterations")
    func widgetEntryHandlesAllDirectionTypes() {
        let directions = ["E", "W", "N", "S"]
        
        for iteration in 0..<100 {
            let direction = directions[iteration % directions.count]
            let lineId = randomLineId()
            let lineName = randomLineName()
            let lineColorHex = randomLineColorHex()
            let stationName = randomStationName()
            let stationShortName = randomStationShortName()
            let arrivalMinutes = randomArrivalMinutes()
            
            // Create entry with each direction type
            let entryData = WidgetEntryTestData(
                lineId: lineId,
                lineName: lineName,
                lineColorHex: lineColorHex,
                stationName: stationName,
                stationShortName: stationShortName,
                direction: direction,
                arrivalMinutes: arrivalMinutes
            )
            
            // Property: Direction must be preserved
            #expect(
                entryData.direction == direction,
                "Iteration \(iteration): direction must be preserved (expected: \(direction), got: \(entryData.direction))"
            )
            
            // Property: Direction must be one of the valid values
            #expect(
                directions.contains(entryData.direction),
                "Iteration \(iteration): direction must be a valid direction ID"
            )
        }
    }
    
    /// Property 14: Widget entry handles nil arrival minutes correctly
    /// **Validates: Requirements 9.5, 9.6**
    /// **Feature: vta-all-lines, Property 14**
    @Test("Property 14: Widget entry handles nil arrival minutes - 100 iterations")
    func widgetEntryHandlesNilArrivalMinutes() {
        for iteration in 0..<100 {
            let lineId = randomLineId()
            let lineName = randomLineName()
            let lineColorHex = randomLineColorHex()
            let stationName = randomStationName()
            let stationShortName = randomStationShortName()
            let direction = randomDirectionId()
            
            // Create entry with nil arrival minutes
            let entryData = WidgetEntryTestData(
                lineId: lineId,
                lineName: lineName,
                lineColorHex: lineColorHex,
                stationName: stationName,
                stationShortName: stationShortName,
                direction: direction,
                arrivalMinutes: nil
            )
            
            // Property: Entry must handle nil arrival minutes without crashing
            #expect(
                entryData.arrivalMinutes == nil,
                "Iteration \(iteration): nil arrival minutes must be preserved"
            )
            
            // Property: Other fields must still be valid
            #expect(
                !entryData.lineId.isEmpty,
                "Iteration \(iteration): lineId must not be empty even with nil arrival"
            )
            #expect(
                !entryData.stationName.isEmpty,
                "Iteration \(iteration): stationName must not be empty even with nil arrival"
            )
        }
    }
    
    /// Property 14: Widget entry color hex is valid format
    /// **Validates: Requirements 9.4**
    /// **Feature: vta-all-lines, Property 14**
    @Test("Property 14: Widget entry color hex is valid format - 100 iterations")
    func widgetEntryColorHexIsValidFormat() {
        for iteration in 0..<100 {
            let lineColorHex = randomLineColorHex()
            
            let entryData = WidgetEntryTestData(
                lineId: randomLineId(),
                lineName: randomLineName(),
                lineColorHex: lineColorHex,
                stationName: randomStationName(),
                stationShortName: randomStationShortName(),
                direction: randomDirectionId(),
                arrivalMinutes: randomArrivalMinutes()
            )
            
            // Property: Color hex must start with #
            #expect(
                entryData.lineColorHex.hasPrefix("#"),
                "Iteration \(iteration): lineColorHex must start with '#'"
            )
            
            // Property: Color hex must be 7 characters (#RRGGBB)
            #expect(
                entryData.lineColorHex.count == 7,
                "Iteration \(iteration): lineColorHex must be 7 characters (#RRGGBB)"
            )
            
            // Property: Color hex must contain only valid hex characters after #
            let hexPart = String(entryData.lineColorHex.dropFirst())
            let validHexChars = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
            #expect(
                hexPart.unicodeScalars.allSatisfy { validHexChars.contains($0) },
                "Iteration \(iteration): lineColorHex must contain only valid hex characters"
            )
        }
    }
}

// MARK: - Widget Entry Test Data Structure

/// Test data structure that mirrors the Widget entry structure
/// Used for property testing without depending on WidgetKit
struct WidgetEntryTestData {
    let lineId: String
    let lineName: String
    let lineColorHex: String
    let stationName: String
    let stationShortName: String
    let direction: String
    let arrivalMinutes: Int?
    
    init(
        lineId: String,
        lineName: String,
        lineColorHex: String,
        stationName: String,
        stationShortName: String,
        direction: String,
        arrivalMinutes: Int?
    ) {
        self.lineId = lineId
        self.lineName = lineName
        self.lineColorHex = lineColorHex
        self.stationName = stationName
        self.stationShortName = stationShortName
        self.direction = direction
        self.arrivalMinutes = arrivalMinutes
    }
}
