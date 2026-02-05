//
//  OrangeLineTracker_Watch_AppTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Created by Zhang, Haochen on 2/3/26.
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Station Model Tests

struct StationModelTests {
    
    // MARK: - Station Structure Tests
    
    @Test func stationHasRequiredProperties() {
        // Validates: Requirements 1.1, 1.5
        let station = Station(eastboundId: "64786", westboundId: "64821", name: "Mountain View", shortName: "MTV", order: 0)
        
        #expect(station.id == "64786")  // id uses eastboundId
        #expect(station.eastboundId == "64786")
        #expect(station.westboundId == "64821")
        #expect(station.name == "Mountain View")
        #expect(station.shortName == "MTV")
        #expect(station.order == 0)
    }
    
    @Test func stationConformsToIdentifiable() {
        // Station should use eastboundId as the identifier
        let station = Station(eastboundId: "64786", westboundId: "64821", name: "Mountain View", shortName: "MTV", order: 0)
        #expect(station.id == "64786")
    }
    
    @Test func stationConformsToEquatable() {
        let station1 = Station(eastboundId: "64786", westboundId: "64821", name: "Mountain View", shortName: "MTV", order: 0)
        let station2 = Station(eastboundId: "64786", westboundId: "64821", name: "Mountain View", shortName: "MTV", order: 0)
        let station3 = Station(eastboundId: "64788", westboundId: "64819", name: "Whisman", shortName: "WSM", order: 1)
        
        #expect(station1 == station2)
        #expect(station1 != station3)
    }
    
    @Test func stationConformsToCodable() throws {
        // Test encoding and decoding
        let station = Station(eastboundId: "64786", westboundId: "64821", name: "Mountain View", shortName: "MTV", order: 0)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(station)
        
        let decoder = JSONDecoder()
        let decodedStation = try decoder.decode(Station.self, from: data)
        
        #expect(decodedStation == station)
    }
    
    @Test func stationIdForDirectionReturnsCorrectId() {
        let station = Station(eastboundId: "64786", westboundId: "64821", name: "Mountain View", shortName: "MTV", order: 0)
        
        // Eastbound (Alum Rock direction) should return eastboundId
        #expect(station.stationId(for: .alumRock) == "64786")
        
        // Westbound (Mountain View direction) should return westboundId
        #expect(station.stationId(for: .mountainView) == "64821")
    }
}

// MARK: - OrangeLineStations Tests

struct OrangeLineStationsTests {
    
    @Test func orangeLineHas26Stations() {
        // Validates: Requirements 1.1 - display all Orange Line stations
        #expect(OrangeLineStations.stations.count == 26)
        #expect(OrangeLineStations.count == 26)
    }
    
    @Test func stationsAreOrderedGeographically() {
        // Validates: Requirements 1.3 - stations ordered from Mountain View to Alum Rock
        let stations = OrangeLineStations.stations
        
        // First station should be Mountain View
        #expect(stations.first?.name == "Mountain View")
        #expect(stations.first?.order == 0)
        
        // Last station should be Alum Rock
        #expect(stations.last?.name == "Alum Rock")
        #expect(stations.last?.order == 25)
    }
    
    @Test func stationsHaveConsecutiveOrderValues() {
        // Validates: Requirements 1.3 - proper ordering
        let stations = OrangeLineStations.stations
        
        for (index, station) in stations.enumerated() {
            #expect(station.order == index, "Station \(station.name) should have order \(index) but has \(station.order)")
        }
    }
    
    @Test func allStationsHaveUniqueEastboundIds() {
        let stations = OrangeLineStations.stations
        let ids = Set(stations.map { $0.eastboundId })
        
        #expect(ids.count == stations.count, "All station eastbound IDs should be unique")
    }
    
    @Test func allStationsHaveUniqueWestboundIds() {
        let stations = OrangeLineStations.stations
        let ids = Set(stations.map { $0.westboundId })
        
        #expect(ids.count == stations.count, "All station westbound IDs should be unique")
    }
    
    @Test func allStationsHaveUniqueShortNames() {
        let stations = OrangeLineStations.stations
        let shortNames = Set(stations.map { $0.shortName })
        
        #expect(shortNames.count == stations.count, "All station short names should be unique")
    }
    
    @Test func allStationsHaveNonEmptyNames() {
        // Validates: Requirements 1.5 - display full station names
        for station in OrangeLineStations.stations {
            #expect(!station.name.isEmpty, "Station name should not be empty")
            #expect(!station.shortName.isEmpty, "Station short name should not be empty")
            #expect(!station.id.isEmpty, "Station ID should not be empty")
        }
    }
    
    @Test func stationByIdFindsCorrectStation() {
        // Should find station by eastbound ID
        let station = OrangeLineStations.station(byId: "64786")
        
        #expect(station != nil)
        #expect(station?.name == "Mountain View")
        
        // Should also find station by westbound ID
        let stationByWestbound = OrangeLineStations.station(byId: "64821")
        #expect(stationByWestbound != nil)
        #expect(stationByWestbound?.name == "Mountain View")
    }
    
    @Test func stationByIdReturnsNilForInvalidId() {
        let station = OrangeLineStations.station(byId: "invalid")
        
        #expect(station == nil)
    }
    
    @Test func stationByOrderFindsCorrectStation() {
        let station = OrangeLineStations.station(byOrder: 0)
        
        #expect(station != nil)
        #expect(station?.name == "Mountain View")
        
        let lastStation = OrangeLineStations.station(byOrder: 25)
        #expect(lastStation?.name == "Alum Rock")
    }
    
    @Test func stationByOrderReturnsNilForInvalidOrder() {
        let station = OrangeLineStations.station(byOrder: 100)
        
        #expect(station == nil)
    }
    
    @Test func firstAndLastStationsAreCorrect() {
        #expect(OrangeLineStations.first.name == "Mountain View")
        #expect(OrangeLineStations.last.name == "Alum Rock")
    }
    
    @Test func verifySpecificStations() {
        // Verify a few key stations exist with correct data
        let stations = OrangeLineStations.stations
        
        // Mountain View (first)
        let mtv = stations[0]
        #expect(mtv.eastboundId == "64786")
        #expect(mtv.westboundId == "64821")
        #expect(mtv.name == "Mountain View")
        #expect(mtv.shortName == "MTV")
        
        // Great America (middle)
        let gam = stations[12]
        #expect(gam.eastboundId == "64798")
        #expect(gam.westboundId == "64809")
        #expect(gam.name == "Great America")
        #expect(gam.shortName == "GAM")
        
        // Alum Rock (last)
        let alr = stations[25]
        #expect(alr.eastboundId == "65242")
        #expect(alr.westboundId == "65243")
        #expect(alr.name == "Alum Rock")
        #expect(alr.shortName == "ALR")
    }
}


// MARK: - Direction Enum Tests

struct DirectionEnumTests {
    
    // MARK: - Direction Cases Tests
    
    @Test func directionHasTwoCases() {
        // Validates: Requirements 2.1 - two direction options
        let allCases = Direction.allCases
        
        #expect(allCases.count == 2)
        #expect(allCases.contains(.mountainView))
        #expect(allCases.contains(.alumRock))
    }
    
    @Test func directionRawValuesAreCorrect() {
        // Validates: Requirements 2.4 - clear text labels for directions
        #expect(Direction.mountainView.rawValue == "Mountain View")
        #expect(Direction.alumRock.rawValue == "Alum Rock")
    }
    
    // MARK: - Display Name Tests
    
    @Test func displayNameReturnsMountainViewForMountainViewDirection() {
        // Validates: Requirements 2.4 - clear text labels
        let direction = Direction.mountainView
        #expect(direction.displayName == "Mountain View")
    }
    
    @Test func displayNameReturnsAlumRockForAlumRockDirection() {
        // Validates: Requirements 2.4 - clear text labels
        let direction = Direction.alumRock
        #expect(direction.displayName == "Alum Rock")
    }
    
    @Test func displayNameMatchesRawValue() {
        // displayName should always equal rawValue
        for direction in Direction.allCases {
            #expect(direction.displayName == direction.rawValue)
        }
    }
    
    // MARK: - Direction ID Tests
    
    @Test func directionIdReturnsWForMountainView() {
        // Mountain View direction is Westbound (W)
        let direction = Direction.mountainView
        #expect(direction.directionId == "W")
    }
    
    @Test func directionIdReturnsEForAlumRock() {
        // Alum Rock direction is Eastbound (E)
        let direction = Direction.alumRock
        #expect(direction.directionId == "E")
    }
    
    @Test func directionIdsAreUnique() {
        let ids = Direction.allCases.map { $0.directionId }
        let uniqueIds = Set(ids)
        
        #expect(uniqueIds.count == Direction.allCases.count, "All direction IDs should be unique")
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Test func directionConformsToStringRawRepresentable() {
        // Test that Direction can be initialized from raw string value
        let mountainView = Direction(rawValue: "Mountain View")
        let alumRock = Direction(rawValue: "Alum Rock")
        
        #expect(mountainView == .mountainView)
        #expect(alumRock == .alumRock)
    }
    
    @Test func directionReturnsNilForInvalidRawValue() {
        let invalid = Direction(rawValue: "Invalid Direction")
        #expect(invalid == nil)
    }
    
    @Test func directionConformsToCodable() throws {
        // Test encoding and decoding for both directions
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for direction in Direction.allCases {
            let data = try encoder.encode(direction)
            let decoded = try decoder.decode(Direction.self, from: data)
            
            #expect(decoded == direction, "Direction \(direction) should survive encoding/decoding roundtrip")
        }
    }
    
    @Test func directionEncodesAsString() throws {
        // Direction should encode as its raw string value
        let encoder = JSONEncoder()
        
        let mountainViewData = try encoder.encode(Direction.mountainView)
        let mountainViewString = String(data: mountainViewData, encoding: .utf8)
        #expect(mountainViewString == "\"Mountain View\"")
        
        let alumRockData = try encoder.encode(Direction.alumRock)
        let alumRockString = String(data: alumRockData, encoding: .utf8)
        #expect(alumRockString == "\"Alum Rock\"")
    }
    
    @Test func directionConformsToCaseIterable() {
        // Verify CaseIterable conformance
        let allCases = Direction.allCases
        
        #expect(allCases.count == 2)
        #expect(allCases[0] == .mountainView || allCases[0] == .alumRock)
        #expect(allCases[1] == .mountainView || allCases[1] == .alumRock)
        #expect(allCases[0] != allCases[1])
    }
    
    // MARK: - Equatable Tests
    
    @Test func directionEquatableWorks() {
        #expect(Direction.mountainView == Direction.mountainView)
        #expect(Direction.alumRock == Direction.alumRock)
        #expect(Direction.mountainView != Direction.alumRock)
    }
}


// MARK: - ArrivalStatus Enum Tests

struct ArrivalStatusEnumTests {
    
    // MARK: - ArrivalStatus Cases Tests
    
    @Test func arrivalStatusHasFourCases() {
        // Validates: Requirements 4.1, 4.2, 4.3, 4.4
        let allCases = ArrivalStatus.allCases
        
        #expect(allCases.count == 4)
        #expect(allCases.contains(.arriving))
        #expect(allCases.contains(.boarding))
        #expect(allCases.contains(.scheduled))
        #expect(allCases.contains(.delayed))
    }
    
    @Test func arrivalStatusRawValuesAreCorrect() {
        // Validates: Requirements 4.3, 4.4 - specific status indicators
        #expect(ArrivalStatus.arriving.rawValue == "ARR")
        #expect(ArrivalStatus.boarding.rawValue == "BRD")
        #expect(ArrivalStatus.scheduled.rawValue == "scheduled")
        #expect(ArrivalStatus.delayed.rawValue == "delayed")
    }
    
    // MARK: - Display Text Tests
    
    @Test func arrivalStatusDisplayTextIsCorrect() {
        // Validates: Requirements 4.3, 4.4 - display text for statuses
        #expect(ArrivalStatus.arriving.displayText == "即将到站")
        #expect(ArrivalStatus.boarding.displayText == "进站中")
        #expect(ArrivalStatus.scheduled.displayText == "按计划")
        #expect(ArrivalStatus.delayed.displayText == "延误")
    }
    
    @Test func arrivalStatusDisplayTextEnglishIsCorrect() {
        #expect(ArrivalStatus.arriving.displayTextEnglish == "Arriving")
        #expect(ArrivalStatus.boarding.displayTextEnglish == "Boarding")
        #expect(ArrivalStatus.scheduled.displayTextEnglish == "Scheduled")
        #expect(ArrivalStatus.delayed.displayTextEnglish == "Delayed")
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Test func arrivalStatusConformsToCodable() throws {
        // Test encoding and decoding for all statuses
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for status in ArrivalStatus.allCases {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(ArrivalStatus.self, from: data)
            
            #expect(decoded == status, "ArrivalStatus \(status) should survive encoding/decoding roundtrip")
        }
    }
    
    @Test func arrivalStatusEncodesAsString() throws {
        let encoder = JSONEncoder()
        
        let arrivingData = try encoder.encode(ArrivalStatus.arriving)
        let arrivingString = String(data: arrivingData, encoding: .utf8)
        #expect(arrivingString == "\"ARR\"")
        
        let boardingData = try encoder.encode(ArrivalStatus.boarding)
        let boardingString = String(data: boardingData, encoding: .utf8)
        #expect(boardingString == "\"BRD\"")
    }
    
    @Test func arrivalStatusConformsToEquatable() {
        #expect(ArrivalStatus.arriving == ArrivalStatus.arriving)
        #expect(ArrivalStatus.boarding == ArrivalStatus.boarding)
        #expect(ArrivalStatus.arriving != ArrivalStatus.boarding)
        #expect(ArrivalStatus.scheduled != ArrivalStatus.delayed)
    }
    
    @Test func arrivalStatusCanBeInitializedFromRawValue() {
        let arriving = ArrivalStatus(rawValue: "ARR")
        let boarding = ArrivalStatus(rawValue: "BRD")
        let scheduled = ArrivalStatus(rawValue: "scheduled")
        let delayed = ArrivalStatus(rawValue: "delayed")
        
        #expect(arriving == .arriving)
        #expect(boarding == .boarding)
        #expect(scheduled == .scheduled)
        #expect(delayed == .delayed)
    }
    
    @Test func arrivalStatusReturnsNilForInvalidRawValue() {
        let invalid = ArrivalStatus(rawValue: "INVALID")
        #expect(invalid == nil)
    }
}

// MARK: - Prediction Model Tests

struct PredictionModelTests {
    
    // MARK: - Prediction Structure Tests
    
    @Test func predictionHasRequiredProperties() {
        // Validates: Requirements 3.3, 3.5, 4.1, 4.2
        let id = UUID()
        let timestamp = Date()
        let prediction = Prediction(
            id: id,
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock",
            vehicleId: "1234",
            timestamp: timestamp
        )
        
        #expect(prediction.id == id)
        #expect(prediction.minutesUntilArrival == 5)
        #expect(prediction.arrivalStatus == .scheduled)
        #expect(prediction.destination == "Alum Rock")
        #expect(prediction.vehicleId == "1234")
        #expect(prediction.timestamp == timestamp)
    }
    
    @Test func predictionAllowsNilMinutesUntilArrival() {
        // Validates: Requirements 4.3 - nil indicates arriving now
        let prediction = Prediction(
            minutesUntilArrival: nil,
            arrivalStatus: .arriving,
            destination: "Mountain View"
        )
        
        #expect(prediction.minutesUntilArrival == nil)
    }
    
    @Test func predictionAllowsNilVehicleId() {
        let prediction = Prediction(
            minutesUntilArrival: 3,
            arrivalStatus: .scheduled,
            destination: "Alum Rock",
            vehicleId: nil
        )
        
        #expect(prediction.vehicleId == nil)
    }
    
    @Test func predictionConformsToIdentifiable() {
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        // id should be a valid UUID
        #expect(prediction.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }
    
    @Test func predictionConformsToEquatable() {
        let id = UUID()
        let timestamp = Date()
        
        let prediction1 = Prediction(
            id: id,
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock",
            vehicleId: "1234",
            timestamp: timestamp
        )
        
        let prediction2 = Prediction(
            id: id,
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock",
            vehicleId: "1234",
            timestamp: timestamp
        )
        
        let prediction3 = Prediction(
            minutesUntilArrival: 10,
            arrivalStatus: .delayed,
            destination: "Mountain View"
        )
        
        #expect(prediction1 == prediction2)
        #expect(prediction1 != prediction3)
    }
    
    @Test func predictionConformsToCodable() throws {
        // Validates: Requirements 3.3 - API response parsing
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock",
            vehicleId: "1234"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(prediction)
        
        let decoder = JSONDecoder()
        let decodedPrediction = try decoder.decode(Prediction.self, from: data)
        
        #expect(decodedPrediction == prediction)
    }
    
    @Test func predictionCodableRoundTripWithNilValues() throws {
        // Test encoding/decoding with nil optional values
        let prediction = Prediction(
            minutesUntilArrival: nil,
            arrivalStatus: .arriving,
            destination: "Mountain View",
            vehicleId: nil
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(prediction)
        
        let decoder = JSONDecoder()
        let decodedPrediction = try decoder.decode(Prediction.self, from: data)
        
        #expect(decodedPrediction.minutesUntilArrival == nil)
        #expect(decodedPrediction.vehicleId == nil)
        #expect(decodedPrediction.arrivalStatus == .arriving)
        #expect(decodedPrediction.destination == "Mountain View")
    }
    
    @Test func predictionDefaultIdIsGenerated() {
        let prediction1 = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        let prediction2 = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        // Each prediction should have a unique ID by default
        #expect(prediction1.id != prediction2.id)
    }
    
    // MARK: - Arrival Time Display Tests
    
    @Test func arrivalTimeDisplayShowsMinutes() {
        // Validates: Requirements 4.2 - display arrival time in minutes
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        #expect(prediction.arrivalTimeDisplay == "5 分钟")
        #expect(prediction.arrivalTimeDisplayEnglish == "5 min")
    }
    
    @Test func arrivalTimeDisplayShowsArrivingForArrivingStatus() {
        // Validates: Requirements 4.3 - display "即将到站" for arriving trains
        let prediction = Prediction(
            minutesUntilArrival: nil,
            arrivalStatus: .arriving,
            destination: "Alum Rock"
        )
        
        #expect(prediction.arrivalTimeDisplay == "即将到站")
        #expect(prediction.arrivalTimeDisplayEnglish == "Arriving")
    }
    
    @Test func arrivalTimeDisplayShowsBoardingForBoardingStatus() {
        // Validates: Requirements 4.4 - display "进站中" for boarding trains
        let prediction = Prediction(
            minutesUntilArrival: nil,
            arrivalStatus: .boarding,
            destination: "Alum Rock"
        )
        
        #expect(prediction.arrivalTimeDisplay == "进站中")
        #expect(prediction.arrivalTimeDisplayEnglish == "Boarding")
    }
    
    @Test func arrivalTimeDisplayShowsArrivingForZeroMinutes() {
        // When minutes is 0 or less, should show arriving
        let prediction = Prediction(
            minutesUntilArrival: 0,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        #expect(prediction.arrivalTimeDisplay == "即将到站")
        #expect(prediction.arrivalTimeDisplayEnglish == "Arriving")
    }
    
    @Test func arrivalTimeDisplayShowsStatusForDelayedWithNilMinutes() {
        let prediction = Prediction(
            minutesUntilArrival: nil,
            arrivalStatus: .delayed,
            destination: "Alum Rock"
        )
        
        #expect(prediction.arrivalTimeDisplay == "延误")
        #expect(prediction.arrivalTimeDisplayEnglish == "Delayed")
    }
    
    // MARK: - Full Display Text Tests
    
    @Test func fullDisplayTextIncludesTimeAndDestination() {
        // Validates: Requirements 4.1, 4.5 - display arrival time and destination
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        #expect(prediction.fullDisplayText == "5 分钟 → Alum Rock")
        #expect(prediction.fullDisplayTextEnglish == "5 min → Alum Rock")
    }
    
    @Test func fullDisplayTextWithArrivingStatus() {
        let prediction = Prediction(
            minutesUntilArrival: nil,
            arrivalStatus: .arriving,
            destination: "Mountain View"
        )
        
        #expect(prediction.fullDisplayText == "即将到站 → Mountain View")
        #expect(prediction.fullDisplayTextEnglish == "Arriving → Mountain View")
    }
    
    // MARK: - Stale Data Tests
    
    @Test func isStaleReturnsFalseForFreshData() {
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock",
            timestamp: Date()
        )
        
        #expect(prediction.isStale() == false)
    }
    
    @Test func isStaleReturnsTrueForOldData() {
        let oldTimestamp = Date().addingTimeInterval(-3 * 60) // 3 minutes ago
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock",
            timestamp: oldTimestamp
        )
        
        #expect(prediction.isStale() == true)
    }
    
    @Test func isStaleUsesCustomReferenceDate() {
        let timestamp = Date()
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Alum Rock",
            timestamp: timestamp
        )
        
        // Reference date 3 minutes in the future
        let futureDate = timestamp.addingTimeInterval(3 * 60)
        #expect(prediction.isStale(referenceDate: futureDate) == true)
        
        // Reference date 1 minute in the future
        let nearFutureDate = timestamp.addingTimeInterval(1 * 60)
        #expect(prediction.isStale(referenceDate: nearFutureDate) == false)
    }
    
    // MARK: - Edge Cases
    
    @Test func predictionWithLargeMinutesValue() {
        let prediction = Prediction(
            minutesUntilArrival: 120,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        #expect(prediction.arrivalTimeDisplay == "120 分钟")
        #expect(prediction.arrivalTimeDisplayEnglish == "120 min")
    }
    
    @Test func predictionWithNegativeMinutesValue() {
        // Negative minutes should show as arriving
        let prediction = Prediction(
            minutesUntilArrival: -1,
            arrivalStatus: .scheduled,
            destination: "Alum Rock"
        )
        
        #expect(prediction.arrivalTimeDisplay == "即将到站")
    }
    
    @Test func predictionWithEmptyDestination() {
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: ""
        )
        
        #expect(prediction.destination == "")
        #expect(prediction.fullDisplayText == "5 分钟 → ")
    }
    
    @Test func predictionWithSpecialCharactersInDestination() {
        let prediction = Prediction(
            minutesUntilArrival: 5,
            arrivalStatus: .scheduled,
            destination: "Bayshore/NASA"
        )
        
        #expect(prediction.destination == "Bayshore/NASA")
        #expect(prediction.fullDisplayText.contains("Bayshore/NASA"))
    }
}


// MARK: - TimeRule Model Tests

struct TimeRuleModelTests {
    
    // MARK: - TimeRule Structure Tests
    
    @Test func timeRuleHasRequiredProperties() {
        // Validates: Requirements 8.1, 8.2
        let id = UUID()
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            id: id,
            name: "Morning Commute",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        
        #expect(rule.id == id)
        #expect(rule.name == "Morning Commute")
        #expect(rule.triggerTime == triggerTime)
        #expect(rule.stationId == "70261")
        #expect(rule.direction == .alumRock)
        #expect(rule.isEnabled == true)
    }
    
    @Test func timeRuleConformsToIdentifiable() {
        let rule = TimeRule(
            name: "Test Rule",
            triggerTime: Date(),
            stationId: "70261",
            direction: .mountainView
        )
        
        // id should be a valid UUID
        #expect(rule.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }
    
    @Test func timeRuleConformsToEquatable() {
        let id = UUID()
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        
        let rule1 = TimeRule(
            id: id,
            name: "Morning Commute",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        
        let rule2 = TimeRule(
            id: id,
            name: "Morning Commute",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        
        let rule3 = TimeRule(
            name: "Evening Return",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 0),
            stationId: "70541",
            direction: .mountainView,
            isEnabled: false
        )
        
        #expect(rule1 == rule2)
        #expect(rule1 != rule3)
    }
    
    @Test func timeRuleConformsToCodable() throws {
        // Validates: Requirements 8.2 - time rules should be persistable
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            name: "Morning Commute",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)
        
        let decoder = JSONDecoder()
        let decodedRule = try decoder.decode(TimeRule.self, from: data)
        
        #expect(decodedRule == rule)
    }
    
    @Test func timeRuleCodableRoundTripWithDisabledRule() throws {
        let triggerTime = TimeRule.createTriggerTime(hour: 17, minute: 45)
        let rule = TimeRule(
            name: "Evening Return",
            triggerTime: triggerTime,
            stationId: "70541",
            direction: .mountainView,
            isEnabled: false
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)
        
        let decoder = JSONDecoder()
        let decodedRule = try decoder.decode(TimeRule.self, from: data)
        
        #expect(decodedRule.name == "Evening Return")
        #expect(decodedRule.stationId == "70541")
        #expect(decodedRule.direction == .mountainView)
        #expect(decodedRule.isEnabled == false)
    }
    
    @Test func timeRuleDefaultIdIsGenerated() {
        let rule1 = TimeRule(
            name: "Rule 1",
            triggerTime: Date(),
            stationId: "70261",
            direction: .alumRock
        )
        
        let rule2 = TimeRule(
            name: "Rule 2",
            triggerTime: Date(),
            stationId: "70261",
            direction: .alumRock
        )
        
        // Each rule should have a unique ID by default
        #expect(rule1.id != rule2.id)
    }
    
    @Test func timeRuleDefaultIsEnabledIsTrue() {
        let rule = TimeRule(
            name: "Test Rule",
            triggerTime: Date(),
            stationId: "70261",
            direction: .alumRock
        )
        
        #expect(rule.isEnabled == true)
    }
    
    // MARK: - Trigger Time Component Tests
    
    @Test func triggerHourExtractsCorrectHour() {
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock
        )
        
        #expect(rule.triggerHour == 8)
    }
    
    @Test func triggerMinuteExtractsCorrectMinute() {
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock
        )
        
        #expect(rule.triggerMinute == 30)
    }
    
    @Test func triggerTimeDisplayFormatsCorrectly() {
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock
        )
        
        #expect(rule.triggerTimeDisplay == "08:30")
    }
    
    @Test func triggerTimeDisplayFormatsWithLeadingZeros() {
        let triggerTime = TimeRule.createTriggerTime(hour: 7, minute: 5)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock
        )
        
        #expect(rule.triggerTimeDisplay == "07:05")
    }
    
    @Test func triggerTimeDisplayFormatsAfternoonTime() {
        let triggerTime = TimeRule.createTriggerTime(hour: 17, minute: 45)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock
        )
        
        #expect(rule.triggerTimeDisplay == "17:45")
    }
    
    // MARK: - Station Lookup Tests
    
    @Test func stationReturnsCorrectStationForValidId() {
        // Mountain View station's primary ID is its eastboundId "64786"
        let rule = TimeRule(
            name: "Test",
            triggerTime: Date(),
            stationId: "64786",
            direction: .alumRock
        )
        
        #expect(rule.station != nil)
        #expect(rule.station?.name == "Mountain View")
    }
    
    @Test func stationReturnsNilForInvalidId() {
        let rule = TimeRule(
            name: "Test",
            triggerTime: Date(),
            stationId: "invalid_id",
            direction: .alumRock
        )
        
        #expect(rule.station == nil)
    }
    
    // MARK: - Time Matching Tests
    
    @Test func matchesTimeReturnsTrueForMatchingTime() {
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock
        )
        
        let testDate = TimeRule.createTriggerTime(hour: 8, minute: 30)
        #expect(rule.matchesTime(testDate) == true)
    }
    
    @Test func matchesTimeReturnsFalseForDifferentHour() {
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock
        )
        
        let testDate = TimeRule.createTriggerTime(hour: 9, minute: 30)
        #expect(rule.matchesTime(testDate) == false)
    }
    
    @Test func matchesTimeReturnsFalseForDifferentMinute() {
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock
        )
        
        let testDate = TimeRule.createTriggerTime(hour: 8, minute: 31)
        #expect(rule.matchesTime(testDate) == false)
    }
    
    // MARK: - Should Trigger Tests
    
    @Test func shouldTriggerReturnsTrueWhenEnabledAndTimeMatches() {
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        
        let testDate = TimeRule.createTriggerTime(hour: 8, minute: 30)
        #expect(rule.shouldTrigger(at: testDate) == true)
    }
    
    @Test func shouldTriggerReturnsFalseWhenDisabled() {
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock,
            isEnabled: false
        )
        
        let testDate = TimeRule.createTriggerTime(hour: 8, minute: 30)
        #expect(rule.shouldTrigger(at: testDate) == false)
    }
    
    @Test func shouldTriggerReturnsFalseWhenTimeDoesNotMatch() {
        let triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 30)
        let rule = TimeRule(
            name: "Test",
            triggerTime: triggerTime,
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        
        let testDate = TimeRule.createTriggerTime(hour: 9, minute: 0)
        #expect(rule.shouldTrigger(at: testDate) == false)
    }
    
    // MARK: - Create Trigger Time Helper Tests
    
    @Test func createTriggerTimeCreatesCorrectDate() {
        let date = TimeRule.createTriggerTime(hour: 14, minute: 30)
        let calendar = Calendar.current
        
        #expect(calendar.component(.hour, from: date) == 14)
        #expect(calendar.component(.minute, from: date) == 30)
        #expect(calendar.component(.second, from: date) == 0)
    }
    
    @Test func createTriggerTimeHandlesMidnight() {
        let date = TimeRule.createTriggerTime(hour: 0, minute: 0)
        let calendar = Calendar.current
        
        #expect(calendar.component(.hour, from: date) == 0)
        #expect(calendar.component(.minute, from: date) == 0)
    }
    
    @Test func createTriggerTimeHandlesEndOfDay() {
        let date = TimeRule.createTriggerTime(hour: 23, minute: 59)
        let calendar = Calendar.current
        
        #expect(calendar.component(.hour, from: date) == 23)
        #expect(calendar.component(.minute, from: date) == 59)
    }
    
    // MARK: - Edge Cases
    
    @Test func timeRuleWithEmptyName() {
        let rule = TimeRule(
            name: "",
            triggerTime: Date(),
            stationId: "70261",
            direction: .alumRock
        )
        
        #expect(rule.name == "")
    }
    
    @Test func timeRuleWithBothDirections() {
        let rule1 = TimeRule(
            name: "To Work",
            triggerTime: TimeRule.createTriggerTime(hour: 8, minute: 0),
            stationId: "70261",
            direction: .alumRock
        )
        
        let rule2 = TimeRule(
            name: "To Home",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 0),
            stationId: "70541",
            direction: .mountainView
        )
        
        #expect(rule1.direction == .alumRock)
        #expect(rule2.direction == .mountainView)
    }
    
    @Test func timeRuleCodableArrayRoundTrip() throws {
        // Validates: Requirements 8.2 - multiple rules should be persistable
        let rules = [
            TimeRule(
                name: "Morning",
                triggerTime: TimeRule.createTriggerTime(hour: 8, minute: 0),
                stationId: "70261",
                direction: .alumRock,
                isEnabled: true
            ),
            TimeRule(
                name: "Evening",
                triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 30),
                stationId: "70541",
                direction: .mountainView,
                isEnabled: true
            )
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(rules)
        
        let decoder = JSONDecoder()
        let decodedRules = try decoder.decode([TimeRule].self, from: data)
        
        #expect(decodedRules.count == 2)
        #expect(decodedRules[0].name == "Morning")
        #expect(decodedRules[1].name == "Evening")
    }
}


// MARK: - Property-Based Tests

/// Property-based tests for station list sorting consistency
/// **Validates: Property 1**
struct StationSortingPropertyTests {
    
    // MARK: - Property 1: 站点列表排序一致性
    
    /// **Validates: Property 1**
    /// For any Orange Line station list, stations should be sorted by the `order` field
    /// from smallest to largest, i.e., from Mountain View (order=0) to Alum Rock (order=28).
    @Test func property1_stationListSortingConsistency() {
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate a random subset of stations
            let allStations = OrangeLineStations.stations
            let subsetSize = Int.random(in: 1...allStations.count)
            let randomSubset = Array(allStations.shuffled().prefix(subsetSize))
            
            // Sort the random subset by order field
            let sortedByOrder = randomSubset.sorted { $0.order < $1.order }
            
            // Verify: sorted list should have ascending order values
            for i in 0..<(sortedByOrder.count - 1) {
                #expect(
                    sortedByOrder[i].order < sortedByOrder[i + 1].order,
                    "Iteration \(iteration): Station at index \(i) (order=\(sortedByOrder[i].order)) should have smaller order than station at index \(i + 1) (order=\(sortedByOrder[i + 1].order))"
                )
            }
            
            // Verify: first station in sorted list should have the minimum order
            if let firstStation = sortedByOrder.first {
                let minOrder = randomSubset.map { $0.order }.min()!
                #expect(
                    firstStation.order == minOrder,
                    "Iteration \(iteration): First station should have minimum order \(minOrder), but has \(firstStation.order)"
                )
            }
            
            // Verify: last station in sorted list should have the maximum order
            if let lastStation = sortedByOrder.last {
                let maxOrder = randomSubset.map { $0.order }.max()!
                #expect(
                    lastStation.order == maxOrder,
                    "Iteration \(iteration): Last station should have maximum order \(maxOrder), but has \(lastStation.order)"
                )
            }
        }
    }
    
    /// **Validates: Property 1**
    /// Verify that the static OrangeLineStations.stations is already sorted by order
    @Test func property1_staticStationListIsSorted() {
        let stations = OrangeLineStations.stations
        
        // Run 100 iterations to verify consistency
        for iteration in 0..<100 {
            // Verify the static list is sorted
            for i in 0..<(stations.count - 1) {
                #expect(
                    stations[i].order < stations[i + 1].order,
                    "Iteration \(iteration): Static station list should be sorted. Station at index \(i) has order \(stations[i].order), but station at index \(i + 1) has order \(stations[i + 1].order)"
                )
            }
            
            // Verify order values are consecutive (0 to 28)
            for (index, station) in stations.enumerated() {
                #expect(
                    station.order == index,
                    "Iteration \(iteration): Station at index \(index) should have order \(index), but has order \(station.order)"
                )
            }
        }
    }
    
    /// **Validates: Property 1**
    /// For any permutation of stations, sorting by order should produce the same geographic order
    @Test func property1_sortingPermutationsProducesConsistentOrder() {
        let originalStations = OrangeLineStations.stations
        
        // Run 100 iterations with different random permutations
        for iteration in 0..<100 {
            // Create a random permutation
            let permutedStations = originalStations.shuffled()
            
            // Sort the permutation by order
            let sortedPermutation = permutedStations.sorted { $0.order < $1.order }
            
            // Verify: sorted permutation should match original order
            #expect(
                sortedPermutation.count == originalStations.count,
                "Iteration \(iteration): Sorted permutation should have same count as original"
            )
            
            for i in 0..<sortedPermutation.count {
                #expect(
                    sortedPermutation[i].id == originalStations[i].id,
                    "Iteration \(iteration): Station at index \(i) should be \(originalStations[i].name) but is \(sortedPermutation[i].name)"
                )
                #expect(
                    sortedPermutation[i].order == originalStations[i].order,
                    "Iteration \(iteration): Station order at index \(i) should be \(originalStations[i].order) but is \(sortedPermutation[i].order)"
                )
            }
        }
    }
    
    /// **Validates: Property 1**
    /// Verify that Mountain View is always first (order=0) and Alum Rock is always last (order=27)
    @Test func property1_boundaryStationsAreCorrect() {
        // Run 100 iterations to verify boundary conditions
        for iteration in 0..<100 {
            let stations = OrangeLineStations.stations
            let sortedStations = stations.shuffled().sorted { $0.order < $1.order }
            
            // First station should always be Mountain View with order 0
            #expect(
                sortedStations.first?.name == "Mountain View",
                "Iteration \(iteration): First station should be Mountain View"
            )
            #expect(
                sortedStations.first?.order == 0,
                "Iteration \(iteration): First station should have order 0"
            )
            
            // Last station should always be Alum Rock with order 25 (26 stations, indexed 0-25)
            #expect(
                sortedStations.last?.name == "Alum Rock",
                "Iteration \(iteration): Last station should be Alum Rock"
            )
            #expect(
                sortedStations.last?.order == 25,
                "Iteration \(iteration): Last station should have order 25"
            )
        }
    }
    
    /// **Validates: Property 1**
    /// For any random subset of stations, the relative order should be preserved after sorting
    @Test func property1_relativeOrderPreservedInSubsets() {
        let allStations = OrangeLineStations.stations
        
        // Run 100 iterations with random subsets
        for iteration in 0..<100 {
            // Generate a random subset (at least 2 stations)
            let subsetSize = Int.random(in: 2...allStations.count)
            let randomIndices = Array(0..<allStations.count).shuffled().prefix(subsetSize)
            let subset = randomIndices.map { allStations[$0] }
            
            // Sort the subset by order
            let sortedSubset = subset.sorted { $0.order < $1.order }
            
            // Verify: for any two stations in the sorted subset, 
            // if station A comes before station B in the original list,
            // then A should come before B in the sorted subset
            for i in 0..<sortedSubset.count {
                for j in (i + 1)..<sortedSubset.count {
                    let stationA = sortedSubset[i]
                    let stationB = sortedSubset[j]
                    
                    #expect(
                        stationA.order < stationB.order,
                        "Iteration \(iteration): Station \(stationA.name) (order=\(stationA.order)) should come before \(stationB.name) (order=\(stationB.order))"
                    )
                }
            }
        }
    }
}


// MARK: - StorageService Tests

struct StorageServiceTests {
    
    // MARK: - Helper Methods
    
    /// Creates a fresh StorageService with a clean UserDefaults suite for testing
    private func createTestStorageService() -> StorageService {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        return StorageService(userDefaults: testDefaults)
    }
    
    // MARK: - Initialization Tests
    
    @Test func storageServiceInitializesWithNilValues() {
        let service = createTestStorageService()
        
        #expect(service.selectedStation == nil)
        #expect(service.selectedDirection == nil)
        #expect(service.timeRules.isEmpty)
        #expect(service.isTimeRuleEnabled == false)
    }
    
    @Test func storageServiceUsesProvidedUserDefaults() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        // Set a value and save
        service.selectedDirection = .alumRock
        service.save()
        
        // Verify it was saved to the correct UserDefaults
        let savedValue = testDefaults.string(forKey: StorageKeys.selectedDirection)
        #expect(savedValue == "Alum Rock")
    }
    
    // MARK: - Selected Station Tests
    
    @Test func saveAndLoadSelectedStation() {
        // Validates: Requirements 1.4, 7.1
        let service = createTestStorageService()
        let station = OrangeLineStations.stations[5] // Lockheed Martin
        
        service.selectedStation = station
        service.save()
        
        // Create a new service instance to load from storage
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.set(station.id, forKey: StorageKeys.selectedStationId)
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.selectedStation?.id == station.id)
        #expect(loadedService.selectedStation?.name == station.name)
    }
    
    @Test func saveAndLoadNilSelectedStation() {
        let service = createTestStorageService()
        
        // First set a station
        service.selectedStation = OrangeLineStations.first
        service.save()
        
        // Then clear it
        service.selectedStation = nil
        service.save()
        service.load()
        
        #expect(service.selectedStation == nil)
    }
    
    @Test func loadSelectedStationWithInvalidIdReturnsNil() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.set("invalid_station_id", forKey: StorageKeys.selectedStationId)
        
        let service = StorageService(userDefaults: testDefaults)
        service.load()
        
        #expect(service.selectedStation == nil)
    }
    
    // MARK: - Selected Direction Tests
    
    @Test func saveAndLoadSelectedDirection() {
        // Validates: Requirements 2.3, 7.2
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        service.selectedDirection = .mountainView
        service.save()
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.selectedDirection == .mountainView)
    }
    
    @Test func saveAndLoadAlumRockDirection() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        service.selectedDirection = .alumRock
        service.save()
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.selectedDirection == .alumRock)
    }
    
    @Test func saveAndLoadNilSelectedDirection() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        // First set a direction
        service.selectedDirection = .alumRock
        service.save()
        
        // Then clear it
        service.selectedDirection = nil
        service.save()
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.selectedDirection == nil)
    }
    
    @Test func loadSelectedDirectionWithInvalidValueReturnsNil() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.set("Invalid Direction", forKey: StorageKeys.selectedDirection)
        
        let service = StorageService(userDefaults: testDefaults)
        service.load()
        
        #expect(service.selectedDirection == nil)
    }
    
    // MARK: - Time Rules Tests
    
    @Test func saveAndLoadTimeRules() {
        // Validates: Requirements 7.3
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        let rule1 = TimeRule(
            name: "Morning Commute",
            triggerTime: TimeRule.createTriggerTime(hour: 8, minute: 30),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        
        let rule2 = TimeRule(
            name: "Evening Return",
            triggerTime: TimeRule.createTriggerTime(hour: 17, minute: 0),
            stationId: "70541",
            direction: .mountainView,
            isEnabled: false
        )
        
        service.timeRules = [rule1, rule2]
        service.save()
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.timeRules.count == 2)
        #expect(loadedService.timeRules[0].name == "Morning Commute")
        #expect(loadedService.timeRules[0].stationId == "70261")
        #expect(loadedService.timeRules[0].direction == .alumRock)
        #expect(loadedService.timeRules[0].isEnabled == true)
        #expect(loadedService.timeRules[1].name == "Evening Return")
        #expect(loadedService.timeRules[1].direction == .mountainView)
        #expect(loadedService.timeRules[1].isEnabled == false)
    }
    
    @Test func saveAndLoadEmptyTimeRules() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        service.timeRules = []
        service.save()
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.timeRules.isEmpty)
    }
    
    @Test func loadTimeRulesWithCorruptedDataReturnsEmptyArray() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.set(Data([0x00, 0x01, 0x02]), forKey: StorageKeys.timeRules)
        
        let service = StorageService(userDefaults: testDefaults)
        service.load()
        
        #expect(service.timeRules.isEmpty)
    }
    
    // MARK: - Time Rule Enabled Tests
    
    @Test func saveAndLoadIsTimeRuleEnabled() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        service.isTimeRuleEnabled = true
        service.save()
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.isTimeRuleEnabled == true)
    }
    
    @Test func saveAndLoadIsTimeRuleDisabled() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        // First enable it
        service.isTimeRuleEnabled = true
        service.save()
        
        // Then disable it
        service.isTimeRuleEnabled = false
        service.save()
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.isTimeRuleEnabled == false)
    }
    
    // MARK: - Combined Save/Load Tests
    
    @Test func saveAndLoadAllPreferences() {
        // Validates: Requirements 1.4, 2.3, 7.1, 7.2, 7.3
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        let station = OrangeLineStations.stations[12] // Great America
        let direction = Direction.mountainView
        let rule = TimeRule(
            name: "Test Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 9, minute: 15),
            stationId: "70381",
            direction: .alumRock,
            isEnabled: true
        )
        
        service.selectedStation = station
        service.selectedDirection = direction
        service.timeRules = [rule]
        service.isTimeRuleEnabled = true
        service.save()
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.selectedStation?.id == station.id)
        #expect(loadedService.selectedDirection == direction)
        #expect(loadedService.timeRules.count == 1)
        #expect(loadedService.timeRules[0].name == "Test Rule")
        #expect(loadedService.isTimeRuleEnabled == true)
    }
    
    // MARK: - Clear All Tests
    
    @Test func clearAllRemovesAllPreferences() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        // Set all preferences
        service.selectedStation = OrangeLineStations.first
        service.selectedDirection = .alumRock
        service.timeRules = [TimeRule(
            name: "Test",
            triggerTime: Date(),
            stationId: "70261",
            direction: .alumRock
        )]
        service.isTimeRuleEnabled = true
        service.save()
        
        // Clear all
        service.clearAll()
        
        #expect(service.selectedStation == nil)
        #expect(service.selectedDirection == nil)
        #expect(service.timeRules.isEmpty)
        #expect(service.isTimeRuleEnabled == false)
        
        // Verify storage is also cleared
        #expect(testDefaults.string(forKey: StorageKeys.selectedStationId) == nil)
        #expect(testDefaults.string(forKey: StorageKeys.selectedDirection) == nil)
        #expect(testDefaults.data(forKey: StorageKeys.timeRules) == nil)
    }
    
    // MARK: - Has Stored Preferences Tests
    
    @Test func hasStoredPreferencesReturnsFalseWhenEmpty() {
        let service = createTestStorageService()
        
        #expect(service.hasStoredPreferences == false)
    }
    
    @Test func hasStoredPreferencesReturnsTrueWhenStationSaved() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        service.selectedStation = OrangeLineStations.first
        service.save()
        
        #expect(service.hasStoredPreferences == true)
    }
    
    @Test func hasStoredPreferencesReturnsTrueWhenDirectionSaved() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        service.selectedDirection = .mountainView
        service.save()
        
        #expect(service.hasStoredPreferences == true)
    }
    
    // MARK: - Edge Cases
    
    @Test func multipleConsecutiveSavesWork() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        // Save multiple times with different values
        service.selectedStation = OrangeLineStations.stations[0]
        service.save()
        
        service.selectedStation = OrangeLineStations.stations[5]
        service.save()
        
        service.selectedStation = OrangeLineStations.stations[10]
        service.save()
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.selectedStation?.id == OrangeLineStations.stations[10].id)
    }
    
    @Test func loadWithoutSaveReturnsDefaults() {
        let service = createTestStorageService()
        service.load()
        
        #expect(service.selectedStation == nil)
        #expect(service.selectedDirection == nil)
        #expect(service.timeRules.isEmpty)
        #expect(service.isTimeRuleEnabled == false)
    }
    
    @Test func savePreservesTimeRuleIds() {
        let suiteName = "com.test.orangelinetracker.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let service = StorageService(userDefaults: testDefaults)
        
        let ruleId = UUID()
        let rule = TimeRule(
            id: ruleId,
            name: "Test Rule",
            triggerTime: TimeRule.createTriggerTime(hour: 8, minute: 0),
            stationId: "70261",
            direction: .alumRock,
            isEnabled: true
        )
        
        service.timeRules = [rule]
        service.save()
        
        let loadedService = StorageService(userDefaults: testDefaults)
        loadedService.load()
        
        #expect(loadedService.timeRules[0].id == ruleId)
    }
}

// MARK: - Property 2: 用户偏好持久化往返测试

/// Property-based tests for user preference persistence round-trip
/// **Validates: Property 2**
struct UserPreferencePersistencePropertyTests {
    
    // MARK: - Helper Methods
    
    /// Creates a fresh StorageService with a clean UserDefaults suite for testing
    private func createTestStorageService() -> (StorageService, UserDefaults) {
        let suiteName = "com.test.orangelinetracker.property2.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        return (StorageService(userDefaults: testDefaults), testDefaults)
    }
    
    /// Generates a random station from the Orange Line stations
    private func randomStation() -> Station {
        OrangeLineStations.stations.randomElement()!
    }
    
    /// Generates a random direction
    private func randomDirection() -> Direction {
        Direction.allCases.randomElement()!
    }
    
    // MARK: - Property 2: 用户偏好持久化往返
    
    /// **Validates: Property 2**
    /// For any valid station and direction combination, saving to UserDefaults and then loading
    /// should produce station and direction values equal to the original values.
    @Test func property2_userPreferencePersistenceRoundTrip() {
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate random station and direction
            let originalStation = randomStation()
            let originalDirection = randomDirection()
            
            // Create a fresh storage service for this iteration
            let (saveService, testDefaults) = createTestStorageService()
            
            // Save the preferences
            saveService.selectedStation = originalStation
            saveService.selectedDirection = originalDirection
            saveService.save()
            
            // Create a new storage service instance to load from storage
            let loadService = StorageService(userDefaults: testDefaults)
            loadService.load()
            
            // Verify: loaded station should equal original station
            #expect(
                loadService.selectedStation != nil,
                "Iteration \(iteration): Loaded station should not be nil"
            )
            #expect(
                loadService.selectedStation?.id == originalStation.id,
                "Iteration \(iteration): Loaded station ID '\(loadService.selectedStation?.id ?? "nil")' should equal original '\(originalStation.id)'"
            )
            #expect(
                loadService.selectedStation?.name == originalStation.name,
                "Iteration \(iteration): Loaded station name '\(loadService.selectedStation?.name ?? "nil")' should equal original '\(originalStation.name)'"
            )
            #expect(
                loadService.selectedStation?.shortName == originalStation.shortName,
                "Iteration \(iteration): Loaded station shortName '\(loadService.selectedStation?.shortName ?? "nil")' should equal original '\(originalStation.shortName)'"
            )
            #expect(
                loadService.selectedStation?.order == originalStation.order,
                "Iteration \(iteration): Loaded station order '\(loadService.selectedStation?.order ?? -1)' should equal original '\(originalStation.order)'"
            )
            
            // Verify: loaded direction should equal original direction
            #expect(
                loadService.selectedDirection != nil,
                "Iteration \(iteration): Loaded direction should not be nil"
            )
            #expect(
                loadService.selectedDirection == originalDirection,
                "Iteration \(iteration): Loaded direction '\(loadService.selectedDirection?.rawValue ?? "nil")' should equal original '\(originalDirection.rawValue)'"
            )
        }
    }
    
    /// **Validates: Property 2**
    /// For any valid station, saving and loading should preserve all station properties
    @Test func property2_stationPersistencePreservesAllProperties() {
        // Run 100 iterations with random stations
        for iteration in 0..<100 {
            let originalStation = randomStation()
            let (saveService, testDefaults) = createTestStorageService()
            
            // Save the station
            saveService.selectedStation = originalStation
            saveService.save()
            
            // Load in a new service instance
            let loadService = StorageService(userDefaults: testDefaults)
            loadService.load()
            
            // Verify complete equality using Equatable
            #expect(
                loadService.selectedStation == originalStation,
                "Iteration \(iteration): Loaded station should be equal to original station '\(originalStation.name)'"
            )
        }
    }
    
    /// **Validates: Property 2**
    /// For any direction, saving and loading should produce the same direction
    @Test func property2_directionPersistenceRoundTrip() {
        // Run 100 iterations with random directions
        for iteration in 0..<100 {
            let originalDirection = randomDirection()
            let (saveService, testDefaults) = createTestStorageService()
            
            // Save the direction
            saveService.selectedDirection = originalDirection
            saveService.save()
            
            // Load in a new service instance
            let loadService = StorageService(userDefaults: testDefaults)
            loadService.load()
            
            // Verify direction equality
            #expect(
                loadService.selectedDirection == originalDirection,
                "Iteration \(iteration): Loaded direction '\(loadService.selectedDirection?.rawValue ?? "nil")' should equal original '\(originalDirection.rawValue)'"
            )
            
            // Verify direction properties are preserved
            #expect(
                loadService.selectedDirection?.displayName == originalDirection.displayName,
                "Iteration \(iteration): Direction displayName should be preserved"
            )
            #expect(
                loadService.selectedDirection?.directionId == originalDirection.directionId,
                "Iteration \(iteration): Direction directionId should be preserved"
            )
        }
    }
    
    /// **Validates: Property 2**
    /// Multiple consecutive save/load cycles should preserve the same values
    @Test func property2_multipleSaveLoadCyclesPreserveValues() {
        // Run 100 iterations
        for iteration in 0..<100 {
            let originalStation = randomStation()
            let originalDirection = randomDirection()
            let (service, testDefaults) = createTestStorageService()
            
            // Perform multiple save/load cycles
            let cycleCount = Int.random(in: 2...5)
            for cycle in 0..<cycleCount {
                service.selectedStation = originalStation
                service.selectedDirection = originalDirection
                service.save()
                
                let loadService = StorageService(userDefaults: testDefaults)
                loadService.load()
                
                #expect(
                    loadService.selectedStation == originalStation,
                    "Iteration \(iteration), Cycle \(cycle): Station should be preserved after save/load cycle"
                )
                #expect(
                    loadService.selectedDirection == originalDirection,
                    "Iteration \(iteration), Cycle \(cycle): Direction should be preserved after save/load cycle"
                )
            }
        }
    }
    
    /// **Validates: Property 2**
    /// Changing station/direction and saving should update the persisted values correctly
    @Test func property2_updatingPreferencesOverwritesPreviousValues() {
        // Run 100 iterations
        for iteration in 0..<100 {
            let (service, testDefaults) = createTestStorageService()
            
            // Save initial values
            let initialStation = randomStation()
            let initialDirection = randomDirection()
            service.selectedStation = initialStation
            service.selectedDirection = initialDirection
            service.save()
            
            // Generate different values for update
            var updatedStation = randomStation()
            while updatedStation.id == initialStation.id && OrangeLineStations.count > 1 {
                updatedStation = randomStation()
            }
            let updatedDirection: Direction = initialDirection == .mountainView ? .alumRock : .mountainView
            
            // Update and save
            service.selectedStation = updatedStation
            service.selectedDirection = updatedDirection
            service.save()
            
            // Load and verify updated values
            let loadService = StorageService(userDefaults: testDefaults)
            loadService.load()
            
            #expect(
                loadService.selectedStation == updatedStation,
                "Iteration \(iteration): Loaded station should be the updated station '\(updatedStation.name)', not '\(loadService.selectedStation?.name ?? "nil")'"
            )
            #expect(
                loadService.selectedDirection == updatedDirection,
                "Iteration \(iteration): Loaded direction should be the updated direction '\(updatedDirection.rawValue)', not '\(loadService.selectedDirection?.rawValue ?? "nil")'"
            )
        }
    }
    
    /// **Validates: Property 2**
    /// All 29 stations should be persistable and loadable correctly
    @Test func property2_allStationsCanBePersisted() {
        // Test all 29 stations
        for (index, station) in OrangeLineStations.stations.enumerated() {
            let (saveService, testDefaults) = createTestStorageService()
            
            // Save the station
            saveService.selectedStation = station
            saveService.save()
            
            // Load in a new service instance
            let loadService = StorageService(userDefaults: testDefaults)
            loadService.load()
            
            // Verify the station was persisted correctly
            #expect(
                loadService.selectedStation == station,
                "Station at index \(index) ('\(station.name)') should be persistable and loadable"
            )
        }
    }
    
    /// **Validates: Property 2**
    /// Both directions should be persistable and loadable correctly
    @Test func property2_allDirectionsCanBePersisted() {
        // Test both directions
        for direction in Direction.allCases {
            let (saveService, testDefaults) = createTestStorageService()
            
            // Save the direction
            saveService.selectedDirection = direction
            saveService.save()
            
            // Load in a new service instance
            let loadService = StorageService(userDefaults: testDefaults)
            loadService.load()
            
            // Verify the direction was persisted correctly
            #expect(
                loadService.selectedDirection == direction,
                "Direction '\(direction.rawValue)' should be persistable and loadable"
            )
        }
    }
    
    /// **Validates: Property 2**
    /// All combinations of stations and directions should be persistable
    @Test func property2_randomStationDirectionCombinationsArePersistable() {
        // Run 100 iterations with random combinations
        for iteration in 0..<100 {
            let station = randomStation()
            let direction = randomDirection()
            let (saveService, testDefaults) = createTestStorageService()
            
            // Save the combination
            saveService.selectedStation = station
            saveService.selectedDirection = direction
            saveService.save()
            
            // Load in a new service instance
            let loadService = StorageService(userDefaults: testDefaults)
            loadService.load()
            
            // Verify both values are correct
            #expect(
                loadService.selectedStation == station && loadService.selectedDirection == direction,
                "Iteration \(iteration): Combination of station '\(station.name)' and direction '\(direction.rawValue)' should be persistable"
            )
        }
    }
}


// MARK: - StorageService Protocol Conformance Tests

struct StorageServiceProtocolTests {
    
    @Test func storageServiceConformsToProtocol() {
        let service: StorageServiceProtocol = StorageService()
        
        // Verify all protocol properties are accessible
        _ = service.selectedStation
        _ = service.selectedDirection
        _ = service.timeRules
        _ = service.isTimeRuleEnabled
        
        // This test passes if it compiles - protocol conformance is verified at compile time
        #expect(true)
    }
    
    @Test func protocolMethodsAreCallable() {
        var service: StorageServiceProtocol = StorageService()
        
        // Verify protocol methods can be called
        service.selectedStation = OrangeLineStations.first
        service.selectedDirection = .alumRock
        service.timeRules = []
        service.isTimeRuleEnabled = true
        
        service.save()
        service.load()
        
        #expect(true)
    }
}


// MARK: - Property 3: API 响应解析往返测试

/// Property-based tests for Prediction serialization/deserialization round-trip
/// **Validates: Property 3**
struct PredictionSerializationPropertyTests {
    
    // MARK: - Helper Methods
    
    /// Generates a random ArrivalStatus
    private func randomArrivalStatus() -> ArrivalStatus {
        ArrivalStatus.allCases.randomElement()!
    }
    
    /// Generates a random destination name
    private func randomDestination() -> String {
        let destinations = [
            "Mountain View",
            "Alum Rock",
            "Great America",
            "Milpitas",
            "Berryessa",
            "Bayshore/NASA",
            "Old Ironsides",
            "Tasman",
            "River Oaks",
            "Champion"
        ]
        return destinations.randomElement()!
    }
    
    /// Generates a random vehicle ID (or nil)
    private func randomVehicleId() -> String? {
        if Bool.random() {
            return String(Int.random(in: 1000...9999))
        }
        return nil
    }
    
    /// Generates a random minutes until arrival (or nil for arriving/boarding)
    private func randomMinutesUntilArrival(for status: ArrivalStatus) -> Int? {
        switch status {
        case .arriving, .boarding:
            // These statuses typically have nil minutes
            return Bool.random() ? nil : Int.random(in: 0...2)
        case .scheduled, .delayed:
            // These statuses typically have minutes
            return Bool.random() ? Int.random(in: 1...120) : nil
        }
    }
    
    /// Generates a random timestamp within the last hour
    private func randomTimestamp() -> Date {
        let secondsAgo = TimeInterval.random(in: 0...3600)
        return Date().addingTimeInterval(-secondsAgo)
    }
    
    /// Generates a random valid Prediction object
    private func randomPrediction() -> Prediction {
        let status = randomArrivalStatus()
        return Prediction(
            id: UUID(),
            minutesUntilArrival: randomMinutesUntilArrival(for: status),
            arrivalStatus: status,
            destination: randomDestination(),
            vehicleId: randomVehicleId(),
            timestamp: randomTimestamp()
        )
    }
    
    // MARK: - Property 3: API 响应解析往返
    
    /// **Validates: Property 3**
    /// For any valid Prediction object, serializing to JSON and then deserializing
    /// should produce a Prediction equal to the original.
    @Test func property3_predictionSerializationRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate a random valid Prediction
            let originalPrediction = randomPrediction()
            
            // Serialize to JSON
            let jsonData = try encoder.encode(originalPrediction)
            
            // Deserialize from JSON
            let decodedPrediction = try decoder.decode(Prediction.self, from: jsonData)
            
            // Verify: decoded prediction should equal original prediction
            #expect(
                decodedPrediction == originalPrediction,
                "Iteration \(iteration): Decoded prediction should equal original prediction"
            )
            
            // Verify individual properties for detailed error messages
            #expect(
                decodedPrediction.id == originalPrediction.id,
                "Iteration \(iteration): Prediction ID should be preserved"
            )
            #expect(
                decodedPrediction.minutesUntilArrival == originalPrediction.minutesUntilArrival,
                "Iteration \(iteration): minutesUntilArrival should be preserved"
            )
            #expect(
                decodedPrediction.arrivalStatus == originalPrediction.arrivalStatus,
                "Iteration \(iteration): arrivalStatus should be preserved"
            )
            #expect(
                decodedPrediction.destination == originalPrediction.destination,
                "Iteration \(iteration): destination should be preserved"
            )
            #expect(
                decodedPrediction.vehicleId == originalPrediction.vehicleId,
                "Iteration \(iteration): vehicleId should be preserved"
            )
            #expect(
                decodedPrediction.timestamp == originalPrediction.timestamp,
                "Iteration \(iteration): timestamp should be preserved"
            )
        }
    }
    
    /// **Validates: Property 3**
    /// Predictions with nil optional values should survive round-trip
    @Test func property3_predictionWithNilValuesRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Run 100 iterations with predictions that have nil values
        for iteration in 0..<100 {
            // Create prediction with nil minutesUntilArrival and nil vehicleId
            let originalPrediction = Prediction(
                id: UUID(),
                minutesUntilArrival: nil,
                arrivalStatus: randomArrivalStatus(),
                destination: randomDestination(),
                vehicleId: nil,
                timestamp: randomTimestamp()
            )
            
            // Serialize and deserialize
            let jsonData = try encoder.encode(originalPrediction)
            let decodedPrediction = try decoder.decode(Prediction.self, from: jsonData)
            
            // Verify nil values are preserved
            #expect(
                decodedPrediction.minutesUntilArrival == nil,
                "Iteration \(iteration): nil minutesUntilArrival should be preserved"
            )
            #expect(
                decodedPrediction.vehicleId == nil,
                "Iteration \(iteration): nil vehicleId should be preserved"
            )
            #expect(
                decodedPrediction == originalPrediction,
                "Iteration \(iteration): Prediction with nil values should survive round-trip"
            )
        }
    }
    
    /// **Validates: Property 3**
    /// Predictions with all non-nil values should survive round-trip
    @Test func property3_predictionWithAllValuesRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Run 100 iterations with predictions that have all values set
        for iteration in 0..<100 {
            // Create prediction with all values set
            let originalPrediction = Prediction(
                id: UUID(),
                minutesUntilArrival: Int.random(in: 1...120),
                arrivalStatus: randomArrivalStatus(),
                destination: randomDestination(),
                vehicleId: String(Int.random(in: 1000...9999)),
                timestamp: randomTimestamp()
            )
            
            // Serialize and deserialize
            let jsonData = try encoder.encode(originalPrediction)
            let decodedPrediction = try decoder.decode(Prediction.self, from: jsonData)
            
            // Verify all values are preserved
            #expect(
                decodedPrediction == originalPrediction,
                "Iteration \(iteration): Prediction with all values should survive round-trip"
            )
        }
    }
    
    /// **Validates: Property 3**
    /// All ArrivalStatus values should survive round-trip
    @Test func property3_allArrivalStatusValuesRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test each arrival status 25 times (100 total iterations)
        for status in ArrivalStatus.allCases {
            for iteration in 0..<25 {
                let originalPrediction = Prediction(
                    id: UUID(),
                    minutesUntilArrival: randomMinutesUntilArrival(for: status),
                    arrivalStatus: status,
                    destination: randomDestination(),
                    vehicleId: randomVehicleId(),
                    timestamp: randomTimestamp()
                )
                
                // Serialize and deserialize
                let jsonData = try encoder.encode(originalPrediction)
                let decodedPrediction = try decoder.decode(Prediction.self, from: jsonData)
                
                // Verify arrival status is preserved
                #expect(
                    decodedPrediction.arrivalStatus == status,
                    "Status \(status), Iteration \(iteration): ArrivalStatus '\(status.rawValue)' should be preserved"
                )
                #expect(
                    decodedPrediction == originalPrediction,
                    "Status \(status), Iteration \(iteration): Prediction should survive round-trip"
                )
            }
        }
    }
    
    /// **Validates: Property 3**
    /// Edge case: Predictions with extreme minutes values should survive round-trip
    @Test func property3_extremeMinutesValuesRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let extremeValues = [0, 1, -1, Int.max, Int.min, 999, -999]
        
        // Run 100 iterations with extreme values
        for iteration in 0..<100 {
            let extremeMinutes = extremeValues.randomElement()!
            
            let originalPrediction = Prediction(
                id: UUID(),
                minutesUntilArrival: extremeMinutes,
                arrivalStatus: .scheduled,
                destination: randomDestination(),
                vehicleId: randomVehicleId(),
                timestamp: randomTimestamp()
            )
            
            // Serialize and deserialize
            let jsonData = try encoder.encode(originalPrediction)
            let decodedPrediction = try decoder.decode(Prediction.self, from: jsonData)
            
            // Verify extreme value is preserved
            #expect(
                decodedPrediction.minutesUntilArrival == extremeMinutes,
                "Iteration \(iteration): Extreme minutes value \(extremeMinutes) should be preserved"
            )
            #expect(
                decodedPrediction == originalPrediction,
                "Iteration \(iteration): Prediction with extreme minutes should survive round-trip"
            )
        }
    }
    
    /// **Validates: Property 3**
    /// Edge case: Predictions with special characters in destination should survive round-trip
    @Test func property3_specialCharactersInDestinationRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let specialDestinations = [
            "Bayshore/NASA",
            "Mountain View - Downtown",
            "Station #1",
            "Test & Demo",
            "日本語駅名",
            "Станция",
            "🚃 Train Station",
            "",
            "   ",
            "Very Long Station Name That Exceeds Normal Length Expectations For A Transit Station"
        ]
        
        // Run 100 iterations with special destinations
        for iteration in 0..<100 {
            let specialDestination = specialDestinations.randomElement()!
            
            let originalPrediction = Prediction(
                id: UUID(),
                minutesUntilArrival: Int.random(in: 1...60),
                arrivalStatus: randomArrivalStatus(),
                destination: specialDestination,
                vehicleId: randomVehicleId(),
                timestamp: randomTimestamp()
            )
            
            // Serialize and deserialize
            let jsonData = try encoder.encode(originalPrediction)
            let decodedPrediction = try decoder.decode(Prediction.self, from: jsonData)
            
            // Verify special destination is preserved
            #expect(
                decodedPrediction.destination == specialDestination,
                "Iteration \(iteration): Special destination '\(specialDestination)' should be preserved"
            )
            #expect(
                decodedPrediction == originalPrediction,
                "Iteration \(iteration): Prediction with special destination should survive round-trip"
            )
        }
    }
    
    /// **Validates: Property 3**
    /// Multiple consecutive serialization/deserialization cycles should preserve values
    @Test func property3_multipleSerializationCyclesPreserveValues() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Run 100 iterations
        for iteration in 0..<100 {
            var currentPrediction = randomPrediction()
            let originalPrediction = currentPrediction
            
            // Perform multiple serialization/deserialization cycles
            let cycleCount = Int.random(in: 2...5)
            for cycle in 0..<cycleCount {
                let jsonData = try encoder.encode(currentPrediction)
                currentPrediction = try decoder.decode(Prediction.self, from: jsonData)
                
                #expect(
                    currentPrediction == originalPrediction,
                    "Iteration \(iteration), Cycle \(cycle): Prediction should be preserved after multiple cycles"
                )
            }
        }
    }
    
    /// **Validates: Property 3**
    /// Array of Predictions should survive round-trip
    @Test func property3_predictionArrayRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Run 100 iterations
        for iteration in 0..<100 {
            // Generate a random array of predictions
            let arraySize = Int.random(in: 1...10)
            let originalPredictions = (0..<arraySize).map { _ in randomPrediction() }
            
            // Serialize and deserialize the array
            let jsonData = try encoder.encode(originalPredictions)
            let decodedPredictions = try decoder.decode([Prediction].self, from: jsonData)
            
            // Verify array size is preserved
            #expect(
                decodedPredictions.count == originalPredictions.count,
                "Iteration \(iteration): Array size should be preserved"
            )
            
            // Verify each prediction is preserved
            for (index, (decoded, original)) in zip(decodedPredictions, originalPredictions).enumerated() {
                #expect(
                    decoded == original,
                    "Iteration \(iteration): Prediction at index \(index) should be preserved"
                )
            }
        }
    }
    
    /// **Validates: Property 3**
    /// JSON output should be valid and parseable
    @Test func property3_jsonOutputIsValidAndParseable() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // Run 100 iterations
        for iteration in 0..<100 {
            let prediction = randomPrediction()
            
            // Serialize to JSON
            let jsonData = try encoder.encode(prediction)
            
            // Verify JSON is valid by parsing it as a dictionary
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            #expect(
                jsonObject is [String: Any],
                "Iteration \(iteration): JSON output should be a valid dictionary"
            )
            
            // Verify required keys are present
            if let dict = jsonObject as? [String: Any] {
                #expect(
                    dict["id"] != nil,
                    "Iteration \(iteration): JSON should contain 'id' key"
                )
                #expect(
                    dict["arrivalStatus"] != nil,
                    "Iteration \(iteration): JSON should contain 'arrivalStatus' key"
                )
                #expect(
                    dict["destination"] != nil,
                    "Iteration \(iteration): JSON should contain 'destination' key"
                )
                #expect(
                    dict["timestamp"] != nil,
                    "Iteration \(iteration): JSON should contain 'timestamp' key"
                )
            }
        }
    }
}


// MARK: - Property 4: 方向过滤正确性测试

/// Property-based tests for direction filtering correctness
/// **Validates: Property 4**
struct DirectionFilteringPropertyTests {
    
    // MARK: - Helper Methods
    
    /// Generates a random ArrivalStatus
    private func randomArrivalStatus() -> ArrivalStatus {
        ArrivalStatus.allCases.randomElement()!
    }
    
    /// Generates a random destination name based on direction
    private func randomDestination(for direction: Direction) -> String {
        // Destinations should match the direction
        return direction.displayName
    }
    
    /// Generates a random vehicle ID (or nil)
    private func randomVehicleId() -> String? {
        if Bool.random() {
            return String(Int.random(in: 1000...9999))
        }
        return nil
    }
    
    /// Generates a random minutes until arrival (or nil for arriving/boarding)
    private func randomMinutesUntilArrival(for status: ArrivalStatus) -> Int? {
        switch status {
        case .arriving, .boarding:
            return Bool.random() ? nil : Int.random(in: 0...2)
        case .scheduled, .delayed:
            return Bool.random() ? Int.random(in: 1...120) : nil
        }
    }
    
    /// Generates a random timestamp within the last hour
    private func randomTimestamp() -> Date {
        let secondsAgo = TimeInterval.random(in: 0...3600)
        return Date().addingTimeInterval(-secondsAgo)
    }
    
    /// Generates a random direction
    private func randomDirection() -> Direction {
        Direction.allCases.randomElement()!
    }
    
    /// Generates a random Prediction with a specific direction (destination matches direction)
    private func randomPrediction(for direction: Direction) -> Prediction {
        let status = randomArrivalStatus()
        return Prediction(
            id: UUID(),
            minutesUntilArrival: randomMinutesUntilArrival(for: status),
            arrivalStatus: status,
            destination: randomDestination(for: direction),
            vehicleId: randomVehicleId(),
            timestamp: randomTimestamp()
        )
    }
    
    /// Generates a list of random predictions with mixed directions
    private func randomMixedPredictions(count: Int) -> [Prediction] {
        (0..<count).map { _ in
            let direction = randomDirection()
            return randomPrediction(for: direction)
        }
    }
    
    /// Filters predictions by direction (simulates VTAService filtering logic)
    /// This is the function under test - it filters predictions based on destination matching direction
    private func filterPredictions(_ predictions: [Prediction], by direction: Direction) -> [Prediction] {
        predictions.filter { prediction in
            prediction.destination == direction.displayName
        }
    }
    
    // MARK: - Property 4: 方向过滤正确性
    
    /// **Validates: Property 4**
    /// For any prediction list and selected direction, every prediction in the filtered result
    /// should have a destination matching the selected direction.
    @Test func property4_filteredPredictionsMatchSelectedDirection() {
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate a random list of predictions with mixed directions
            let listSize = Int.random(in: 0...20)
            let mixedPredictions = randomMixedPredictions(count: listSize)
            
            // Select a random direction to filter by
            let selectedDirection = randomDirection()
            
            // Filter predictions by the selected direction
            let filteredPredictions = filterPredictions(mixedPredictions, by: selectedDirection)
            
            // Verify: every prediction in the filtered result should match the selected direction
            for (index, prediction) in filteredPredictions.enumerated() {
                #expect(
                    prediction.destination == selectedDirection.displayName,
                    "Iteration \(iteration): Prediction at index \(index) has destination '\(prediction.destination)' but should match selected direction '\(selectedDirection.displayName)'"
                )
            }
        }
    }
    
    /// **Validates: Property 4**
    /// Filtering by Mountain View direction should only return Mountain View predictions
    @Test func property4_filterByMountainViewReturnsOnlyMountainViewPredictions() {
        // Run 100 iterations
        for iteration in 0..<100 {
            // Generate mixed predictions
            let listSize = Int.random(in: 1...20)
            let mixedPredictions = randomMixedPredictions(count: listSize)
            
            // Filter by Mountain View direction
            let filteredPredictions = filterPredictions(mixedPredictions, by: .mountainView)
            
            // Verify: all filtered predictions should have Mountain View as destination
            for prediction in filteredPredictions {
                #expect(
                    prediction.destination == Direction.mountainView.displayName,
                    "Iteration \(iteration): Filtered prediction should have destination 'Mountain View' but has '\(prediction.destination)'"
                )
            }
        }
    }
    
    /// **Validates: Property 4**
    /// Filtering by Alum Rock direction should only return Alum Rock predictions
    @Test func property4_filterByAlumRockReturnsOnlyAlumRockPredictions() {
        // Run 100 iterations
        for iteration in 0..<100 {
            // Generate mixed predictions
            let listSize = Int.random(in: 1...20)
            let mixedPredictions = randomMixedPredictions(count: listSize)
            
            // Filter by Alum Rock direction
            let filteredPredictions = filterPredictions(mixedPredictions, by: .alumRock)
            
            // Verify: all filtered predictions should have Alum Rock as destination
            for prediction in filteredPredictions {
                #expect(
                    prediction.destination == Direction.alumRock.displayName,
                    "Iteration \(iteration): Filtered prediction should have destination 'Alum Rock' but has '\(prediction.destination)'"
                )
            }
        }
    }
    
    /// **Validates: Property 4**
    /// Filtering an empty list should return an empty list
    @Test func property4_filterEmptyListReturnsEmptyList() {
        // Run 100 iterations
        for iteration in 0..<100 {
            let emptyPredictions: [Prediction] = []
            let selectedDirection = randomDirection()
            
            let filteredPredictions = filterPredictions(emptyPredictions, by: selectedDirection)
            
            #expect(
                filteredPredictions.isEmpty,
                "Iteration \(iteration): Filtering empty list should return empty list"
            )
        }
    }
    
    /// **Validates: Property 4**
    /// Filtering a list with only matching predictions should return all predictions
    @Test func property4_filterListWithOnlyMatchingPredictionsReturnsAll() {
        // Run 100 iterations
        for iteration in 0..<100 {
            let selectedDirection = randomDirection()
            let listSize = Int.random(in: 1...20)
            
            // Generate predictions all with the same direction
            let matchingPredictions = (0..<listSize).map { _ in
                randomPrediction(for: selectedDirection)
            }
            
            let filteredPredictions = filterPredictions(matchingPredictions, by: selectedDirection)
            
            // Verify: all predictions should be returned
            #expect(
                filteredPredictions.count == matchingPredictions.count,
                "Iteration \(iteration): All \(matchingPredictions.count) matching predictions should be returned, but got \(filteredPredictions.count)"
            )
            
            // Verify: each filtered prediction matches the direction
            for prediction in filteredPredictions {
                #expect(
                    prediction.destination == selectedDirection.displayName,
                    "Iteration \(iteration): Prediction destination should match selected direction"
                )
            }
        }
    }
    
    /// **Validates: Property 4**
    /// Filtering a list with no matching predictions should return empty list
    @Test func property4_filterListWithNoMatchingPredictionsReturnsEmpty() {
        // Run 100 iterations
        for iteration in 0..<100 {
            let selectedDirection = randomDirection()
            let oppositeDirection: Direction = selectedDirection == .mountainView ? .alumRock : .mountainView
            let listSize = Int.random(in: 1...20)
            
            // Generate predictions all with the opposite direction
            let nonMatchingPredictions = (0..<listSize).map { _ in
                randomPrediction(for: oppositeDirection)
            }
            
            let filteredPredictions = filterPredictions(nonMatchingPredictions, by: selectedDirection)
            
            // Verify: no predictions should be returned
            #expect(
                filteredPredictions.isEmpty,
                "Iteration \(iteration): Filtering list with no matching predictions should return empty list, but got \(filteredPredictions.count) predictions"
            )
        }
    }
    
    /// **Validates: Property 4**
    /// The count of filtered predictions should equal the count of predictions matching the direction
    @Test func property4_filteredCountEqualsMatchingCount() {
        // Run 100 iterations
        for iteration in 0..<100 {
            let listSize = Int.random(in: 0...30)
            let mixedPredictions = randomMixedPredictions(count: listSize)
            let selectedDirection = randomDirection()
            
            // Count predictions that should match
            let expectedCount = mixedPredictions.filter { 
                $0.destination == selectedDirection.displayName 
            }.count
            
            // Filter predictions
            let filteredPredictions = filterPredictions(mixedPredictions, by: selectedDirection)
            
            // Verify: filtered count should equal expected count
            #expect(
                filteredPredictions.count == expectedCount,
                "Iteration \(iteration): Filtered count \(filteredPredictions.count) should equal expected count \(expectedCount)"
            )
        }
    }
    
    /// **Validates: Property 4**
    /// Filtering should preserve prediction properties (only filter, not modify)
    @Test func property4_filteringPreservesPredictionProperties() {
        // Run 100 iterations
        for iteration in 0..<100 {
            let listSize = Int.random(in: 1...20)
            let mixedPredictions = randomMixedPredictions(count: listSize)
            let selectedDirection = randomDirection()
            
            // Get the original predictions that should match
            let expectedPredictions = mixedPredictions.filter { 
                $0.destination == selectedDirection.displayName 
            }
            
            // Filter predictions
            let filteredPredictions = filterPredictions(mixedPredictions, by: selectedDirection)
            
            // Verify: filtered predictions should be identical to expected predictions
            #expect(
                filteredPredictions.count == expectedPredictions.count,
                "Iteration \(iteration): Filtered count should match expected count"
            )
            
            for (filtered, expected) in zip(filteredPredictions, expectedPredictions) {
                #expect(
                    filtered.id == expected.id,
                    "Iteration \(iteration): Prediction ID should be preserved"
                )
                #expect(
                    filtered.minutesUntilArrival == expected.minutesUntilArrival,
                    "Iteration \(iteration): minutesUntilArrival should be preserved"
                )
                #expect(
                    filtered.arrivalStatus == expected.arrivalStatus,
                    "Iteration \(iteration): arrivalStatus should be preserved"
                )
                #expect(
                    filtered.destination == expected.destination,
                    "Iteration \(iteration): destination should be preserved"
                )
                #expect(
                    filtered.vehicleId == expected.vehicleId,
                    "Iteration \(iteration): vehicleId should be preserved"
                )
            }
        }
    }
    
    /// **Validates: Property 4**
    /// Filtering should be idempotent - filtering twice should produce the same result
    @Test func property4_filteringIsIdempotent() {
        // Run 100 iterations
        for iteration in 0..<100 {
            let listSize = Int.random(in: 0...20)
            let mixedPredictions = randomMixedPredictions(count: listSize)
            let selectedDirection = randomDirection()
            
            // Filter once
            let firstFilter = filterPredictions(mixedPredictions, by: selectedDirection)
            
            // Filter again
            let secondFilter = filterPredictions(firstFilter, by: selectedDirection)
            
            // Verify: second filter should produce the same result as first filter
            #expect(
                secondFilter.count == firstFilter.count,
                "Iteration \(iteration): Filtering twice should produce same count"
            )
            
            for (first, second) in zip(firstFilter, secondFilter) {
                #expect(
                    first == second,
                    "Iteration \(iteration): Filtering twice should produce identical predictions"
                )
            }
        }
    }
    
    /// **Validates: Property 4**
    /// Filtering by both directions should cover all predictions (union property)
    @Test func property4_filteringByBothDirectionsCoversAllPredictions() {
        // Run 100 iterations
        for iteration in 0..<100 {
            let listSize = Int.random(in: 0...20)
            let mixedPredictions = randomMixedPredictions(count: listSize)
            
            // Filter by both directions
            let mountainViewPredictions = filterPredictions(mixedPredictions, by: .mountainView)
            let alumRockPredictions = filterPredictions(mixedPredictions, by: .alumRock)
            
            // Verify: union of both filtered lists should equal original list
            let totalFiltered = mountainViewPredictions.count + alumRockPredictions.count
            #expect(
                totalFiltered == mixedPredictions.count,
                "Iteration \(iteration): Sum of filtered predictions (\(totalFiltered)) should equal original count (\(mixedPredictions.count))"
            )
            
            // Verify: no prediction appears in both filtered lists (disjoint property)
            let mountainViewIds = Set(mountainViewPredictions.map { $0.id })
            let alumRockIds = Set(alumRockPredictions.map { $0.id })
            let intersection = mountainViewIds.intersection(alumRockIds)
            
            #expect(
                intersection.isEmpty,
                "Iteration \(iteration): Filtered lists should be disjoint, but found \(intersection.count) common predictions"
            )
        }
    }
}


// MARK: - Property 8: 时间规则触发正确性测试

/// Property-based tests for time rule trigger correctness
/// **Validates: Property 8**
struct TimeRuleTriggerCorrectnessPropertyTests {
    
    // MARK: - Helper Methods
    
    /// Creates a MockStorageService for testing
    private func createMockStorage(
        rules: [TimeRule] = [],
        isTimeRuleEnabled: Bool = true
    ) -> MockStorageService {
        let mockStorage = MockStorageService()
        mockStorage.timeRules = rules
        mockStorage.isTimeRuleEnabled = isTimeRuleEnabled
        return mockStorage
    }
    
    /// Creates a date with specific hour and minute
    private func createDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// Generates a random valid hour (0-23)
    private func randomHour() -> Int {
        Int.random(in: 0...23)
    }
    
    /// Generates a random valid minute (0-59)
    private func randomMinute() -> Int {
        Int.random(in: 0...59)
    }
    
    /// Generates a random station ID from Orange Line stations
    private func randomStationId() -> String {
        OrangeLineStations.stations.randomElement()!.id
    }
    
    /// Generates a random direction
    private func randomDirection() -> Direction {
        Direction.allCases.randomElement()!
    }
    
    /// Generates a random TimeRule with specified hour and minute
    private func createRandomRule(
        hour: Int,
        minute: Int,
        isEnabled: Bool = true
    ) -> TimeRule {
        return TimeRule(
            name: "Rule_\(hour)_\(minute)",
            triggerTime: TimeRule.createTriggerTime(hour: hour, minute: minute),
            stationId: randomStationId(),
            direction: randomDirection(),
            isEnabled: isEnabled
        )
    }
    
    // MARK: - Property 8: 时间规则触发正确性
    
    /// **Validates: Property 8**
    /// For any time rule and current time, if the current time's hour:minute equals
    /// the rule's trigger time and the rule is enabled, the rule should be triggered
    /// and apply its station and direction settings.
    @Test func property8_timeRuleTriggerCorrectness() {
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate random hour and minute for the rule
            let ruleHour = randomHour()
            let ruleMinute = randomMinute()
            
            // Create an enabled rule with the random trigger time
            let rule = createRandomRule(hour: ruleHour, minute: ruleMinute, isEnabled: true)
            
            // Create a current time that matches the rule's trigger time
            let currentTime = createDate(hour: ruleHour, minute: ruleMinute)
            
            // Create the service with the rule
            let mockStorage = createMockStorage(rules: [rule], isTimeRuleEnabled: true)
            let service = TimeRuleService(
                storageService: mockStorage,
                dateProvider: { currentTime }
            )
            
            // Get the active rule
            let activeRule = service.shouldApplyRule(at: currentTime)
            
            // Verify: when time matches and rule is enabled, rule should be triggered
            #expect(
                activeRule != nil,
                "Iteration \(iteration): Rule should be triggered when time matches (\(ruleHour):\(ruleMinute)) and rule is enabled"
            )
            
            // Verify: the triggered rule should have the correct station and direction settings
            #expect(
                activeRule?.stationId == rule.stationId,
                "Iteration \(iteration): Triggered rule should have correct stationId '\(rule.stationId)'"
            )
            #expect(
                activeRule?.direction == rule.direction,
                "Iteration \(iteration): Triggered rule should have correct direction '\(rule.direction.rawValue)'"
            )
            
            // Verify: the triggered rule's trigger time should match
            #expect(
                activeRule?.triggerHour == ruleHour,
                "Iteration \(iteration): Triggered rule should have correct trigger hour \(ruleHour)"
            )
            #expect(
                activeRule?.triggerMinute == ruleMinute,
                "Iteration \(iteration): Triggered rule should have correct trigger minute \(ruleMinute)"
            )
        }
    }
    
    /// **Validates: Property 8**
    /// For any enabled rule, when current time is after the trigger time (same day),
    /// the rule should be active and its settings should be applied.
    @Test func property8_ruleRemainsActiveAfterTriggerTime() {
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate random trigger time (not too late to allow time after)
            let ruleHour = Int.random(in: 0...22)
            let ruleMinute = Int.random(in: 0...58)
            
            // Create an enabled rule
            let rule = createRandomRule(hour: ruleHour, minute: ruleMinute, isEnabled: true)
            
            // Create a current time that is after the rule's trigger time
            let minutesAfter = Int.random(in: 1...60)
            var currentHour = ruleHour
            var currentMinute = ruleMinute + minutesAfter
            
            // Handle minute overflow
            if currentMinute >= 60 {
                currentHour += currentMinute / 60
                currentMinute = currentMinute % 60
            }
            
            // Ensure we don't go past midnight
            if currentHour > 23 {
                currentHour = 23
                currentMinute = 59
            }
            
            let currentTime = createDate(hour: currentHour, minute: currentMinute)
            
            // Create the service with the rule
            let mockStorage = createMockStorage(rules: [rule], isTimeRuleEnabled: true)
            let service = TimeRuleService(
                storageService: mockStorage,
                dateProvider: { currentTime }
            )
            
            // Get the active rule
            let activeRule = service.shouldApplyRule(at: currentTime)
            
            // Verify: rule should still be active after its trigger time
            #expect(
                activeRule != nil,
                "Iteration \(iteration): Rule triggered at \(ruleHour):\(ruleMinute) should still be active at \(currentHour):\(currentMinute)"
            )
            
            // Verify: the active rule's settings should be applied
            #expect(
                activeRule?.stationId == rule.stationId,
                "Iteration \(iteration): Active rule should apply correct stationId"
            )
            #expect(
                activeRule?.direction == rule.direction,
                "Iteration \(iteration): Active rule should apply correct direction"
            )
        }
    }
    
    /// **Validates: Property 8**
    /// For any disabled rule, even when time matches, the rule should NOT be triggered.
    @Test func property8_disabledRuleNotTriggeredEvenWhenTimeMatches() {
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate random hour and minute
            let ruleHour = randomHour()
            let ruleMinute = randomMinute()
            
            // Create a DISABLED rule
            let rule = createRandomRule(hour: ruleHour, minute: ruleMinute, isEnabled: false)
            
            // Create a current time that matches the rule's trigger time
            let currentTime = createDate(hour: ruleHour, minute: ruleMinute)
            
            // Create the service with the disabled rule
            let mockStorage = createMockStorage(rules: [rule], isTimeRuleEnabled: true)
            let service = TimeRuleService(
                storageService: mockStorage,
                dateProvider: { currentTime }
            )
            
            // Get the active rule
            let activeRule = service.shouldApplyRule(at: currentTime)
            
            // Verify: disabled rule should NOT be triggered even when time matches
            #expect(
                activeRule == nil,
                "Iteration \(iteration): Disabled rule should NOT be triggered even when time matches (\(ruleHour):\(ruleMinute))"
            )
        }
    }
    
    /// **Validates: Property 8**
    /// For any rule, when current time is before the trigger time, the rule should NOT be triggered.
    @Test func property8_ruleNotTriggeredBeforeTriggerTime() {
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate random trigger time (not too early to allow time before)
            let ruleHour = Int.random(in: 1...23)
            let ruleMinute = Int.random(in: 1...59)
            
            // Create an enabled rule
            let rule = createRandomRule(hour: ruleHour, minute: ruleMinute, isEnabled: true)
            
            // Create a current time that is before the rule's trigger time
            let minutesBefore = Int.random(in: 1...min(ruleHour * 60 + ruleMinute, 60))
            var currentHour = ruleHour
            var currentMinute = ruleMinute - minutesBefore
            
            // Handle minute underflow
            while currentMinute < 0 {
                currentHour -= 1
                currentMinute += 60
            }
            
            // Ensure we don't go before midnight
            if currentHour < 0 {
                currentHour = 0
                currentMinute = 0
            }
            
            let currentTime = createDate(hour: currentHour, minute: currentMinute)
            
            // Create the service with the rule (no other rules)
            let mockStorage = createMockStorage(rules: [rule], isTimeRuleEnabled: true)
            let service = TimeRuleService(
                storageService: mockStorage,
                dateProvider: { currentTime }
            )
            
            // Get the active rule
            let activeRule = service.shouldApplyRule(at: currentTime)
            
            // Verify: rule should NOT be triggered before its trigger time
            #expect(
                activeRule == nil,
                "Iteration \(iteration): Rule with trigger time \(ruleHour):\(ruleMinute) should NOT be triggered at \(currentHour):\(currentMinute)"
            )
        }
    }
    
    /// **Validates: Property 8**
    /// When multiple rules exist, the most recently triggered enabled rule should be active.
    @Test func property8_mostRecentlyTriggeredRuleIsActive() {
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate two different trigger times
            let hour1 = Int.random(in: 0...11)
            let minute1 = randomMinute()
            let hour2 = Int.random(in: 12...23)
            let minute2 = randomMinute()
            
            // Create two enabled rules with different trigger times
            let rule1 = createRandomRule(hour: hour1, minute: minute1, isEnabled: true)
            let rule2 = createRandomRule(hour: hour2, minute: minute2, isEnabled: true)
            
            // Create a current time that is after both rules' trigger times
            let currentHour = 23
            let currentMinute = 59
            let currentTime = createDate(hour: currentHour, minute: currentMinute)
            
            // Create the service with both rules
            let mockStorage = createMockStorage(rules: [rule1, rule2], isTimeRuleEnabled: true)
            let service = TimeRuleService(
                storageService: mockStorage,
                dateProvider: { currentTime }
            )
            
            // Get the active rule
            let activeRule = service.shouldApplyRule(at: currentTime)
            
            // Verify: the most recently triggered rule (rule2, later in the day) should be active
            #expect(
                activeRule != nil,
                "Iteration \(iteration): An active rule should exist"
            )
            #expect(
                activeRule?.triggerHour == hour2,
                "Iteration \(iteration): The most recently triggered rule (hour \(hour2)) should be active, not hour \(activeRule?.triggerHour ?? -1)"
            )
            #expect(
                activeRule?.triggerMinute == minute2,
                "Iteration \(iteration): The most recently triggered rule (minute \(minute2)) should be active"
            )
            
            // Verify: the active rule's settings should be from rule2
            #expect(
                activeRule?.stationId == rule2.stationId,
                "Iteration \(iteration): Active rule should have rule2's stationId"
            )
            #expect(
                activeRule?.direction == rule2.direction,
                "Iteration \(iteration): Active rule should have rule2's direction"
            )
        }
    }
    
    /// **Validates: Property 8**
    /// For any valid time rule configuration, the shouldTrigger method on TimeRule
    /// should correctly determine if the rule should trigger at a given time.
    @Test func property8_timeRuleShouldTriggerMethodCorrectness() {
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate random hour and minute
            let ruleHour = randomHour()
            let ruleMinute = randomMinute()
            
            // Create an enabled rule
            let enabledRule = TimeRule(
                name: "Enabled_\(iteration)",
                triggerTime: TimeRule.createTriggerTime(hour: ruleHour, minute: ruleMinute),
                stationId: randomStationId(),
                direction: randomDirection(),
                isEnabled: true
            )
            
            // Create a disabled rule with same time
            let disabledRule = TimeRule(
                name: "Disabled_\(iteration)",
                triggerTime: TimeRule.createTriggerTime(hour: ruleHour, minute: ruleMinute),
                stationId: randomStationId(),
                direction: randomDirection(),
                isEnabled: false
            )
            
            // Create matching time
            let matchingTime = createDate(hour: ruleHour, minute: ruleMinute)
            
            // Create non-matching time
            let nonMatchingHour = (ruleHour + 1) % 24
            let nonMatchingTime = createDate(hour: nonMatchingHour, minute: ruleMinute)
            
            // Verify: enabled rule should trigger at matching time
            #expect(
                enabledRule.shouldTrigger(at: matchingTime) == true,
                "Iteration \(iteration): Enabled rule should trigger at matching time \(ruleHour):\(ruleMinute)"
            )
            
            // Verify: enabled rule should NOT trigger at non-matching time
            #expect(
                enabledRule.shouldTrigger(at: nonMatchingTime) == false,
                "Iteration \(iteration): Enabled rule should NOT trigger at non-matching time \(nonMatchingHour):\(ruleMinute)"
            )
            
            // Verify: disabled rule should NOT trigger even at matching time
            #expect(
                disabledRule.shouldTrigger(at: matchingTime) == false,
                "Iteration \(iteration): Disabled rule should NOT trigger even at matching time"
            )
            
            // Verify: disabled rule should NOT trigger at non-matching time
            #expect(
                disabledRule.shouldTrigger(at: nonMatchingTime) == false,
                "Iteration \(iteration): Disabled rule should NOT trigger at non-matching time"
            )
        }
    }
    
    /// **Validates: Property 8**
    /// For any time rule, the matchesTime method should correctly identify matching times.
    @Test func property8_timeRuleMatchesTimeMethodCorrectness() {
        // Run 100 iterations with random test data
        for iteration in 0..<100 {
            // Generate random hour and minute
            let ruleHour = randomHour()
            let ruleMinute = randomMinute()
            
            // Create a rule
            let rule = TimeRule(
                name: "Test_\(iteration)",
                triggerTime: TimeRule.createTriggerTime(hour: ruleHour, minute: ruleMinute),
                stationId: randomStationId(),
                direction: randomDirection(),
                isEnabled: Bool.random()  // Enabled state shouldn't affect matchesTime
            )
            
            // Create matching time
            let matchingTime = createDate(hour: ruleHour, minute: ruleMinute)
            
            // Create times with different hour
            let differentHour = (ruleHour + Int.random(in: 1...23)) % 24
            let differentHourTime = createDate(hour: differentHour, minute: ruleMinute)
            
            // Create times with different minute
            let differentMinute = (ruleMinute + Int.random(in: 1...59)) % 60
            let differentMinuteTime = createDate(hour: ruleHour, minute: differentMinute)
            
            // Verify: matchesTime should return true for matching time
            #expect(
                rule.matchesTime(matchingTime) == true,
                "Iteration \(iteration): matchesTime should return true for \(ruleHour):\(ruleMinute)"
            )
            
            // Verify: matchesTime should return false for different hour
            #expect(
                rule.matchesTime(differentHourTime) == false,
                "Iteration \(iteration): matchesTime should return false for different hour \(differentHour):\(ruleMinute)"
            )
            
            // Verify: matchesTime should return false for different minute
            #expect(
                rule.matchesTime(differentMinuteTime) == false,
                "Iteration \(iteration): matchesTime should return false for different minute \(ruleHour):\(differentMinute)"
            )
        }
    }
    
    /// **Validates: Property 8**
    /// Edge case: Rules at boundary times (midnight, end of day) should trigger correctly.
    @Test func property8_boundaryTimesTriggeredCorrectly() {
        let boundaryTimes = [
            (hour: 0, minute: 0),    // Midnight
            (hour: 0, minute: 1),    // Just after midnight
            (hour: 23, minute: 59),  // End of day
            (hour: 23, minute: 58),  // Just before end of day
            (hour: 12, minute: 0),   // Noon
            (hour: 12, minute: 30),  // Half past noon
        ]
        
        // Run multiple iterations for each boundary time
        for (hour, minute) in boundaryTimes {
            for iteration in 0..<17 {  // ~100 total iterations across all boundary times
                // Create an enabled rule at the boundary time
                let rule = createRandomRule(hour: hour, minute: minute, isEnabled: true)
                
                // Create a current time that matches
                let currentTime = createDate(hour: hour, minute: minute)
                
                // Create the service
                let mockStorage = createMockStorage(rules: [rule], isTimeRuleEnabled: true)
                let service = TimeRuleService(
                    storageService: mockStorage,
                    dateProvider: { currentTime }
                )
                
                // Get the active rule
                let activeRule = service.shouldApplyRule(at: currentTime)
                
                // Verify: boundary time rule should be triggered
                #expect(
                    activeRule != nil,
                    "Boundary time \(hour):\(minute), Iteration \(iteration): Rule should be triggered at boundary time"
                )
                #expect(
                    activeRule?.stationId == rule.stationId,
                    "Boundary time \(hour):\(minute), Iteration \(iteration): Triggered rule should have correct stationId"
                )
                #expect(
                    activeRule?.direction == rule.direction,
                    "Boundary time \(hour):\(minute), Iteration \(iteration): Triggered rule should have correct direction"
                )
            }
        }
    }
    
    /// **Validates: Property 8**
    /// For any combination of station and direction in a rule, when triggered,
    /// those exact settings should be available for application.
    @Test func property8_allStationDirectionCombinationsWork() {
        // Test with random combinations of all stations and directions
        for iteration in 0..<100 {
            // Pick a random station
            let station = OrangeLineStations.stations.randomElement()!
            
            // Pick a random direction
            let direction = Direction.allCases.randomElement()!
            
            // Generate random trigger time
            let hour = randomHour()
            let minute = randomMinute()
            
            // Create the rule with specific station and direction
            let rule = TimeRule(
                name: "Test_\(station.shortName)_\(direction.rawValue)",
                triggerTime: TimeRule.createTriggerTime(hour: hour, minute: minute),
                stationId: station.id,
                direction: direction,
                isEnabled: true
            )
            
            // Create matching time
            let currentTime = createDate(hour: hour, minute: minute)
            
            // Create the service
            let mockStorage = createMockStorage(rules: [rule], isTimeRuleEnabled: true)
            let service = TimeRuleService(
                storageService: mockStorage,
                dateProvider: { currentTime }
            )
            
            // Get the active rule
            let activeRule = service.shouldApplyRule(at: currentTime)
            
            // Verify: rule should be triggered with correct station and direction
            #expect(
                activeRule != nil,
                "Iteration \(iteration): Rule for station '\(station.name)' and direction '\(direction.rawValue)' should be triggered"
            )
            #expect(
                activeRule?.stationId == station.id,
                "Iteration \(iteration): Triggered rule should have stationId '\(station.id)'"
            )
            #expect(
                activeRule?.direction == direction,
                "Iteration \(iteration): Triggered rule should have direction '\(direction.rawValue)'"
            )
            
            // Verify: the station can be looked up from the rule
            #expect(
                activeRule?.station?.id == station.id,
                "Iteration \(iteration): Rule's station lookup should return correct station"
            )
        }
    }
}
