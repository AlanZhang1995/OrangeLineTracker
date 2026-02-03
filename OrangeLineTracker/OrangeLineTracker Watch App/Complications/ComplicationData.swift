//
//  ComplicationData.swift
//  OrangeLineTracker Watch App
//
//  Data model for watch face complications
//

import Foundation

/// Represents the data needed for watch face complications
/// - Validates: Requirements 9.2, 9.6
struct ComplicationData: Codable, Equatable {
    /// Station short name/abbreviation (e.g., "MTV" for Mountain View)
    let stationShortName: String
    
    /// Minutes until the next train arrives
    /// - nil indicates the train is arriving now or data is unavailable
    let minutesUntilArrival: Int?
    
    /// Travel direction
    let direction: Direction
    
    /// Timestamp when this data was last updated
    let lastUpdated: Date
    
    /// Creates a new ComplicationData instance
    /// - Parameters:
    ///   - stationShortName: Station abbreviation for display
    ///   - minutesUntilArrival: Minutes until arrival, nil for arriving now
    ///   - direction: Travel direction
    ///   - lastUpdated: Data timestamp (defaults to current date)
    init(
        stationShortName: String,
        minutesUntilArrival: Int?,
        direction: Direction,
        lastUpdated: Date = Date()
    ) {
        self.stationShortName = stationShortName
        self.minutesUntilArrival = minutesUntilArrival
        self.direction = direction
        self.lastUpdated = lastUpdated
    }
    
    // MARK: - Display Text Properties
    
    /// Short display text for arrival time
    /// - Returns: A string like "3m", "ARR" for arriving, or "--" for no data/error
    /// - Validates: Requirements 9.2, 9.7
    var displayText: String {
        // Check for error state first - show "--" for no data
        // Validates: Requirement 9.7 - show "--" when no data
        if isErrorState {
            return Self.noDataDisplayText
        }
        
        guard let minutes = minutesUntilArrival else {
            return "ARR"  // 即将到站 (Arriving)
        }
        if minutes <= 0 {
            return "ARR"
        }
        return "\(minutes)m"
    }
    
    /// Display text with stale indicator if data is old
    /// - Parameter maxAge: Maximum age before showing stale indicator (default: 5 minutes)
    /// - Returns: Display text with "⚠" prefix if stale
    /// - Validates: Requirement 9.7 - show stale indicator for cached data
    func displayTextWithStaleIndicator(maxAge: TimeInterval = 5 * 60) -> String {
        if isStale(maxAge: maxAge) {
            return "⚠\(displayText)"
        }
        return displayText
    }
    
    /// Full display text with stale indicator if data is old
    /// - Parameter maxAge: Maximum age before showing stale indicator (default: 5 minutes)
    /// - Returns: Full display text with "⚠" prefix if stale
    /// - Validates: Requirement 9.7 - show stale indicator for cached data
    func fullDisplayTextWithStaleIndicator(maxAge: TimeInterval = 5 * 60) -> String {
        if isStale(maxAge: maxAge) {
            return "⚠\(fullDisplayText)"
        }
        return fullDisplayText
    }
    
    /// Full display text including station abbreviation
    /// - Returns: A string like "MTV 3m" or "MTV ARR" or "-- --" for error
    /// - Validates: Requirements 9.2, 9.6, 9.7
    var fullDisplayText: String {
        "\(stationShortName) \(displayText)"
    }
    
    /// Detailed display text for larger complications
    /// - Returns: A string like "Mountain View 3 min" or "--" for error
    /// - Validates: Requirement 9.7
    var detailedDisplayText: String {
        // Check for error state first
        if isErrorState {
            return Self.noDataDisplayText
        }
        
        guard let minutes = minutesUntilArrival else {
            return "Arriving"
        }
        if minutes <= 0 {
            return "Arriving"
        }
        return "\(minutes) min"
    }
    
    /// Detailed display text with stale indicator
    /// - Parameter maxAge: Maximum age before showing stale indicator (default: 5 minutes)
    /// - Returns: Detailed display text with "⚠" prefix if stale
    /// - Validates: Requirement 9.7 - show stale indicator for cached data
    func detailedDisplayTextWithStaleIndicator(maxAge: TimeInterval = 5 * 60) -> String {
        if isStale(maxAge: maxAge) {
            return "⚠\(detailedDisplayText)"
        }
        return detailedDisplayText
    }
    
    /// Display text with direction indicator
    /// - Returns: A string like "MTV→ALR 3m" or "-- --" for error
    var displayTextWithDirection: String {
        if isErrorState {
            return "\(Self.noDataDisplayText) \(Self.noDataDisplayText)"
        }
        let directionAbbrev = direction == .mountainView ? "MTV" : "ALR"
        return "\(stationShortName)→\(directionAbbrev) \(displayText)"
    }
    
    /// Display text with direction and stale indicator
    /// - Parameter maxAge: Maximum age before showing stale indicator (default: 5 minutes)
    /// - Returns: Display text with direction and "⚠" prefix if stale
    /// - Validates: Requirement 9.7 - show stale indicator for cached data
    func displayTextWithDirectionAndStaleIndicator(maxAge: TimeInterval = 5 * 60) -> String {
        if isStale(maxAge: maxAge) {
            return "⚠\(displayTextWithDirection)"
        }
        return displayTextWithDirection
    }
    
    // MARK: - Data Freshness
    
    /// Checks if the data is stale (older than specified duration)
    /// - Parameter maxAge: Maximum age in seconds before data is considered stale (default: 5 minutes)
    /// - Returns: true if the data is older than maxAge
    func isStale(maxAge: TimeInterval = 5 * 60) -> Bool {
        Date().timeIntervalSince(lastUpdated) > maxAge
    }
    
    /// Age of the data in seconds
    var dataAge: TimeInterval {
        Date().timeIntervalSince(lastUpdated)
    }
    
    // MARK: - Error State Representation
    
    /// Creates a ComplicationData representing an error/no-data state
    /// - Parameters:
    ///   - stationShortName: Station abbreviation (defaults to "--")
    ///   - direction: Direction (defaults to .alumRock)
    /// - Returns: ComplicationData with nil minutesUntilArrival
    static func errorState(
        stationShortName: String = "--",
        direction: Direction = .alumRock
    ) -> ComplicationData {
        ComplicationData(
            stationShortName: stationShortName,
            minutesUntilArrival: nil,
            direction: direction,
            lastUpdated: Date()
        )
    }
    
    /// Display text for error state
    /// - Returns: "--" to indicate no data available
    /// - Validates: Requirement 9.7
    static let noDataDisplayText = "--"
    
    /// Checks if this represents an error/no-data state
    var isErrorState: Bool {
        stationShortName == "--" || stationShortName.isEmpty
    }
}

// MARK: - Factory Methods

extension ComplicationData {
    /// Creates ComplicationData from a Prediction and Station
    /// - Parameters:
    ///   - prediction: The arrival prediction
    ///   - station: The station
    ///   - direction: The travel direction
    /// - Returns: ComplicationData populated from the prediction
    static func from(
        prediction: Prediction,
        station: Station,
        direction: Direction
    ) -> ComplicationData {
        let minutes: Int?
        
        switch prediction.arrivalStatus {
        case .arriving, .boarding:
            minutes = nil  // Will display "ARR"
        case .scheduled, .delayed:
            minutes = prediction.minutesUntilArrival
        }
        
        return ComplicationData(
            stationShortName: station.shortName,
            minutesUntilArrival: minutes,
            direction: direction,
            lastUpdated: prediction.timestamp
        )
    }
    
    /// Creates ComplicationData from optional prediction data
    /// - Parameters:
    ///   - prediction: Optional arrival prediction
    ///   - station: Optional station
    ///   - direction: The travel direction
    /// - Returns: ComplicationData or error state if data is missing
    static func from(
        prediction: Prediction?,
        station: Station?,
        direction: Direction
    ) -> ComplicationData {
        guard let prediction = prediction, let station = station else {
            return errorState(direction: direction)
        }
        return from(prediction: prediction, station: station, direction: direction)
    }
}
