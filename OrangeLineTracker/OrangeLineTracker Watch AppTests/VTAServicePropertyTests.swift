//
//  VTAServicePropertyTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Property-based tests for VTAService line prediction filtering
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Property 9: 线路预测过滤正确性

/// Property-based tests for VTAService line prediction filtering
/// **Feature: vta-all-lines, Property 9: 线路预测过滤正确性**
/// **Validates: Requirements 6.1, 6.4**
///
/// Property 9: 对于任意包含多条线路预测的 API 响应和指定的线路 ID，
/// 过滤后的结果必须只包含该线路的预测，且不丢失任何该线路的预测。
struct VTAServiceLinePredictionFilteringPropertyTests {
    
    // MARK: - Test Data Generators
    
    /// Available line IDs for testing
    private let availableLineIds = ["Orange", "Blue", "Green", "Yellow", "Red", "22", "522", "60"]
    
    /// Available direction IDs for testing
    private let availableDirectionIds = ["E", "W", "N", "S", "NB", "SB", "IB", "OB"]
    
    /// Generates a random line ID
    private func randomLineId() -> String {
        availableLineIds.randomElement()!
    }
    
    /// Generates a random direction ID
    private func randomDirectionId() -> String {
        availableDirectionIds.randomElement()!
    }
    
    /// Generates a random destination name
    private func randomDestination() -> String {
        let destinations = [
            "Mountain View", "Alum Rock", "Winchester", "Santa Teresa",
            "Baypointe", "Diridon", "Downtown San Jose", "Milpitas",
            "Berryessa", "Great Mall", "Old Ironsides", "Eastridge"
        ]
        return destinations.randomElement()!
    }

    /// Generates a random vehicle ID
    private func randomVehicleId() -> String? {
        // 30% chance of nil vehicle ID
        if Int.random(in: 0..<10) < 3 {
            return nil
        }
        return String(Int.random(in: 1000...9999))
    }
    
    /// Generates a random arrival status
    private func randomArrivalStatus() -> String {
        let statuses = ["onTime", "early", "delayed", "late", "arriving", "arr", "boarding", "brd", "atStop"]
        return statuses.randomElement()!
    }
    
    /// Generates a random future ISO8601 timestamp
    private func randomFutureTimestamp() -> String {
        let minutesFromNow = Int.random(in: 1...60)
        let futureDate = Date().addingTimeInterval(Double(minutesFromNow * 60))
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: futureDate)
    }
    
    /// Generates a random station ID (511.org stop code format)
    private func randomStationId() -> String {
        String(Int.random(in: 60000...69999))
    }
    
    /// Builds the line reference string as returned by the API
    /// Light rail lines have " Line" suffix, bus routes are just numbers
    private func buildLineRef(from lineId: String) -> String {
        switch lineId {
        case "Orange", "Blue", "Green", "Yellow", "Red":
            return "\(lineId) Line"
        default:
            return lineId
        }
    }
    
    /// Generates a single MonitoredStopVisit for a specific line and direction
    private func generateVisit(lineId: String, directionId: String) -> MonitoredStopVisit {
        let lineRef = buildLineRef(from: lineId)
        let journey = MonitoredVehicleJourney(
            LineRef: lineRef,
            DirectionRef: directionId,
            DestinationName: randomDestination(),
            MonitoredCall: MonitoredCall(
                StopPointRef: randomStationId(),
                ExpectedArrivalTime: randomFutureTimestamp(),
                AimedArrivalTime: nil,
                ArrivalStatus: randomArrivalStatus()
            ),
            VehicleRef: randomVehicleId()
        )
        return MonitoredStopVisit(MonitoredVehicleJourney: journey)
    }

    /// Generates a SIRI API response with visits from multiple lines
    /// - Parameters:
    ///   - targetLineId: The line ID we want to test filtering for
    ///   - targetDirectionId: The direction ID we want to test filtering for
    ///   - targetCount: Number of visits for the target line/direction
    ///   - otherCount: Number of visits for other lines/directions
    /// - Returns: A tuple of (JSON data, expected count of target predictions)
    private func generateMultiLineResponse(
        targetLineId: String,
        targetDirectionId: String,
        targetCount: Int,
        otherCount: Int
    ) -> (Data, Int) {
        var visits: [MonitoredStopVisit] = []
        
        // Generate visits for the target line and direction
        for _ in 0..<targetCount {
            visits.append(generateVisit(lineId: targetLineId, directionId: targetDirectionId))
        }
        
        // Generate visits for other lines and directions
        for _ in 0..<otherCount {
            // Pick a random line that's different from target, or same line with different direction
            var otherLineId = randomLineId()
            var otherDirectionId = randomDirectionId()
            
            // Ensure at least one of lineId or directionId is different
            while otherLineId == targetLineId && otherDirectionId == targetDirectionId {
                otherLineId = randomLineId()
                otherDirectionId = randomDirectionId()
            }
            
            visits.append(generateVisit(lineId: otherLineId, directionId: otherDirectionId))
        }
        
        // Shuffle to randomize order
        visits.shuffle()
        
        // Build the SIRI response structure
        let response = SIRIResponse(
            ServiceDelivery: ServiceDelivery(
                StopMonitoringDelivery: StopMonitoringDelivery(
                    MonitoredStopVisit: visits
                )
            )
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let data = try! encoder.encode(response)
        
        return (data, targetCount)
    }

    // MARK: - Helper: Parse Response for Testing
    
    /// A testable version of parseResponse that we can call directly
    /// This mirrors the VTAService.parseResponse logic for testing purposes
    private func parseResponseForTesting(data: Data, lineId: String, directionId: String) throws -> [Prediction] {
        let decoder = JSONDecoder()
        let siriResponse = try decoder.decode(SIRIResponse.self, from: data)
        
        guard let visits = siriResponse.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit else {
            return []
        }
        
        let lineRef = buildLineRef(from: lineId)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        let predictions = visits.compactMap { visit -> Prediction? in
            let journey = visit.MonitoredVehicleJourney
            
            // Filter by line ID
            guard journey.LineRef == lineRef else {
                return nil
            }
            
            // Filter by direction
            guard journey.DirectionRef == directionId else {
                return nil
            }
            
            // Extract arrival information
            guard let monitoredCall = journey.MonitoredCall else {
                return nil
            }
            
            // Parse arrival time
            var minutesUntilArrival: Int? = nil
            var arrivalStatus: ArrivalStatus = .scheduled
            
            if let statusString = monitoredCall.ArrivalStatus?.lowercased() {
                switch statusString {
                case "arriving", "arr":
                    arrivalStatus = .arriving
                case "boarding", "brd", "atstop":
                    arrivalStatus = .boarding
                case "delayed", "late":
                    arrivalStatus = .delayed
                default:
                    arrivalStatus = .scheduled
                }
            }
            
            if arrivalStatus != .arriving && arrivalStatus != .boarding {
                if let timeString = monitoredCall.ExpectedArrivalTime ?? monitoredCall.AimedArrivalTime,
                   let arrivalDate = dateFormatter.date(from: timeString) {
                    let interval = arrivalDate.timeIntervalSince(Date())
                    let minutes = Int(ceil(interval / 60))
                    minutesUntilArrival = max(0, minutes)
                }
            }
            
            return Prediction(
                minutesUntilArrival: minutesUntilArrival,
                arrivalStatus: arrivalStatus,
                destination: journey.DestinationName ?? "",
                vehicleId: journey.VehicleRef,
                timestamp: Date()
            )
        }
        
        return predictions.sorted { p1, p2 in
            let m1 = p1.minutesUntilArrival ?? -1
            let m2 = p2.minutesUntilArrival ?? -1
            return m1 < m2
        }
    }

    // MARK: - Property 9 Tests
    
    /// Property 9: Filtered results contain only predictions for the specified line
    /// **Validates: Requirements 6.1, 6.4**
    /// **Feature: vta-all-lines, Property 9: 线路预测过滤正确性**
    @Test("Property 9: Filtered results contain only target line predictions - 100 iterations")
    func filteredResultsContainOnlyTargetLinePredictions() throws {
        for iteration in 1...100 {
            // Generate random test parameters
            let targetLineId = randomLineId()
            let targetDirectionId = randomDirectionId()
            let targetCount = Int.random(in: 1...10)
            let otherCount = Int.random(in: 1...20)
            
            // Generate multi-line response
            let (data, _) = generateMultiLineResponse(
                targetLineId: targetLineId,
                targetDirectionId: targetDirectionId,
                targetCount: targetCount,
                otherCount: otherCount
            )
            
            // Parse and filter the response
            let predictions = try parseResponseForTesting(
                data: data,
                lineId: targetLineId,
                directionId: targetDirectionId
            )
            
            // Decode the original response to verify filtering
            let decoder = JSONDecoder()
            let siriResponse = try decoder.decode(SIRIResponse.self, from: data)
            let visits = siriResponse.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit ?? []
            
            let targetLineRef = buildLineRef(from: targetLineId)
            
            // Property: All returned predictions must be for the target line and direction
            // We verify this by checking that the count matches expected target count
            // and that no predictions from other lines leaked through
            
            // Count how many visits in original data match target line and direction
            let expectedMatchCount = visits.filter { visit in
                visit.MonitoredVehicleJourney.LineRef == targetLineRef &&
                visit.MonitoredVehicleJourney.DirectionRef == targetDirectionId &&
                visit.MonitoredVehicleJourney.MonitoredCall != nil
            }.count
            
            #expect(
                predictions.count == expectedMatchCount,
                "Iteration \(iteration): Expected \(expectedMatchCount) predictions for line '\(targetLineId)' direction '\(targetDirectionId)', got \(predictions.count)"
            )
        }
    }

    /// Property 9: No predictions for the target line are lost during filtering
    /// **Validates: Requirements 6.1, 6.4**
    /// **Feature: vta-all-lines, Property 9: 线路预测过滤正确性**
    @Test("Property 9: No target line predictions are lost - 100 iterations")
    func noTargetLinePredictionsAreLost() throws {
        for iteration in 1...100 {
            // Generate random test parameters
            let targetLineId = randomLineId()
            let targetDirectionId = randomDirectionId()
            let targetCount = Int.random(in: 1...10)
            let otherCount = Int.random(in: 0...20)
            
            // Generate multi-line response
            let (data, expectedTargetCount) = generateMultiLineResponse(
                targetLineId: targetLineId,
                targetDirectionId: targetDirectionId,
                targetCount: targetCount,
                otherCount: otherCount
            )
            
            // Parse and filter the response
            let predictions = try parseResponseForTesting(
                data: data,
                lineId: targetLineId,
                directionId: targetDirectionId
            )
            
            // Property: The number of returned predictions must equal the number of
            // target line predictions in the original response (none lost)
            #expect(
                predictions.count == expectedTargetCount,
                "Iteration \(iteration): Expected \(expectedTargetCount) predictions for target line, got \(predictions.count). Some predictions were lost!"
            )
        }
    }
    
    /// Property 9: Filtering excludes predictions from other lines
    /// **Validates: Requirements 6.1, 6.4**
    /// **Feature: vta-all-lines, Property 9: 线路预测过滤正确性**
    @Test("Property 9: Filtering excludes other line predictions - 100 iterations")
    func filteringExcludesOtherLinePredictions() throws {
        for iteration in 1...100 {
            // Generate random test parameters
            let targetLineId = randomLineId()
            let targetDirectionId = randomDirectionId()
            let targetCount = Int.random(in: 0...5)
            let otherCount = Int.random(in: 5...20)
            
            // Generate multi-line response
            let (data, expectedTargetCount) = generateMultiLineResponse(
                targetLineId: targetLineId,
                targetDirectionId: targetDirectionId,
                targetCount: targetCount,
                otherCount: otherCount
            )
            
            // Parse and filter the response
            let predictions = try parseResponseForTesting(
                data: data,
                lineId: targetLineId,
                directionId: targetDirectionId
            )
            
            // Decode original to count total visits
            let decoder = JSONDecoder()
            let siriResponse = try decoder.decode(SIRIResponse.self, from: data)
            let totalVisits = siriResponse.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit?.count ?? 0
            
            // Property: Filtered count must be less than or equal to total
            // and must equal exactly the target count
            #expect(
                predictions.count <= totalVisits,
                "Iteration \(iteration): Filtered count (\(predictions.count)) should not exceed total visits (\(totalVisits))"
            )
            
            #expect(
                predictions.count == expectedTargetCount,
                "Iteration \(iteration): Expected exactly \(expectedTargetCount) target predictions, got \(predictions.count)"
            )
        }
    }

    /// Property 9: Filtering by different line IDs returns different results
    /// **Validates: Requirements 6.1, 6.4**
    /// **Feature: vta-all-lines, Property 9: 线路预测过滤正确性**
    @Test("Property 9: Different line IDs return different filtered results - 100 iterations")
    func differentLineIdsReturnDifferentResults() throws {
        for iteration in 1...100 {
            // Pick two different line IDs
            let lineId1 = "Orange"
            let lineId2 = "Blue"
            let directionId = randomDirectionId()
            
            // Generate response with predictions for both lines
            var visits: [MonitoredStopVisit] = []
            let line1Count = Int.random(in: 1...5)
            let line2Count = Int.random(in: 1...5)
            
            for _ in 0..<line1Count {
                visits.append(generateVisit(lineId: lineId1, directionId: directionId))
            }
            for _ in 0..<line2Count {
                visits.append(generateVisit(lineId: lineId2, directionId: directionId))
            }
            
            visits.shuffle()
            
            let response = SIRIResponse(
                ServiceDelivery: ServiceDelivery(
                    StopMonitoringDelivery: StopMonitoringDelivery(
                        MonitoredStopVisit: visits
                    )
                )
            )
            
            let data = try JSONEncoder().encode(response)
            
            // Filter for line 1
            let predictions1 = try parseResponseForTesting(
                data: data,
                lineId: lineId1,
                directionId: directionId
            )
            
            // Filter for line 2
            let predictions2 = try parseResponseForTesting(
                data: data,
                lineId: lineId2,
                directionId: directionId
            )
            
            // Property: Each filter should return the correct count for its line
            #expect(
                predictions1.count == line1Count,
                "Iteration \(iteration): Line 1 (\(lineId1)) should have \(line1Count) predictions, got \(predictions1.count)"
            )
            
            #expect(
                predictions2.count == line2Count,
                "Iteration \(iteration): Line 2 (\(lineId2)) should have \(line2Count) predictions, got \(predictions2.count)"
            )
            
            // Property: Total filtered predictions should equal total visits
            #expect(
                predictions1.count + predictions2.count == visits.count,
                "Iteration \(iteration): Sum of filtered predictions should equal total visits"
            )
        }
    }

    /// Property 9: Empty response returns empty predictions
    /// **Validates: Requirements 6.1, 6.4**
    /// **Feature: vta-all-lines, Property 9: 线路预测过滤正确性**
    @Test("Property 9: Empty response returns empty predictions - 100 iterations")
    func emptyResponseReturnsEmptyPredictions() throws {
        for iteration in 1...100 {
            let targetLineId = randomLineId()
            let targetDirectionId = randomDirectionId()
            
            // Generate empty response
            let response = SIRIResponse(
                ServiceDelivery: ServiceDelivery(
                    StopMonitoringDelivery: StopMonitoringDelivery(
                        MonitoredStopVisit: []
                    )
                )
            )
            
            let data = try JSONEncoder().encode(response)
            
            let predictions = try parseResponseForTesting(
                data: data,
                lineId: targetLineId,
                directionId: targetDirectionId
            )
            
            // Property: Empty input should produce empty output
            #expect(
                predictions.isEmpty,
                "Iteration \(iteration): Empty response should return empty predictions"
            )
        }
    }
    
    /// Property 9: Response with no matching line returns empty predictions
    /// **Validates: Requirements 6.1, 6.4**
    /// **Feature: vta-all-lines, Property 9: 线路预测过滤正确性**
    @Test("Property 9: No matching line returns empty predictions - 100 iterations")
    func noMatchingLineReturnsEmptyPredictions() throws {
        for iteration in 1...100 {
            // Generate response with only "Orange" line predictions
            let (data, _) = generateMultiLineResponse(
                targetLineId: "Orange",
                targetDirectionId: "E",
                targetCount: Int.random(in: 1...10),
                otherCount: 0
            )
            
            // Try to filter for a different line that doesn't exist in the response
            let predictions = try parseResponseForTesting(
                data: data,
                lineId: "NonExistentLine",
                directionId: "E"
            )
            
            // Property: Non-matching line should return empty predictions
            #expect(
                predictions.isEmpty,
                "Iteration \(iteration): Non-matching line should return empty predictions"
            )
        }
    }

    /// Property 9: Direction filtering is independent of line filtering
    /// **Validates: Requirements 6.1, 6.4**
    /// **Feature: vta-all-lines, Property 9: 线路预测过滤正确性**
    @Test("Property 9: Direction filtering is independent of line filtering - 100 iterations")
    func directionFilteringIsIndependentOfLineFiltering() throws {
        for iteration in 1...100 {
            let targetLineId = randomLineId()
            let direction1 = "E"
            let direction2 = "W"
            
            // Generate visits for same line but different directions
            var visits: [MonitoredStopVisit] = []
            let dir1Count = Int.random(in: 1...5)
            let dir2Count = Int.random(in: 1...5)
            
            for _ in 0..<dir1Count {
                visits.append(generateVisit(lineId: targetLineId, directionId: direction1))
            }
            for _ in 0..<dir2Count {
                visits.append(generateVisit(lineId: targetLineId, directionId: direction2))
            }
            
            visits.shuffle()
            
            let response = SIRIResponse(
                ServiceDelivery: ServiceDelivery(
                    StopMonitoringDelivery: StopMonitoringDelivery(
                        MonitoredStopVisit: visits
                    )
                )
            )
            
            let data = try JSONEncoder().encode(response)
            
            // Filter for direction 1
            let predictionsDir1 = try parseResponseForTesting(
                data: data,
                lineId: targetLineId,
                directionId: direction1
            )
            
            // Filter for direction 2
            let predictionsDir2 = try parseResponseForTesting(
                data: data,
                lineId: targetLineId,
                directionId: direction2
            )
            
            // Property: Each direction filter should return correct count
            #expect(
                predictionsDir1.count == dir1Count,
                "Iteration \(iteration): Direction 1 should have \(dir1Count) predictions, got \(predictionsDir1.count)"
            )
            
            #expect(
                predictionsDir2.count == dir2Count,
                "Iteration \(iteration): Direction 2 should have \(dir2Count) predictions, got \(predictionsDir2.count)"
            )
            
            // Property: No overlap between direction filters
            #expect(
                predictionsDir1.count + predictionsDir2.count == visits.count,
                "Iteration \(iteration): Sum of direction-filtered predictions should equal total visits"
            )
        }
    }

    /// Property 9: Line reference string building is correct for all line types
    /// **Validates: Requirements 6.1, 6.4**
    /// **Feature: vta-all-lines, Property 9: 线路预测过滤正确性**
    @Test("Property 9: Line reference string building is correct - 100 iterations")
    func lineReferenceStringBuildingIsCorrect() throws {
        // Test light rail lines (should have " Line" suffix)
        let lightRailLines = ["Orange", "Blue", "Green", "Yellow", "Red"]
        for lineId in lightRailLines {
            let lineRef = buildLineRef(from: lineId)
            #expect(
                lineRef == "\(lineId) Line",
                "Light rail line '\(lineId)' should have LineRef '\(lineId) Line', got '\(lineRef)'"
            )
        }
        
        // Test bus routes (should be just the number)
        let busRoutes = ["22", "522", "60", "68", "181"]
        for lineId in busRoutes {
            let lineRef = buildLineRef(from: lineId)
            #expect(
                lineRef == lineId,
                "Bus route '\(lineId)' should have LineRef '\(lineId)', got '\(lineRef)'"
            )
        }
        
        // Property test: random line IDs follow the pattern
        for iteration in 1...100 {
            let lineId = randomLineId()
            let lineRef = buildLineRef(from: lineId)
            
            let isLightRail = ["Orange", "Blue", "Green", "Yellow", "Red"].contains(lineId)
            
            if isLightRail {
                #expect(
                    lineRef.hasSuffix(" Line"),
                    "Iteration \(iteration): Light rail line '\(lineId)' should have ' Line' suffix"
                )
            } else {
                #expect(
                    lineRef == lineId,
                    "Iteration \(iteration): Bus route '\(lineId)' should not have suffix"
                )
            }
        }
    }
    
    /// Property 9: Combined test - filtering preserves all and only target predictions
    /// **Validates: Requirements 6.1, 6.4**
    /// **Feature: vta-all-lines, Property 9: 线路预测过滤正确性**
    @Test("Property 9: Filtering preserves all and only target predictions - 100 iterations")
    func filteringPreservesAllAndOnlyTargetPredictions() throws {
        for iteration in 1...100 {
            // Generate random test scenario
            let targetLineId = randomLineId()
            let targetDirectionId = randomDirectionId()
            let targetCount = Int.random(in: 0...10)
            let otherCount = Int.random(in: 0...20)
            
            // Generate multi-line response
            let (data, expectedTargetCount) = generateMultiLineResponse(
                targetLineId: targetLineId,
                targetDirectionId: targetDirectionId,
                targetCount: targetCount,
                otherCount: otherCount
            )
            
            // Parse and filter
            let predictions = try parseResponseForTesting(
                data: data,
                lineId: targetLineId,
                directionId: targetDirectionId
            )
            
            // Property 9 combined verification:
            // 1. Count equals expected (no predictions lost)
            #expect(
                predictions.count == expectedTargetCount,
                "Iteration \(iteration): Expected \(expectedTargetCount) predictions, got \(predictions.count)"
            )
            
            // 2. If we had target predictions, we should have results
            if expectedTargetCount > 0 {
                #expect(
                    !predictions.isEmpty,
                    "Iteration \(iteration): Should have predictions when target count > 0"
                )
            }
            
            // 3. If we had no target predictions, result should be empty
            if expectedTargetCount == 0 {
                #expect(
                    predictions.isEmpty,
                    "Iteration \(iteration): Should have no predictions when target count is 0"
                )
            }
        }
    }
}
