//
//  TimeRule.swift
//  OrangeLineTracker Watch App
//
//  Time-based rule for automatic station and direction switching
//

import Foundation

/// Represents a time-based rule for automatically switching line, station and direction
/// - Validates: Requirements 8.1, 8.2, 8.4
struct TimeRule: Identifiable, Equatable {
    /// Unique identifier for the rule
    let id: UUID
    
    /// Human-readable name for the rule (e.g., "Morning Commute", "Evening Return")
    var name: String
    
    /// The time at which this rule should trigger (only hour and minute are used)
    var triggerTime: Date
    
    /// The line ID to switch to when this rule triggers
    /// Defaults to "Orange" for backward compatibility
    var lineId: String
    
    /// The station ID to switch to when this rule triggers
    var stationId: String
    
    /// The direction ID to switch to when this rule triggers
    /// Uses generic direction IDs (e.g., "E", "W", "N", "S") instead of Direction enum
    var directionId: String
    
    /// Whether this rule is currently enabled
    var isEnabled: Bool
    
    /// Creates a new TimeRule with the specified parameters
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - name: Human-readable name for the rule
    ///   - triggerTime: The time at which this rule should trigger
    ///   - lineId: The line ID to switch to (defaults to "Orange")
    ///   - stationId: The station ID to switch to
    ///   - directionId: The direction ID to switch to
    ///   - isEnabled: Whether this rule is enabled (defaults to true)
    init(
        id: UUID = UUID(),
        name: String,
        triggerTime: Date,
        lineId: String = "Orange",
        stationId: String,
        directionId: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.triggerTime = triggerTime
        self.lineId = lineId
        self.stationId = stationId
        self.directionId = directionId
        self.isEnabled = isEnabled
    }
    
    /// Backward-compatible initializer using Direction enum
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - name: Human-readable name for the rule
    ///   - triggerTime: The time at which this rule should trigger
    ///   - stationId: The station ID to switch to
    ///   - direction: The direction to switch to (converted to directionId)
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
        self.lineId = "Orange"  // Default to Orange Line for backward compatibility
        self.stationId = stationId
        self.directionId = direction.directionId
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
    
    /// Returns the Direction enum value for backward compatibility
    /// Maps directionId to Direction enum (only works for Orange Line E/W directions)
    var direction: Direction {
        switch directionId {
        case "W":
            return .mountainView
        case "E":
            return .alumRock
        default:
            // Default to Mountain View for unknown direction IDs
            return .mountainView
        }
    }
    
    /// Returns the station associated with this rule, if it exists
    /// Searches across all line station collections based on lineId
    var station: Station? {
        switch lineId {
        case "Orange":
            return OrangeLineStations.station(byId: stationId)
        case "Blue":
            return BlueLineStations.station(byId: stationId)
        case "Green":
            return GreenLineStations.station(byId: stationId)
        default:
            // Try Orange Line first for backward compatibility
            return OrangeLineStations.station(byId: stationId)
        }
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

// MARK: - Codable Implementation

extension TimeRule: Codable {
    /// Coding keys for encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case triggerTime
        case lineId
        case stationId
        case directionId
        case direction  // Legacy key for backward compatibility
        case isEnabled
    }
    
    /// Custom decoder to handle migration from old format
    /// - Old format: uses `direction` (Direction enum)
    /// - New format: uses `directionId` (String) and `lineId` (String)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode required fields
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        triggerTime = try container.decode(Date.self, forKey: .triggerTime)
        stationId = try container.decode(String.self, forKey: .stationId)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        
        // Handle lineId - default to "Orange" if not present (migration from v1)
        lineId = try container.decodeIfPresent(String.self, forKey: .lineId) ?? "Orange"
        
        // Handle direction migration
        // Try to decode new format (directionId) first
        if let decodedDirectionId = try container.decodeIfPresent(String.self, forKey: .directionId) {
            directionId = decodedDirectionId
        } else if let legacyDirection = try container.decodeIfPresent(Direction.self, forKey: .direction) {
            // Fall back to old format (Direction enum) and convert to directionId
            directionId = legacyDirection.directionId
        } else {
            // Default to Eastbound if neither is present
            directionId = "E"
        }
    }
    
    /// Custom encoder - always uses new format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(triggerTime, forKey: .triggerTime)
        try container.encode(lineId, forKey: .lineId)
        try container.encode(stationId, forKey: .stationId)
        try container.encode(directionId, forKey: .directionId)
        try container.encode(isEnabled, forKey: .isEnabled)
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
