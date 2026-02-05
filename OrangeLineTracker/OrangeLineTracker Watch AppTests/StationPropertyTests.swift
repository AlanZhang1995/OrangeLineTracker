//
//  StationPropertyTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Property-based tests for Station model backward compatibility
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Property 11: 向后兼容性 - 旧数据迁移

/// Property-based tests for Station model backward compatibility
/// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
/// **Validates: Requirements 1.5**
///
/// Property 11: 对于任意 v1 版本的存储数据（仅包含 Orange Line 设置），
/// 迁移后必须正确设置 lineId 为 "Orange Line"，且原有的站点和方向设置保持不变。
struct StationBackwardCompatibilityPropertyTests {
    
    // MARK: - Test Data Generators
    
    /// Generates a random valid station ID (511.org stop code format)
    /// Stop codes are typically 5-digit numbers in the 60000-69999 range
    private func randomStationId() -> String {
        String(Int.random(in: 60000...69999))
    }
    
    /// Generates a random valid station name
    /// Names are human-readable station names
    private func randomStationName() -> String {
        let names = [
            "Mountain View", "Whisman", "Middlefield", "Bayshore/NASA",
            "Moffett Park", "Lockheed Martin", "Borregas", "Crossman",
            "Fair Oaks", "Vienna", "Reamwood", "Old Ironsides",
            "Great America", "Lick Mill", "Champion", "Baypointe",
            "Cisco Way", "River Oaks", "Tasman", "Orchard",
            "Alder", "Great Mall", "Milpitas", "Cropley",
            "Hostetter", "Berryessa", "Penitencia Creek", "Alum Rock",
            "Test Station \(Int.random(in: 1...100))"
        ]
        return names.randomElement()!
    }
    
    /// Generates a random valid short name (1-4 characters)
    /// Short names are abbreviated versions for widget display
    private func randomShortName() -> String {
        let shortNames = [
            "MTV", "WSM", "MDF", "NASA", "MFT", "LMT", "BRG", "CRS",
            "FOK", "VNA", "RWD", "OIS", "GAM", "LML", "CHP", "BPT",
            "CSC", "ROK", "TSM", "ORC", "ALD", "GML", "MLP", "CRP",
            "HST", "BRY", "PNC", "ALR", "TS\(Int.random(in: 1...99))"
        ]
        return shortNames.randomElement()!
    }
    
    /// Generates a random valid order (0-based index)
    private func randomOrder() -> Int {
        Int.random(in: 0...50)
    }
    
    /// Generates v1-style station data (eastboundId, westboundId, name, shortName, order)
    /// This simulates the old data format before multi-line support
    private func randomV1StationData() -> (eastboundId: String, westboundId: String, name: String, shortName: String, order: Int) {
        return (
            eastboundId: randomStationId(),
            westboundId: randomStationId(),
            name: randomStationName(),
            shortName: randomShortName(),
            order: randomOrder()
        )
    }
    
    // MARK: - Property 11 Tests
    
    /// Property 11: Backward-compatible initializer sets lineId to "Orange"
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Backward-compatible initializer sets lineId to Orange - 100 iterations")
    func backwardCompatibleInitializerSetsLineIdToOrange() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            // Create station using backward-compatible initializer
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: lineId must be "Orange" for backward compatibility
            #expect(
                station.lineId == "Orange",
                "Iteration \(iteration): lineId should be 'Orange' for backward-compatible stations, got '\(station.lineId)'"
            )
        }
    }
    
    /// Property 11: Backward-compatible initializer preserves station name
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Backward-compatible initializer preserves name - 100 iterations")
    func backwardCompatibleInitializerPreservesName() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: name must be preserved exactly
            #expect(
                station.name == v1Data.name,
                "Iteration \(iteration): name should be preserved, expected '\(v1Data.name)', got '\(station.name)'"
            )
        }
    }
    
    /// Property 11: Backward-compatible initializer preserves shortName
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Backward-compatible initializer preserves shortName - 100 iterations")
    func backwardCompatibleInitializerPreservesShortName() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: shortName must be preserved exactly
            #expect(
                station.shortName == v1Data.shortName,
                "Iteration \(iteration): shortName should be preserved, expected '\(v1Data.shortName)', got '\(station.shortName)'"
            )
        }
    }
    
    /// Property 11: Backward-compatible initializer preserves order
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Backward-compatible initializer preserves order - 100 iterations")
    func backwardCompatibleInitializerPreservesOrder() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: order must be preserved exactly
            #expect(
                station.order == v1Data.order,
                "Iteration \(iteration): order should be preserved, expected \(v1Data.order), got \(station.order)"
            )
        }
    }
    
    /// Property 11: Backward-compatible initializer creates correct platformIds
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Backward-compatible initializer creates correct platformIds - 100 iterations")
    func backwardCompatibleInitializerCreatesCorrectPlatformIds() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: platformIds must contain "E" key with eastboundId value
            #expect(
                station.platformIds["E"] == v1Data.eastboundId,
                "Iteration \(iteration): platformIds['E'] should be '\(v1Data.eastboundId)', got '\(station.platformIds["E"] ?? "nil")'"
            )
            
            // Property: platformIds must contain "W" key with westboundId value
            #expect(
                station.platformIds["W"] == v1Data.westboundId,
                "Iteration \(iteration): platformIds['W'] should be '\(v1Data.westboundId)', got '\(station.platformIds["W"] ?? "nil")'"
            )
            
            // Property: platformIds must have exactly 2 entries
            #expect(
                station.platformIds.count == 2,
                "Iteration \(iteration): platformIds should have exactly 2 entries, got \(station.platformIds.count)"
            )
        }
    }
    
    /// Property 11: Backward-compatible initializer uses eastboundId as primary ID
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Backward-compatible initializer uses eastboundId as primary ID - 100 iterations")
    func backwardCompatibleInitializerUsesEastboundIdAsPrimaryId() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: id must equal eastboundId for backward compatibility
            #expect(
                station.id == v1Data.eastboundId,
                "Iteration \(iteration): id should equal eastboundId '\(v1Data.eastboundId)', got '\(station.id)'"
            )
        }
    }
    
    /// Property 11: eastboundId computed property returns correct value
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: eastboundId computed property returns correct value - 100 iterations")
    func eastboundIdComputedPropertyReturnsCorrectValue() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: eastboundId computed property must return original eastboundId
            #expect(
                station.eastboundId == v1Data.eastboundId,
                "Iteration \(iteration): eastboundId should be '\(v1Data.eastboundId)', got '\(station.eastboundId)'"
            )
        }
    }
    
    /// Property 11: westboundId computed property returns correct value
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: westboundId computed property returns correct value - 100 iterations")
    func westboundIdComputedPropertyReturnsCorrectValue() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: westboundId computed property must return original westboundId
            #expect(
                station.westboundId == v1Data.westboundId,
                "Iteration \(iteration): westboundId should be '\(v1Data.westboundId)', got '\(station.westboundId)'"
            )
        }
    }
    
    /// Property 11: stationId(for:) returns correct platform ID for each direction
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: stationId(for:) returns correct platform ID - 100 iterations")
    func stationIdForDirectionReturnsCorrectPlatformId() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: stationId(for: .alumRock) must return eastboundId
            #expect(
                station.stationId(for: .alumRock) == v1Data.eastboundId,
                "Iteration \(iteration): stationId(for: .alumRock) should be '\(v1Data.eastboundId)', got '\(station.stationId(for: .alumRock))'"
            )
            
            // Property: stationId(for: .mountainView) must return westboundId
            #expect(
                station.stationId(for: .mountainView) == v1Data.westboundId,
                "Iteration \(iteration): stationId(for: .mountainView) should be '\(v1Data.westboundId)', got '\(station.stationId(for: .mountainView))'"
            )
        }
    }
    
    /// Property 11: platformId(for:) returns correct value for E and W directions
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: platformId(for:) returns correct value - 100 iterations")
    func platformIdForDirectionIdReturnsCorrectValue() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: platformId(for: "E") must return eastboundId
            #expect(
                station.platformId(for: "E") == v1Data.eastboundId,
                "Iteration \(iteration): platformId(for: 'E') should be '\(v1Data.eastboundId)', got '\(station.platformId(for: "E") ?? "nil")'"
            )
            
            // Property: platformId(for: "W") must return westboundId
            #expect(
                station.platformId(for: "W") == v1Data.westboundId,
                "Iteration \(iteration): platformId(for: 'W') should be '\(v1Data.westboundId)', got '\(station.platformId(for: "W") ?? "nil")'"
            )
            
            // Property: platformId(for: "N") must return nil (not defined)
            #expect(
                station.platformId(for: "N") == nil,
                "Iteration \(iteration): platformId(for: 'N') should be nil for E/W stations"
            )
        }
    }
    
    /// Property 11: Combined test - all v1 data is preserved after migration
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: All v1 data preserved after migration - 100 iterations")
    func allV1DataPreservedAfterMigration() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            // Simulate migration: create station using backward-compatible initializer
            let station = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property 1: lineId is set to "Orange"
            #expect(station.lineId == "Orange", "Iteration \(iteration): lineId should be 'Orange'")
            
            // Property 2: name is preserved
            #expect(station.name == v1Data.name, "Iteration \(iteration): name should be preserved")
            
            // Property 3: shortName is preserved
            #expect(station.shortName == v1Data.shortName, "Iteration \(iteration): shortName should be preserved")
            
            // Property 4: order is preserved
            #expect(station.order == v1Data.order, "Iteration \(iteration): order should be preserved")
            
            // Property 5: eastboundId is preserved and accessible
            #expect(station.eastboundId == v1Data.eastboundId, "Iteration \(iteration): eastboundId should be preserved")
            
            // Property 6: westboundId is preserved and accessible
            #expect(station.westboundId == v1Data.westboundId, "Iteration \(iteration): westboundId should be preserved")
            
            // Property 7: direction-based station ID lookup works
            #expect(station.stationId(for: .alumRock) == v1Data.eastboundId, "Iteration \(iteration): alumRock direction should use eastboundId")
            #expect(station.stationId(for: .mountainView) == v1Data.westboundId, "Iteration \(iteration): mountainView direction should use westboundId")
        }
    }
    
    /// Property 11: Station Codable roundtrip preserves all data
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Station Codable roundtrip preserves data - 100 iterations")
    func stationCodableRoundtripPreservesData() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let originalStation = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Encode to JSON
            let jsonData = try encoder.encode(originalStation)
            
            // Decode back to Station
            let decodedStation = try decoder.decode(Station.self, from: jsonData)
            
            // Property: decoded Station must equal original
            #expect(
                decodedStation == originalStation,
                "Iteration \(iteration): Decoded Station should equal original Station"
            )
            
            // Verify all fields are preserved
            #expect(decodedStation.id == originalStation.id, "Iteration \(iteration): id should be preserved")
            #expect(decodedStation.lineId == originalStation.lineId, "Iteration \(iteration): lineId should be preserved")
            #expect(decodedStation.name == originalStation.name, "Iteration \(iteration): name should be preserved")
            #expect(decodedStation.shortName == originalStation.shortName, "Iteration \(iteration): shortName should be preserved")
            #expect(decodedStation.order == originalStation.order, "Iteration \(iteration): order should be preserved")
            #expect(decodedStation.platformIds == originalStation.platformIds, "Iteration \(iteration): platformIds should be preserved")
            
            // Verify backward-compatible accessors work after roundtrip
            #expect(decodedStation.eastboundId == v1Data.eastboundId, "Iteration \(iteration): eastboundId should be preserved after roundtrip")
            #expect(decodedStation.westboundId == v1Data.westboundId, "Iteration \(iteration): westboundId should be preserved after roundtrip")
        }
    }
    
    /// Property 11: Station Equatable works correctly for migrated stations
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Station Equatable works correctly - 100 iterations")
    func stationEquatableWorksCorrectly() {
        for iteration in 1...100 {
            let v1Data = randomV1StationData()
            
            let station1 = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Create an identical station
            let station2 = Station(
                eastboundId: v1Data.eastboundId,
                westboundId: v1Data.westboundId,
                name: v1Data.name,
                shortName: v1Data.shortName,
                order: v1Data.order
            )
            
            // Property: identical stations should be equal
            #expect(
                station1 == station2,
                "Iteration \(iteration): Identical stations should be equal"
            )
            
            // Create a different station
            let differentV1Data = randomV1StationData()
            let station3 = Station(
                eastboundId: differentV1Data.eastboundId,
                westboundId: differentV1Data.westboundId,
                name: differentV1Data.name,
                shortName: differentV1Data.shortName,
                order: differentV1Data.order
            )
            
            // Property: different stations should not be equal (with high probability)
            if station1.id != station3.id || station1.name != station3.name {
                #expect(
                    station1 != station3,
                    "Iteration \(iteration): Different stations should not be equal"
                )
            }
        }
    }
}

// MARK: - OrangeLineStations Backward Compatibility Tests

/// Tests that OrangeLineStations static data maintains backward compatibility
/// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
struct OrangeLineStationsBackwardCompatibilityTests {
    
    /// Property 11: All OrangeLineStations have lineId "Orange"
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: All OrangeLineStations have lineId Orange")
    func allOrangeLineStationsHaveLineIdOrange() {
        for station in OrangeLineStations.stations {
            #expect(
                station.lineId == "Orange",
                "Station '\(station.name)' should have lineId 'Orange', got '\(station.lineId)'"
            )
        }
    }
    
    /// Property 11: All OrangeLineStations have valid platformIds
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: All OrangeLineStations have valid platformIds")
    func allOrangeLineStationsHaveValidPlatformIds() {
        for station in OrangeLineStations.stations {
            // Must have E and W platform IDs
            #expect(
                station.platformIds["E"] != nil,
                "Station '\(station.name)' should have 'E' platform ID"
            )
            #expect(
                station.platformIds["W"] != nil,
                "Station '\(station.name)' should have 'W' platform ID"
            )
            
            // Platform IDs should be non-empty
            #expect(
                !station.eastboundId.isEmpty,
                "Station '\(station.name)' eastboundId should not be empty"
            )
            #expect(
                !station.westboundId.isEmpty,
                "Station '\(station.name)' westboundId should not be empty"
            )
        }
    }
    
    /// Property 11: OrangeLineStations stationId(for:) works for all stations
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: OrangeLineStations stationId(for:) works for all stations")
    func orangeLineStationsStationIdForDirectionWorks() {
        for station in OrangeLineStations.stations {
            // stationId(for: .alumRock) should return eastboundId
            #expect(
                station.stationId(for: .alumRock) == station.eastboundId,
                "Station '\(station.name)' stationId(for: .alumRock) should equal eastboundId"
            )
            
            // stationId(for: .mountainView) should return westboundId
            #expect(
                station.stationId(for: .mountainView) == station.westboundId,
                "Station '\(station.name)' stationId(for: .mountainView) should equal westboundId"
            )
        }
    }
    
    /// Property 11: OrangeLineStations station(byId:) finds stations by both IDs
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: OrangeLineStations station(byId:) finds stations by both IDs")
    func orangeLineStationsStationByIdFindsByBothIds() {
        for station in OrangeLineStations.stations {
            // Should find by eastboundId
            let foundByEastbound = OrangeLineStations.station(byId: station.eastboundId)
            #expect(
                foundByEastbound?.id == station.id,
                "Station '\(station.name)' should be found by eastboundId '\(station.eastboundId)'"
            )
            
            // Should find by westboundId
            let foundByWestbound = OrangeLineStations.station(byId: station.westboundId)
            #expect(
                foundByWestbound?.id == station.id,
                "Station '\(station.name)' should be found by westboundId '\(station.westboundId)'"
            )
        }
    }
    
    /// Property 11: OrangeLineStations maintains correct count
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: OrangeLineStations has 26 stations")
    func orangeLineStationsHas26Stations() {
        #expect(
            OrangeLineStations.count == 26,
            "OrangeLineStations should have 26 stations, got \(OrangeLineStations.count)"
        )
        
        #expect(
            OrangeLineStations.stations.count == 26,
            "OrangeLineStations.stations should have 26 stations"
        )
    }
    
    /// Property 11: OrangeLineStations first and last are correct
    /// **Validates: Requirements 1.5**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: OrangeLineStations first and last are correct")
    func orangeLineStationsFirstAndLastAreCorrect() {
        #expect(
            OrangeLineStations.first.name == "Mountain View",
            "First station should be Mountain View"
        )
        #expect(
            OrangeLineStations.first.order == 0,
            "First station order should be 0"
        )
        
        #expect(
            OrangeLineStations.last.name == "Alum Rock",
            "Last station should be Alum Rock"
        )
        #expect(
            OrangeLineStations.last.order == 25,
            "Last station order should be 25"
        )
    }
}
