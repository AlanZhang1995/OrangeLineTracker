//
//  Prediction.swift
//  OrangeLineTracker Watch App
//
//  VTA Orange Line arrival prediction model
//

import Foundation

/// Represents the arrival status of a train
/// - Validates: Requirements 4.1, 4.2, 4.3, 4.4
enum ArrivalStatus: String, Codable, CaseIterable, Equatable {
    /// Train is arriving (即将到站)
    case arriving = "ARR"
    
    /// Train is boarding (进站中)
    case boarding = "BRD"
    
    /// Train is on schedule (按计划)
    case scheduled
    
    /// Train is delayed (延误)
    case delayed
    
    /// Human-readable display text for the status
    var displayText: String {
        switch self {
        case .arriving:
            return "即将到站"
        case .boarding:
            return "进站中"
        case .scheduled:
            return "按计划"
        case .delayed:
            return "延误"
        }
    }
    
    /// English display text for the status
    var displayTextEnglish: String {
        switch self {
        case .arriving:
            return "Arriving"
        case .boarding:
            return "Boarding"
        case .scheduled:
            return "Scheduled"
        case .delayed:
            return "Delayed"
        }
    }
}

/// Represents a train arrival prediction for a station
/// - Validates: Requirements 3.3, 3.5, 4.1, 4.2
struct Prediction: Identifiable, Codable, Equatable {
    /// Unique identifier for this prediction
    let id: UUID
    
    /// Minutes until the train arrives at the station (at the time of API fetch)
    /// - nil indicates the train is arriving now (即将到站)
    let minutesUntilArrival: Int?
    
    /// Current arrival status of the train
    let arrivalStatus: ArrivalStatus
    
    /// Destination station name (终点站)
    let destination: String
    
    /// Vehicle/train identifier (optional)
    let vehicleId: String?
    
    /// Timestamp when this prediction data was generated
    let timestamp: Date
    
    /// Creates a new Prediction instance
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - minutesUntilArrival: Minutes until arrival, nil for arriving now
    ///   - arrivalStatus: Current arrival status
    ///   - destination: Destination station name
    ///   - vehicleId: Optional vehicle identifier
    ///   - timestamp: Data timestamp (defaults to current date)
    init(
        id: UUID = UUID(),
        minutesUntilArrival: Int?,
        arrivalStatus: ArrivalStatus,
        destination: String,
        vehicleId: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.minutesUntilArrival = minutesUntilArrival
        self.arrivalStatus = arrivalStatus
        self.destination = destination
        self.vehicleId = vehicleId
        self.timestamp = timestamp
    }
    
    /// Calculates the current minutes until arrival based on elapsed time since fetch
    /// - Parameter currentTime: The current time to calculate against (defaults to now)
    /// - Returns: The adjusted minutes until arrival, accounting for time elapsed since API fetch
    func currentMinutesUntilArrival(at currentTime: Date = Date()) -> Int? {
        guard let originalMinutes = minutesUntilArrival else {
            return nil
        }
        
        // Calculate how many minutes have passed since the prediction was fetched
        let elapsedSeconds = currentTime.timeIntervalSince(timestamp)
        let elapsedMinutes = Int(elapsedSeconds / 60)
        
        // Subtract elapsed time from original prediction
        let adjustedMinutes = originalMinutes - elapsedMinutes
        
        // Don't return negative values
        return max(0, adjustedMinutes)
    }
    
    /// Formatted display string for arrival time (real-time countdown)
    /// Shows 1 minute less than actual to encourage users to leave early
    /// - Parameter currentTime: The current time to calculate against (defaults to now)
    /// - Returns: A string like "3 分钟", "即将到站", or "进站中"
    func arrivalTimeDisplay(at currentTime: Date = Date()) -> String {
        switch arrivalStatus {
        case .arriving:
            return LanguageService.shared.isEnglish ? ArrivalStatus.arriving.displayTextEnglish : ArrivalStatus.arriving.displayText
        case .boarding:
            return LanguageService.shared.isEnglish ? ArrivalStatus.boarding.displayTextEnglish : ArrivalStatus.boarding.displayText
        case .scheduled, .delayed:
            if let minutes = currentMinutesUntilArrival(at: currentTime) {
                // Subtract 1 minute to encourage users to leave early (better early than late)
                let displayMinutes = max(0, minutes - 1)
                if displayMinutes <= 0 {
                    return LanguageService.shared.isEnglish ? ArrivalStatus.arriving.displayTextEnglish : ArrivalStatus.arriving.displayText
                }
                return LanguageService.shared.isEnglish ? "\(displayMinutes) min" : "\(displayMinutes) 分钟"
            }
            return LanguageService.shared.isEnglish ? arrivalStatus.displayTextEnglish : arrivalStatus.displayText
        }
    }
    
    /// Formatted display string for arrival time in English (real-time countdown)
    /// Shows 1 minute less than actual to encourage users to leave early
    /// - Parameter currentTime: The current time to calculate against (defaults to now)
    /// - Returns: A string like "3 min", "Arriving", or "Boarding"
    func arrivalTimeDisplayEnglish(at currentTime: Date = Date()) -> String {
        switch arrivalStatus {
        case .arriving:
            return ArrivalStatus.arriving.displayTextEnglish
        case .boarding:
            return ArrivalStatus.boarding.displayTextEnglish
        case .scheduled, .delayed:
            if let minutes = currentMinutesUntilArrival(at: currentTime) {
                // Subtract 1 minute to encourage users to leave early (better early than late)
                let displayMinutes = max(0, minutes - 1)
                if displayMinutes <= 0 {
                    return ArrivalStatus.arriving.displayTextEnglish
                }
                return "\(displayMinutes) min"
            }
            return arrivalStatus.displayTextEnglish
        }
    }
    
    /// Static display string (for backward compatibility, uses original fetch time)
    var arrivalTimeDisplay: String {
        arrivalTimeDisplay(at: timestamp)
    }
    
    /// Static display string in English (for backward compatibility)
    var arrivalTimeDisplayEnglish: String {
        arrivalTimeDisplayEnglish(at: timestamp)
    }
    
    /// Full display text including destination (real-time countdown)
    /// - Parameter currentTime: The current time to calculate against (defaults to now)
    /// - Returns: A string like "3 分钟 → Alum Rock"
    func fullDisplayText(at currentTime: Date = Date()) -> String {
        "\(arrivalTimeDisplay(at: currentTime)) → \(destination)"
    }
    
    /// Full display text in English including destination (real-time countdown)
    /// - Parameter currentTime: The current time to calculate against (defaults to now)
    /// - Returns: A string like "3 min → Alum Rock"
    func fullDisplayTextEnglish(at currentTime: Date = Date()) -> String {
        "\(arrivalTimeDisplayEnglish(at: currentTime)) → \(destination)"
    }
    
    /// Static full display text (for backward compatibility)
    var fullDisplayText: String {
        fullDisplayText(at: timestamp)
    }
    
    /// Static full display text in English (for backward compatibility)
    var fullDisplayTextEnglish: String {
        fullDisplayTextEnglish(at: timestamp)
    }
    
    /// Checks if the prediction data is stale (older than 2 minutes)
    /// - Parameter referenceDate: The date to compare against (defaults to now)
    /// - Returns: true if the data is older than 2 minutes
    func isStale(referenceDate: Date = Date()) -> Bool {
        let staleDuration: TimeInterval = 2 * 60 // 2 minutes
        return referenceDate.timeIntervalSince(timestamp) > staleDuration
    }
}
