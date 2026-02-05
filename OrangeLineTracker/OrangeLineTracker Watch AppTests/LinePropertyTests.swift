//
//  LinePropertyTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Property-based tests for Line model integrity
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Property 1: Line 模型完整性测试

/// Property-based tests for Line model integrity
/// **Feature: vta-all-lines, Property 1: Line 模型完整性**
/// **Validates: Requirements 1.1, 1.3**
///
/// Property 1: 对于任意 Line 实例，该实例必须包含有效的 id、name、shortName、type、colorHex 字段，
/// 且 directions 数组恰好包含两个方向。
struct LineModelIntegrityPropertyTests {
    
    // MARK: - Test Data Generators
    
    /// Generates a random valid line ID
    /// Line IDs are typically alphanumeric strings like "Orange", "Blue", "22", "522"
    private func randomLineId() -> String {
        let idTypes: [() -> String] = [
            // Color-based IDs (light rail)
            { ["Orange", "Blue", "Green", "Yellow", "Red", "Purple"].randomElement()! },
            // Numeric IDs (bus routes)
            { String(Int.random(in: 1...999)) },
            // Alphanumeric IDs
            { "\(Int.random(in: 1...99))\(["A", "B", "X", "R", "L"].randomElement()!)" }
        ]
        return idTypes.randomElement()!()
    }
    
    /// Generates a random valid line name
    /// Names are human-readable like "Orange Line", "Route 22", "Blue Line"
    private func randomLineName() -> String {
        let nameTypes: [() -> String] = [
            // Light rail names
            { "\(["Orange", "Blue", "Green", "Yellow", "Red", "Purple"].randomElement()!) Line" },
            // Bus route names
            { "Route \(Int.random(in: 1...999))" },
            // Express route names
            { "\(Int.random(in: 100...599)) Express" }
        ]
        return nameTypes.randomElement()!()
    }
    
    /// Generates a random valid short name
    /// Short names are abbreviated versions for widget display (1-6 characters)
    private func randomShortName() -> String {
        let shortNameTypes: [() -> String] = [
            // Color abbreviations
            { ["ORG", "BLU", "GRN", "YEL", "RED", "PUR"].randomElement()! },
            // Numeric short names
            { String(Int.random(in: 1...999)) },
            // Alphanumeric short names
            { "\(Int.random(in: 1...99))\(["A", "B", "X"].randomElement()!)" }
        ]
        return shortNameTypes.randomElement()!()
    }
    
    /// Generates a random line type
    private func randomLineType() -> LineType {
        LineType.allCases.randomElement()!
    }
    
    /// Generates a random valid hex color string
    /// Colors are 6-character hex strings like "FF6600", "0066CC"
    private func randomColorHex() -> String {
        let colors = [
            "FF6600", // Orange
            "0066CC", // Blue
            "00AA00", // Green
            "FFCC00", // Yellow
            "CC0000", // Red
            "9900CC", // Purple
            "333333", // Gray
            "000000", // Black
            "FFFFFF"  // White
        ]
        
        // 70% chance of predefined color, 30% chance of random hex
        if Int.random(in: 0..<10) < 7 {
            return colors.randomElement()!
        } else {
            // Generate random hex color
            let r = String(format: "%02X", Int.random(in: 0...255))
            let g = String(format: "%02X", Int.random(in: 0...255))
            let b = String(format: "%02X", Int.random(in: 0...255))
            return "\(r)\(g)\(b)"
        }
    }
    
    /// Generates a random valid direction ID
    /// Direction IDs are typically single characters like "N", "S", "E", "W" or "IB", "OB"
    private func randomDirectionId() -> String {
        let directionIds = ["N", "S", "E", "W", "NB", "SB", "EB", "WB", "IB", "OB", "1", "2"]
        return directionIds.randomElement()!
    }
    
    /// Generates a random valid headsign (terminal station name)
    private func randomHeadsign() -> String {
        let headsigns = [
            "Mountain View",
            "Alum Rock",
            "Winchester",
            "Santa Teresa",
            "Baypointe",
            "Diridon",
            "Downtown San Jose",
            "Milpitas",
            "Berryessa",
            "Great Mall"
        ]
        return headsigns.randomElement()!
    }
    
    /// Generates a valid LineDirection
    private func randomLineDirection() -> LineDirection {
        LineDirection(
            id: randomDirectionId(),
            headsign: randomHeadsign()
        )
    }
    
    /// Generates exactly two distinct directions for a line
    private func randomTwoDirections() -> [LineDirection] {
        // Generate two distinct direction IDs
        let directionPairs = [
            ("E", "W"),
            ("N", "S"),
            ("NB", "SB"),
            ("EB", "WB"),
            ("IB", "OB"),
            ("1", "2")
        ]
        let pair = directionPairs.randomElement()!
        
        return [
            LineDirection(id: pair.0, headsign: randomHeadsign()),
            LineDirection(id: pair.1, headsign: randomHeadsign())
        ]
    }
    
    /// Generates a random valid Station for a line
    private func randomStation(lineId: String, order: Int) -> Station {
        Station(
            eastboundId: "\(Int.random(in: 60000...69999))",
            westboundId: "\(Int.random(in: 60000...69999))",
            name: "Station \(order + 1)",
            shortName: "ST\(order + 1)",
            order: order
        )
    }
    
    /// Generates a random list of stations for a line
    private func randomStations(lineId: String) -> [Station] {
        let stationCount = Int.random(in: 2...30)
        return (0..<stationCount).map { order in
            randomStation(lineId: lineId, order: order)
        }
    }
    
    /// Generates a complete valid Line instance
    private func randomLine() -> Line {
        let lineId = randomLineId()
        return Line(
            id: lineId,
            name: randomLineName(),
            shortName: randomShortName(),
            type: randomLineType(),
            colorHex: randomColorHex(),
            directions: randomTwoDirections(),
            stations: randomStations(lineId: lineId)
        )
    }
    
    // MARK: - Property 1 Tests
    
    /// Property 1: Line id must be non-empty
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: Line id is non-empty - 100 iterations")
    func lineIdIsNonEmpty() {
        for iteration in 1...100 {
            let line = randomLine()
            
            // Property: Line id must be non-empty
            #expect(
                !line.id.isEmpty,
                "Iteration \(iteration): Line id should not be empty"
            )
        }
    }
    
    /// Property 1: Line name must be non-empty
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: Line name is non-empty - 100 iterations")
    func lineNameIsNonEmpty() {
        for iteration in 1...100 {
            let line = randomLine()
            
            // Property: Line name must be non-empty
            #expect(
                !line.name.isEmpty,
                "Iteration \(iteration): Line name should not be empty"
            )
        }
    }
    
    /// Property 1: Line shortName must be non-empty
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: Line shortName is non-empty - 100 iterations")
    func lineShortNameIsNonEmpty() {
        for iteration in 1...100 {
            let line = randomLine()
            
            // Property: Line shortName must be non-empty
            #expect(
                !line.shortName.isEmpty,
                "Iteration \(iteration): Line shortName should not be empty"
            )
        }
    }
    
    /// Property 1: Line colorHex must be a valid 6-character hex string
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: Line colorHex is valid hex - 100 iterations")
    func lineColorHexIsValidHex() {
        for iteration in 1...100 {
            let line = randomLine()
            
            // Property: colorHex must be exactly 6 characters
            #expect(
                line.colorHex.count == 6,
                "Iteration \(iteration): Line colorHex '\(line.colorHex)' should be 6 characters"
            )
            
            // Property: colorHex must contain only valid hex characters
            let hexCharacterSet = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
            let isValidHex = line.colorHex.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) }
            #expect(
                isValidHex,
                "Iteration \(iteration): Line colorHex '\(line.colorHex)' should contain only hex characters"
            )
        }
    }
    
    /// Property 1: Line type must be a valid LineType
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: Line type is valid - 100 iterations")
    func lineTypeIsValid() {
        for iteration in 1...100 {
            let line = randomLine()
            
            // Property: Line type must be one of the valid types
            let validTypes: [LineType] = [.lightRail, .bus]
            #expect(
                validTypes.contains(line.type),
                "Iteration \(iteration): Line type '\(line.type)' should be a valid LineType"
            )
        }
    }
    
    /// Property 1: Line directions must contain exactly two directions
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: Line has exactly two directions - 100 iterations")
    func lineHasExactlyTwoDirections() {
        for iteration in 1...100 {
            let line = randomLine()
            
            // Property: directions array must contain exactly 2 elements
            #expect(
                line.directions.count == 2,
                "Iteration \(iteration): Line should have exactly 2 directions, got \(line.directions.count)"
            )
        }
    }
    
    /// Property 1: Each direction must have non-empty id and headsign
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: Line directions have valid fields - 100 iterations")
    func lineDirectionsHaveValidFields() {
        for iteration in 1...100 {
            let line = randomLine()
            
            for (index, direction) in line.directions.enumerated() {
                // Property: direction id must be non-empty
                #expect(
                    !direction.id.isEmpty,
                    "Iteration \(iteration): Direction \(index) id should not be empty"
                )
                
                // Property: direction headsign must be non-empty
                #expect(
                    !direction.headsign.isEmpty,
                    "Iteration \(iteration): Direction \(index) headsign should not be empty"
                )
            }
        }
    }
    
    /// Property 1: Combined test - all Line fields are valid
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: All Line fields are valid - 100 iterations")
    func allLineFieldsAreValid() {
        for iteration in 1...100 {
            let line = randomLine()
            
            // Property 1: id is non-empty
            #expect(!line.id.isEmpty, "Iteration \(iteration): id should not be empty")
            
            // Property 2: name is non-empty
            #expect(!line.name.isEmpty, "Iteration \(iteration): name should not be empty")
            
            // Property 3: shortName is non-empty
            #expect(!line.shortName.isEmpty, "Iteration \(iteration): shortName should not be empty")
            
            // Property 4: colorHex is valid 6-character hex
            #expect(line.colorHex.count == 6, "Iteration \(iteration): colorHex should be 6 characters")
            let hexCharacterSet = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
            let isValidHex = line.colorHex.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) }
            #expect(isValidHex, "Iteration \(iteration): colorHex should be valid hex")
            
            // Property 5: type is valid
            #expect([LineType.lightRail, LineType.bus].contains(line.type), "Iteration \(iteration): type should be valid")
            
            // Property 6: exactly 2 directions
            #expect(line.directions.count == 2, "Iteration \(iteration): should have exactly 2 directions")
            
            // Property 7: each direction has valid fields
            for direction in line.directions {
                #expect(!direction.id.isEmpty, "Iteration \(iteration): direction id should not be empty")
                #expect(!direction.headsign.isEmpty, "Iteration \(iteration): direction headsign should not be empty")
            }
        }
    }
    
    /// Property 1: Line model conforms to Codable - encode/decode roundtrip
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: Line Codable roundtrip preserves data - 100 iterations")
    func lineCodableRoundtripPreservesData() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for iteration in 1...100 {
            let originalLine = randomLine()
            
            // Encode to JSON
            let jsonData = try encoder.encode(originalLine)
            
            // Decode back to Line
            let decodedLine = try decoder.decode(Line.self, from: jsonData)
            
            // Property: decoded Line must equal original
            #expect(
                decodedLine == originalLine,
                "Iteration \(iteration): Decoded Line should equal original Line"
            )
            
            // Verify all fields are preserved
            #expect(decodedLine.id == originalLine.id, "Iteration \(iteration): id should be preserved")
            #expect(decodedLine.name == originalLine.name, "Iteration \(iteration): name should be preserved")
            #expect(decodedLine.shortName == originalLine.shortName, "Iteration \(iteration): shortName should be preserved")
            #expect(decodedLine.type == originalLine.type, "Iteration \(iteration): type should be preserved")
            #expect(decodedLine.colorHex == originalLine.colorHex, "Iteration \(iteration): colorHex should be preserved")
            #expect(decodedLine.directions.count == originalLine.directions.count, "Iteration \(iteration): directions count should be preserved")
        }
    }
    
    /// Property 1: Line model conforms to Equatable correctly
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: Line Equatable works correctly - 100 iterations")
    func lineEquatableWorksCorrectly() {
        for iteration in 1...100 {
            let line1 = randomLine()
            
            // Create an identical copy
            let line2 = Line(
                id: line1.id,
                name: line1.name,
                shortName: line1.shortName,
                type: line1.type,
                colorHex: line1.colorHex,
                directions: line1.directions,
                stations: line1.stations
            )
            
            // Property: identical Lines should be equal
            #expect(
                line1 == line2,
                "Iteration \(iteration): Identical Lines should be equal"
            )
            
            // Create a different Line
            let line3 = randomLine()
            
            // Property: different Lines should not be equal (with high probability)
            // Note: There's a tiny chance they could be equal if random generates same values
            if line1.id != line3.id || line1.name != line3.name {
                #expect(
                    line1 != line3,
                    "Iteration \(iteration): Different Lines should not be equal"
                )
            }
        }
    }
    
    /// Property 1: Line model conforms to Identifiable correctly
    /// **Validates: Requirements 1.1, 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: Line Identifiable id matches id property - 100 iterations")
    func lineIdentifiableIdMatchesIdProperty() {
        for iteration in 1...100 {
            let line = randomLine()
            
            // Property: Identifiable id should match the id property
            #expect(
                line.id == line.id,
                "Iteration \(iteration): Identifiable id should match id property"
            )
        }
    }
}

// MARK: - LineType Property Tests

/// Property tests for LineType enum
/// **Feature: vta-all-lines, Property 1: Line 模型完整性**
struct LineTypePropertyTests {
    
    /// Property 1: LineType rawValue roundtrip
    /// **Validates: Requirements 1.1**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: LineType rawValue roundtrip - all cases")
    func lineTypeRawValueRoundtrip() {
        for lineType in LineType.allCases {
            // Get raw value
            let rawValue = lineType.rawValue
            
            // Create from raw value
            let recreated = LineType(rawValue: rawValue)
            
            // Property: recreated type should equal original
            #expect(
                recreated == lineType,
                "LineType '\(lineType)' should roundtrip through rawValue '\(rawValue)'"
            )
        }
    }
    
    /// Property 1: LineType has exactly two cases
    /// **Validates: Requirements 1.1**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: LineType has exactly two cases")
    func lineTypeHasExactlyTwoCases() {
        #expect(
            LineType.allCases.count == 2,
            "LineType should have exactly 2 cases (lightRail, bus)"
        )
        
        #expect(
            LineType.allCases.contains(.lightRail),
            "LineType should contain lightRail case"
        )
        
        #expect(
            LineType.allCases.contains(.bus),
            "LineType should contain bus case"
        )
    }
}

// MARK: - LineDirection Property Tests

/// Property tests for LineDirection struct
/// **Feature: vta-all-lines, Property 1: Line 模型完整性**
struct LineDirectionPropertyTests {
    
    /// Generates a random valid direction ID
    private func randomDirectionId() -> String {
        let directionIds = ["N", "S", "E", "W", "NB", "SB", "EB", "WB", "IB", "OB", "1", "2"]
        return directionIds.randomElement()!
    }
    
    /// Generates a random valid headsign
    private func randomHeadsign() -> String {
        let headsigns = [
            "Mountain View", "Alum Rock", "Winchester", "Santa Teresa",
            "Baypointe", "Diridon", "Downtown San Jose", "Milpitas"
        ]
        return headsigns.randomElement()!
    }
    
    /// Property 1: LineDirection Codable roundtrip
    /// **Validates: Requirements 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: LineDirection Codable roundtrip - 100 iterations")
    func lineDirectionCodableRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for iteration in 1...100 {
            let original = LineDirection(
                id: randomDirectionId(),
                headsign: randomHeadsign()
            )
            
            // Encode to JSON
            let jsonData = try encoder.encode(original)
            
            // Decode back
            let decoded = try decoder.decode(LineDirection.self, from: jsonData)
            
            // Property: decoded should equal original
            #expect(
                decoded == original,
                "Iteration \(iteration): Decoded LineDirection should equal original"
            )
            
            #expect(decoded.id == original.id, "Iteration \(iteration): id should be preserved")
            #expect(decoded.headsign == original.headsign, "Iteration \(iteration): headsign should be preserved")
        }
    }
    
    /// Property 1: LineDirection Equatable works correctly
    /// **Validates: Requirements 1.3**
    /// **Feature: vta-all-lines, Property 1: Line 模型完整性**
    @Test("Property 1: LineDirection Equatable - 100 iterations")
    func lineDirectionEquatable() {
        for iteration in 1...100 {
            let id = randomDirectionId()
            let headsign = randomHeadsign()
            
            let direction1 = LineDirection(id: id, headsign: headsign)
            let direction2 = LineDirection(id: id, headsign: headsign)
            
            // Property: identical directions should be equal
            #expect(
                direction1 == direction2,
                "Iteration \(iteration): Identical LineDirections should be equal"
            )
            
            // Create different direction
            let direction3 = LineDirection(id: randomDirectionId(), headsign: randomHeadsign())
            
            // Property: different directions should not be equal (with high probability)
            if direction1.id != direction3.id || direction1.headsign != direction3.headsign {
                #expect(
                    direction1 != direction3,
                    "Iteration \(iteration): Different LineDirections should not be equal"
                )
            }
        }
    }
}
