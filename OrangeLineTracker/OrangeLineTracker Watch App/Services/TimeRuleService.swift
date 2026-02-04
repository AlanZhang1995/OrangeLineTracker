//
//  TimeRuleService.swift
//  OrangeLineTracker Watch App
//
//  Service for managing time-based rules for automatic station and direction switching
//

import Foundation

// MARK: - TimeRuleServiceProtocol

/// Protocol defining the time rule service interface
/// - Validates: Requirements 8.3, 8.4, 8.6, 8.7
protocol TimeRuleServiceProtocol {
    /// Gets the currently active rule based on the current time
    /// - Returns: The active TimeRule if one matches the current time and is enabled, nil otherwise
    func getCurrentActiveRule() -> TimeRule?
    
    /// Determines if a rule should be applied at the given date
    /// - Parameter date: The date to check against
    /// - Returns: The TimeRule that should be applied, or nil if no rule matches
    func shouldApplyRule(at date: Date) -> TimeRule?
    
    /// Adds a new time rule
    /// - Parameter rule: The TimeRule to add
    func addRule(_ rule: TimeRule)
    
    /// Updates an existing time rule
    /// - Parameter rule: The TimeRule with updated values (matched by id)
    func updateRule(_ rule: TimeRule)
    
    /// Deletes a time rule
    /// - Parameter rule: The TimeRule to delete (matched by id)
    func deleteRule(_ rule: TimeRule)
}

// MARK: - TimeRuleService

/// Implementation of TimeRuleServiceProtocol for managing time-based rules
/// - Validates: Requirements 8.3, 8.4, 8.6, 8.7
class TimeRuleService: TimeRuleServiceProtocol {
    
    // MARK: - Properties
    
    /// The storage service used for persisting rules
    private let storageService: StorageServiceProtocol
    
    /// Provides the current date (injectable for testing)
    private let dateProvider: () -> Date
    
    // MARK: - Initialization
    
    /// Creates a new TimeRuleService instance
    /// - Parameters:
    ///   - storageService: The storage service to use for persistence
    ///   - dateProvider: A closure that provides the current date (defaults to Date())
    init(
        storageService: StorageServiceProtocol,
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.storageService = storageService
        self.dateProvider = dateProvider
    }
    
    // MARK: - TimeRuleServiceProtocol Methods
    
    /// Gets the currently active rule based on the current time
    /// - Returns: The active TimeRule if one matches the current time and is enabled, nil otherwise
    /// - Validates: Requirements 8.3, 8.6, 8.7
    func getCurrentActiveRule() -> TimeRule? {
        return shouldApplyRule(at: dateProvider())
    }
    
    /// Determines if a rule should be applied at the given date
    /// - Parameter date: The date to check against
    /// - Returns: The TimeRule that should be applied, or nil if no rule matches
    /// - Validates: Requirements 8.3, 8.6, 8.7
    func shouldApplyRule(at date: Date) -> TimeRule? {
        // Reload storage to get fresh data from UserDefaults
        // This is critical for background refresh and timer-based checks
        storageService.load()
        
        // If time rules are disabled globally, return nil
        // Validates: Requirements 8.6, 8.7
        guard storageService.isTimeRuleEnabled else {
            return nil
        }
        
        // Find the most recently triggered rule that is still active
        // Validates: Requirements 8.3
        return findActiveRule(at: date)
    }
    
    /// Adds a new time rule
    /// - Parameter rule: The TimeRule to add
    /// - Validates: Requirements 8.4
    func addRule(_ rule: TimeRule) {
        var rules = storageService.timeRules
        rules.append(rule)
        updateStorageRules(rules)
    }
    
    /// Updates an existing time rule
    /// - Parameter rule: The TimeRule with updated values (matched by id)
    /// - Validates: Requirements 8.4
    func updateRule(_ rule: TimeRule) {
        var rules = storageService.timeRules
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            updateStorageRules(rules)
        }
    }
    
    /// Deletes a time rule
    /// - Parameter rule: The TimeRule to delete (matched by id)
    /// - Validates: Requirements 8.4
    func deleteRule(_ rule: TimeRule) {
        var rules = storageService.timeRules
        rules.removeAll { $0.id == rule.id }
        updateStorageRules(rules)
    }
    
    // MARK: - Private Methods
    
    /// Updates the rules in storage and saves
    /// - Parameter rules: The updated list of rules
    private func updateStorageRules(_ rules: [TimeRule]) {
        storageService.timeRules = rules
        storageService.save()
    }
    
    /// Finds the active rule at the given date
    /// The active rule is the most recent enabled rule whose trigger time has passed today
    /// - Parameter date: The date to check against
    /// - Returns: The active TimeRule, or nil if no rule is active
    private func findActiveRule(at date: Date) -> TimeRule? {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        // Get all enabled rules (storage was already loaded in shouldApplyRule)
        let enabledRules = storageService.timeRules.filter { $0.isEnabled }
        
        print("TimeRuleService: Checking rules at \(currentHour):\(String(format: "%02d", currentMinute)) (\(currentTimeInMinutes) minutes)")
        print("TimeRuleService: Found \(enabledRules.count) enabled rules")
        
        guard !enabledRules.isEmpty else {
            print("TimeRuleService: No enabled rules found")
            return nil
        }
        
        // Find rules that have triggered today (trigger time <= current time)
        // and select the one with the latest trigger time
        var activeRule: TimeRule?
        var latestTriggerTime = -1
        
        for rule in enabledRules {
            let ruleTriggerTimeInMinutes = rule.triggerHour * 60 + rule.triggerMinute
            print("TimeRuleService: Rule '\(rule.name)' triggers at \(rule.triggerHour):\(String(format: "%02d", rule.triggerMinute)) (\(ruleTriggerTimeInMinutes) minutes)")
            
            // Check if this rule's trigger time has passed today
            if ruleTriggerTimeInMinutes <= currentTimeInMinutes {
                // This rule has triggered, check if it's the most recent
                if ruleTriggerTimeInMinutes > latestTriggerTime {
                    latestTriggerTime = ruleTriggerTimeInMinutes
                    activeRule = rule
                    print("TimeRuleService: Rule '\(rule.name)' is now the active candidate")
                }
            }
        }
        
        if let active = activeRule {
            print("TimeRuleService: Active rule is '\(active.name)'")
        } else {
            print("TimeRuleService: No active rule (all rules trigger in the future)")
        }
        
        return activeRule
    }
    
    // MARK: - Convenience Methods
    
    /// Gets all configured time rules
    var allRules: [TimeRule] {
        return storageService.timeRules
    }
    
    /// Gets all enabled time rules
    var enabledRules: [TimeRule] {
        return storageService.timeRules.filter { $0.isEnabled }
    }
    
    /// Checks if time rules are globally enabled
    var isTimeRuleEnabled: Bool {
        return storageService.isTimeRuleEnabled
    }
    
    /// Sets the global time rule enabled state
    /// - Parameter enabled: Whether time rules should be enabled
    func setTimeRuleEnabled(_ enabled: Bool) {
        storageService.isTimeRuleEnabled = enabled
        storageService.save()
    }
    
    /// Gets the rule that will trigger next after the given date
    /// - Parameter date: The reference date
    /// - Returns: The next rule to trigger, or nil if no rules are configured
    func getNextRule(after date: Date) -> TimeRule? {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        let enabledRules = storageService.timeRules.filter { $0.isEnabled }
        
        guard !enabledRules.isEmpty else {
            return nil
        }
        
        // Find the next rule to trigger (smallest trigger time > current time)
        var nextRule: TimeRule?
        var earliestFutureTriggerTime = Int.max
        
        for rule in enabledRules {
            let ruleTriggerTimeInMinutes = rule.triggerHour * 60 + rule.triggerMinute
            
            // Check if this rule triggers in the future today
            if ruleTriggerTimeInMinutes > currentTimeInMinutes {
                if ruleTriggerTimeInMinutes < earliestFutureTriggerTime {
                    earliestFutureTriggerTime = ruleTriggerTimeInMinutes
                    nextRule = rule
                }
            }
        }
        
        // If no future rule today, wrap around to the earliest rule tomorrow
        if nextRule == nil {
            var earliestTriggerTime = Int.max
            for rule in enabledRules {
                let ruleTriggerTimeInMinutes = rule.triggerHour * 60 + rule.triggerMinute
                if ruleTriggerTimeInMinutes < earliestTriggerTime {
                    earliestTriggerTime = ruleTriggerTimeInMinutes
                    nextRule = rule
                }
            }
        }
        
        return nextRule
    }
}


// MARK: - Mock TimeRuleService for Testing

/// Mock implementation of TimeRuleServiceProtocol for testing
class MockTimeRuleService: TimeRuleServiceProtocol {
    
    /// The storage service used for persisting rules
    private let storageService: StorageServiceProtocol
    
    /// Mock active rule to return from getCurrentActiveRule
    var mockActiveRule: TimeRule?
    
    /// Number of times getCurrentActiveRule was called
    var getCurrentActiveRuleCallCount: Int = 0
    
    /// Number of times shouldApplyRule was called
    var shouldApplyRuleCallCount: Int = 0
    
    /// Creates a new MockTimeRuleService instance
    /// - Parameter storageService: The storage service to use for persistence
    init(storageService: StorageServiceProtocol) {
        self.storageService = storageService
    }
    
    func getCurrentActiveRule() -> TimeRule? {
        getCurrentActiveRuleCallCount += 1
        return mockActiveRule
    }
    
    func shouldApplyRule(at date: Date) -> TimeRule? {
        shouldApplyRuleCallCount += 1
        return mockActiveRule
    }
    
    func addRule(_ rule: TimeRule) {
        var rules = storageService.timeRules
        rules.append(rule)
        var mutableStorage = storageService
        mutableStorage.timeRules = rules
        mutableStorage.save()
    }
    
    func updateRule(_ rule: TimeRule) {
        var rules = storageService.timeRules
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            var mutableStorage = storageService
            mutableStorage.timeRules = rules
            mutableStorage.save()
        }
    }
    
    func deleteRule(_ rule: TimeRule) {
        var rules = storageService.timeRules
        rules.removeAll { $0.id == rule.id }
        var mutableStorage = storageService
        mutableStorage.timeRules = rules
        mutableStorage.save()
    }
    
    /// Resets all mock state
    func reset() {
        mockActiveRule = nil
        getCurrentActiveRuleCallCount = 0
        shouldApplyRuleCallCount = 0
    }
}
