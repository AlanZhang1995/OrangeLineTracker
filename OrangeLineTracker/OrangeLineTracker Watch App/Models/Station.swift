//
//  Station.swift
//  OrangeLineTracker Watch App
//
//  VTA Orange Line station model
//

import Foundation

/// Represents a VTA Orange Line station
/// - Validates: Requirements 1.1, 1.3, 1.5
struct Station: Identifiable, Codable, Equatable {
    /// Station ID (511.org stop code)
    let id: String
    
    /// Full station name
    let name: String
    
    /// Short name/abbreviation for watch face display
    let shortName: String
    
    /// Sort order (geographic order from Mountain View to Alum Rock)
    let order: Int
}

/// Static data containing all VTA Orange Line stations
/// Stations are ordered geographically from Mountain View (order=0) to Alum Rock (order=27)
/// Station IDs are from 511.org SIRI API - each station has two platform IDs for different directions
enum OrangeLineStations {
    /// All 28 Orange Line stations in geographic order (correct 511.org stop codes)
    static let stations: [Station] = [
        Station(id: "64786", name: "Mountain View", shortName: "MTV", order: 0),
        Station(id: "64819", name: "Whisman", shortName: "WSM", order: 1),
        Station(id: "64789", name: "Middlefield", shortName: "MDF", order: 2),
        Station(id: "64790", name: "Bayshore/NASA", shortName: "NASA", order: 3),
        Station(id: "65024", name: "Moffett Park", shortName: "MFT", order: 4),
        Station(id: "64791", name: "Lockheed Martin", shortName: "LMT", order: 5),
        Station(id: "64815", name: "Borregas", shortName: "BRG", order: 6),
        Station(id: "64814", name: "Crossman", shortName: "CRS", order: 7),
        Station(id: "64813", name: "Fair Oaks", shortName: "FOK", order: 8),
        Station(id: "64812", name: "Vienna", shortName: "VNA", order: 9),
        Station(id: "64796", name: "Reamwood", shortName: "RWD", order: 10),
        Station(id: "64797", name: "Old Ironsides", shortName: "OIS", order: 11),
        Station(id: "64798", name: "Great America", shortName: "GAM", order: 12),
        Station(id: "64808", name: "Lick Mill", shortName: "LML", order: 13),
        Station(id: "64807", name: "Champion", shortName: "CHP", order: 14),
        Station(id: "64801", name: "Baypointe", shortName: "BPT", order: 15),
        Station(id: "64802", name: "Cisco Way", shortName: "CSC", order: 16),
        Station(id: "64758", name: "River Oaks", shortName: "ROK", order: 17),
        Station(id: "64762", name: "Tasman", shortName: "TSM", order: 18),
        Station(id: "64764", name: "Orchard", shortName: "ORC", order: 19),
        Station(id: "64803", name: "Alder", shortName: "ALD", order: 20),
        Station(id: "65235", name: "Great Mall", shortName: "GML", order: 21),
        Station(id: "65236", name: "Milpitas", shortName: "MLP", order: 22),
        Station(id: "65237", name: "Cropley", shortName: "CRP", order: 23),
        Station(id: "65238", name: "Hostetter", shortName: "HST", order: 24),
        Station(id: "65239", name: "Berryessa", shortName: "BRY", order: 25),
        Station(id: "65240", name: "Penitencia Creek", shortName: "PNC", order: 26),
        Station(id: "65243", name: "Alum Rock", shortName: "ALR", order: 27)
    ]
    
    /// Total number of stations on the Orange Line
    static var count: Int {
        stations.count
    }
    
    /// Find a station by its ID
    /// - Parameter id: The station ID (511.org stop code)
    /// - Returns: The station if found, nil otherwise
    static func station(byId id: String) -> Station? {
        stations.first { $0.id == id }
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
