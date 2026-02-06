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
    /// Lazy-loaded stations array - only initialized when first accessed
    private static var _stations: [Station]?
    
    /// All Orange Line stations in geographic order (correct 511.org stop codes)
    /// Each station has separate eastbound and westbound platform IDs
    static var stations: [Station] {
        if _stations == nil {
            _stations = loadStations()
        }
        return _stations!
    }
    
    /// Loads Orange Line station data
    private static func loadStations() -> [Station] {
        [
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
    }
    
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
/// Station IDs are from 511.org GTFS data (stops.txt)
/// 
/// ============================================================================
/// 511.org API STOP_ID MAPPING (From GTFS - Verified 2026-02-05):
/// ============================================================================
/// 
/// CRITICAL: Each direction has its OWN unique stop_id sequence!
/// - Northbound (to Baypointe): 64801, 64759, 64758, 64757, ... 64736
/// - Southbound (to Santa Teresa): 64761, 64762, 64763, 64764, ... 64785
/// 
/// The stop_id automatically includes direction - querying 64751 returns
/// Northbound trains, querying 64770 returns Southbound trains.
/// 
/// API Testing Confirmed:
/// - 64751 (Civic Center N) → Returns Blue:N, Green:N trains ✓
/// - 64770 (Civic Center S) → Returns Blue:S, Green:S trains ✓
/// - 64746 (Convention Center N) → Returns N direction data ✓
/// - 64775 (Convention Center S) → Returns S direction data ✓
/// ============================================================================
enum BlueLineStations {
    /// Lazy-loaded stations array - only initialized when first accessed
    private static var _stations: [Station]?
    
    /// All Blue Line stations in geographic order (North to South)
    /// Blue Line: Baypointe ↔ Santa Teresa (goes through Tasman, River Oaks, NOT through Old Ironsides/Great America)
    static var stations: [Station] {
        if _stations == nil {
            _stations = loadStations()
        }
        return _stations!
    }
    
    /// Loads Blue Line station data
    private static func loadStations() -> [Station] {
        [
            // Baypointe - northern terminus
            Station(id: "64801", lineId: "Blue", name: "Baypointe", shortName: "BPT", order: 0, platformIds: ["N": "64801", "S": "64761"]),
            // Tasman branch stations
            Station(id: "64759", lineId: "Blue", name: "Tasman", shortName: "TSM", order: 1, platformIds: ["N": "64759", "S": "64762"]),
            Station(id: "64758", lineId: "Blue", name: "River Oaks", shortName: "ROK", order: 2, platformIds: ["N": "64758", "S": "64763"]),
            Station(id: "64757", lineId: "Blue", name: "Orchard", shortName: "ORC", order: 3, platformIds: ["N": "64757", "S": "64764"]),
            Station(id: "64756", lineId: "Blue", name: "Bonaventura", shortName: "BNV", order: 4, platformIds: ["N": "64756", "S": "64765"]),
            Station(id: "64755", lineId: "Blue", name: "Component", shortName: "CMP", order: 5, platformIds: ["N": "64755", "S": "64766"]),
            Station(id: "64754", lineId: "Blue", name: "Karina", shortName: "KRN", order: 6, platformIds: ["N": "64754", "S": "64767"]),
            Station(id: "64753", lineId: "Blue", name: "Metro/Airport", shortName: "APT", order: 7, platformIds: ["N": "64753", "S": "64768"]),
            Station(id: "64752", lineId: "Blue", name: "Gish", shortName: "GSH", order: 8, platformIds: ["N": "64752", "S": "64769"]),
            Station(id: "64751", lineId: "Blue", name: "Civic Center", shortName: "CVC", order: 9, platformIds: ["N": "64751", "S": "64770"]),
            Station(id: "64750", lineId: "Blue", name: "Japantown/Ayer", shortName: "JPN", order: 10, platformIds: ["N": "64750", "S": "64771"]),
            Station(id: "64749", lineId: "Blue", name: "St. James", shortName: "STJ", order: 11, platformIds: ["N": "64749", "S": "64772"]),
            Station(id: "64748", lineId: "Blue", name: "Santa Clara", shortName: "STC", order: 12, platformIds: ["N": "64748", "S": "64773"]),
            Station(id: "64747", lineId: "Blue", name: "San Antonio", shortName: "SAN", order: 13, platformIds: ["N": "64747", "S": "64774"]),
            Station(id: "64746", lineId: "Blue", name: "Convention Center", shortName: "CNV", order: 14, platformIds: ["N": "64746", "S": "64775"]),
            Station(id: "64745", lineId: "Blue", name: "Children's Discovery Museum", shortName: "CDM", order: 15, platformIds: ["N": "64745", "S": "64776"]),
            Station(id: "64744", lineId: "Blue", name: "Virginia", shortName: "VRG", order: 16, platformIds: ["N": "64744", "S": "64777"]),
            Station(id: "64743", lineId: "Blue", name: "Tamien", shortName: "TMN", order: 17, platformIds: ["N": "64743", "S": "64778"]),
            Station(id: "64742", lineId: "Blue", name: "Curtner", shortName: "CRT", order: 18, platformIds: ["N": "64742", "S": "64779"]),
            Station(id: "64741", lineId: "Blue", name: "Capitol", shortName: "CPT", order: 19, platformIds: ["N": "64741", "S": "64780"]),
            Station(id: "64740", lineId: "Blue", name: "Branham", shortName: "BRH", order: 20, platformIds: ["N": "64740", "S": "64781"]),
            Station(id: "64731", lineId: "Blue", name: "Ohlone/Chynoweth", shortName: "OHL", order: 21, platformIds: ["N": "64731", "S": "64733"]),
            Station(id: "64739", lineId: "Blue", name: "Blossom Hill", shortName: "BLH", order: 22, platformIds: ["N": "64739", "S": "64782"]),
            Station(id: "64738", lineId: "Blue", name: "Snell", shortName: "SNL", order: 23, platformIds: ["N": "64738", "S": "64783"]),
            Station(id: "64737", lineId: "Blue", name: "Cottle", shortName: "CTL", order: 24, platformIds: ["N": "64737", "S": "64784"]),
            Station(id: "64736", lineId: "Blue", name: "Santa Teresa", shortName: "STT", order: 25, platformIds: ["N": "64736", "S": "64785"])
        ]
    }
    
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
/// Station IDs are from 511.org GTFS data (stops.txt)
///
/// ============================================================================
/// 511.org API STOP_ID MAPPING FOR GREEN LINE (From GTFS - Verified 2026-02-05):
/// ============================================================================
/// 
/// Green Line has THREE sections with different stop_id patterns:
/// 
/// 1. SHARED WITH ORANGE LINE (Old Ironsides → Champion):
///    - Uses Orange Line E/W stop_ids (64797-64810 range)
///    - E platform = Southbound (toward Winchester)
///    - W platform = Northbound (toward Old Ironsides)
/// 
/// 2. SHARED WITH BLUE LINE (Tasman → Convention Center):
///    - Uses Blue Line N/S stop_ids (64746-64770 range)
///    - Same as Blue Line mapping
/// 
/// 3. WINCHESTER BRANCH (San Fernando → Winchester):
///    - Uses dedicated stop_ids (65374-65389 range)
///    - 65374-65380 = Northbound (toward Old Ironsides)
///    - 65381-65387 = Southbound (toward Winchester)
/// ============================================================================
enum GreenLineStations {
    /// Lazy-loaded stations array - only initialized when first accessed
    private static var _stations: [Station]?
    
    /// All Green Line stations in geographic order (North to South)
    /// Green Line: Old Ironsides ↔ Winchester (via Great America, Tasman branch)
    static var stations: [Station] {
        if _stations == nil {
            _stations = loadStations()
        }
        return _stations!
    }
    
    /// Loads Green Line station data
    private static func loadStations() -> [Station] {
        [
            // Old Ironsides through Champion - shared with Orange Line (E/W directions)
            Station(id: "64797", lineId: "Green", name: "Old Ironsides", shortName: "OIS", order: 0, platformIds: ["N": "64810", "S": "64797"]),
            Station(id: "64798", lineId: "Green", name: "Great America", shortName: "GAM", order: 1, platformIds: ["N": "64809", "S": "64798"]),
            Station(id: "64799", lineId: "Green", name: "Lick Mill", shortName: "LML", order: 2, platformIds: ["N": "64808", "S": "64799"]),
            Station(id: "64800", lineId: "Green", name: "Champion", shortName: "CHP", order: 3, platformIds: ["N": "64807", "S": "64800"]),
            // Tasman branch - shared with Blue Line (N/S directions)
            Station(id: "64759", lineId: "Green", name: "Tasman", shortName: "TSM", order: 4, platformIds: ["N": "64759", "S": "64762"]),
            Station(id: "64758", lineId: "Green", name: "River Oaks", shortName: "ROK", order: 5, platformIds: ["N": "64758", "S": "64763"]),
            Station(id: "64757", lineId: "Green", name: "Orchard", shortName: "ORC", order: 6, platformIds: ["N": "64757", "S": "64764"]),
            Station(id: "64756", lineId: "Green", name: "Bonaventura", shortName: "BNV", order: 7, platformIds: ["N": "64756", "S": "64765"]),
            Station(id: "64755", lineId: "Green", name: "Component", shortName: "CMP", order: 8, platformIds: ["N": "64755", "S": "64766"]),
            Station(id: "64754", lineId: "Green", name: "Karina", shortName: "KRN", order: 9, platformIds: ["N": "64754", "S": "64767"]),
            Station(id: "64753", lineId: "Green", name: "Metro/Airport", shortName: "APT", order: 10, platformIds: ["N": "64753", "S": "64768"]),
            Station(id: "64752", lineId: "Green", name: "Gish", shortName: "GSH", order: 11, platformIds: ["N": "64752", "S": "64769"]),
            Station(id: "64751", lineId: "Green", name: "Civic Center", shortName: "CVC", order: 12, platformIds: ["N": "64751", "S": "64770"]),
            Station(id: "64750", lineId: "Green", name: "Japantown/Ayer", shortName: "JPN", order: 13, platformIds: ["N": "64750", "S": "64771"]),
            Station(id: "64749", lineId: "Green", name: "St. James", shortName: "STJ", order: 14, platformIds: ["N": "64749", "S": "64772"]),
            Station(id: "64748", lineId: "Green", name: "Santa Clara", shortName: "STC", order: 15, platformIds: ["N": "64748", "S": "64773"]),
            Station(id: "64747", lineId: "Green", name: "San Antonio", shortName: "SAN", order: 16, platformIds: ["N": "64747", "S": "64774"]),
            Station(id: "64746", lineId: "Green", name: "Convention Center", shortName: "CNV", order: 17, platformIds: ["N": "64746", "S": "64775"]),
            // Winchester branch - dedicated stop_ids (65374-65389)
            Station(id: "65388", lineId: "Green", name: "San Fernando", shortName: "SFN", order: 18, platformIds: ["N": "65388", "S": "65389"]),
            Station(id: "65374", lineId: "Green", name: "San Jose Diridon", shortName: "SJD", order: 19, platformIds: ["N": "65374", "S": "65381"]),
            Station(id: "65375", lineId: "Green", name: "Race", shortName: "RCE", order: 20, platformIds: ["N": "65375", "S": "65382"]),
            Station(id: "65376", lineId: "Green", name: "Fruitdale", shortName: "FRD", order: 21, platformIds: ["N": "65376", "S": "65383"]),
            Station(id: "65377", lineId: "Green", name: "Bascom", shortName: "BSC", order: 22, platformIds: ["N": "65377", "S": "65384"]),
            Station(id: "65378", lineId: "Green", name: "Hamilton", shortName: "HML", order: 23, platformIds: ["N": "65378", "S": "65385"]),
            Station(id: "65379", lineId: "Green", name: "Campbell", shortName: "CMB", order: 24, platformIds: ["N": "65379", "S": "65386"]),
            Station(id: "65380", lineId: "Green", name: "Winchester", shortName: "WNC", order: 25, platformIds: ["N": "65380", "S": "65387"])
        ]
    }
    
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
