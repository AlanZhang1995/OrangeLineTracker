//
//  VTAService.swift
//  OrangeLineTracker Watch App
//
//  VTA API service for fetching real-time arrival predictions
//  Uses 511.org SIRI StopMonitoring API
//

import Foundation

// MARK: - VTAServiceError

/// Errors that can occur when fetching VTA data
/// - Validates: Requirements 5.1, 5.2, 5.4
enum VTAServiceError: Error, LocalizedError, Equatable {
    /// Network connection failed
    case networkError(String)
    
    /// API returned an error response
    case apiError(Int, String)
    
    /// Failed to parse API response
    case parsingError(String)
    
    /// API key is invalid or missing
    case invalidAPIKey
    
    /// No data available for the requested station/direction
    case noDataAvailable
    
    /// Invalid URL construction
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "网络连接失败: \(message)"
        case .apiError(let code, let message):
            return "API 错误 (\(code)): \(message)"
        case .parsingError(let message):
            return "数据解析错误: \(message)"
        case .invalidAPIKey:
            return "API 密钥无效，请检查配置"
        case .noDataAvailable:
            return "暂无列车信息"
        case .invalidURL:
            return "无效的请求地址"
        }
    }
}

// MARK: - VTAServiceProtocol

/// Protocol defining the VTA service interface
/// - Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
protocol VTAServiceProtocol {
    /// Fetches arrival predictions for a specific station and direction
    /// - Parameters:
    ///   - stationId: The 511.org stop code for the station
    ///   - direction: The travel direction (Mountain View or Alum Rock)
    /// - Returns: An array of Prediction objects sorted by arrival time
    /// - Throws: VTAServiceError if the request fails
    func fetchPredictions(
        stationId: String,
        direction: Direction
    ) async throws -> [Prediction]
}

// MARK: - SIRI API Response Models

/// Root response structure from 511.org SIRI StopMonitoring API
struct SIRIResponse: Codable {
    let ServiceDelivery: ServiceDelivery
}

/// Service delivery container
struct ServiceDelivery: Codable {
    let StopMonitoringDelivery: StopMonitoringDelivery
}

/// Stop monitoring delivery container
struct StopMonitoringDelivery: Codable {
    let MonitoredStopVisit: [MonitoredStopVisit]?
}

/// Individual stop visit (train arrival)
struct MonitoredStopVisit: Codable {
    let MonitoredVehicleJourney: MonitoredVehicleJourney
}

/// Vehicle journey information
struct MonitoredVehicleJourney: Codable {
    let LineRef: String?
    let DirectionRef: String?
    let DestinationName: String?
    let MonitoredCall: MonitoredCall?
    let VehicleRef: String?
}

/// Monitored call (arrival information)
struct MonitoredCall: Codable {
    let StopPointRef: String?
    let ExpectedArrivalTime: String?
    let AimedArrivalTime: String?
    let ArrivalStatus: String?
}

// MARK: - VTAService

/// Implementation of VTAServiceProtocol using 511.org SIRI StopMonitoring API
/// - Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
class VTAService: VTAServiceProtocol {
    
    // MARK: - Constants
    
    /// VTA Orange Line identifier (as returned by 511.org API)
    private static let orangeLineRef = "Orange Line"
    
    /// 511.org API base URL
    private static let baseURL = "https://api.511.org/transit/StopMonitoring"
    
    /// VTA agency identifier
    private static let agencyId = "SC"
    
    // MARK: - Properties
    
    /// API key for 511.org
    private let apiKey: String
    
    /// URLSession for network requests
    private let urlSession: URLSession
    
    /// JSON decoder configured for API responses
    private let decoder: JSONDecoder
    
    /// ISO8601 date formatter for parsing API timestamps
    private let dateFormatter: ISO8601DateFormatter
    
    // MARK: - Initialization
    
    /// Creates a new VTAService instance
    /// - Parameters:
    ///   - apiKey: The 511.org API key
    ///   - urlSession: URLSession to use for requests (defaults to .shared)
    init(apiKey: String, urlSession: URLSession = .shared) {
        self.apiKey = apiKey
        self.urlSession = urlSession
        self.decoder = JSONDecoder()
        self.dateFormatter = ISO8601DateFormatter()
        self.dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }
    
    // MARK: - VTAServiceProtocol
    
    /// Fetches arrival predictions for a specific station and direction
    /// - Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
    func fetchPredictions(
        stationId: String,
        direction: Direction
    ) async throws -> [Prediction] {
        // Build the API URL
        // Validates: Requirements 3.2 - use VTA real-time data API endpoint
        guard let url = buildURL(stationId: stationId) else {
            throw VTAServiceError.invalidURL
        }
        
        // Make the API request
        // Validates: Requirements 3.1 - fetch real-time arrival prediction data
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await urlSession.data(from: url)
        } catch {
            throw VTAServiceError.networkError(error.localizedDescription)
        }
        
        // Check HTTP response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VTAServiceError.networkError("Invalid response type")
        }
        
        // Handle HTTP errors
        // Validates: Requirements 5.2, 5.4 - handle API errors
        switch httpResponse.statusCode {
        case 200:
            break // Success
        case 401, 403:
            throw VTAServiceError.invalidAPIKey
        default:
            throw VTAServiceError.apiError(
                httpResponse.statusCode,
                HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }
        
        // Parse the response
        // Validates: Requirements 3.3 - parse response and extract Orange Line train info
        let predictions = try parseResponse(data: data, direction: direction)
        
        // Check if we have any predictions
        // Validates: Requirements 5.3 - handle no data available
        if predictions.isEmpty {
            throw VTAServiceError.noDataAvailable
        }
        
        return predictions
    }
    
    // MARK: - Private Methods
    
    /// Builds the API URL for the StopMonitoring request
    private func buildURL(stationId: String) -> URL? {
        var components = URLComponents(string: Self.baseURL)
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "agency", value: Self.agencyId),
            URLQueryItem(name: "stopCode", value: stationId),
            URLQueryItem(name: "format", value: "json")
        ]
        return components?.url
    }
    
    /// Parses the SIRI API response and extracts predictions
    /// - Validates: Requirements 3.3, 3.4 - parse response and filter by direction
    private func parseResponse(data: Data, direction: Direction) throws -> [Prediction] {
        // Parse JSON response
        let siriResponse: SIRIResponse
        do {
            siriResponse = try decoder.decode(SIRIResponse.self, from: data)
        } catch {
            throw VTAServiceError.parsingError(error.localizedDescription)
        }
        
        // Extract monitored stop visits
        guard let visits = siriResponse.ServiceDelivery.StopMonitoringDelivery.MonitoredStopVisit else {
            return []
        }
        
        // Filter and convert to Prediction objects
        // Validates: Requirements 3.3, 3.4 - extract Orange Line info and filter by direction
        let predictions = visits.compactMap { visit -> Prediction? in
            let journey = visit.MonitoredVehicleJourney
            
            // Filter for Orange Line only
            guard journey.LineRef == Self.orangeLineRef else {
                return nil
            }
            
            // Filter by direction
            // Validates: Requirements 3.4 - filter train data by user-selected direction
            guard journey.DirectionRef == direction.directionId else {
                return nil
            }
            
            // Extract arrival information
            guard let monitoredCall = journey.MonitoredCall else {
                return nil
            }
            
            // Parse arrival time
            let (minutesUntilArrival, arrivalStatus) = parseArrivalTime(
                expectedTime: monitoredCall.ExpectedArrivalTime,
                aimedTime: monitoredCall.AimedArrivalTime,
                statusString: monitoredCall.ArrivalStatus
            )
            
            // Get destination name
            let destination = journey.DestinationName ?? direction.displayName
            
            // Create prediction
            // Validates: Requirements 3.5 - return next train arrival time
            return Prediction(
                minutesUntilArrival: minutesUntilArrival,
                arrivalStatus: arrivalStatus,
                destination: destination,
                vehicleId: journey.VehicleRef,
                timestamp: Date()
            )
        }
        
        // Sort by arrival time (soonest first)
        return predictions.sorted { p1, p2 in
            let m1 = p1.minutesUntilArrival ?? -1
            let m2 = p2.minutesUntilArrival ?? -1
            return m1 < m2
        }
    }
    
    /// Parses arrival time from API response
    /// - Returns: Tuple of (minutes until arrival, arrival status)
    private func parseArrivalTime(
        expectedTime: String?,
        aimedTime: String?,
        statusString: String?
    ) -> (Int?, ArrivalStatus) {
        // Determine arrival status from API status string
        let arrivalStatus = parseArrivalStatus(statusString)
        
        // If status indicates arriving or boarding, return nil minutes
        if arrivalStatus == .arriving || arrivalStatus == .boarding {
            return (nil, arrivalStatus)
        }
        
        // Parse expected arrival time
        let timeString = expectedTime ?? aimedTime
        guard let timeString = timeString else {
            return (nil, arrivalStatus)
        }
        
        // Try parsing with fractional seconds first, then without
        var arrivalDate: Date?
        arrivalDate = dateFormatter.date(from: timeString)
        
        if arrivalDate == nil {
            // Try without fractional seconds
            let fallbackFormatter = ISO8601DateFormatter()
            fallbackFormatter.formatOptions = [.withInternetDateTime]
            arrivalDate = fallbackFormatter.date(from: timeString)
        }
        
        guard let arrivalDate = arrivalDate else {
            return (nil, arrivalStatus)
        }
        
        // Calculate minutes until arrival
        let now = Date()
        let interval = arrivalDate.timeIntervalSince(now)
        let minutes = Int(ceil(interval / 60))
        
        // If less than 1 minute, consider it arriving
        if minutes <= 0 {
            return (nil, .arriving)
        }
        
        return (minutes, arrivalStatus)
    }
    
    /// Parses the arrival status string from the API
    private func parseArrivalStatus(_ statusString: String?) -> ArrivalStatus {
        guard let status = statusString?.lowercased() else {
            return .scheduled
        }
        
        switch status {
        case "ontime", "early":
            return .scheduled
        case "delayed", "late":
            return .delayed
        case "arriving", "arr":
            return .arriving
        case "boarding", "brd", "atstop":
            return .boarding
        default:
            return .scheduled
        }
    }
}

// MARK: - Mock VTAService for Testing

/// Mock implementation of VTAServiceProtocol for testing
class MockVTAService: VTAServiceProtocol {
    
    /// Predictions to return from fetchPredictions
    var mockPredictions: [Prediction] = []
    
    /// Error to throw from fetchPredictions (if set)
    var mockError: VTAServiceError?
    
    /// Records the last station ID requested
    var lastRequestedStationId: String?
    
    /// Records the last direction requested
    var lastRequestedDirection: Direction?
    
    /// Number of times fetchPredictions was called
    var fetchCallCount: Int = 0
    
    func fetchPredictions(
        stationId: String,
        direction: Direction
    ) async throws -> [Prediction] {
        fetchCallCount += 1
        lastRequestedStationId = stationId
        lastRequestedDirection = direction
        
        if let error = mockError {
            throw error
        }
        
        return mockPredictions
    }
    
    /// Resets all mock state
    func reset() {
        mockPredictions = []
        mockError = nil
        lastRequestedStationId = nil
        lastRequestedDirection = nil
        fetchCallCount = 0
    }
}
