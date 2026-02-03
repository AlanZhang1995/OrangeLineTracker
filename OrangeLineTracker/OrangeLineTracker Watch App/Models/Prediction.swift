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
    
    /// Minutes until the train arrives at the station
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
    
    /// Formatted display string for arrival time
    /// - Returns: A string like "3 分钟", "即将到站", or "进站中"
    var arrivalTimeDisplay: String {
        switch arrivalStatus {
        case .arriving:
            return ArrivalStatus.arriving.displayText
        case .boarding:
            return ArrivalStatus.boarding.displayText
        case .scheduled, .delayed:
            if let minutes = minutesUntilArrival {
                if minutes <= 0 {
                    return ArrivalStatus.arriving.displayText
                }
                return "\(minutes) 分钟"
            }
            return arrivalStatus.displayText
        }
    }
    
    /// Formatted display string for arrival time in English
    /// - Returns: A string like "3 min", "Arriving", or "Boarding"
    var arrivalTimeDisplayEnglish: String {
        switch arrivalStatus {
        case .arriving:
            return ArrivalStatus.arriving.displayTextEnglish
        case .boarding:
            return ArrivalStatus.boarding.displayTextEnglish
        case .scheduled, .delayed:
            if let minutes = minutesUntilArrival {
                if minutes <= 0 {
                    return ArrivalStatus.arriving.displayTextEnglish
                }
                return "\(minutes) min"
            }
            return arrivalStatus.displayTextEnglish
        }
    }
    
    /// Full display text including destination
    /// - Returns: A string like "3 分钟 → Alum Rock"
    var fullDisplayText: String {
        "\(arrivalTimeDisplay) → \(destination)"
    }
    
    /// Full display text in English including destination
    /// - Returns: A string like "3 min → Alum Rock"
    var fullDisplayTextEnglish: String {
        "\(arrivalTimeDisplayEnglish) → \(destination)"
    }
    
    /// Checks if the prediction data is stale (older than 2 minutes)
    /// - Parameter referenceDate: The date to compare against (defaults to now)
    /// - Returns: true if the data is older than 2 minutes
    func isStale(referenceDate: Date = Date()) -> Bool {
        let staleDuration: TimeInterval = 2 * 60 // 2 minutes
        return referenceDate.timeIntervalSince(timestamp) > staleDuration
    }
}
