//
//  Station.swift
//  OrangeLineTracker Watch App
//
//  VTA Orange Line station model
//

import Foundation

/// Represents a VTA Orange Line station
/// VTA uses different platform IDs for each direction at each station
/// - Validates: Requirements 1.1, 1.3, 1.5
struct Station: Identifiable, Codable, Equatable {
    /// Unique identifier for the station (uses eastbound ID as primary)
    var id: String { eastboundId }
    
    /// Station ID for Eastbound platform (towards Alum Rock)
    let eastboundId: String
    
    /// Station ID for Westbound platform (towards Mountain View)
    let westboundId: String
    
    /// Full station name
    let name: String
    
    /// Short name/abbreviation for watch face display
    let shortName: String
    
    /// Sort order (geographic order from Mountain View to Alum Rock)
    let order: Int
    
    /// Returns the correct station ID for the given direction
    /// - Parameter direction: The travel direction
    /// - Returns: The platform ID for that direction
    func stationId(for direction: Direction) -> String {
        switch direction {
        case .alumRock:
            return eastboundId  // Eastbound platform for Alum Rock direction
        case .mountainView:
            return westboundId  // Westbound platform for Mountain View direction
        }
    }
}

/// Static data containing all VTA Orange Line stations
/// Stations are ordered geographically from Mountain View (order=0) to Alum Rock (order=27)
/// Station IDs are from 511.org SIRI API - each station has two platform IDs for different directions
enum OrangeLineStations {
    /// All 28 Orange Line stations in geographic order (correct 511.org stop codes)
    /// Each station has separate eastbound and westbound platform IDs
    static let stations: [Station] = [
        Station(eastboundId: "64786", westboundId: "64821", name: "Mountain View", shortName: "MTV", order: 0),
        Station(eastboundId: "64788", westboundId: "64819", name: "Whisman", shortName: "WSM", order: 1),
        Station(eastboundId: "64789", westboundId: "64818", name: "Middlefield", shortName: "MDF", order: 2),
        Station(eastboundId: "64790", westboundId: "64817", name: "Bayshore/NASA", shortName: "NASA", order: 3),
        Station(eastboundId: "65024", westboundId: "65025", name: "Moffett Park", shortName: "MFT", order: 4),
        Station(eastboundId: "64791", westboundId: "64816", name: "Lockheed Martin", shortName: "LMT", order: 5),
        Station(eastboundId: "64792", westboundId: "64815", name: "Borregas", shortName: "BRG", order: 6),
        Station(eastboundId: "64793", westboundId: "64814", name: "Crossman", shortName: "CRS", order: 7),
        Station(eastboundId: "64794", westboundId: "64813", name: "Fair Oaks", shortName: "FOK", order: 8),
        Station(eastboundId: "64795", westboundId: "64812", name: "Vienna", shortName: "VNA", order: 9),
        Station(eastboundId: "64796", westboundId: "64811", name: "Reamwood", shortName: "RWD", order: 10),
        Station(eastboundId: "64797", westboundId: "64810", name: "Old Ironsides", shortName: "OIS", order: 11),
        Station(eastboundId: "64798", westboundId: "64809", name: "Great America", shortName: "GAM", order: 12),
        Station(eastboundId: "64799", westboundId: "64808", name: "Lick Mill", shortName: "LML", order: 13),
        Station(eastboundId: "64800", westboundId: "64807", name: "Champion", shortName: "CHP", order: 14),
        Station(eastboundId: "64801", westboundId: "64806", name: "Baypointe", shortName: "BPT", order: 15),
        Station(eastboundId: "64802", westboundId: "64805", name: "Cisco Way", shortName: "CSC", order: 16),
        Station(eastboundId: "64758", westboundId: "64759", name: "River Oaks", shortName: "ROK", order: 17),
        Station(eastboundId: "64762", westboundId: "64763", name: "Tasman", shortName: "TSM", order: 18),
        Station(eastboundId: "64764", westboundId: "64765", name: "Orchard", shortName: "ORC", order: 19),
        Station(eastboundId: "64803", westboundId: "64804", name: "Alder", shortName: "ALD", order: 20),
        Station(eastboundId: "65235", westboundId: "65250", name: "Great Mall", shortName: "GML", order: 21),
        Station(eastboundId: "65236", westboundId: "65249", name: "Milpitas", shortName: "MLP", order: 22),
        Station(eastboundId: "65237", westboundId: "65248", name: "Cropley", shortName: "CRP", order: 23),
        Station(eastboundId: "65238", westboundId: "65247", name: "Hostetter", shortName: "HST", order: 24),
        Station(eastboundId: "65239", westboundId: "65246", name: "Berryessa", shortName: "BRY", order: 25),
        Station(eastboundId: "65240", westboundId: "65245", name: "Penitencia Creek", shortName: "PNC", order: 26),
        Station(eastboundId: "65242", westboundId: "65243", name: "Alum Rock", shortName: "ALR", order: 27)
    ]
    
    /// Total number of stations on the Orange Line
    static var count: Int {
        stations.count
    }
    
    /// Find a station by its ID (checks both eastbound and westbound IDs)
    /// - Parameter id: The station ID (511.org stop code)
    /// - Returns: The station if found, nil otherwise
    static func station(byId id: String) -> Station? {
        stations.first { $0.eastboundId == id || $0.westboundId == id }
    }
    
    /// Find a station by its order index
    /// - Parameter order: The order index (0-27)
    /// - Returns: The station if found, nil otherwise
    static func station(byOrder order: Int) -> Station? {
        stations.first { $0.order == order }
    }
    
    /// First station (Mountain View)
    static var first: Station {
        stations[0]
    }
    
    /// Last station (Alum Rock)
    static var last: Station {
        stations[stations.count - 1]
    }
}
