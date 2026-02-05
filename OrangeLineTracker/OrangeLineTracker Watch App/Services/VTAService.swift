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
/// - Validates: Requirements 1.4, 3.1, 3.2, 3.3, 3.4, 3.5, 6.1, 6.2, 6.3, 6.4
protocol VTAServiceProtocol {
    /// Fetches all available VTA lines
    /// - Returns: An array of Line objects representing all VTA lines
    /// - Throws: VTAServiceError if the request fails
    /// - Validates: Requirements 1.4, 6.1
    func fetchAllLines() async throws -> [Line]
    
    /// Fetches stations for a specific line
    /// - Parameter lineId: The line identifier
    /// - Returns: An array of Station objects for the specified line
    /// - Throws: VTAServiceError if the request fails
    /// - Validates: Requirements 6.2
    func fetchStations(for lineId: String) async throws -> [Station]
    
    /// Fetches arrival predictions for a specific station and direction (backward compatible)
    /// - Parameters:
    ///   - stationId: The 511.org stop code for the station
    ///   - direction: The travel direction (Mountain View or Alum Rock)
    /// - Returns: An array of Prediction objects sorted by arrival time
    /// - Throws: VTAServiceError if the request fails
    /// - Note: This method defaults to Orange Line for backward compatibility
    func fetchPredictions(
        stationId: String,
        direction: Direction
    ) async throws -> [Prediction]
    
    /// Fetches arrival predictions for any line, station, and direction
    /// - Parameters:
    ///   - lineId: The line identifier (e.g., "Orange", "Blue", "Green")
    ///   - stationId: The 511.org stop code for the station
    ///   - directionId: The direction identifier (e.g., "E", "W", "N", "S")
    /// - Returns: An array of Prediction objects sorted by arrival time
    /// - Throws: VTAServiceError if the request fails
    /// - Validates: Requirements 6.1, 6.4
    func fetchPredictions(
        lineId: String,
        stationId: String,
        directionId: String
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
/// - Validates: Requirements 1.4, 3.1, 3.2, 3.3, 3.4, 3.5, 6.1, 6.2, 6.3
class VTAService: VTAServiceProtocol {
    
    // MARK: - Constants
    
    /// VTA Orange Line identifier (as returned by 511.org API)
    private static let orangeLineRef = "Orange Line"
    
    /// 511.org API base URL
    private static let baseURL = "https://api.511.org/transit/StopMonitoring"
    
    /// VTA agency identifier
    private static let agencyId = "SC"
    
    // MARK: - Static Line Data
    
    /// Static VTA light rail line definitions
    /// Since 511.org API doesn't provide a simple lines endpoint, we define the lines statically
    /// - Validates: Requirements 1.4, 6.1
    private static let vtaLines: [Line] = [
        // Orange Line: Mountain View ↔ Alum Rock
        Line(
            id: "Orange",
            name: "Orange Line",
            shortName: "OL",
            type: .lightRail,
            colorHex: "#F7931E",
            directions: [
                LineDirection(id: "E", headsign: "Alum Rock"),
                LineDirection(id: "W", headsign: "Mountain View")
            ],
            stations: OrangeLineStations.stations
        ),
        // Blue Line: Baypointe ↔ Santa Teresa
        Line(
            id: "Blue",
            name: "Blue Line",
            shortName: "BL",
            type: .lightRail,
            colorHex: "#0072BC",
            directions: [
                LineDirection(id: "S", headsign: "Santa Teresa"),
                LineDirection(id: "N", headsign: "Baypointe")
            ],
            stations: BlueLineStations.stations
        ),
        // Green Line: Old Ironsides ↔ Winchester
        Line(
            id: "Green",
            name: "Green Line",
            shortName: "GL",
            type: .lightRail,
            colorHex: "#00A651",
            directions: [
                LineDirection(id: "S", headsign: "Winchester"),
                LineDirection(id: "N", headsign: "Old Ironsides")
            ],
            stations: GreenLineStations.stations
        )
    ]
    
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
    
    // MARK: - VTAServiceProtocol - Line Methods
    
    /// Fetches all available VTA lines
    /// Returns static line data since 511.org API doesn't provide a simple lines endpoint
    /// - Returns: An array of Line objects representing all VTA lines
    /// - Throws: VTAServiceError if the request fails
    /// - Validates: Requirements 1.4, 6.1
    func fetchAllLines() async throws -> [Line] {
        // Return static line data
        // In the future, this could be enhanced to fetch from an API
        return Self.vtaLines
    }
    
    /// Fetches stations for a specific line
    /// - Parameter lineId: The line identifier (e.g., "Orange", "Blue", "Green")
    /// - Returns: An array of Station objects for the specified line, sorted by order
    /// - Throws: VTAServiceError if the line is not found
    /// - Validates: Requirements 6.2
    func fetchStations(for lineId: String) async throws -> [Station] {
        // Find the line by ID
        guard let line = Self.vtaLines.first(where: { $0.id == lineId }) else {
            throw VTAServiceError.noDataAvailable
        }
        
        // Return stations sorted by order (geographic order)
        return line.stations.sorted { $0.order < $1.order }
    }
    
    // MARK: - VTAServiceProtocol - Prediction Methods
    
    /// Fetches arrival predictions for a specific station and direction (backward compatible)
    /// This method defaults to Orange Line for backward compatibility
    /// - Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
    func fetchPredictions(
        stationId: String,
        direction: Direction
    ) async throws -> [Prediction] {
        // Call the new method with Orange Line as default for backward compatibility
        return try await fetchPredictions(
            lineId: "Orange",
            stationId: stationId,
            directionId: direction.directionId
        )
    }
    
    /// Fetches arrival predictions for any line, station, and direction
    /// - Validates: Requirements 6.1, 6.4
    func fetchPredictions(
        lineId: String,
        stationId: String,
        directionId: String
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
        
        // Parse the response with the specified line ID and direction ID
        // Validates: Requirements 6.1, 6.4 - filter by line ID
        let predictions = try parseResponse(data: data, lineId: lineId, directionId: directionId)
        
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
    /// - Parameters:
    ///   - data: The raw API response data
    ///   - lineId: The line identifier to filter by (e.g., "Orange", "Blue", "Green")
    ///   - directionId: The direction identifier to filter by (e.g., "E", "W", "N", "S")
    /// - Returns: An array of Prediction objects sorted by arrival time
    /// - Validates: Requirements 6.1, 6.4 - filter by line ID and direction
    private func parseResponse(data: Data, lineId: String, directionId: String) throws -> [Prediction] {
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
        
        // Build the line reference string for filtering
        // The API returns line names like "Orange Line", "Blue Line", etc.
        let lineRef = buildLineRef(from: lineId)
        
        // Filter and convert to Prediction objects
        // Validates: Requirements 6.1, 6.4 - filter by line ID and direction
        let predictions = visits.compactMap { visit -> Prediction? in
            let journey = visit.MonitoredVehicleJourney
            
            // Filter by line ID
            // Validates: Requirements 6.1, 6.4 - only return predictions for the selected line
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
            let (minutesUntilArrival, arrivalStatus) = parseArrivalTime(
                expectedTime: monitoredCall.ExpectedArrivalTime,
                aimedTime: monitoredCall.AimedArrivalTime,
                statusString: monitoredCall.ArrivalStatus
            )
            
            // Get destination name
            let destination = journey.DestinationName ?? ""
            
            // Create prediction
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
    
    /// Builds the line reference string for API filtering
    /// - Parameter lineId: The line identifier (e.g., "Orange", "Blue", "Green")
    /// - Returns: The line reference string as returned by the API (e.g., "Orange Line", "Blue Line")
    private func buildLineRef(from lineId: String) -> String {
        // The API returns line names with " Line" suffix for light rail lines
        // For bus routes, it returns just the route number
        switch lineId {
        case "Orange", "Blue", "Green":
            return "\(lineId) Line"
        default:
            return lineId
        }
    }
    
    /// Parses the SIRI API response and extracts predictions (backward compatible)
    /// - Validates: Requirements 3.3, 3.4 - parse response and filter by direction
    private func parseResponse(data: Data, direction: Direction) throws -> [Prediction] {
        // Call the new method with Orange Line as default
        return try parseResponse(data: data, lineId: "Orange", directionId: direction.directionId)
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
    
    /// Lines to return from fetchAllLines
    var mockLines: [Line] = []
    
    /// Stations to return from fetchStations
    var mockStations: [Station] = []
    
    /// Predictions to return from fetchPredictions
    var mockPredictions: [Prediction] = []
    
    /// Error to throw from any method (if set)
    var mockError: VTAServiceError?
    
    /// Records the last station ID requested
    var lastRequestedStationId: String?
    
    /// Records the last direction requested
    var lastRequestedDirection: Direction?
    
    /// Records the last line ID requested
    var lastRequestedLineId: String?
    
    /// Records the last direction ID requested
    var lastRequestedDirectionId: String?
    
    /// Number of times fetchPredictions was called
    var fetchCallCount: Int = 0
    
    /// Number of times fetchAllLines was called
    var fetchLinesCallCount: Int = 0
    
    /// Number of times fetchStations was called
    var fetchStationsCallCount: Int = 0
    
    func fetchAllLines() async throws -> [Line] {
        fetchLinesCallCount += 1
        
        if let error = mockError {
            throw error
        }
        
        return mockLines
    }
    
    func fetchStations(for lineId: String) async throws -> [Station] {
        fetchStationsCallCount += 1
        lastRequestedLineId = lineId
        
        if let error = mockError {
            throw error
        }
        
        return mockStations
    }
    
    func fetchPredictions(
        stationId: String,
        direction: Direction
    ) async throws -> [Prediction] {
        fetchCallCount += 1
        lastRequestedStationId = stationId
        lastRequestedDirection = direction
        lastRequestedLineId = "Orange"  // Default to Orange for backward compatibility
        lastRequestedDirectionId = direction.directionId
        
        if let error = mockError {
            throw error
        }
        
        return mockPredictions
    }
    
    func fetchPredictions(
        lineId: String,
        stationId: String,
        directionId: String
    ) async throws -> [Prediction] {
        fetchCallCount += 1
        lastRequestedLineId = lineId
        lastRequestedStationId = stationId
        lastRequestedDirectionId = directionId
        
        if let error = mockError {
            throw error
        }
        
        return mockPredictions
    }
    
    /// Resets all mock state
    func reset() {
        mockLines = []
        mockStations = []
        mockPredictions = []
        mockError = nil
        lastRequestedStationId = nil
        lastRequestedDirection = nil
        lastRequestedLineId = nil
        lastRequestedDirectionId = nil
        fetchCallCount = 0
        fetchLinesCallCount = 0
        fetchStationsCallCount = 0
    }
}
