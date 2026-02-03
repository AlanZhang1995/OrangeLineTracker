//
//  TimeRuleViewModel.swift
//  OrangeLineTracker Watch App
//
//  ViewModel for managing time-based rules for automatic station and direction switching
//

import Foundation
import Combine

// MARK: - TimeRuleViewModel

/// ViewModel for managing time rules in the OrangeLineTracker app
/// Coordinates between TimeRuleService, StorageService, and views
/// - Validates: Requirements 8.1, 8.2, 8.6
@MainActor
class TimeRuleViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The list of all configured time rules
    /// - Validates: Requirements 8.1, 8.2
    @Published var timeRules: [TimeRule] = []
    
    /// Whether the global time rule feature is enabled
    /// - Validates: Requirements 8.6
    @Published var isTimeRuleEnabled: Bool = false
    
    /// Error message to display to the user, nil if no error
    @Published var errorMessage: String?
    
    /// Whether a save operation is in progress
    @Published var isSaving: Bool = false
    
    // MARK: - Private Properties
    
    /// Service for managing time rules
    private let timeRuleService: TimeRuleServiceProtocol
    
    /// Service for persisting preferences
    private var storageService: StorageServiceProtocol
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Creates a new TimeRuleViewModel instance
    /// - Parameters:
    ///   - timeRuleService: Service for managing time rules
    ///   - storageService: Service for persisting preferences
    init(
        timeRuleService: TimeRuleServiceProtocol,
        storageService: StorageServiceProtocol
    ) {
        self.timeRuleService = timeRuleService
        self.storageService = storageService
        
        // Load existing rules and settings
        loadRules()
    }
    
    // MARK: - CRUD Operations
    
    /// Adds a new time rule
    /// - Parameter rule: The TimeRule to add
    /// - Validates: Requirements 8.1, 8.2
    func addRule(_ rule: TimeRule) {
        isSaving = true
        errorMessage = nil
        
        timeRuleService.addRule(rule)
        loadRules()
        
        isSaving = false
    }
    
    /// Creates and adds a new time rule with the specified parameters
    /// - Parameters:
    ///   - name: Human-readable name for the rule
    ///   - triggerTime: The time at which this rule should trigger
    ///   - stationId: The station ID to switch to
    ///   - direction: The direction to switch to
    ///   - isEnabled: Whether this rule is enabled (defaults to true)
    /// - Returns: The created TimeRule
    /// - Validates: Requirements 8.1, 8.2
    @discardableResult
    func createRule(
        name: String,
        triggerTime: Date,
        stationId: String,
        direction: Direction,
        isEnabled: Bool = true
    ) -> TimeRule {
        let rule = TimeRule(
            name: name,
            triggerTime: triggerTime,
            stationId: stationId,
            direction: direction,
            isEnabled: isEnabled
        )
        
        addRule(rule)
        return rule
    }
    
    /// Updates an existing time rule
    /// - Parameter rule: The TimeRule with updated values (matched by id)
    /// - Validates: Requirements 8.1, 8.2
    func updateRule(_ rule: TimeRule) {
        isSaving = true
        errorMessage = nil
        
        timeRuleService.updateRule(rule)
        loadRules()
        
        isSaving = false
    }
    
    /// Deletes a time rule
    /// - Parameter rule: The TimeRule to delete (matched by id)
    /// - Validates: Requirements 8.1
    func deleteRule(_ rule: TimeRule) {
        isSaving = true
        errorMessage = nil
        
        timeRuleService.deleteRule(rule)
        loadRules()
        
        isSaving = false
    }
    
    /// Deletes time rules at the specified offsets
    /// - Parameter offsets: The index set of rules to delete
    /// - Validates: Requirements 8.1
    func deleteRules(at offsets: IndexSet) {
        let rulesToDelete = offsets.map { timeRules[$0] }
        for rule in rulesToDelete {
            deleteRule(rule)
        }
    }
    
    // MARK: - Enable/Disable Operations
    
    /// Toggles the enabled state of a specific rule
    /// - Parameter rule: The TimeRule to toggle
    /// - Validates: Requirements 8.6
    func toggleRuleEnabled(_ rule: TimeRule) {
        var updatedRule = rule
        updatedRule.isEnabled.toggle()
        updateRule(updatedRule)
    }
    
    /// Sets the enabled state of a specific rule
    /// - Parameters:
    ///   - rule: The TimeRule to update
    ///   - isEnabled: The new enabled state
    /// - Validates: Requirements 8.6
    func setRuleEnabled(_ rule: TimeRule, isEnabled: Bool) {
        guard rule.isEnabled != isEnabled else { return }
        
        var updatedRule = rule
        updatedRule.isEnabled = isEnabled
        updateRule(updatedRule)
    }
    
    /// Toggles the global time rule feature
    /// - Validates: Requirements 8.6
    func toggleGlobalTimeRuleEnabled() {
        setGlobalTimeRuleEnabled(!isTimeRuleEnabled)
    }
    
    /// Sets the global time rule enabled state
    /// - Parameter enabled: Whether time rules should be enabled globally
    /// - Validates: Requirements 8.6
    func setGlobalTimeRuleEnabled(_ enabled: Bool) {
        isSaving = true
        errorMessage = nil
        
        storageService.isTimeRuleEnabled = enabled
        storageService.save()
        isTimeRuleEnabled = enabled
        
        isSaving = false
    }
    
    // MARK: - Data Loading
    
    /// Loads rules and settings from storage
    private func loadRules() {
        storageService.load()
        timeRules = storageService.timeRules
        isTimeRuleEnabled = storageService.isTimeRuleEnabled
    }
    
    /// Refreshes the rules from storage
    func refresh() {
        loadRules()
    }
    
    // MARK: - Computed Properties
    
    /// Returns the number of configured rules
    var ruleCount: Int {
        timeRules.count
    }
    
    /// Returns whether there are any configured rules
    var hasRules: Bool {
        !timeRules.isEmpty
    }
    
    /// Returns the number of enabled rules
    var enabledRuleCount: Int {
        timeRules.filter { $0.isEnabled }.count
    }
    
    /// Returns all enabled rules
    var enabledRules: [TimeRule] {
        timeRules.filter { $0.isEnabled }
    }
    
    /// Returns all disabled rules
    var disabledRules: [TimeRule] {
        timeRules.filter { !$0.isEnabled }
    }
    
    /// Returns rules sorted by trigger time
    var rulesSortedByTime: [TimeRule] {
        timeRules.sorted { rule1, rule2 in
            let time1 = rule1.triggerHour * 60 + rule1.triggerMinute
            let time2 = rule2.triggerHour * 60 + rule2.triggerMinute
            return time1 < time2
        }
    }
    
    /// Returns whether the time rule feature is effectively active
    /// (globally enabled and has at least one enabled rule)
    var isTimeRuleActive: Bool {
        isTimeRuleEnabled && enabledRuleCount > 0
    }
    
    /// Returns a summary string for the current time rule configuration
    var configurationSummary: String {
        if !isTimeRuleEnabled {
            return "时间规则已禁用"
        }
        
        if timeRules.isEmpty {
            return "未配置规则"
        }
        
        let enabledCount = enabledRuleCount
        if enabledCount == 0 {
            return "所有规则已禁用"
        }
        
        return "\(enabledCount) 条规则已启用"
    }
    
    /// Returns the currently active rule based on the current time
    var currentActiveRule: TimeRule? {
        timeRuleService.getCurrentActiveRule()
    }
    
    // MARK: - Validation
    
    /// Validates a rule name
    /// - Parameter name: The name to validate
    /// - Returns: true if the name is valid
    func isValidRuleName(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Validates a station ID
    /// - Parameter stationId: The station ID to validate
    /// - Returns: true if the station ID is valid
    func isValidStationId(_ stationId: String) -> Bool {
        OrangeLineStations.station(byId: stationId) != nil
    }
    
    /// Checks if a rule with the same trigger time already exists
    /// - Parameters:
    ///   - triggerTime: The trigger time to check
    ///   - excludingRuleId: Optional rule ID to exclude from the check (for updates)
    /// - Returns: true if a conflicting rule exists
    func hasConflictingRule(triggerTime: Date, excludingRuleId: UUID? = nil) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: triggerTime)
        let minute = calendar.component(.minute, from: triggerTime)
        
        return timeRules.contains { rule in
            if let excludeId = excludingRuleId, rule.id == excludeId {
                return false
            }
            return rule.triggerHour == hour && rule.triggerMinute == minute
        }
    }
}

// MARK: - Convenience Initializer

extension TimeRuleViewModel {
    /// Creates a TimeRuleViewModel with default services
    convenience init() {
        let storageService = StorageService()
        let timeRuleService = TimeRuleService(storageService: storageService)
        
        self.init(
            timeRuleService: timeRuleService,
            storageService: storageService
        )
    }
}

// MARK: - Preview Support

#if DEBUG
extension TimeRuleViewModel {
    /// Creates a TimeRuleViewModel with sample data for previews
    static var preview: TimeRuleViewModel {
        let viewModel = TimeRuleViewModel()
        
        // Add sample rules for preview
        viewModel.createRule(
            name: "早班通勤",
            triggerTime: TimeRule.createTriggerTime(hour: 7, minute: 30),
            stationId: "70261", // Mountain View
            direction: .alumRock,
            isEnabled: true
        )
        
        viewModel.createRule(
            name: "晚班回家",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 30),
            stationId: "70541", // Alum Rock
            direction: .mountainView,
            isEnabled: true
        )
        
        viewModel.setGlobalTimeRuleEnabled(true)
        
        return viewModel
    }
}
#endif
