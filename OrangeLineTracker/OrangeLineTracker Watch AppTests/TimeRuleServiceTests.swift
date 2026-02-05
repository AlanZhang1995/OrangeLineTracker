//
//  TimeRuleServiceTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Unit tests for TimeRuleService
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Mock Storage Service

/// Mock implementation of StorageServiceProtocol for testing
class MockStorageService: StorageServiceProtocol {
    var selectedStation: Station?
    var selectedDirection: Direction?
    var timeRules: [TimeRule] = []
    var isTimeRuleEnabled: Bool = false
    var isSmartRefreshEnabled: Bool = true
    var cachedArrivalMinutes: Int?
    var lastUpdateTime: Date?
    
    // Line-related properties (VTA All Lines support)
    var selectedLineId: String?
    var favoriteLineIds: Set<String> = []
    var cachedLines: [Line]?
    
    var saveCallCount = 0
    var loadCallCount = 0
    var updateWidgetDataCallCount = 0
    
    func save() {
        saveCallCount += 1
    }
    
    func load() {
        loadCallCount += 1
    }
    
    func updateWidgetData(stationName: String, stationShortName: String, direction: String, arrivalMinutes: Int?, arrivalMinutes2: Int? = nil, arrivalMinutes3: Int? = nil, lineId: String? = nil, lineName: String? = nil, lineColor: String? = nil) {
        updateWidgetDataCallCount += 1
        cachedArrivalMinutes = arrivalMinutes
        lastUpdateTime = Date()
    }
    
    func migrateFromV1IfNeeded() {
        // Mock implementation - no-op for tests
    }
}

// MARK: - TimeRuleService Tests

struct TimeRuleServiceTests {
    
    // MARK: - Helper Methods
    
    /// Creates a TimeRuleService with a mock storage service and optional fixed date
    private func createService(
        rules: [TimeRule] = [],
        isTimeRuleEnabled: Bool = true,
        currentDate: Date = Date()
    ) -> (TimeRuleService, MockStorageService) {
        let mockStorage = MockStorageService()
        mockStorage.timeRules = rules
        mockStorage.isTimeRuleEnabled = isTimeRuleEnabled
        
        let service = TimeRuleService(
            storageService: mockStorage,
            dateProvider: { currentDate }
        )
        
        return (service, mockStorage)
    }
    
    /// Creates a date with specific hour and minute
    private func createDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// Creates a test TimeRule with specified parameters
    private func createRule(
        name: String = "Test Rule",
        hour: Int,
        minute: Int,
        stationId: String = "70261",
        direction: Direction = .alumRock,
        isEnabled: Bool = true
    ) -> TimeRule {
        return TimeRule(
            name: name,
            triggerTime: TimeRule.createTriggerTime(hour: hour, minute: minute),
            stationId: stationId,
            direction: direction,
            isEnabled: isEnabled
        )
    }
    
    // MARK: - getCurrentActiveRule Tests
    
    @Test func getCurrentActiveRuleReturnsNilWhenNoRules() {
        // Validates: Requirements 8.3
        let (service, _) = createService(rules: [], isTimeRuleEnabled: true)
        
        let activeRule = service.getCurrentActiveRule()
        
        #expect(activeRule == nil)
    }
    
    @Test func getCurrentActiveRuleReturnsNilWhenTimeRulesDisabled() {
        // Validates: Requirements 8.6, 8.7
        let rule = createRule(hour: 8, minute: 0)
        let currentDate = createDate(hour: 10, minute: 0)
        let (service, _) = createService(
            rules: [rule],
            isTimeRuleEnabled: false,
            currentDate: currentDate
        )
        
        let activeRule = service.getCurrentActiveRule()
        
        #expect(activeRule == nil)
    }
    
    @Test func getCurrentActiveRuleReturnsRuleWhenTimeMatches() {
        // Validates: Requirements 8.3
        let rule = createRule(name: "Morning", hour: 8, minute: 0)
        let currentDate = createDate(hour: 8, minute: 30)
        let (service, _) = createService(
            rules: [rule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let activeRule = service.getCurrentActiveRule()
        
        #expect(activeRule != nil)
        #expect(activeRule?.name == "Morning")
    }
    
    @Test func getCurrentActiveRuleReturnsNilBeforeRuleTriggerTime() {
        // Validates: Requirements 8.3
        let rule = createRule(hour: 10, minute: 0)
        let currentDate = createDate(hour: 8, minute: 0)
        let (service, _) = createService(
            rules: [rule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let activeRule = service.getCurrentActiveRule()
        
        #expect(activeRule == nil)
    }
    
    @Test func getCurrentActiveRuleReturnsLatestTriggeredRule() {
        // Validates: Requirements 8.3
        let morningRule = createRule(name: "Morning", hour: 8, minute: 0, direction: .alumRock)
        let eveningRule = createRule(name: "Evening", hour: 17, minute: 0, direction: .mountainView)
        let currentDate = createDate(hour: 18, minute: 0)
        
        let (service, _) = createService(
            rules: [morningRule, eveningRule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let activeRule = service.getCurrentActiveRule()
        
        #expect(activeRule != nil)
        #expect(activeRule?.name == "Evening")
        #expect(activeRule?.direction == .mountainView)
    }
    
    @Test func getCurrentActiveRuleIgnoresDisabledRules() {
        // Validates: Requirements 8.3
        let enabledRule = createRule(name: "Enabled", hour: 8, minute: 0, isEnabled: true)
        let disabledRule = createRule(name: "Disabled", hour: 10, minute: 0, isEnabled: false)
        let currentDate = createDate(hour: 12, minute: 0)
        
        let (service, _) = createService(
            rules: [enabledRule, disabledRule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let activeRule = service.getCurrentActiveRule()
        
        #expect(activeRule != nil)
        #expect(activeRule?.name == "Enabled")
    }
    
    // MARK: - shouldApplyRule Tests
    
    @Test func shouldApplyRuleReturnsNilWhenGloballyDisabled() {
        // Validates: Requirements 8.6, 8.7
        let rule = createRule(hour: 8, minute: 0)
        let testDate = createDate(hour: 10, minute: 0)
        let (service, _) = createService(
            rules: [rule],
            isTimeRuleEnabled: false,
            currentDate: testDate
        )
        
        let result = service.shouldApplyRule(at: testDate)
        
        #expect(result == nil)
    }
    
    @Test func shouldApplyRuleReturnsRuleWhenEnabled() {
        // Validates: Requirements 8.3
        let rule = createRule(name: "Test", hour: 8, minute: 0)
        let testDate = createDate(hour: 9, minute: 0)
        let (service, _) = createService(
            rules: [rule],
            isTimeRuleEnabled: true,
            currentDate: testDate
        )
        
        let result = service.shouldApplyRule(at: testDate)
        
        #expect(result != nil)
        #expect(result?.name == "Test")
    }
    
    @Test func shouldApplyRuleSelectsCorrectRuleBasedOnTime() {
        // Validates: Requirements 8.3
        let morningRule = createRule(name: "Morning", hour: 7, minute: 0, stationId: "70261")
        let noonRule = createRule(name: "Noon", hour: 12, minute: 0, stationId: "70381")
        let eveningRule = createRule(name: "Evening", hour: 18, minute: 0, stationId: "70541")
        
        let (service, _) = createService(
            rules: [morningRule, noonRule, eveningRule],
            isTimeRuleEnabled: true,
            currentDate: Date()
        )
        
        // Test at 8:00 - morning rule should be active
        let morningTime = createDate(hour: 8, minute: 0)
        let morningResult = service.shouldApplyRule(at: morningTime)
        #expect(morningResult?.name == "Morning")
        
        // Test at 14:00 - noon rule should be active
        let afternoonTime = createDate(hour: 14, minute: 0)
        let afternoonResult = service.shouldApplyRule(at: afternoonTime)
        #expect(afternoonResult?.name == "Noon")
        
        // Test at 20:00 - evening rule should be active
        let eveningTime = createDate(hour: 20, minute: 0)
        let eveningResult = service.shouldApplyRule(at: eveningTime)
        #expect(eveningResult?.name == "Evening")
    }
    
    // MARK: - addRule Tests
    
    @Test func addRuleAddsRuleToStorage() {
        // Validates: Requirements 8.4
        let (service, mockStorage) = createService(rules: [], isTimeRuleEnabled: true)
        let newRule = createRule(name: "New Rule", hour: 9, minute: 30)
        
        service.addRule(newRule)
        
        #expect(mockStorage.timeRules.count == 1)
        #expect(mockStorage.timeRules.first?.name == "New Rule")
    }
    
    @Test func addRuleSavesToStorage() {
        // Validates: Requirements 8.4
        let (service, mockStorage) = createService(rules: [], isTimeRuleEnabled: true)
        let newRule = createRule(name: "New Rule", hour: 9, minute: 30)
        
        service.addRule(newRule)
        
        #expect(mockStorage.saveCallCount == 1)
    }
    
    @Test func addRulePreservesExistingRules() {
        // Validates: Requirements 8.4
        let existingRule = createRule(name: "Existing", hour: 8, minute: 0)
        let (service, mockStorage) = createService(rules: [existingRule], isTimeRuleEnabled: true)
        let newRule = createRule(name: "New", hour: 17, minute: 0)
        
        service.addRule(newRule)
        
        #expect(mockStorage.timeRules.count == 2)
        #expect(mockStorage.timeRules.contains { $0.name == "Existing" })
        #expect(mockStorage.timeRules.contains { $0.name == "New" })
    }
    
    // MARK: - updateRule Tests
    
    @Test func updateRuleUpdatesExistingRule() {
        // Validates: Requirements 8.4
        var originalRule = createRule(name: "Original", hour: 8, minute: 0)
        let (service, mockStorage) = createService(rules: [originalRule], isTimeRuleEnabled: true)
        
        // Update the rule
        originalRule.name = "Updated"
        service.updateRule(originalRule)
        
        #expect(mockStorage.timeRules.count == 1)
        #expect(mockStorage.timeRules.first?.name == "Updated")
    }
    
    @Test func updateRuleSavesToStorage() {
        // Validates: Requirements 8.4
        var rule = createRule(name: "Test", hour: 8, minute: 0)
        let (service, mockStorage) = createService(rules: [rule], isTimeRuleEnabled: true)
        
        rule.name = "Updated"
        service.updateRule(rule)
        
        #expect(mockStorage.saveCallCount == 1)
    }
    
    @Test func updateRuleDoesNothingForNonExistentRule() {
        // Validates: Requirements 8.4
        let existingRule = createRule(name: "Existing", hour: 8, minute: 0)
        let (service, mockStorage) = createService(rules: [existingRule], isTimeRuleEnabled: true)
        let nonExistentRule = createRule(name: "NonExistent", hour: 10, minute: 0)
        
        service.updateRule(nonExistentRule)
        
        #expect(mockStorage.timeRules.count == 1)
        #expect(mockStorage.timeRules.first?.name == "Existing")
    }
    
    @Test func updateRuleCanToggleEnabled() {
        // Validates: Requirements 8.4
        var rule = createRule(name: "Test", hour: 8, minute: 0, isEnabled: true)
        let (service, mockStorage) = createService(rules: [rule], isTimeRuleEnabled: true)
        
        rule.isEnabled = false
        service.updateRule(rule)
        
        #expect(mockStorage.timeRules.first?.isEnabled == false)
    }
    
    @Test func updateRuleCanChangeDirection() {
        // Validates: Requirements 8.4
        var rule = createRule(name: "Test", hour: 8, minute: 0, direction: .alumRock)
        let (service, mockStorage) = createService(rules: [rule], isTimeRuleEnabled: true)
        
        // Use directionId to change direction (direction is now a computed property)
        rule.directionId = Direction.mountainView.directionId
        service.updateRule(rule)
        
        #expect(mockStorage.timeRules.first?.direction == .mountainView)
    }
    
    // MARK: - deleteRule Tests
    
    @Test func deleteRuleRemovesRuleFromStorage() {
        // Validates: Requirements 8.4
        let rule = createRule(name: "ToDelete", hour: 8, minute: 0)
        let (service, mockStorage) = createService(rules: [rule], isTimeRuleEnabled: true)
        
        service.deleteRule(rule)
        
        #expect(mockStorage.timeRules.isEmpty)
    }
    
    @Test func deleteRuleSavesToStorage() {
        // Validates: Requirements 8.4
        let rule = createRule(name: "ToDelete", hour: 8, minute: 0)
        let (service, mockStorage) = createService(rules: [rule], isTimeRuleEnabled: true)
        
        service.deleteRule(rule)
        
        #expect(mockStorage.saveCallCount == 1)
    }
    
    @Test func deleteRulePreservesOtherRules() {
        // Validates: Requirements 8.4
        let rule1 = createRule(name: "Keep", hour: 8, minute: 0)
        let rule2 = createRule(name: "Delete", hour: 17, minute: 0)
        let (service, mockStorage) = createService(rules: [rule1, rule2], isTimeRuleEnabled: true)
        
        service.deleteRule(rule2)
        
        #expect(mockStorage.timeRules.count == 1)
        #expect(mockStorage.timeRules.first?.name == "Keep")
    }
    
    @Test func deleteRuleDoesNothingForNonExistentRule() {
        // Validates: Requirements 8.4
        let existingRule = createRule(name: "Existing", hour: 8, minute: 0)
        let (service, mockStorage) = createService(rules: [existingRule], isTimeRuleEnabled: true)
        let nonExistentRule = createRule(name: "NonExistent", hour: 10, minute: 0)
        
        service.deleteRule(nonExistentRule)
        
        #expect(mockStorage.timeRules.count == 1)
        #expect(mockStorage.timeRules.first?.name == "Existing")
    }
    
    // MARK: - Convenience Methods Tests
    
    @Test func allRulesReturnsAllRules() {
        let rule1 = createRule(name: "Rule1", hour: 8, minute: 0, isEnabled: true)
        let rule2 = createRule(name: "Rule2", hour: 17, minute: 0, isEnabled: false)
        let (service, _) = createService(rules: [rule1, rule2], isTimeRuleEnabled: true)
        
        let allRules = service.allRules
        
        #expect(allRules.count == 2)
    }
    
    @Test func enabledRulesReturnsOnlyEnabledRules() {
        let enabledRule = createRule(name: "Enabled", hour: 8, minute: 0, isEnabled: true)
        let disabledRule = createRule(name: "Disabled", hour: 17, minute: 0, isEnabled: false)
        let (service, _) = createService(rules: [enabledRule, disabledRule], isTimeRuleEnabled: true)
        
        let enabledRules = service.enabledRules
        
        #expect(enabledRules.count == 1)
        #expect(enabledRules.first?.name == "Enabled")
    }
    
    @Test func isTimeRuleEnabledReflectsStorageState() {
        let (service, _) = createService(rules: [], isTimeRuleEnabled: true)
        #expect(service.isTimeRuleEnabled == true)
        
        let (service2, _) = createService(rules: [], isTimeRuleEnabled: false)
        #expect(service2.isTimeRuleEnabled == false)
    }
    
    @Test func setTimeRuleEnabledUpdatesStorage() {
        let (service, mockStorage) = createService(rules: [], isTimeRuleEnabled: false)
        
        service.setTimeRuleEnabled(true)
        
        #expect(mockStorage.isTimeRuleEnabled == true)
        #expect(mockStorage.saveCallCount == 1)
    }
    
    // MARK: - getNextRule Tests
    
    @Test func getNextRuleReturnsNextRuleToTrigger() {
        let morningRule = createRule(name: "Morning", hour: 8, minute: 0)
        let eveningRule = createRule(name: "Evening", hour: 17, minute: 0)
        let currentDate = createDate(hour: 10, minute: 0)
        
        let (service, _) = createService(
            rules: [morningRule, eveningRule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let nextRule = service.getNextRule(after: currentDate)
        
        #expect(nextRule?.name == "Evening")
    }
    
    @Test func getNextRuleWrapsAroundToNextDay() {
        let morningRule = createRule(name: "Morning", hour: 8, minute: 0)
        let eveningRule = createRule(name: "Evening", hour: 17, minute: 0)
        let currentDate = createDate(hour: 20, minute: 0)
        
        let (service, _) = createService(
            rules: [morningRule, eveningRule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let nextRule = service.getNextRule(after: currentDate)
        
        // Should wrap around to morning rule (earliest tomorrow)
        #expect(nextRule?.name == "Morning")
    }
    
    @Test func getNextRuleReturnsNilWhenNoRules() {
        let currentDate = createDate(hour: 10, minute: 0)
        let (service, _) = createService(rules: [], isTimeRuleEnabled: true, currentDate: currentDate)
        
        let nextRule = service.getNextRule(after: currentDate)
        
        #expect(nextRule == nil)
    }
    
    @Test func getNextRuleIgnoresDisabledRules() {
        let enabledRule = createRule(name: "Enabled", hour: 17, minute: 0, isEnabled: true)
        let disabledRule = createRule(name: "Disabled", hour: 12, minute: 0, isEnabled: false)
        let currentDate = createDate(hour: 10, minute: 0)
        
        let (service, _) = createService(
            rules: [enabledRule, disabledRule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let nextRule = service.getNextRule(after: currentDate)
        
        #expect(nextRule?.name == "Enabled")
    }
    
    // MARK: - Edge Cases
    
    @Test func handlesRuleAtMidnight() {
        let midnightRule = createRule(name: "Midnight", hour: 0, minute: 0)
        let currentDate = createDate(hour: 1, minute: 0)
        
        let (service, _) = createService(
            rules: [midnightRule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let activeRule = service.getCurrentActiveRule()
        
        #expect(activeRule?.name == "Midnight")
    }
    
    @Test func handlesRuleAtEndOfDay() {
        let lateRule = createRule(name: "Late", hour: 23, minute: 59)
        let currentDate = createDate(hour: 23, minute: 59)
        
        let (service, _) = createService(
            rules: [lateRule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let activeRule = service.getCurrentActiveRule()
        
        #expect(activeRule?.name == "Late")
    }
    
    @Test func handlesMultipleRulesAtSameTime() {
        // When multiple rules have the same trigger time, one should be selected
        let rule1 = createRule(name: "Rule1", hour: 8, minute: 0, stationId: "70261")
        let rule2 = createRule(name: "Rule2", hour: 8, minute: 0, stationId: "70541")
        let currentDate = createDate(hour: 10, minute: 0)
        
        let (service, _) = createService(
            rules: [rule1, rule2],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let activeRule = service.getCurrentActiveRule()
        
        // Should return one of the rules (implementation-dependent which one)
        #expect(activeRule != nil)
        #expect(activeRule?.triggerHour == 8)
        #expect(activeRule?.triggerMinute == 0)
    }
    
    @Test func handlesExactTriggerTime() {
        // Rule should be active exactly at its trigger time
        let rule = createRule(name: "Exact", hour: 8, minute: 30)
        let currentDate = createDate(hour: 8, minute: 30)
        
        let (service, _) = createService(
            rules: [rule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let activeRule = service.getCurrentActiveRule()
        
        #expect(activeRule?.name == "Exact")
    }
    
    @Test func handlesOneMinuteBeforeTrigger() {
        // Rule should NOT be active one minute before trigger time
        let rule = createRule(name: "Test", hour: 8, minute: 30)
        let currentDate = createDate(hour: 8, minute: 29)
        
        let (service, _) = createService(
            rules: [rule],
            isTimeRuleEnabled: true,
            currentDate: currentDate
        )
        
        let activeRule = service.getCurrentActiveRule()
        
        #expect(activeRule == nil)
    }
}

// MARK: - Property 9: Time Rule Enable/Disable Behavior Property Tests

/// Property-based tests for time rule enable/disable behavior
/// **Validates: Property 9**
///
/// Property 9: 时间规则启用/禁用行为
/// *对于任意* 时间规则配置，当时间规则功能被禁用时，即使当前时间匹配某条规则，
/// 系统也应该使用用户手动选择的站点和方向。
struct TimeRuleEnableDisablePropertyTests {
    
    // MARK: - Random Data Generators
    
    /// Generates a random hour (0-23)
    private func randomHour() -> Int {
        Int.random(in: 0...23)
    }
    
    /// Generates a random minute (0-59)
    private func randomMinute() -> Int {
        Int.random(in: 0...59)
    }
    
    /// Generates a random station ID from the orange line stations
    private func randomStationId() -> String {
        let stationIds = ["70261", "70271", "70281", "70291", "70301", "70311", "70321", "70331",
                         "70341", "70351", "70361", "70371", "70381", "70391", "70401", "70411",
                         "70421", "70431", "70441", "70451", "70461", "70471", "70481", "70491",
                         "70501", "70511", "70521", "70531", "70541"]
        return stationIds.randomElement()!
    }
    
    /// Generates a random direction
    private func randomDirection() -> Direction {
        Direction.allCases.randomElement()!
    }
    
    /// Generates a random rule name
    private func randomRuleName() -> String {
        let names = ["Morning", "Evening", "Lunch", "Night", "Custom", "Work", "Home", "Test"]
        return "\(names.randomElement()!) Rule \(Int.random(in: 1...100))"
    }
    
    /// Creates a date with specific hour and minute
    private func createDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// Creates a TimeRuleService with a mock storage service
    private func createService(
        rules: [TimeRule] = [],
        isTimeRuleEnabled: Bool = true,
        currentDate: Date = Date()
    ) -> (TimeRuleService, MockStorageService) {
        let mockStorage = MockStorageService()
        mockStorage.timeRules = rules
        mockStorage.isTimeRuleEnabled = isTimeRuleEnabled
        
        let service = TimeRuleService(
            storageService: mockStorage,
            dateProvider: { currentDate }
        )
        
        return (service, mockStorage)
    }
    
    // MARK: - Property Tests
    
    /// **Validates: Property 9**
    ///
    /// Property: Disabled time rules (isEnabled = false) should NOT be returned by
    /// getCurrentActiveRule() even if the current time matches the rule's trigger time.
    ///
    /// This test runs 100 iterations with random data to verify that disabled rules
    /// are never returned regardless of time matching.
    @Test func disabledRulesNeverReturnedEvenWhenTimeMatches() {
        // **Validates: Requirements 8.6, 8.7**
        
        for iteration in 0..<100 {
            // Generate random time for the rule
            let ruleHour = randomHour()
            let ruleMinute = randomMinute()
            
            // Create a disabled rule
            let disabledRule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: ruleHour, minute: ruleMinute),
                stationId: randomStationId(),
                direction: randomDirection(),
                isEnabled: false  // Rule is DISABLED
            )
            
            // Set current time to EXACTLY match the rule's trigger time
            let currentDate = createDate(hour: ruleHour, minute: ruleMinute)
            
            // Create service with global time rules ENABLED but individual rule DISABLED
            let (service, _) = createService(
                rules: [disabledRule],
                isTimeRuleEnabled: true,  // Global setting is enabled
                currentDate: currentDate
            )
            
            // Property assertion: disabled rule should NOT be returned
            let activeRule = service.getCurrentActiveRule()
            
            #expect(
                activeRule == nil,
                "Iteration \(iteration): Disabled rule should not be returned even when time matches (hour: \(ruleHour), minute: \(ruleMinute))"
            )
        }
    }
    
    /// **Validates: Property 9**
    ///
    /// Property: When isEnabled = true AND the current time is at or after the trigger time,
    /// the rule SHOULD be returned by getCurrentActiveRule().
    ///
    /// This test runs 100 iterations with random data to verify that enabled rules
    /// are correctly returned when time conditions are met.
    @Test func enabledRulesReturnedWhenTimeMatches() {
        // **Validates: Requirements 8.3, 8.6**
        
        for iteration in 0..<100 {
            // Generate random time for the rule
            let ruleHour = randomHour()
            let ruleMinute = randomMinute()
            
            // Create an enabled rule
            let enabledRule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: ruleHour, minute: ruleMinute),
                stationId: randomStationId(),
                direction: randomDirection(),
                isEnabled: true  // Rule is ENABLED
            )
            
            // Set current time to be at or after the rule's trigger time (same day)
            // Add random offset of 0-60 minutes after trigger time, capped at 23:59
            let offsetMinutes = Int.random(in: 0...60)
            let totalMinutes = ruleHour * 60 + ruleMinute + offsetMinutes
            let cappedMinutes = min(totalMinutes, 23 * 60 + 59)
            let currentHour = cappedMinutes / 60
            let currentMinute = cappedMinutes % 60
            let currentDate = createDate(hour: currentHour, minute: currentMinute)
            
            // Create service with global time rules ENABLED
            let (service, _) = createService(
                rules: [enabledRule],
                isTimeRuleEnabled: true,  // Global setting is enabled
                currentDate: currentDate
            )
            
            // Property assertion: enabled rule should be returned when time is at or after trigger
            let activeRule = service.getCurrentActiveRule()
            
            #expect(
                activeRule != nil,
                "Iteration \(iteration): Enabled rule should be returned when time is at or after trigger (rule: \(ruleHour):\(ruleMinute), current: \(currentHour):\(currentMinute))"
            )
            #expect(
                activeRule?.id == enabledRule.id,
                "Iteration \(iteration): Returned rule should match the enabled rule"
            )
        }
    }
    
    /// **Validates: Property 9**
    ///
    /// Property: When global time rule feature is disabled (isTimeRuleEnabled = false),
    /// NO rules should be returned regardless of individual rule's isEnabled state or time matching.
    ///
    /// This test runs 100 iterations with random data to verify that the global disable
    /// takes precedence over individual rule settings.
    @Test func globalDisableOverridesIndividualRuleSettings() {
        // **Validates: Requirements 8.6, 8.7**
        
        for iteration in 0..<100 {
            // Generate random time for the rule
            let ruleHour = randomHour()
            let ruleMinute = randomMinute()
            
            // Create an enabled rule (individual setting)
            let enabledRule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: ruleHour, minute: ruleMinute),
                stationId: randomStationId(),
                direction: randomDirection(),
                isEnabled: true  // Individual rule is ENABLED
            )
            
            // Set current time to EXACTLY match the rule's trigger time
            let currentDate = createDate(hour: ruleHour, minute: ruleMinute)
            
            // Create service with global time rules DISABLED
            let (service, _) = createService(
                rules: [enabledRule],
                isTimeRuleEnabled: false,  // Global setting is DISABLED
                currentDate: currentDate
            )
            
            // Property assertion: no rule should be returned when globally disabled
            let activeRule = service.getCurrentActiveRule()
            
            #expect(
                activeRule == nil,
                "Iteration \(iteration): No rule should be returned when global time rules are disabled (hour: \(ruleHour), minute: \(ruleMinute))"
            )
        }
    }
    
    /// **Validates: Property 9**
    ///
    /// Property: Among multiple rules, only enabled rules should be considered for activation.
    /// Disabled rules should be completely ignored in the selection process.
    ///
    /// This test runs 100 iterations with random data to verify that disabled rules
    /// are filtered out when selecting the active rule.
    @Test func onlyEnabledRulesConsideredForActivation() {
        // **Validates: Requirements 8.3, 8.6, 8.7**
        
        for iteration in 0..<100 {
            // Generate random times for rules
            let enabledRuleHour = Int.random(in: 0...12)  // Earlier in the day
            let enabledRuleMinute = randomMinute()
            let disabledRuleHour = Int.random(in: 13...23)  // Later in the day
            let disabledRuleMinute = randomMinute()
            
            // Create an enabled rule (earlier time)
            let enabledRule = TimeRule(
                name: "Enabled \(randomRuleName())",
                triggerTime: TimeRule.createTriggerTime(hour: enabledRuleHour, minute: enabledRuleMinute),
                stationId: randomStationId(),
                direction: randomDirection(),
                isEnabled: true
            )
            
            // Create a disabled rule (later time - would normally take precedence)
            let disabledRule = TimeRule(
                name: "Disabled \(randomRuleName())",
                triggerTime: TimeRule.createTriggerTime(hour: disabledRuleHour, minute: disabledRuleMinute),
                stationId: randomStationId(),
                direction: randomDirection(),
                isEnabled: false
            )
            
            // Set current time to after both rules' trigger times
            let currentDate = createDate(hour: 23, minute: 59)
            
            // Create service with both rules
            let (service, _) = createService(
                rules: [enabledRule, disabledRule],
                isTimeRuleEnabled: true,
                currentDate: currentDate
            )
            
            // Property assertion: only the enabled rule should be returned
            let activeRule = service.getCurrentActiveRule()
            
            #expect(
                activeRule != nil,
                "Iteration \(iteration): An enabled rule should be returned"
            )
            #expect(
                activeRule?.id == enabledRule.id,
                "Iteration \(iteration): The enabled rule should be returned, not the disabled one"
            )
            #expect(
                activeRule?.isEnabled == true,
                "Iteration \(iteration): Returned rule should have isEnabled = true"
            )
        }
    }
    
    /// **Validates: Property 9**
    ///
    /// Property: Toggling a rule's isEnabled state should immediately affect whether
    /// it can be returned by getCurrentActiveRule().
    ///
    /// This test runs 100 iterations to verify the toggle behavior.
    @Test func togglingRuleEnabledStateAffectsActivation() {
        // **Validates: Requirements 8.6, 8.7**
        
        for iteration in 0..<100 {
            // Generate random time for the rule
            let ruleHour = randomHour()
            let ruleMinute = randomMinute()
            
            // Create a rule (initially enabled)
            var rule = TimeRule(
                name: randomRuleName(),
                triggerTime: TimeRule.createTriggerTime(hour: ruleHour, minute: ruleMinute),
                stationId: randomStationId(),
                direction: randomDirection(),
                isEnabled: true
            )
            
            // Set current time to after the rule's trigger time
            let offsetMinutes = Int.random(in: 0...60)
            let totalMinutes = ruleHour * 60 + ruleMinute + offsetMinutes
            let cappedMinutes = min(totalMinutes, 23 * 60 + 59)
            let currentHour = cappedMinutes / 60
            let currentMinute = cappedMinutes % 60
            let currentDate = createDate(hour: currentHour, minute: currentMinute)
            
            // Test with enabled rule
            let (service1, mockStorage1) = createService(
                rules: [rule],
                isTimeRuleEnabled: true,
                currentDate: currentDate
            )
            
            let activeRuleWhenEnabled = service1.getCurrentActiveRule()
            #expect(
                activeRuleWhenEnabled != nil,
                "Iteration \(iteration): Rule should be active when enabled"
            )
            
            // Toggle to disabled
            rule.isEnabled = false
            let (service2, _) = createService(
                rules: [rule],
                isTimeRuleEnabled: true,
                currentDate: currentDate
            )
            
            let activeRuleWhenDisabled = service2.getCurrentActiveRule()
            #expect(
                activeRuleWhenDisabled == nil,
                "Iteration \(iteration): Rule should not be active when disabled"
            )
        }
    }
}

// MARK: - Property 10: TimeRule Persistence Round-Trip Property Tests

/// Property-based tests for TimeRule persistence round-trip
/// **Validates: Property 10**
///
/// Property 10: 时间规则持久化往返
/// *对于任意* 有效的 TimeRule 对象，保存到存储后再加载，应该得到与原始对象相等的 TimeRule。
struct TimeRulePersistencePropertyTests {
    
    // MARK: - Random Data Generators
    
    /// Generates a random hour (0-23)
    private func randomHour() -> Int {
        Int.random(in: 0...23)
    }
    
    /// Generates a random minute (0-59)
    private func randomMinute() -> Int {
        Int.random(in: 0...59)
    }
    
    /// Generates a random station ID from the orange line stations
    private func randomStationId() -> String {
        let stationIds = ["70261", "70271", "70281", "70291", "70301", "70311", "70321", "70331",
                         "70341", "70351", "70361", "70371", "70381", "70391", "70401", "70411",
                         "70421", "70431", "70441", "70451", "70461", "70471", "70481", "70491",
                         "70501", "70511", "70521", "70531", "70541"]
        return stationIds.randomElement()!
    }
    
    /// Generates a random direction
    private func randomDirection() -> Direction {
        Direction.allCases.randomElement()!
    }
    
    /// Generates a random rule name with various characters
    private func randomRuleName() -> String {
        let prefixes = ["Morning", "Evening", "Lunch", "Night", "Custom", "Work", "Home", "Test", "早上", "晚上"]
        let suffixes = ["Commute", "Return", "Rule", "Schedule", "通勤", "回家"]
        return "\(prefixes.randomElement()!) \(suffixes.randomElement()!) \(Int.random(in: 1...999))"
    }
    
    /// Generates a random boolean
    private func randomBool() -> Bool {
        Bool.random()
    }
    
    /// Creates a random TimeRule with all properties randomized
    private func createRandomTimeRule() -> TimeRule {
        let hour = randomHour()
        let minute = randomMinute()
        
        return TimeRule(
            id: UUID(),
            name: randomRuleName(),
            triggerTime: TimeRule.createTriggerTime(hour: hour, minute: minute),
            stationId: randomStationId(),
            direction: randomDirection(),
            isEnabled: randomBool()
        )
    }
    
    // MARK: - Property Tests
    
    /// **Validates: Property 10**
    ///
    /// Property: A single TimeRule saved to storage and loaded back should be identical
    /// to the original TimeRule in all properties: id, name, triggerHour, triggerMinute,
    /// stationId, direction, isEnabled.
    ///
    /// This test runs 100 iterations with random data to verify round-trip consistency.
    @Test func singleTimeRulePersistenceRoundTrip() {
        // **Validates: Requirements 8.2**
        
        for iteration in 0..<100 {
            // Create a random TimeRule
            let originalRule = createRandomTimeRule()
            
            // Create a fresh UserDefaults for isolation
            let testSuiteName = "TestSuite_SingleRule_\(iteration)_\(UUID().uuidString)"
            let testDefaults = UserDefaults(suiteName: testSuiteName)!
            
            // Save the rule using StorageService
            let saveStorage = StorageService(userDefaults: testDefaults)
            saveStorage.timeRules = [originalRule]
            saveStorage.save()
            
            // Load the rule using a new StorageService instance
            let loadStorage = StorageService(userDefaults: testDefaults)
            loadStorage.load()
            
            // Verify the loaded rules
            #expect(
                loadStorage.timeRules.count == 1,
                "Iteration \(iteration): Should have exactly 1 rule after loading"
            )
            
            guard let loadedRule = loadStorage.timeRules.first else {
                Issue.record("Iteration \(iteration): Failed to load rule")
                testDefaults.removePersistentDomain(forName: testSuiteName)
                continue
            }
            
            // Verify all properties match
            #expect(
                loadedRule.id == originalRule.id,
                "Iteration \(iteration): id should match - expected \(originalRule.id), got \(loadedRule.id)"
            )
            #expect(
                loadedRule.name == originalRule.name,
                "Iteration \(iteration): name should match - expected '\(originalRule.name)', got '\(loadedRule.name)'"
            )
            #expect(
                loadedRule.triggerHour == originalRule.triggerHour,
                "Iteration \(iteration): triggerHour should match - expected \(originalRule.triggerHour), got \(loadedRule.triggerHour)"
            )
            #expect(
                loadedRule.triggerMinute == originalRule.triggerMinute,
                "Iteration \(iteration): triggerMinute should match - expected \(originalRule.triggerMinute), got \(loadedRule.triggerMinute)"
            )
            #expect(
                loadedRule.stationId == originalRule.stationId,
                "Iteration \(iteration): stationId should match - expected '\(originalRule.stationId)', got '\(loadedRule.stationId)'"
            )
            #expect(
                loadedRule.direction == originalRule.direction,
                "Iteration \(iteration): direction should match - expected \(originalRule.direction), got \(loadedRule.direction)"
            )
            #expect(
                loadedRule.isEnabled == originalRule.isEnabled,
                "Iteration \(iteration): isEnabled should match - expected \(originalRule.isEnabled), got \(loadedRule.isEnabled)"
            )
            
            // Verify full equality using Equatable
            #expect(
                loadedRule == originalRule,
                "Iteration \(iteration): Loaded rule should be equal to original rule"
            )
            
            // Cleanup
            testDefaults.removePersistentDomain(forName: testSuiteName)
        }
    }
    
    /// **Validates: Property 10**
    ///
    /// Property: Multiple TimeRules saved to storage and loaded back should all be
    /// identical to their original versions, preserving order and all properties.
    ///
    /// This test runs 100 iterations with random data to verify round-trip consistency
    /// for multiple rules.
    @Test func multipleTimeRulesPersistenceRoundTrip() {
        // **Validates: Requirements 8.2, 8.4**
        
        for iteration in 0..<100 {
            // Generate a random number of rules (1-5)
            let ruleCount = Int.random(in: 1...5)
            
            // Create random TimeRules
            var originalRules: [TimeRule] = []
            for _ in 0..<ruleCount {
                originalRules.append(createRandomTimeRule())
            }
            
            // Create a fresh UserDefaults for isolation
            let testSuiteName = "TestSuite_MultiRule_\(iteration)_\(UUID().uuidString)"
            let testDefaults = UserDefaults(suiteName: testSuiteName)!
            
            // Save the rules using StorageService
            let saveStorage = StorageService(userDefaults: testDefaults)
            saveStorage.timeRules = originalRules
            saveStorage.save()
            
            // Load the rules using a new StorageService instance
            let loadStorage = StorageService(userDefaults: testDefaults)
            loadStorage.load()
            
            // Verify the count matches
            #expect(
                loadStorage.timeRules.count == originalRules.count,
                "Iteration \(iteration): Rule count should match - expected \(originalRules.count), got \(loadStorage.timeRules.count)"
            )
            
            // Verify each rule matches
            for (index, originalRule) in originalRules.enumerated() {
                guard index < loadStorage.timeRules.count else {
                    Issue.record("Iteration \(iteration): Missing rule at index \(index)")
                    continue
                }
                
                let loadedRule = loadStorage.timeRules[index]
                
                #expect(
                    loadedRule == originalRule,
                    "Iteration \(iteration): Rule at index \(index) should match original"
                )
            }
            
            // Cleanup
            testDefaults.removePersistentDomain(forName: testSuiteName)
        }
    }
    
    /// **Validates: Property 10**
    ///
    /// Property: TimeRule JSON encoding/decoding round-trip should preserve all properties.
    /// This tests the Codable conformance directly without UserDefaults.
    ///
    /// This test runs 100 iterations with random data.
    @Test func timeRuleJSONEncodingDecodingRoundTrip() {
        // **Validates: Requirements 8.2**
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for iteration in 0..<100 {
            // Create a random TimeRule
            let originalRule = createRandomTimeRule()
            
            // Encode to JSON
            guard let jsonData = try? encoder.encode(originalRule) else {
                Issue.record("Iteration \(iteration): Failed to encode TimeRule to JSON")
                continue
            }
            
            // Decode from JSON
            guard let decodedRule = try? decoder.decode(TimeRule.self, from: jsonData) else {
                Issue.record("Iteration \(iteration): Failed to decode TimeRule from JSON")
                continue
            }
            
            // Verify all properties match
            #expect(
                decodedRule.id == originalRule.id,
                "Iteration \(iteration): id should match after JSON round-trip"
            )
            #expect(
                decodedRule.name == originalRule.name,
                "Iteration \(iteration): name should match after JSON round-trip"
            )
            #expect(
                decodedRule.triggerHour == originalRule.triggerHour,
                "Iteration \(iteration): triggerHour should match after JSON round-trip"
            )
            #expect(
                decodedRule.triggerMinute == originalRule.triggerMinute,
                "Iteration \(iteration): triggerMinute should match after JSON round-trip"
            )
            #expect(
                decodedRule.stationId == originalRule.stationId,
                "Iteration \(iteration): stationId should match after JSON round-trip"
            )
            #expect(
                decodedRule.direction == originalRule.direction,
                "Iteration \(iteration): direction should match after JSON round-trip"
            )
            #expect(
                decodedRule.isEnabled == originalRule.isEnabled,
                "Iteration \(iteration): isEnabled should match after JSON round-trip"
            )
            
            // Verify full equality
            #expect(
                decodedRule == originalRule,
                "Iteration \(iteration): Decoded rule should be equal to original rule"
            )
        }
    }
    
    /// **Validates: Property 10**
    ///
    /// Property: TimeRule array JSON encoding/decoding round-trip should preserve
    /// all rules and their properties.
    ///
    /// This test runs 100 iterations with random data.
    @Test func timeRuleArrayJSONEncodingDecodingRoundTrip() {
        // **Validates: Requirements 8.2**
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for iteration in 0..<100 {
            // Generate a random number of rules (0-10)
            let ruleCount = Int.random(in: 0...10)
            
            // Create random TimeRules
            var originalRules: [TimeRule] = []
            for _ in 0..<ruleCount {
                originalRules.append(createRandomTimeRule())
            }
            
            // Encode to JSON
            guard let jsonData = try? encoder.encode(originalRules) else {
                Issue.record("Iteration \(iteration): Failed to encode TimeRule array to JSON")
                continue
            }
            
            // Decode from JSON
            guard let decodedRules = try? decoder.decode([TimeRule].self, from: jsonData) else {
                Issue.record("Iteration \(iteration): Failed to decode TimeRule array from JSON")
                continue
            }
            
            // Verify count matches
            #expect(
                decodedRules.count == originalRules.count,
                "Iteration \(iteration): Rule count should match after JSON round-trip"
            )
            
            // Verify each rule matches
            for (index, originalRule) in originalRules.enumerated() {
                guard index < decodedRules.count else {
                    Issue.record("Iteration \(iteration): Missing rule at index \(index)")
                    continue
                }
                
                #expect(
                    decodedRules[index] == originalRule,
                    "Iteration \(iteration): Rule at index \(index) should match after JSON round-trip"
                )
            }
        }
    }
    
    /// **Validates: Property 10**
    ///
    /// Property: Edge case values for TimeRule properties should persist correctly.
    /// Tests boundary values like hour 0/23, minute 0/59, empty names, etc.
    ///
    /// This test runs 100 iterations with edge case values.
    @Test func timeRuleEdgeCasesPersistenceRoundTrip() {
        // **Validates: Requirements 8.2**
        
        for iteration in 0..<100 {
            // Create edge case values
            let edgeCaseHours = [0, 12, 23]
            let edgeCaseMinutes = [0, 30, 59]
            let edgeCaseNames = ["", "A", "Very Long Rule Name With Many Characters 测试中文名称 🚃", "Rule\nWith\nNewlines", "Rule\tWith\tTabs"]
            let edgeCaseStationIds = ["70261", "70541"] // First and last stations
            
            let hour = edgeCaseHours.randomElement()!
            let minute = edgeCaseMinutes.randomElement()!
            let name = edgeCaseNames.randomElement()!
            let stationId = edgeCaseStationIds.randomElement()!
            let direction = randomDirection()
            let isEnabled = randomBool()
            
            let originalRule = TimeRule(
                id: UUID(),
                name: name,
                triggerTime: TimeRule.createTriggerTime(hour: hour, minute: minute),
                stationId: stationId,
                direction: direction,
                isEnabled: isEnabled
            )
            
            // Create a fresh UserDefaults for isolation
            let testSuiteName = "TestSuite_EdgeCase_\(iteration)_\(UUID().uuidString)"
            let testDefaults = UserDefaults(suiteName: testSuiteName)!
            
            // Save and load
            let saveStorage = StorageService(userDefaults: testDefaults)
            saveStorage.timeRules = [originalRule]
            saveStorage.save()
            
            let loadStorage = StorageService(userDefaults: testDefaults)
            loadStorage.load()
            
            // Verify
            #expect(
                loadStorage.timeRules.count == 1,
                "Iteration \(iteration): Should have exactly 1 rule after loading edge case"
            )
            
            if let loadedRule = loadStorage.timeRules.first {
                #expect(
                    loadedRule == originalRule,
                    "Iteration \(iteration): Edge case rule should persist correctly - hour: \(hour), minute: \(minute), name: '\(name)'"
                )
            }
            
            // Cleanup
            testDefaults.removePersistentDomain(forName: testSuiteName)
        }
    }
}

// MARK: - TimeRuleService Integration Tests

struct TimeRuleServiceIntegrationTests {
    
    @Test func fullWorkflowAddUpdateDelete() {
        // Test a complete workflow of adding, updating, and deleting rules
        let mockStorage = MockStorageService()
        mockStorage.isTimeRuleEnabled = true
        let service = TimeRuleService(storageService: mockStorage)
        
        // Add a rule
        let rule = TimeRule(
            name: "Morning Commute",
            triggerTime: TimeRule.createTriggerTime(hour: 8, minute: 0),
            stationId: "70261",
            direction: .alumRock
        )
        service.addRule(rule)
        #expect(service.allRules.count == 1)
        
        // Update the rule
        var updatedRule = service.allRules.first!
        updatedRule.name = "Updated Morning"
        // Use directionId to change direction (direction is now a computed property)
        updatedRule.directionId = Direction.mountainView.directionId
        service.updateRule(updatedRule)
        #expect(service.allRules.first?.name == "Updated Morning")
        #expect(service.allRules.first?.direction == .mountainView)
        
        // Delete the rule
        service.deleteRule(service.allRules.first!)
        #expect(service.allRules.isEmpty)
    }
    
    @Test func multipleRulesScenario() {
        // Validates: Requirements 8.4 - support at least two time rules
        let mockStorage = MockStorageService()
        mockStorage.isTimeRuleEnabled = true
        let service = TimeRuleService(storageService: mockStorage)
        
        // Add morning rule
        let morningRule = TimeRule(
            name: "Morning Commute",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock
        )
        service.addRule(morningRule)
        
        // Add evening rule
        let eveningRule = TimeRule(
            name: "Evening Return",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 30),
            stationId: "70541",
            direction: .mountainView
        )
        service.addRule(eveningRule)
        
        #expect(service.allRules.count == 2)
        #expect(service.enabledRules.count == 2)
    }
}
