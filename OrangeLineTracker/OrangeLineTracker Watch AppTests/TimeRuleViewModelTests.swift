//
//  TimeRuleViewModelTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Unit tests for TimeRuleViewModel
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Mock Services for TimeRuleViewModel Testing

class TimeRuleViewModelMockStorageService: StorageServiceProtocol {
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
    
    func reset() {
        selectedStation = nil
        selectedDirection = nil
        timeRules = []
        isTimeRuleEnabled = false
        cachedArrivalMinutes = nil
        lastUpdateTime = nil
        selectedLineId = nil
        favoriteLineIds = []
        cachedLines = nil
        saveCallCount = 0
        loadCallCount = 0
        updateWidgetDataCallCount = 0
    }
}

class TimeRuleViewModelMockTimeRuleService: TimeRuleServiceProtocol {
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

// MARK: - TimeRuleViewModel Initialization Tests

@MainActor
struct TimeRuleViewModelInitializationTests {
    
    @Test func viewModelInitializesWithEmptyRules() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.timeRules.isEmpty)
        #expect(viewModel.isTimeRuleEnabled == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isSaving == false)
    }
    
    @Test func viewModelLoadsExistingRules() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        // Set up existing rules
        let existingRule = TimeRule(
            name: "Morning Commute",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [existingRule]
        mockStorageService.isTimeRuleEnabled = true
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        // Validates: Requirements 8.1, 8.2 - load existing rules
        #expect(viewModel.timeRules.count == 1)
        #expect(viewModel.timeRules[0].name == "Morning Commute")
        #expect(viewModel.isTimeRuleEnabled == true)
        #expect(mockStorageService.loadCallCount == 1)
    }
}

// MARK: - Add Rule Tests

@MainActor
struct TimeRuleViewModelAddRuleTests {
    
    @Test func addRuleCallsService() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        let newRule = TimeRule(
            name: "Test Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 8, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        
        viewModel.addRule(newRule)
        
        // Validates: Requirements 8.1, 8.2 - add new rule
        #expect(mockTimeRuleService.addedRules.count == 1)
        #expect(mockTimeRuleService.addedRules[0].name == "Test Rule")
    }
    
    @Test func createRuleCreatesAndAddsRule() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        let triggerTime = TimeRule.createTriggerTime(hour: 9, minute: 15)
        let createdRule = viewModel.createRule(
            name: "Created Rule",
            triggerTime: triggerTime,
            stationId: "70271",
            direction: .mountainView,
            isEnabled: true
        )
        
        // Validates: Requirements 8.1, 8.2 - create rule with all parameters
        #expect(createdRule.name == "Created Rule")
        #expect(createdRule.stationId == "70271")
        #expect(createdRule.direction == .mountainView)
        #expect(createdRule.isEnabled == true)
        #expect(mockTimeRuleService.addedRules.count == 1)
    }
}

// MARK: - Update Rule Tests

@MainActor
struct TimeRuleViewModelUpdateRuleTests {
    
    @Test func updateRuleCallsService() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let existingRule = TimeRule(
            name: "Original Name",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [existingRule]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        var updatedRule = existingRule
        updatedRule.name = "Updated Name"
        
        viewModel.updateRule(updatedRule)
        
        // Validates: Requirements 8.1, 8.2 - update existing rule
        #expect(mockTimeRuleService.updatedRules.count == 1)
        #expect(mockTimeRuleService.updatedRules[0].name == "Updated Name")
    }
}

// MARK: - Delete Rule Tests

@MainActor
struct TimeRuleViewModelDeleteRuleTests {
    
    @Test func deleteRuleCallsService() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let ruleToDelete = TimeRule(
            name: "Rule to Delete",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [ruleToDelete]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        viewModel.deleteRule(ruleToDelete)
        
        // Validates: Requirements 8.1 - delete rule
        #expect(mockTimeRuleService.deletedRules.count == 1)
        #expect(mockTimeRuleService.deletedRules[0].id == ruleToDelete.id)
    }
    
    @Test func deleteRulesAtOffsetsDeletesMultipleRules() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule1 = TimeRule(
            name: "Rule 1",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        let rule2 = TimeRule(
            name: "Rule 2",
            triggerTime: TimeRule.createTriggerTime(hour: 8, minute: 0),
            stationId: "70271",
            direction: .mountainView,
            isEnabled: true
        )
        let rule3 = TimeRule(
            name: "Rule 3",
            triggerTime: TimeRule.createTriggerTime(hour: 9, minute: 0),
            stationId: "70281",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [rule1, rule2, rule3]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        // Delete rules at indices 0 and 2
        viewModel.deleteRules(at: IndexSet([0, 2]))
        
        #expect(mockTimeRuleService.deletedRules.count == 2)
    }
}


// MARK: - Enable/Disable Rule Tests

@MainActor
struct TimeRuleViewModelEnableDisableTests {
    
    @Test func toggleRuleEnabledTogglesState() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule = TimeRule(
            name: "Test Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [rule]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        viewModel.toggleRuleEnabled(rule)
        
        // Validates: Requirements 8.6 - toggle rule enabled state
        #expect(mockTimeRuleService.updatedRules.count == 1)
        #expect(mockTimeRuleService.updatedRules[0].isEnabled == false)
    }
    
    @Test func setRuleEnabledSetsState() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule = TimeRule(
            name: "Test Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [rule]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        viewModel.setRuleEnabled(rule, isEnabled: false)
        
        // Validates: Requirements 8.6 - set rule enabled state
        #expect(mockTimeRuleService.updatedRules.count == 1)
        #expect(mockTimeRuleService.updatedRules[0].isEnabled == false)
    }
    
    @Test func setRuleEnabledDoesNothingWhenSameState() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule = TimeRule(
            name: "Test Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [rule]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        viewModel.setRuleEnabled(rule, isEnabled: true) // Same state
        
        // Should not call update since state is the same
        #expect(mockTimeRuleService.updatedRules.isEmpty)
    }
}

// MARK: - Global Time Rule Enable/Disable Tests

@MainActor
struct TimeRuleViewModelGlobalEnableTests {
    
    @Test func toggleGlobalTimeRuleEnabledTogglesState() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        mockStorageService.isTimeRuleEnabled = false
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        viewModel.toggleGlobalTimeRuleEnabled()
        
        // Validates: Requirements 8.6 - toggle global time rule feature
        #expect(viewModel.isTimeRuleEnabled == true)
        #expect(mockStorageService.isTimeRuleEnabled == true)
        #expect(mockStorageService.saveCallCount >= 1)
    }
    
    @Test func setGlobalTimeRuleEnabledSetsState() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        mockStorageService.isTimeRuleEnabled = false
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        viewModel.setGlobalTimeRuleEnabled(true)
        
        // Validates: Requirements 8.6 - enable/disable time rule feature
        #expect(viewModel.isTimeRuleEnabled == true)
        #expect(mockStorageService.isTimeRuleEnabled == true)
        #expect(mockStorageService.saveCallCount >= 1)
    }
    
    @Test func setGlobalTimeRuleDisabledSetsState() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        mockStorageService.isTimeRuleEnabled = true
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        viewModel.setGlobalTimeRuleEnabled(false)
        
        // Validates: Requirements 8.6 - disable time rule feature
        #expect(viewModel.isTimeRuleEnabled == false)
        #expect(mockStorageService.isTimeRuleEnabled == false)
    }
}

// MARK: - Computed Properties Tests

@MainActor
struct TimeRuleViewModelComputedPropertiesTests {
    
    @Test func ruleCountReturnsCorrectCount() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule1 = TimeRule(
            name: "Rule 1",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        let rule2 = TimeRule(
            name: "Rule 2",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 0),
            stationId: "70541",
            direction: .mountainView,
            isEnabled: false
        )
        mockStorageService.timeRules = [rule1, rule2]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.ruleCount == 2)
    }
    
    @Test func hasRulesReturnsTrueWhenRulesExist() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule = TimeRule(
            name: "Test Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [rule]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.hasRules == true)
    }
    
    @Test func hasRulesReturnsFalseWhenNoRules() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.hasRules == false)
    }
    
    @Test func enabledRuleCountReturnsCorrectCount() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule1 = TimeRule(
            name: "Rule 1",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        let rule2 = TimeRule(
            name: "Rule 2",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 0),
            stationId: "70541",
            direction: .mountainView,
            isEnabled: false
        )
        let rule3 = TimeRule(
            name: "Rule 3",
            triggerTime: TimeRule.createTriggerTime(hour: 12, minute: 0),
            stationId: "70281",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [rule1, rule2, rule3]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.enabledRuleCount == 2)
    }
    
    @Test func enabledRulesReturnsOnlyEnabledRules() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule1 = TimeRule(
            name: "Enabled Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        let rule2 = TimeRule(
            name: "Disabled Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 0),
            stationId: "70541",
            direction: .mountainView,
            isEnabled: false
        )
        mockStorageService.timeRules = [rule1, rule2]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.enabledRules.count == 1)
        #expect(viewModel.enabledRules[0].name == "Enabled Rule")
    }
    
    @Test func disabledRulesReturnsOnlyDisabledRules() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule1 = TimeRule(
            name: "Enabled Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        let rule2 = TimeRule(
            name: "Disabled Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 0),
            stationId: "70541",
            direction: .mountainView,
            isEnabled: false
        )
        mockStorageService.timeRules = [rule1, rule2]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.disabledRules.count == 1)
        #expect(viewModel.disabledRules[0].name == "Disabled Rule")
    }

    
    @Test func rulesSortedByTimeReturnsSortedRules() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule1 = TimeRule(
            name: "Evening Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 30),
            stationId: "70541",
            direction: .mountainView,
            isEnabled: true
        )
        let rule2 = TimeRule(
            name: "Morning Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        let rule3 = TimeRule(
            name: "Noon Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 12, minute: 0),
            stationId: "70281",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [rule1, rule2, rule3]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        let sortedRules = viewModel.rulesSortedByTime
        
        #expect(sortedRules[0].name == "Morning Rule")
        #expect(sortedRules[1].name == "Noon Rule")
        #expect(sortedRules[2].name == "Evening Rule")
    }
    
    @Test func isTimeRuleActiveReturnsTrueWhenEnabledWithRules() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule = TimeRule(
            name: "Test Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [rule]
        mockStorageService.isTimeRuleEnabled = true
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.isTimeRuleActive == true)
    }
    
    @Test func isTimeRuleActiveReturnsFalseWhenDisabled() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule = TimeRule(
            name: "Test Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [rule]
        mockStorageService.isTimeRuleEnabled = false
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.isTimeRuleActive == false)
    }
    
    @Test func isTimeRuleActiveReturnsFalseWhenNoEnabledRules() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule = TimeRule(
            name: "Disabled Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: false
        )
        mockStorageService.timeRules = [rule]
        mockStorageService.isTimeRuleEnabled = true
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.isTimeRuleActive == false)
    }
}

// MARK: - Configuration Summary Tests

@MainActor
struct TimeRuleViewModelConfigurationSummaryTests {
    
    @Test func configurationSummaryShowsDisabledWhenGloballyDisabled() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        mockStorageService.isTimeRuleEnabled = false
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.configurationSummary == L10n.timeRulesDisabled)
    }
    
    @Test func configurationSummaryShowsNoRulesWhenEmpty() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        mockStorageService.isTimeRuleEnabled = true
        mockStorageService.timeRules = []
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.configurationSummary == L10n.noRulesConfigured)
    }
    
    @Test func configurationSummaryShowsAllDisabledWhenNoEnabledRules() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule = TimeRule(
            name: "Disabled Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: false
        )
        mockStorageService.timeRules = [rule]
        mockStorageService.isTimeRuleEnabled = true
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.configurationSummary == L10n.allRulesDisabled)
    }
    
    @Test func configurationSummaryShowsEnabledCount() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let rule1 = TimeRule(
            name: "Rule 1",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        let rule2 = TimeRule(
            name: "Rule 2",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 0),
            stationId: "70541",
            direction: .mountainView,
            isEnabled: true
        )
        mockStorageService.timeRules = [rule1, rule2]
        mockStorageService.isTimeRuleEnabled = true
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.configurationSummary == L10n.rulesEnabled(2))
    }
}

// MARK: - Validation Tests

@MainActor
struct TimeRuleViewModelValidationTests {
    
    @Test func isValidRuleNameReturnsTrueForValidName() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.isValidRuleName("Morning Commute") == true)
    }
    
    @Test func isValidRuleNameReturnsFalseForEmptyName() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.isValidRuleName("") == false)
        #expect(viewModel.isValidRuleName("   ") == false)
    }
    
    @Test func isValidStationIdReturnsTrueForValidId() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        // Mountain View station's primary ID is its eastboundId "64786"
        #expect(viewModel.isValidStationId("64786") == true) // Mountain View
    }
    
    @Test func isValidStationIdReturnsFalseForInvalidId() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.isValidStationId("invalid-id") == false)
    }
    
    @Test func hasConflictingRuleReturnsTrueWhenConflictExists() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let existingRule = TimeRule(
            name: "Existing Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [existingRule]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        let conflictingTime = TimeRule.createTriggerTime(hour: 7, minute: 30)
        #expect(viewModel.hasConflictingRule(triggerTime: conflictingTime) == true)
    }
    
    @Test func hasConflictingRuleReturnsFalseWhenNoConflict() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let existingRule = TimeRule(
            name: "Existing Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [existingRule]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        let nonConflictingTime = TimeRule.createTriggerTime(hour: 8, minute: 0)
        #expect(viewModel.hasConflictingRule(triggerTime: nonConflictingTime) == false)
    }
    
    @Test func hasConflictingRuleExcludesSpecifiedRule() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let existingRule = TimeRule(
            name: "Existing Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [existingRule]
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        // When updating the same rule, it should not conflict with itself
        let sameTime = TimeRule.createTriggerTime(hour: 7, minute: 30)
        #expect(viewModel.hasConflictingRule(triggerTime: sameTime, excludingRuleId: existingRule.id) == false)
    }
}

// MARK: - Refresh Tests

@MainActor
struct TimeRuleViewModelRefreshTests {
    
    @Test func refreshReloadsRulesFromStorage() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        // Initial load count
        let initialLoadCount = mockStorageService.loadCallCount
        
        // Add a rule directly to storage (simulating external change)
        let newRule = TimeRule(
            name: "New Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 9, minute: 0),
            stationId: "70281",
            direction: .alumRock,
            isEnabled: true
        )
        mockStorageService.timeRules = [newRule]
        
        viewModel.refresh()
        
        #expect(mockStorageService.loadCallCount == initialLoadCount + 1)
        #expect(viewModel.timeRules.count == 1)
        #expect(viewModel.timeRules[0].name == "New Rule")
    }
}

// MARK: - Current Active Rule Tests

@MainActor
struct TimeRuleViewModelCurrentActiveRuleTests {
    
    @Test func currentActiveRuleReturnsActiveRule() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        let activeRule = TimeRule(
            name: "Active Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        mockTimeRuleService.mockActiveRule = activeRule
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.currentActiveRule?.id == activeRule.id)
    }
    
    @Test func currentActiveRuleReturnsNilWhenNoActiveRule() {
        let mockStorageService = TimeRuleViewModelMockStorageService()
        let mockTimeRuleService = TimeRuleViewModelMockTimeRuleService()
        
        mockTimeRuleService.mockActiveRule = nil
        
        let viewModel = TimeRuleViewModel(
            timeRuleService: mockTimeRuleService,
            storageService: mockStorageService
        )
        
        #expect(viewModel.currentActiveRule == nil)
    }
}
