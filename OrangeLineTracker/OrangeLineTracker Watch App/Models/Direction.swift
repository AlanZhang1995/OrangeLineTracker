//
//  Direction.swift
//  OrangeLineTracker Watch App
//
//  VTA Orange Line direction enumeration
//

import Foundation

/// Represents the travel direction on the VTA Orange Line
/// - Validates: Requirements 2.1, 2.4
enum Direction: String, Codable, CaseIterable {
    /// Inbound direction towards Mountain View
    case mountainView = "Mountain View"
    
    /// Outbound direction towards Alum Rock
    case alumRock = "Alum Rock"
    
    /// Human-readable display name for the direction
    /// Returns the raw value which is the destination name
    var displayName: String {
        rawValue
    }
    
    /// Direction ID used by the VTA API
    /// - "W" for Westbound (Mountain View direction)
    /// - "E" for Eastbound (Alum Rock direction)
    var directionId: String {
        switch self {
        case .mountainView:
            return "W"  // Westbound
        case .alumRock:
            return "E"  // Eastbound
        }
    }
}
