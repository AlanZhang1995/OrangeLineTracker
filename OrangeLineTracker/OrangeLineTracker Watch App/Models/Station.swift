//
//  Station.swift
//  OrangeLineTracker Watch App
//
//  VTA station model supporting multiple lines
//

import Foundation

/// Represents a VTA station supporting multiple lines
/// VTA uses different platform IDs for each direction at each station
/// - Validates: Requirements 1.1, 1.2, 1.3, 1.5
struct Station: Identifiable, Codable, Equatable {
    /// Unique identifier for the station
    let id: String
    
    /// Line ID this station belongs to
    let lineId: String
    
    /// Full station name
    let name: String
    
    /// Short name/abbreviation for watch face display
    let shortName: String
    
    /// Sort order (geographic order on the line)
    let order: Int
    
    /// Platform IDs for each direction [directionId: platformId]
    let platformIds: [String: String]
    
    // MARK: - Backward Compatibility
    
    /// Station ID for Eastbound platform (towards Alum Rock) - backward compatibility
    var eastboundId: String {
        platformIds["E"] ?? id
    }
    
    /// Station ID for Westbound platform (towards Mountain View) - backward compatibility
    var westboundId: String {
        platformIds["W"] ?? id
    }
    
    // MARK: - Methods
    
    /// Returns the platform ID for the given direction ID
    /// - Parameter directionId: The direction ID (e.g., "E", "W", "N", "S")
    /// - Returns: The platform ID for that direction, or nil if not found
    func platformId(for directionId: String) -> String? {
        platformIds[directionId]
    }
    
    /// Returns the correct station ID for the given direction (backward compatibility)
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
    
    // MARK: - Initializers
    
    /// Full initializer with all fields
    init(id: String, lineId: String, name: String, shortName: String, order: Int, platformIds: [String: String]) {
        self.id = id
        self.lineId = lineId
        self.name = name
        self.shortName = shortName
        self.order = order
        self.platformIds = platformIds
    }
    
    /// Backward-compatible initializer using eastboundId/westboundId
    /// Creates a station for the Orange Line with E/W direction platform IDs
    init(eastboundId: String, westboundId: String, name: String, shortName: String, order: Int) {
        self.id = eastboundId  // Use eastboundId as primary ID for backward compatibility
        self.lineId = "Orange"  // Default to Orange Line
        self.name = name
        self.shortName = shortName
        self.order = order
        self.platformIds = [
            "E": eastboundId,  // Eastbound (Alum Rock direction)
            "W": westboundId   // Westbound (Mountain View direction)
        ]
    }
}

/// Static data containing all VTA Orange Line stations
/// Stations are ordered geographically from Mountain View (order=0) to Alum Rock (order=26)
/// Station IDs are from 511.org SIRI API - each station has two platform IDs for different directions
/// Orange Line: Mountain View ↔ Alum Rock (does NOT go through River Oaks, Tasman, Orchard)
enum OrangeLineStations {
    /// All Orange Line stations in geographic order (correct 511.org stop codes)
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
        Station(eastboundId: "64803", westboundId: "64804", name: "Alder", shortName: "ALD", order: 17),
        Station(eastboundId: "65235", westboundId: "65250", name: "Great Mall", shortName: "GML", order: 18),
        Station(eastboundId: "65236", westboundId: "65249", name: "Milpitas", shortName: "MLP", order: 19),
        Station(eastboundId: "65237", westboundId: "65248", name: "Cropley", shortName: "CRP", order: 20),
        Station(eastboundId: "65238", westboundId: "65247", name: "Hostetter", shortName: "HST", order: 21),
        Station(eastboundId: "65239", westboundId: "65246", name: "Berryessa", shortName: "BRY", order: 22),
        Station(eastboundId: "65240", westboundId: "65245", name: "Penitencia Creek", shortName: "PNC", order: 23),
        Station(eastboundId: "65241", westboundId: "65244", name: "McKee", shortName: "MCK", order: 24),
        Station(eastboundId: "65242", westboundId: "65243", name: "Alum Rock", shortName: "ALR", order: 25)
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

/// Static data containing all VTA Blue Line stations
/// Blue Line runs from Baypointe to Santa Teresa via Tasman branch
/// Station IDs are from 511.org SIRI API
enum BlueLineStations {
    /// All Blue Line stations in geographic order (North to South)
    /// Blue Line: Baypointe ↔ Santa Teresa (goes through Tasman, River Oaks, NOT through Old Ironsides/Great America)
    static let stations: [Station] = [
        Station(id: "64801", lineId: "Blue", name: "Baypointe", shortName: "BPT", order: 0, platformIds: ["N": "64801", "S": "64806"]),
        Station(id: "64762", lineId: "Blue", name: "Tasman", shortName: "TSM", order: 1, platformIds: ["N": "64762", "S": "64763"]),
        Station(id: "64758", lineId: "Blue", name: "River Oaks", shortName: "ROK", order: 2, platformIds: ["N": "64758", "S": "64759"]),
        Station(id: "64764", lineId: "Blue", name: "Orchard", shortName: "ORC", order: 3, platformIds: ["N": "64764", "S": "64765"]),
        Station(id: "64770", lineId: "Blue", name: "Bonaventura", shortName: "BNV", order: 4, platformIds: ["N": "64770", "S": "64771"]),
        Station(id: "64768", lineId: "Blue", name: "Component", shortName: "CMP", order: 5, platformIds: ["N": "64768", "S": "64769"]),
        Station(id: "64766", lineId: "Blue", name: "Karina", shortName: "KRN", order: 6, platformIds: ["N": "64766", "S": "64767"]),
        Station(id: "64772", lineId: "Blue", name: "Metro/Airport", shortName: "APT", order: 7, platformIds: ["N": "64772", "S": "64773"]),
        Station(id: "64774", lineId: "Blue", name: "Gish", shortName: "GSH", order: 8, platformIds: ["N": "64774", "S": "64775"]),
        Station(id: "64776", lineId: "Blue", name: "Civic Center", shortName: "CVC", order: 9, platformIds: ["N": "64776", "S": "64777"]),
        Station(id: "64778", lineId: "Blue", name: "Japantown/Ayer", shortName: "JPN", order: 10, platformIds: ["N": "64778", "S": "64779"]),
        Station(id: "64780", lineId: "Blue", name: "St. James", shortName: "STJ", order: 11, platformIds: ["N": "64780", "S": "64781"]),
        Station(id: "64782", lineId: "Blue", name: "Santa Clara", shortName: "STC", order: 12, platformIds: ["N": "64782", "S": "64783"]),
        Station(id: "64784", lineId: "Blue", name: "Paseo de San Antonio", shortName: "PSA", order: 13, platformIds: ["N": "64784", "S": "64785"]),
        Station(id: "64824", lineId: "Blue", name: "Convention Center", shortName: "CNV", order: 14, platformIds: ["N": "64824", "S": "64825"]),
        Station(id: "64848", lineId: "Blue", name: "Children's Discovery Museum", shortName: "CDM", order: 15, platformIds: ["N": "64848", "S": "64849"]),
        Station(id: "64828", lineId: "Blue", name: "Virginia", shortName: "VRG", order: 16, platformIds: ["N": "64828", "S": "64829"]),
        Station(id: "64830", lineId: "Blue", name: "Tamien", shortName: "TMN", order: 17, platformIds: ["N": "64830", "S": "64831"]),
        Station(id: "64832", lineId: "Blue", name: "Curtner", shortName: "CRT", order: 18, platformIds: ["N": "64832", "S": "64833"]),
        Station(id: "64834", lineId: "Blue", name: "Capitol", shortName: "CPT", order: 19, platformIds: ["N": "64834", "S": "64835"]),
        Station(id: "64836", lineId: "Blue", name: "Branham", shortName: "BRH", order: 20, platformIds: ["N": "64836", "S": "64837"]),
        Station(id: "64838", lineId: "Blue", name: "Ohlone/Chynoweth", shortName: "OHL", order: 21, platformIds: ["N": "64838", "S": "64839"]),
        Station(id: "64840", lineId: "Blue", name: "Blossom Hill", shortName: "BLH", order: 22, platformIds: ["N": "64840", "S": "64841"]),
        Station(id: "64842", lineId: "Blue", name: "Snell", shortName: "SNL", order: 23, platformIds: ["N": "64842", "S": "64843"]),
        Station(id: "64844", lineId: "Blue", name: "Cottle", shortName: "CTL", order: 24, platformIds: ["N": "64844", "S": "64845"]),
        Station(id: "64846", lineId: "Blue", name: "Santa Teresa", shortName: "STT", order: 25, platformIds: ["N": "64846", "S": "64847"])
    ]
    
    /// Total number of stations on the Blue Line
    static var count: Int {
        stations.count
    }
    
    /// Find a station by its ID
    static func station(byId id: String) -> Station? {
        stations.first { $0.id == id || $0.platformIds.values.contains(id) }
    }
    
    /// First station (Baypointe)
    static var first: Station {
        stations[0]
    }
    
    /// Last station (Santa Teresa)
    static var last: Station {
        stations[stations.count - 1]
    }
}

/// Static data containing all VTA Green Line stations
/// Green Line runs from Old Ironsides to Winchester via San Jose Diridon
/// Station IDs are from 511.org SIRI API
enum GreenLineStations {
    /// All Green Line stations in geographic order (North to South)
    /// Green Line: Old Ironsides ↔ Winchester (via Great America, Tasman branch, NOT through Lockheed Martin/Borregas)
    static let stations: [Station] = [
        // Old Ironsides through Champion use E/W platform IDs (shared with Orange Line)
        Station(id: "64797", lineId: "Green", name: "Old Ironsides", shortName: "OIS", order: 0, platformIds: ["N": "64797", "S": "64810"]),
        Station(id: "64798", lineId: "Green", name: "Great America", shortName: "GAM", order: 1, platformIds: ["N": "64798", "S": "64809"]),
        Station(id: "64799", lineId: "Green", name: "Lick Mill", shortName: "LML", order: 2, platformIds: ["N": "64799", "S": "64808"]),
        Station(id: "64800", lineId: "Green", name: "Champion", shortName: "CHP", order: 3, platformIds: ["N": "64800", "S": "64807"]),
        // Tasman branch uses N/S platform IDs
        Station(id: "64762", lineId: "Green", name: "Tasman", shortName: "TSM", order: 4, platformIds: ["N": "64762", "S": "64763"]),
        Station(id: "64758", lineId: "Green", name: "River Oaks", shortName: "ROK", order: 5, platformIds: ["N": "64758", "S": "64759"]),
        Station(id: "64764", lineId: "Green", name: "Orchard", shortName: "ORC", order: 6, platformIds: ["N": "64764", "S": "64765"]),
        Station(id: "64770", lineId: "Green", name: "Bonaventura", shortName: "BNV", order: 7, platformIds: ["N": "64770", "S": "64771"]),
        Station(id: "64768", lineId: "Green", name: "Component", shortName: "CMP", order: 8, platformIds: ["N": "64768", "S": "64769"]),
        Station(id: "64766", lineId: "Green", name: "Karina", shortName: "KRN", order: 9, platformIds: ["N": "64766", "S": "64767"]),
        Station(id: "64772", lineId: "Green", name: "Metro/Airport", shortName: "APT", order: 10, platformIds: ["N": "64772", "S": "64773"]),
        Station(id: "64774", lineId: "Green", name: "Gish", shortName: "GSH", order: 11, platformIds: ["N": "64774", "S": "64775"]),
        Station(id: "64776", lineId: "Green", name: "Civic Center", shortName: "CVC", order: 12, platformIds: ["N": "64776", "S": "64777"]),
        Station(id: "64778", lineId: "Green", name: "Japantown/Ayer", shortName: "JPN", order: 13, platformIds: ["N": "64778", "S": "64779"]),
        Station(id: "64780", lineId: "Green", name: "St. James", shortName: "STJ", order: 14, platformIds: ["N": "64780", "S": "64781"]),
        Station(id: "64782", lineId: "Green", name: "Santa Clara", shortName: "STC", order: 15, platformIds: ["N": "64782", "S": "64783"]),
        Station(id: "64784", lineId: "Green", name: "Paseo de San Antonio", shortName: "PSA", order: 16, platformIds: ["N": "64784", "S": "64785"]),
        Station(id: "64824", lineId: "Green", name: "Convention Center", shortName: "CNV", order: 17, platformIds: ["N": "64824", "S": "64825"]),
        Station(id: "64822", lineId: "Green", name: "San Fernando", shortName: "SFN", order: 18, platformIds: ["N": "64822", "S": "64823"]),
        Station(id: "64826", lineId: "Green", name: "San Jose Diridon", shortName: "SJD", order: 19, platformIds: ["N": "64826", "S": "64827"]),
        Station(id: "64850", lineId: "Green", name: "Race", shortName: "RCE", order: 20, platformIds: ["N": "64850", "S": "64851"]),
        Station(id: "64852", lineId: "Green", name: "Fruitdale", shortName: "FRD", order: 21, platformIds: ["N": "64852", "S": "64853"]),
        Station(id: "64854", lineId: "Green", name: "Bascom", shortName: "BSC", order: 22, platformIds: ["N": "64854", "S": "64855"]),
        Station(id: "64856", lineId: "Green", name: "Hamilton", shortName: "HML", order: 23, platformIds: ["N": "64856", "S": "64857"]),
        Station(id: "64858", lineId: "Green", name: "Downtown Campbell", shortName: "DTC", order: 24, platformIds: ["N": "64858", "S": "64859"]),
        Station(id: "64860", lineId: "Green", name: "Winchester", shortName: "WNC", order: 25, platformIds: ["N": "64860", "S": "64861"])
    ]
    
    /// Total number of stations on the Green Line
    static var count: Int {
        stations.count
    }
    
    /// Find a station by its ID
    static func station(byId id: String) -> Station? {
        stations.first { $0.id == id || $0.platformIds.values.contains(id) }
    }
    
    /// First station (Old Ironsides)
    static var first: Station {
        stations[0]
    }
    
    /// Last station (Winchester)
    static var last: Station {
        stations[stations.count - 1]
    }
}
