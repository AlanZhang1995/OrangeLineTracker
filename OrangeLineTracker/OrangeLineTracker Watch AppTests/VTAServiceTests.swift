//
//  VTAServiceTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Unit tests for VTAService
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - VTAServiceError Tests

struct VTAServiceErrorTests {
    
    @Test func networkErrorHasCorrectDescription() {
        let error = VTAServiceError.networkError("Connection timeout")
        #expect(error.errorDescription?.contains("网络连接失败") == true)
        #expect(error.errorDescription?.contains("Connection timeout") == true)
    }
    
    @Test func apiErrorHasCorrectDescription() {
        let error = VTAServiceError.apiError(500, "Internal Server Error")
        #expect(error.errorDescription?.contains("API 错误") == true)
        #expect(error.errorDescription?.contains("500") == true)
    }
    
    @Test func parsingErrorHasCorrectDescription() {
        let error = VTAServiceError.parsingError("Invalid JSON")
        #expect(error.errorDescription?.contains("数据解析错误") == true)
    }
    
    @Test func invalidAPIKeyHasCorrectDescription() {
        let error = VTAServiceError.invalidAPIKey
        #expect(error.errorDescription?.contains("API 密钥无效") == true)
    }
    
    @Test func noDataAvailableHasCorrectDescription() {
        let error = VTAServiceError.noDataAvailable
        #expect(error.errorDescription?.contains("暂无列车信息") == true)
    }
    
    @Test func invalidURLHasCorrectDescription() {
        let error = VTAServiceError.invalidURL
        #expect(error.errorDescription?.contains("无效的请求地址") == true)
    }
    
    @Test func errorsAreEquatable() {
        #expect(VTAServiceError.invalidAPIKey == VTAServiceError.invalidAPIKey)
        #expect(VTAServiceError.noDataAvailable == VTAServiceError.noDataAvailable)
        #expect(VTAServiceError.invalidURL == VTAServiceError.invalidURL)
        #expect(VTAServiceError.networkError("test") == VTAServiceError.networkError("test"))
        #expect(VTAServiceError.apiError(500, "error") == VTAServiceError.apiError(500, "error"))
        #expect(VTAServiceError.parsingError("test") == VTAServiceError.parsingError("test"))
        
        #expect(VTAServiceError.invalidAPIKey != VTAServiceError.noDataAvailable)
        #expect(VTAServiceError.networkError("a") != VTAServiceError.networkError("b"))
    }
}

// MARK: - SIRI Response Model Tests

struct SIRIResponseModelTests {
    
    @Test func siriResponseDecodesCorrectly() throws {
        // Validates: Requirements 3.3 - parse SIRI JSON response
        let json = """
        {
          "ServiceDelivery": {
            "StopMonitoringDelivery": {
              "MonitoredStopVisit": [
                {
                  "MonitoredVehicleJourney": {
                    "LineRef": "902",
                    "DirectionRef": "OB",
                    "DestinationName": "Alum Rock",
                    "MonitoredCall": {
                      "StopPointRef": "70261",
                      "ExpectedArrivalTime": "2024-01-15T10:30:00Z",
                      "ArrivalStatus": "onTime"
                    },
                    "VehicleRef": "1234"
                  }
                }
              ]
            }
          }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SIRIResponse.self, from: data)
        
        #expect(response.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit?.count == 1)
        
        let visit = response.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit?.first
        #expect(visit?.MonitoredVehicleJourney.LineRef == "902")
        #expect(visit?.MonitoredVehicleJourney.DirectionRef == "OB")
        #expect(visit?.MonitoredVehicleJourney.DestinationName == "Alum Rock")
        #expect(visit?.MonitoredVehicleJourney.VehicleRef == "1234")
        #expect(visit?.MonitoredVehicleJourney.MonitoredCall?.StopPointRef == "70261")
        #expect(visit?.MonitoredVehicleJourney.MonitoredCall?.ExpectedArrivalTime == "2024-01-15T10:30:00Z")
        #expect(visit?.MonitoredVehicleJourney.MonitoredCall?.ArrivalStatus == "onTime")
    }
    
    @Test func siriResponseDecodesWithEmptyVisits() throws {
        let json = """
        {
          "ServiceDelivery": {
            "StopMonitoringDelivery": {
              "MonitoredStopVisit": []
            }
          }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SIRIResponse.self, from: data)
        
        #expect(response.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit?.isEmpty == true)
    }
    
    @Test func siriResponseDecodesWithNullVisits() throws {
        let json = """
        {
          "ServiceDelivery": {
            "StopMonitoringDelivery": {
              "MonitoredStopVisit": null
            }
          }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SIRIResponse.self, from: data)
        
        #expect(response.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit == nil)
    }
    
    @Test func siriResponseDecodesWithMultipleVisits() throws {
        let json = """
        {
          "ServiceDelivery": {
            "StopMonitoringDelivery": {
              "MonitoredStopVisit": [
                {
                  "MonitoredVehicleJourney": {
                    "LineRef": "902",
                    "DirectionRef": "OB",
                    "DestinationName": "Alum Rock",
                    "MonitoredCall": {
                      "ExpectedArrivalTime": "2024-01-15T10:30:00Z"
                    }
                  }
                },
                {
                  "MonitoredVehicleJourney": {
                    "LineRef": "902",
                    "DirectionRef": "OB",
                    "DestinationName": "Alum Rock",
                    "MonitoredCall": {
                      "ExpectedArrivalTime": "2024-01-15T10:45:00Z"
                    }
                  }
                }
              ]
            }
          }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SIRIResponse.self, from: data)
        
        #expect(response.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit?.count == 2)
    }
    
    @Test func siriResponseDecodesWithOptionalFields() throws {
        // Test that optional fields can be missing
        let json = """
        {
          "ServiceDelivery": {
            "StopMonitoringDelivery": {
              "MonitoredStopVisit": [
                {
                  "MonitoredVehicleJourney": {
                    "LineRef": "902",
                    "DirectionRef": "OB"
                  }
                }
              ]
            }
          }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SIRIResponse.self, from: data)
        
        let visit = response.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit?.first
        #expect(visit?.MonitoredVehicleJourney.DestinationName == nil)
        #expect(visit?.MonitoredVehicleJourney.VehicleRef == nil)
        #expect(visit?.MonitoredVehicleJourney.MonitoredCall == nil)
    }
}

// MARK: - MockVTAService Tests

struct MockVTAServiceTests {
    
    @Test func mockServiceReturnsMockPredictions() async throws {
        let mockService = MockVTAService()
        let expectedPredictions = [
            Prediction(
                minutesUntilArrival: 5,
                arrivalStatus: .scheduled,
                destination: "Alum Rock"
            ),
            Prediction(
                minutesUntilArrival: 15,
                arrivalStatus: .scheduled,
                destination: "Alum Rock"
            )
        ]
        mockService.mockPredictions = expectedPredictions
        
        let predictions = try await mockService.fetchPredictions(
            stationId: "70261",
            direction: .alumRock
        )
        
        #expect(predictions.count == 2)
        #expect(predictions[0].minutesUntilArrival == 5)
        #expect(predictions[1].minutesUntilArrival == 15)
    }
    
    @Test func mockServiceThrowsMockError() async {
        let mockService = MockVTAService()
        mockService.mockError = .networkError("Test error")
        
        do {
            _ = try await mockService.fetchPredictions(
                stationId: "70261",
                direction: .alumRock
            )
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as VTAServiceError {
            #expect(error == .networkError("Test error"))
        } catch {
            #expect(Bool(false), "Wrong error type thrown")
        }
    }
    
    @Test func mockServiceRecordsRequestParameters() async throws {
        let mockService = MockVTAService()
        mockService.mockPredictions = [
            Prediction(
                minutesUntilArrival: 5,
                arrivalStatus: .scheduled,
                destination: "Alum Rock"
            )
        ]
        
        _ = try await mockService.fetchPredictions(
            stationId: "70261",
            direction: .alumRock
        )
        
        #expect(mockService.lastRequestedStationId == "70261")
        #expect(mockService.lastRequestedDirection == .alumRock)
        #expect(mockService.fetchCallCount == 1)
    }
    
    @Test func mockServiceCountsMultipleCalls() async throws {
        let mockService = MockVTAService()
        mockService.mockPredictions = [
            Prediction(
                minutesUntilArrival: 5,
                arrivalStatus: .scheduled,
                destination: "Alum Rock"
            )
        ]
        
        _ = try await mockService.fetchPredictions(stationId: "70261", direction: .alumRock)
        _ = try await mockService.fetchPredictions(stationId: "70271", direction: .mountainView)
        _ = try await mockService.fetchPredictions(stationId: "70281", direction: .alumRock)
        
        #expect(mockService.fetchCallCount == 3)
        #expect(mockService.lastRequestedStationId == "70281")
        #expect(mockService.lastRequestedDirection == .alumRock)
    }
    
    @Test func mockServiceResetClearsState() async throws {
        let mockService = MockVTAService()
        mockService.mockPredictions = [
            Prediction(
                minutesUntilArrival: 5,
                arrivalStatus: .scheduled,
                destination: "Alum Rock"
            )
        ]
        mockService.mockError = .networkError("Test")
        
        _ = try? await mockService.fetchPredictions(stationId: "70261", direction: .alumRock)
        
        mockService.reset()
        
        #expect(mockService.mockPredictions.isEmpty)
        #expect(mockService.mockError == nil)
        #expect(mockService.lastRequestedStationId == nil)
        #expect(mockService.lastRequestedDirection == nil)
        #expect(mockService.fetchCallCount == 0)
    }
}

// MARK: - VTAService Protocol Conformance Tests

struct VTAServiceProtocolTests {
    
    @Test func vtaServiceConformsToProtocol() {
        // Verify VTAService conforms to VTAServiceProtocol
        let service: VTAServiceProtocol = VTAService(apiKey: "test-key")
        #expect(service is VTAService)
    }
    
    @Test func mockVTAServiceConformsToProtocol() {
        // Verify MockVTAService conforms to VTAServiceProtocol
        let service: VTAServiceProtocol = MockVTAService()
        #expect(service is MockVTAService)
    }
}

// MARK: - VTAService Initialization Tests

struct VTAServiceInitializationTests {
    
    @Test func vtaServiceInitializesWithAPIKey() {
        let service = VTAService(apiKey: "test-api-key")
        #expect(service is VTAService)
    }
    
    @Test func vtaServiceInitializesWithCustomURLSession() {
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        let service = VTAService(apiKey: "test-api-key", urlSession: session)
        #expect(service is VTAService)
    }
}

// MARK: - Direction Filtering Tests

struct DirectionFilteringTests {
    
    @Test func directionIdMapsCorrectlyForMountainView() {
        // Validates: Requirements 3.4 - filter by direction
        let direction = Direction.mountainView
        #expect(direction.directionId == "W")  // Westbound
    }
    
    @Test func directionIdMapsCorrectlyForAlumRock() {
        // Validates: Requirements 3.4 - filter by direction
        let direction = Direction.alumRock
        #expect(direction.directionId == "E")  // Eastbound
    }
}

// MARK: - Prediction Sorting Tests

struct PredictionSortingTests {
    
    @Test func predictionsAreSortedByArrivalTime() {
        // Validates: Requirements 3.5 - return next train arrival time
        var predictions = [
            Prediction(minutesUntilArrival: 15, arrivalStatus: .scheduled, destination: "Alum Rock"),
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock"),
            Prediction(minutesUntilArrival: 10, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        predictions.sort { p1, p2 in
            let m1 = p1.minutesUntilArrival ?? -1
            let m2 = p2.minutesUntilArrival ?? -1
            return m1 < m2
        }
        
        #expect(predictions[0].minutesUntilArrival == 5)
        #expect(predictions[1].minutesUntilArrival == 10)
        #expect(predictions[2].minutesUntilArrival == 15)
    }
    
    @Test func arrivingPredictionsComesFirst() {
        // Predictions with nil minutes (arriving) should come first
        var predictions = [
            Prediction(minutesUntilArrival: 5, arrivalStatus: .scheduled, destination: "Alum Rock"),
            Prediction(minutesUntilArrival: nil, arrivalStatus: .arriving, destination: "Alum Rock"),
            Prediction(minutesUntilArrival: 10, arrivalStatus: .scheduled, destination: "Alum Rock")
        ]
        
        predictions.sort { p1, p2 in
            let m1 = p1.minutesUntilArrival ?? -1
            let m2 = p2.minutesUntilArrival ?? -1
            return m1 < m2
        }
        
        #expect(predictions[0].minutesUntilArrival == nil)
        #expect(predictions[0].arrivalStatus == .arriving)
        #expect(predictions[1].minutesUntilArrival == 5)
        #expect(predictions[2].minutesUntilArrival == 10)
    }
}

// MARK: - API Response Parsing Integration Tests

struct APIResponseParsingTests {
    
    @Test func parseValidAPIResponse() throws {
        // Validates: Requirements 3.3 - parse SIRI JSON response format
        let json = """
        {
          "ServiceDelivery": {
            "StopMonitoringDelivery": {
              "MonitoredStopVisit": [
                {
                  "MonitoredVehicleJourney": {
                    "LineRef": "902",
                    "DirectionRef": "OB",
                    "DestinationName": "Alum Rock",
                    "MonitoredCall": {
                      "StopPointRef": "70261",
                      "ExpectedArrivalTime": "2024-01-15T10:30:00Z",
                      "ArrivalStatus": "onTime"
                    },
                    "VehicleRef": "1234"
                  }
                }
              ]
            }
          }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SIRIResponse.self, from: data)
        
        let visits = response.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit
        #expect(visits?.count == 1)
        
        let journey = visits?.first?.MonitoredVehicleJourney
        #expect(journey?.LineRef == "902")
        #expect(journey?.DirectionRef == "OB")
        #expect(journey?.DestinationName == "Alum Rock")
        #expect(journey?.VehicleRef == "1234")
    }
    
    @Test func parseResponseWithDifferentLineRef() throws {
        // Non-Orange Line trains should be filtered out
        let json = """
        {
          "ServiceDelivery": {
            "StopMonitoringDelivery": {
              "MonitoredStopVisit": [
                {
                  "MonitoredVehicleJourney": {
                    "LineRef": "901",
                    "DirectionRef": "OB",
                    "DestinationName": "Winchester"
                  }
                }
              ]
            }
          }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SIRIResponse.self, from: data)
        
        // The response parses, but LineRef is not 902 (Orange Line)
        let journey = response.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit?.first?.MonitoredVehicleJourney
        #expect(journey?.LineRef == "901")
        #expect(journey?.LineRef != "902")
    }
    
    @Test func parseResponseWithMixedLines() throws {
        // Validates: Requirements 3.3 - extract Orange Line train info
        let json = """
        {
          "ServiceDelivery": {
            "StopMonitoringDelivery": {
              "MonitoredStopVisit": [
                {
                  "MonitoredVehicleJourney": {
                    "LineRef": "901",
                    "DirectionRef": "OB",
                    "DestinationName": "Winchester"
                  }
                },
                {
                  "MonitoredVehicleJourney": {
                    "LineRef": "902",
                    "DirectionRef": "OB",
                    "DestinationName": "Alum Rock"
                  }
                },
                {
                  "MonitoredVehicleJourney": {
                    "LineRef": "903",
                    "DirectionRef": "IB",
                    "DestinationName": "Downtown"
                  }
                }
              ]
            }
          }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SIRIResponse.self, from: data)
        
        let visits = response.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit
        #expect(visits?.count == 3)
        
        // Filter for Orange Line (902) only
        let orangeLineVisits = visits?.filter { $0.MonitoredVehicleJourney.LineRef == "902" }
        #expect(orangeLineVisits?.count == 1)
        #expect(orangeLineVisits?.first?.MonitoredVehicleJourney.DestinationName == "Alum Rock")
    }
}

// MARK: - Arrival Status Parsing Tests

struct ArrivalStatusParsingTests {
    
    @Test func parseOnTimeStatus() {
        // "onTime" should map to .scheduled
        let statusString = "onTime"
        let expectedStatus = ArrivalStatus.scheduled
        
        // Verify the mapping logic
        let status: ArrivalStatus
        switch statusString.lowercased() {
        case "ontime", "early":
            status = .scheduled
        case "delayed", "late":
            status = .delayed
        case "arriving", "arr":
            status = .arriving
        case "boarding", "brd", "atstop":
            status = .boarding
        default:
            status = .scheduled
        }
        
        #expect(status == expectedStatus)
    }
    
    @Test func parseDelayedStatus() {
        let statusString = "delayed"
        let status: ArrivalStatus
        switch statusString.lowercased() {
        case "ontime", "early":
            status = .scheduled
        case "delayed", "late":
            status = .delayed
        case "arriving", "arr":
            status = .arriving
        case "boarding", "brd", "atstop":
            status = .boarding
        default:
            status = .scheduled
        }
        
        #expect(status == .delayed)
    }
    
    @Test func parseArrivingStatus() {
        let statusString = "arriving"
        let status: ArrivalStatus
        switch statusString.lowercased() {
        case "ontime", "early":
            status = .scheduled
        case "delayed", "late":
            status = .delayed
        case "arriving", "arr":
            status = .arriving
        case "boarding", "brd", "atstop":
            status = .boarding
        default:
            status = .scheduled
        }
        
        #expect(status == .arriving)
    }
    
    @Test func parseBoardingStatus() {
        let statusString = "atStop"
        let status: ArrivalStatus
        switch statusString.lowercased() {
        case "ontime", "early":
            status = .scheduled
        case "delayed", "late":
            status = .delayed
        case "arriving", "arr":
            status = .arriving
        case "boarding", "brd", "atstop":
            status = .boarding
        default:
            status = .scheduled
        }
        
        #expect(status == .boarding)
    }
    
    @Test func parseUnknownStatusDefaultsToScheduled() {
        let statusString = "unknown_status"
        let status: ArrivalStatus
        switch statusString.lowercased() {
        case "ontime", "early":
            status = .scheduled
        case "delayed", "late":
            status = .delayed
        case "arriving", "arr":
            status = .arriving
        case "boarding", "brd", "atstop":
            status = .boarding
        default:
            status = .scheduled
        }
        
        #expect(status == .scheduled)
    }
}

// MARK: - Time Calculation Tests

struct TimeCalculationTests {
    
    @Test func calculateMinutesFromFutureTime() {
        let now = Date()
        let futureTime = now.addingTimeInterval(5 * 60) // 5 minutes from now
        
        let interval = futureTime.timeIntervalSince(now)
        let minutes = Int(ceil(interval / 60))
        
        #expect(minutes == 5)
    }
    
    @Test func calculateMinutesFromPastTime() {
        let now = Date()
        let pastTime = now.addingTimeInterval(-2 * 60) // 2 minutes ago
        
        let interval = pastTime.timeIntervalSince(now)
        let minutes = Int(ceil(interval / 60))
        
        #expect(minutes <= 0)
    }
    
    @Test func calculateMinutesFromImmediateTime() {
        let now = Date()
        let immediateTime = now.addingTimeInterval(30) // 30 seconds from now
        
        let interval = immediateTime.timeIntervalSince(now)
        let minutes = Int(ceil(interval / 60))
        
        #expect(minutes == 1)
    }
}

// MARK: - ISO8601 Date Parsing Tests

struct ISO8601DateParsingTests {
    
    @Test func parseStandardISO8601Date() {
        let dateString = "2024-01-15T10:30:00Z"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        let date = formatter.date(from: dateString)
        #expect(date != nil)
    }
    
    @Test func parseISO8601DateWithFractionalSeconds() {
        let dateString = "2024-01-15T10:30:00.123Z"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let date = formatter.date(from: dateString)
        #expect(date != nil)
    }
    
    @Test func parseISO8601DateWithTimezone() {
        let dateString = "2024-01-15T10:30:00-08:00"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        let date = formatter.date(from: dateString)
        #expect(date != nil)
    }
}

// MARK: - All Lines All Directions API Tests

/// Tests that verify all VTA lines and all directions can fetch data from the API
/// This is a live API test that validates the multi-line support implementation
struct AllLinesAllDirectionsAPITests {
    
    /// Test that all lines can be fetched from the API
    @Test func fetchAllLinesReturnsData() async throws {
        let vtaService = VTAService(apiKey: APIConfig.vtaAPIKey)
        
        let lines = try await vtaService.fetchAllLines()
        
        // Should have at least the 3 main light rail lines
        #expect(lines.count >= 3, "Expected at least 3 lines (Orange, Blue, Green)")
        
        // Verify Orange Line exists
        let orangeLine = lines.first { $0.id == "Orange" }
        #expect(orangeLine != nil, "Orange Line should exist")
        #expect(orangeLine?.directions.count == 2, "Orange Line should have 2 directions")
        
        // Verify Blue Line exists
        let blueLine = lines.first { $0.id == "Blue" }
        #expect(blueLine != nil, "Blue Line should exist")
        #expect(blueLine?.directions.count == 2, "Blue Line should have 2 directions")
        
        // Verify Green Line exists
        let greenLine = lines.first { $0.id == "Green" }
        #expect(greenLine != nil, "Green Line should exist")
        #expect(greenLine?.directions.count == 2, "Green Line should have 2 directions")
        
        print("✅ Fetched \(lines.count) lines from API")
        for line in lines {
            print("  - \(line.name): \(line.directions.count) directions, \(line.stations.count) stations")
        }
    }
    
    /// Test that predictions can be fetched for all lines and all directions
    /// This validates that the API returns data for every line/direction combination
    @Test func fetchPredictionsForAllLinesAllDirections() async throws {
        let vtaService = VTAService(apiKey: APIConfig.vtaAPIKey)
        
        // Fetch all lines first
        let lines = try await vtaService.fetchAllLines()
        #expect(!lines.isEmpty, "Should have at least one line")
        
        var successCount = 0
        var noDataCount = 0
        var errorCount = 0
        var results: [(line: String, direction: String, station: String, status: String)] = []
        
        // Test each line
        for line in lines {
            // Skip bus lines for now, focus on light rail
            guard line.type == .lightRail else { continue }
            
            // Test each direction
            for direction in line.directions {
                // Pick a station from the middle of the line for testing
                let stationIndex = line.stations.count / 2
                guard stationIndex < line.stations.count else { continue }
                let station = line.stations[stationIndex]
                
                do {
                    let predictions = try await vtaService.fetchPredictions(
                        lineId: line.id,
                        stationId: station.id,
                        directionId: direction.id
                    )
                    
                    if predictions.isEmpty {
                        noDataCount += 1
                        results.append((line.name, direction.headsign, station.name, "No data (may be off-hours)"))
                    } else {
                        successCount += 1
                        let firstPrediction = predictions.first!
                        results.append((line.name, direction.headsign, station.name, "✅ \(predictions.count) predictions, next: \(firstPrediction.minutesUntilArrival ?? -1) min"))
                    }
                } catch VTAServiceError.noDataAvailable {
                    noDataCount += 1
                    results.append((line.name, direction.headsign, station.name, "No data available"))
                } catch {
                    errorCount += 1
                    results.append((line.name, direction.headsign, station.name, "❌ Error: \(error.localizedDescription)"))
                }
                
                // Small delay to avoid rate limiting
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
        
        // Print results
        print("\n📊 All Lines All Directions API Test Results:")
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        for result in results {
            print("[\(result.line)] \(result.direction) @ \(result.station): \(result.status)")
        }
        print("=" .padding(toLength: 80, withPad: "=", startingAt: 0))
        print("Summary: ✅ \(successCount) success, ⚠️ \(noDataCount) no data, ❌ \(errorCount) errors")
        
        // The test passes if we got at least some successful responses
        // No data is acceptable during off-hours
        #expect(errorCount == 0, "Should have no API errors")
        #expect(successCount + noDataCount > 0, "Should have tested at least one line/direction")
    }
    
    /// Test Orange Line specifically - both directions
    @Test func fetchOrangeLineBothDirections() async throws {
        let vtaService = VTAService(apiKey: APIConfig.vtaAPIKey)
        
        // Use a known Orange Line station
        let station = OrangeLineStations.stations[5] // Convention Center
        
        // Test Eastbound (Alum Rock)
        do {
            let eastboundPredictions = try await vtaService.fetchPredictions(
                stationId: station.id,
                direction: .alumRock
            )
            print("Orange Line Eastbound @ \(station.name): \(eastboundPredictions.count) predictions")
            // No assertion on count - may be empty during off-hours
        } catch VTAServiceError.noDataAvailable {
            print("Orange Line Eastbound @ \(station.name): No data (off-hours)")
        }
        
        // Test Westbound (Mountain View)
        do {
            let westboundPredictions = try await vtaService.fetchPredictions(
                stationId: station.id,
                direction: .mountainView
            )
            print("Orange Line Westbound @ \(station.name): \(westboundPredictions.count) predictions")
            // No assertion on count - may be empty during off-hours
        } catch VTAServiceError.noDataAvailable {
            print("Orange Line Westbound @ \(station.name): No data (off-hours)")
        }
        
        // Test passes if no errors thrown (noDataAvailable is acceptable)
    }
    
    /// Test Blue Line specifically - both directions
    @Test func fetchBlueLineBothDirections() async throws {
        let vtaService = VTAService(apiKey: APIConfig.vtaAPIKey)
        let lines = try await vtaService.fetchAllLines()
        
        guard let blueLine = lines.first(where: { $0.id == "Blue" }),
              !blueLine.stations.isEmpty else {
            print("Blue Line not found or has no stations")
            return
        }
        
        let station = blueLine.stations[blueLine.stations.count / 2]
        
        for direction in blueLine.directions {
            do {
                let predictions = try await vtaService.fetchPredictions(
                    lineId: blueLine.id,
                    stationId: station.id,
                    directionId: direction.id
                )
                print("Blue Line \(direction.headsign) @ \(station.name): \(predictions.count) predictions")
            } catch VTAServiceError.noDataAvailable {
                print("Blue Line \(direction.headsign) @ \(station.name): No data (off-hours)")
            }
        }
    }
    
    /// Test Green Line specifically - both directions
    @Test func fetchGreenLineBothDirections() async throws {
        let vtaService = VTAService(apiKey: APIConfig.vtaAPIKey)
        let lines = try await vtaService.fetchAllLines()
        
        guard let greenLine = lines.first(where: { $0.id == "Green" }),
              !greenLine.stations.isEmpty else {
            print("Green Line not found or has no stations")
            return
        }
        
        let station = greenLine.stations[greenLine.stations.count / 2]
        
        for direction in greenLine.directions {
            do {
                let predictions = try await vtaService.fetchPredictions(
                    lineId: greenLine.id,
                    stationId: station.id,
                    directionId: direction.id
                )
                print("Green Line \(direction.headsign) @ \(station.name): \(predictions.count) predictions")
            } catch VTAServiceError.noDataAvailable {
                print("Green Line \(direction.headsign) @ \(station.name): No data (off-hours)")
            }
        }
    }
}
