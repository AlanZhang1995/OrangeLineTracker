//
//  TimeRulePropertyTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Property tests for TimeRule multi-line support
//  - Validates: Requirements 8.1, 8.3, 8.4
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Property 12: TimeRule Line Field Completeness

/// Property-based tests for TimeRule line field completeness
/// **Feature: vta-all-lines, Property 12: TimeRule line field completeness**
///
/// *For any* TimeRule instance, it must contain a valid lineId field, and this field
/// must remain unchanged after serialization/deserialization.
/// **Validates: Requirements 8.1, 8.4**
@MainActor
struct TimeRuleLineFieldPropertyTests {
    
    // MARK: - Random Data Generators
    
    /// Generates a random line ID
    private func randomLineId() -> String {
        ["Orange", "Blue", "Green"].randomElement()!
    }
    
    /// Generates a random direction ID based on line
    private func randomDirectionId(for lineId: String) -> String {
        switch lineId {
        case "Orange":
            return ["E", "W"].randomElement()!
        case "Blue", "Green":
            return ["N", "S"].randomElement()!
        default:
            return "E"
        }
    }
    
    /// Generates a random station ID for a line
    private func randomStationId(for lineId: String) -> String {
        switch lineId {
        case "Orange":
            return OrangeLineStations.stations.randomElement()?.id ?? "70261"
        case "Blue":
            return BlueLineStations.stations.randomElement()?.id ?? "64791"
        case "Green":
            return GreenLineStations.stations.randomElement()?.id ?? "64001"
        default:
            return "70261"
        }
    }
    
    /// Generates a random hour (0-23)
    private func randomHour() -> Int {
        Int.random(in: 0...23)
    }
    
    /// Generates a random minute (0-59)
    private func randomMinute() -> Int {
        Int.random(in: 0...59)
    }
    
    /// Generates a random rule name
    private func randomRuleName() -> String {
        let names = ["Morning", "Evening", "Lunch", "Night", "Custom", "Work", "Home"]
        return "\(names.randomElement()!) Rule \(Int.random(in: 1...100))"
    }
    
    // MARK: - Property Tests
    
    /// **Feature: vta-all-lines, Property 12: TimeRule always has valid lineId**
    ///
    /// Property: For any TimeRule instance created with the new initializer,
    /// the lineId field must be a non-empty string.
    @Test("Property 12: TimeRule always has valid lineId - 100 iterations")
    func timeRuleAlwaysHasValidLineId() {
        // **Validates: Requirements 8.1, 8.4**
        
        for iteration in 0..<100 {
            let lineId = randomLineId()
            let directionId = randomDirectionId(for: lineId)
            let stationId = randomStationId(for: lineId)
            
            let rule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: randomHour(), minute: randomMinute()),
                lineId: lineId,
                stationId: stationId,
                directionId: directionId,
                isEnabled: Bool.random()
            )
            
            // Property assertion: lineId must be non-empty
            #expect(
                !rule.lineId.isEmpty,
                "Iteration \(iteration): TimeRule lineId must be non-empty"
            )
            
            // Property assertion: lineId must be one of the valid values
            #expect(
                ["Orange", "Blue", "Green"].contains(rule.lineId),
                "Iteration \(iteration): TimeRule lineId must be a valid line ID"
            )
        }
    }
    
    /// **Feature: vta-all-lines, Property 12: TimeRule lineId survives Codable roundtrip**
    ///
    /// Property: For any TimeRule instance, encoding to JSON and decoding back
    /// must preserve the lineId field exactly.
    @Test("Property 12: TimeRule lineId survives Codable roundtrip - 100 iterations")
    func timeRuleLineIdSurvivesCodableRoundtrip() throws {
        // **Validates: Requirements 8.1, 8.4**
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for iteration in 0..<100 {
            let lineId = randomLineId()
            let directionId = randomDirectionId(for: lineId)
            let stationId = randomStationId(for: lineId)
            
            let originalRule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: randomHour(), minute: randomMinute()),
                lineId: lineId,
                stationId: stationId,
                directionId: directionId,
                isEnabled: Bool.random()
            )
            
            // Encode to JSON
            let data = try encoder.encode(originalRule)
            
            // Decode back
            let decodedRule = try decoder.decode(TimeRule.self, from: data)
            
            // Property assertion: lineId must be preserved
            #expect(
                decodedRule.lineId == originalRule.lineId,
                "Iteration \(iteration): lineId must survive roundtrip (original: \(originalRule.lineId), decoded: \(decodedRule.lineId))"
            )
        }
    }
    
    /// **Feature: vta-all-lines, Property 12: TimeRule directionId survives Codable roundtrip**
    ///
    /// Property: For any TimeRule instance, encoding to JSON and decoding back
    /// must preserve the directionId field exactly.
    @Test("Property 12: TimeRule directionId survives Codable roundtrip - 100 iterations")
    func timeRuleDirectionIdSurvivesCodableRoundtrip() throws {
        // **Validates: Requirements 8.1, 8.4**
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for iteration in 0..<100 {
            let lineId = randomLineId()
            let directionId = randomDirectionId(for: lineId)
            let stationId = randomStationId(for: lineId)
            
            let originalRule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: randomHour(), minute: randomMinute()),
                lineId: lineId,
                stationId: stationId,
                directionId: directionId,
                isEnabled: Bool.random()
            )
            
            // Encode to JSON
            let data = try encoder.encode(originalRule)
            
            // Decode back
            let decodedRule = try decoder.decode(TimeRule.self, from: data)
            
            // Property assertion: directionId must be preserved
            #expect(
                decodedRule.directionId == originalRule.directionId,
                "Iteration \(iteration): directionId must survive roundtrip (original: \(originalRule.directionId), decoded: \(decodedRule.directionId))"
            )
        }
    }
    
    /// **Feature: vta-all-lines, Property 12: TimeRule all fields survive Codable roundtrip**
    ///
    /// Property: For any TimeRule instance, all fields must be preserved after
    /// encoding to JSON and decoding back.
    @Test("Property 12: TimeRule all fields survive Codable roundtrip - 100 iterations")
    func timeRuleAllFieldsSurviveCodableRoundtrip() throws {
        // **Validates: Requirements 8.1, 8.4**
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for iteration in 0..<100 {
            let lineId = randomLineId()
            let directionId = randomDirectionId(for: lineId)
            let stationId = randomStationId(for: lineId)
            let name = randomRuleName()
            let hour = randomHour()
            let minute = randomMinute()
            let isEnabled = Bool.random()
            
            let originalRule = TimeRule(
                name: name,
                triggerTime: TimeRule.createTriggerTime(hour: hour, minute: minute),
                lineId: lineId,
                stationId: stationId,
                directionId: directionId,
                isEnabled: isEnabled
            )
            
            // Encode to JSON
            let data = try encoder.encode(originalRule)
            
            // Decode back
            let decodedRule = try decoder.decode(TimeRule.self, from: data)
            
            // Property assertions: all fields must be preserved
            #expect(decodedRule.id == originalRule.id, "Iteration \(iteration): id must be preserved")
            #expect(decodedRule.name == originalRule.name, "Iteration \(iteration): name must be preserved")
            #expect(decodedRule.lineId == originalRule.lineId, "Iteration \(iteration): lineId must be preserved")
            #expect(decodedRule.stationId == originalRule.stationId, "Iteration \(iteration): stationId must be preserved")
            #expect(decodedRule.directionId == originalRule.directionId, "Iteration \(iteration): directionId must be preserved")
            #expect(decodedRule.isEnabled == originalRule.isEnabled, "Iteration \(iteration): isEnabled must be preserved")
            #expect(decodedRule.triggerHour == originalRule.triggerHour, "Iteration \(iteration): triggerHour must be preserved")
            #expect(decodedRule.triggerMinute == originalRule.triggerMinute, "Iteration \(iteration): triggerMinute must be preserved")
        }
    }
}

// MARK: - Property 12: TimeRule Migration Tests

/// Property-based tests for TimeRule migration from old format
/// **Feature: vta-all-lines, Property 12: TimeRule migration from old format**
///
/// *For any* old format TimeRule (with Direction enum), migration must correctly
/// set lineId to "Orange" and convert direction to directionId.
/// **Validates: Requirements 8.1, 8.4**
@MainActor
struct TimeRuleMigrationPropertyTests {
    
    // MARK: - Random Data Generators
    
    private func randomHour() -> Int {
        Int.random(in: 0...23)
    }
    
    private func randomMinute() -> Int {
        Int.random(in: 0...59)
    }
    
    private func randomStationId() -> String {
        OrangeLineStations.stations.randomElement()?.id ?? "70261"
    }
    
    private func randomDirection() -> Direction {
        Direction.allCases.randomElement()!
    }
    
    private func randomRuleName() -> String {
        let names = ["Morning", "Evening", "Lunch", "Night", "Custom"]
        return "\(names.randomElement()!) Rule \(Int.random(in: 1...100))"
    }
    
    // MARK: - Property Tests
    
    /// **Feature: vta-all-lines, Property 12: Backward compatible initializer sets lineId to Orange**
    ///
    /// Property: When using the backward-compatible initializer with Direction enum,
    /// the lineId must be set to "Orange".
    @Test("Property 12: Backward compatible initializer sets lineId to Orange - 100 iterations")
    func backwardCompatibleInitializerSetsLineIdToOrange() {
        // **Validates: Requirements 8.1, 8.4**
        
        for iteration in 0..<100 {
            let direction = randomDirection()
            
            // Use backward-compatible initializer
            let rule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: randomHour(), minute: randomMinute()),
                stationId: randomStationId(),
                direction: direction,
                isEnabled: Bool.random()
            )
            
            // Property assertion: lineId must be "Orange"
            #expect(
                rule.lineId == "Orange",
                "Iteration \(iteration): Backward compatible initializer must set lineId to 'Orange'"
            )
            
            // Property assertion: directionId must match the direction
            #expect(
                rule.directionId == direction.directionId,
                "Iteration \(iteration): directionId must match the Direction enum value"
            )
        }
    }
    
    /// **Feature: vta-all-lines, Property 12: Direction computed property returns correct value**
    ///
    /// Property: The computed `direction` property must correctly convert directionId
    /// back to the Direction enum for Orange Line directions.
    @Test("Property 12: Direction computed property returns correct value - 100 iterations")
    func directionComputedPropertyReturnsCorrectValue() {
        // **Validates: Requirements 8.1, 8.4**
        
        for iteration in 0..<100 {
            let originalDirection = randomDirection()
            
            // Create rule with backward-compatible initializer
            let rule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: randomHour(), minute: randomMinute()),
                stationId: randomStationId(),
                direction: originalDirection,
                isEnabled: Bool.random()
            )
            
            // Property assertion: direction computed property must return the original direction
            #expect(
                rule.direction == originalDirection,
                "Iteration \(iteration): direction computed property must return original direction"
            )
        }
    }
    
    /// **Feature: vta-all-lines, Property 12: Migration from old JSON format**
    ///
    /// Property: When decoding JSON with old format (direction as Direction enum),
    /// the decoder must correctly migrate to new format with lineId and directionId.
    @Test("Property 12: Migration from old JSON format - 100 iterations")
    func migrationFromOldJsonFormat() throws {
        // **Validates: Requirements 8.1, 8.4**
        
        let decoder = JSONDecoder()
        
        for iteration in 0..<100 {
            let direction = randomDirection()
            let stationId = randomStationId()
            let name = randomRuleName()
            let hour = randomHour()
            let minute = randomMinute()
            let isEnabled = Bool.random()
            let id = UUID()
            
            // Create old format JSON (with direction instead of directionId, no lineId)
            let triggerTime = TimeRule.createTriggerTime(hour: hour, minute: minute)
            let triggerTimeData = try JSONEncoder().encode(triggerTime)
            let triggerTimeString = String(data: triggerTimeData, encoding: .utf8)!
            
            let oldFormatJson = """
            {
                "id": "\(id.uuidString)",
                "name": "\(name)",
                "triggerTime": \(triggerTimeString),
                "stationId": "\(stationId)",
                "direction": "\(direction.rawValue)",
                "isEnabled": \(isEnabled)
            }
            """
            
            let data = oldFormatJson.data(using: .utf8)!
            
            // Decode using new decoder
            let decodedRule = try decoder.decode(TimeRule.self, from: data)
            
            // Property assertions: migration must work correctly
            #expect(
                decodedRule.lineId == "Orange",
                "Iteration \(iteration): lineId must default to 'Orange' for old format"
            )
            #expect(
                decodedRule.directionId == direction.directionId,
                "Iteration \(iteration): directionId must be converted from Direction enum"
            )
            #expect(
                decodedRule.name == name,
                "Iteration \(iteration): name must be preserved"
            )
            #expect(
                decodedRule.stationId == stationId,
                "Iteration \(iteration): stationId must be preserved"
            )
        }
    }
}

// MARK: - Property 13: Time Rule Trigger State Update

/// Property-based tests for time rule trigger state update
/// **Feature: vta-all-lines, Property 13: Time rule trigger state update**
///
/// *For any* enabled time rule, when the trigger condition is met, the system state
/// must update to the line, station, and direction specified by the rule.
/// **Validates: Requirement 8.3**
@MainActor
struct TimeRuleTriggerStatePropertyTests {
    
    // MARK: - Random Data Generators
    
    private func randomLineId() -> String {
        ["Orange", "Blue", "Green"].randomElement()!
    }
    
    private func randomDirectionId(for lineId: String) -> String {
        switch lineId {
        case "Orange":
            return ["E", "W"].randomElement()!
        case "Blue", "Green":
            return ["N", "S"].randomElement()!
        default:
            return "E"
        }
    }
    
    private func randomStationId(for lineId: String) -> String {
        switch lineId {
        case "Orange":
            return OrangeLineStations.stations.randomElement()?.id ?? "70261"
        case "Blue":
            return BlueLineStations.stations.randomElement()?.id ?? "64791"
        case "Green":
            return GreenLineStations.stations.randomElement()?.id ?? "64001"
        default:
            return "70261"
        }
    }
    
    private func randomHour() -> Int {
        Int.random(in: 0...23)
    }
    
    private func randomMinute() -> Int {
        Int.random(in: 0...59)
    }
    
    private func randomRuleName() -> String {
        let names = ["Morning", "Evening", "Lunch", "Night", "Custom"]
        return "\(names.randomElement()!) Rule \(Int.random(in: 1...100))"
    }
    
    private func createDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // MARK: - Property Tests
    
    /// **Feature: vta-all-lines, Property 13: Active rule contains correct line information**
    ///
    /// Property: When a time rule is active, the returned rule must contain
    /// the correct lineId, stationId, and directionId.
    @Test("Property 13: Active rule contains correct line information - 100 iterations")
    func activeRuleContainsCorrectLineInformation() {
        // **Validates: Requirement 8.3**
        
        for iteration in 0..<100 {
            let lineId = randomLineId()
            let directionId = randomDirectionId(for: lineId)
            let stationId = randomStationId(for: lineId)
            let hour = randomHour()
            let minute = randomMinute()
            
            let rule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: hour, minute: minute),
                lineId: lineId,
                stationId: stationId,
                directionId: directionId,
                isEnabled: true
            )
            
            // Set current time to be after the rule's trigger time
            let offsetMinutes = Int.random(in: 0...60)
            let totalMinutes = hour * 60 + minute + offsetMinutes
            let cappedMinutes = min(totalMinutes, 23 * 60 + 59)
            let currentHour = cappedMinutes / 60
            let currentMinute = cappedMinutes % 60
            let currentDate = createDate(hour: currentHour, minute: currentMinute)
            
            // Create service
            let mockStorage = MockStorageService()
            mockStorage.timeRules = [rule]
            mockStorage.isTimeRuleEnabled = true
            
            let service = TimeRuleService(
                storageService: mockStorage,
                dateProvider: { currentDate }
            )
            
            // Get active rule
            let activeRule = service.getCurrentActiveRule()
            
            // Property assertions
            #expect(activeRule != nil, "Iteration \(iteration): Active rule should not be nil")
            #expect(
                activeRule?.lineId == lineId,
                "Iteration \(iteration): Active rule lineId must match (expected: \(lineId), got: \(activeRule?.lineId ?? "nil"))"
            )
            #expect(
                activeRule?.stationId == stationId,
                "Iteration \(iteration): Active rule stationId must match"
            )
            #expect(
                activeRule?.directionId == directionId,
                "Iteration \(iteration): Active rule directionId must match"
            )
        }
    }
    
    /// **Feature: vta-all-lines, Property 13: Multi-line rules are correctly selected**
    ///
    /// Property: When multiple rules for different lines exist, the correct rule
    /// (most recent triggered) should be returned with its line information intact.
    @Test("Property 13: Multi-line rules are correctly selected - 100 iterations")
    func multiLineRulesAreCorrectlySelected() {
        // **Validates: Requirement 8.3**
        
        for iteration in 0..<100 {
            // Create rules for different lines at different times
            let orangeRule = TimeRule(
                name: "Orange Rule",
                triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
                lineId: "Orange",
                stationId: OrangeLineStations.stations.randomElement()?.id ?? "70261",
                directionId: "E",
                isEnabled: true
            )
            
            let blueRule = TimeRule(
                name: "Blue Rule",
                triggerTime: TimeRule.createTriggerTime(hour: 12, minute: 0),
                lineId: "Blue",
                stationId: BlueLineStations.stations.randomElement()?.id ?? "64791",
                directionId: "N",
                isEnabled: true
            )
            
            let greenRule = TimeRule(
                name: "Green Rule",
                triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 0),
                lineId: "Green",
                stationId: GreenLineStations.stations.randomElement()?.id ?? "64001",
                directionId: "S",
                isEnabled: true
            )
            
            // Test at different times
            let testCases: [(hour: Int, expectedLine: String)] = [
                (8, "Orange"),   // After orange, before blue
                (14, "Blue"),    // After blue, before green
                (20, "Green")    // After green
            ]
            
            let testCase = testCases[iteration % testCases.count]
            let currentDate = createDate(hour: testCase.hour, minute: 0)
            
            // Create service
            let mockStorage = MockStorageService()
            mockStorage.timeRules = [orangeRule, blueRule, greenRule]
            mockStorage.isTimeRuleEnabled = true
            
            let service = TimeRuleService(
                storageService: mockStorage,
                dateProvider: { currentDate }
            )
            
            // Get active rule
            let activeRule = service.getCurrentActiveRule()
            
            // Property assertion
            #expect(
                activeRule?.lineId == testCase.expectedLine,
                "Iteration \(iteration): At \(testCase.hour):00, expected \(testCase.expectedLine) line rule, got \(activeRule?.lineId ?? "nil")"
            )
        }
    }
    
    /// **Feature: vta-all-lines, Property 13: Rule station lookup works for all lines**
    ///
    /// Property: The `station` computed property must correctly find the station
    /// for any line (Orange, Blue, or Green).
    @Test("Property 13: Rule station lookup works for all lines - 100 iterations")
    func ruleStationLookupWorksForAllLines() {
        // **Validates: Requirement 8.3**
        
        for iteration in 0..<100 {
            let lineId = randomLineId()
            let stationId = randomStationId(for: lineId)
            let directionId = randomDirectionId(for: lineId)
            
            let rule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: randomHour(), minute: randomMinute()),
                lineId: lineId,
                stationId: stationId,
                directionId: directionId,
                isEnabled: true
            )
            
            // Property assertion: station lookup must work
            let station = rule.station
            #expect(
                station != nil,
                "Iteration \(iteration): Station lookup must succeed for line \(lineId), stationId \(stationId)"
            )
            #expect(
                station?.id == stationId,
                "Iteration \(iteration): Station ID must match"
            )
        }
    }
}

// Note: MockStorageService is defined in TimeRuleServiceTests.swift and shared across test files
