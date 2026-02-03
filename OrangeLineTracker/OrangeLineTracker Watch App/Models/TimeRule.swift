//
//  TimeRule.swift
//  OrangeLineTracker Watch App
//
//  Time-based rule for automatic station and direction switching
//

import Foundation

/// Represents a time-based rule for automatically switching station and direction
/// - Validates: Requirements 8.1, 8.2
struct TimeRule: Identifiable, Codable, Equatable {
    /// Unique identifier for the rule
    let id: UUID
    
    /// Human-readable name for the rule (e.g., "Morning Commute", "Evening Return")
    var name: String
    
    /// The time at which this rule should trigger (only hour and minute are used)
    var triggerTime: Date
    
    /// The station ID to switch to when this rule triggers
    var stationId: String
    
    /// The direction to switch to when this rule triggers
    var direction: Direction
    
    /// Whether this rule is currently enabled
    var isEnabled: Bool
    
    /// Creates a new TimeRule with the specified parameters
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - name: Human-readable name for the rule
    ///   - triggerTime: The time at which this rule should trigger
    ///   - stationId: The station ID to switch to
    ///   - direction: The direction to switch to
    ///   - isEnabled: Whether this rule is enabled (defaults to true)
    init(
        id: UUID = UUID(),
        name: String,
        triggerTime: Date,
        stationId: String,
        direction: Direction,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.triggerTime = triggerTime
        self.stationId = stationId
        self.direction = direction
        self.isEnabled = isEnabled
    }
    
    // MARK: - Computed Properties
    
    /// Extracts the hour component from the trigger time
    var triggerHour: Int {
        Calendar.current.component(.hour, from: triggerTime)
    }
    
    /// Extracts the minute component from the trigger time
    var triggerMinute: Int {
        Calendar.current.component(.minute, from: triggerTime)
    }
    
    /// Returns a formatted string representation of the trigger time (HH:mm)
    var triggerTimeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: triggerTime)
    }
    
    /// Returns the station associated with this rule, if it exists
    var station: Station? {
        OrangeLineStations.station(byId: stationId)
    }
    
    // MARK: - Time Matching
    
    /// Checks if the given date matches this rule's trigger time (hour and minute only)
    /// - Parameter date: The date to check against
    /// - Returns: true if the hour and minute match the trigger time
    func matchesTime(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateHour = calendar.component(.hour, from: date)
        let dateMinute = calendar.component(.minute, from: date)
        
        return dateHour == triggerHour && dateMinute == triggerMinute
    }
    
    /// Checks if this rule should be triggered at the given date
    /// - Parameter date: The date to check against
    /// - Returns: true if the rule is enabled and the time matches
    func shouldTrigger(at date: Date) -> Bool {
        isEnabled && matchesTime(date)
    }
}

// MARK: - TimeRule Helpers

extension TimeRule {
    /// Creates a trigger time Date from hour and minute components
    /// - Parameters:
    ///   - hour: The hour component (0-23)
    ///   - minute: The minute component (0-59)
    /// - Returns: A Date with the specified hour and minute (other components are set to current date)
    static func createTriggerTime(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
