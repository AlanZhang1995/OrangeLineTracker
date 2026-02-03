//
//  ComplicationController.swift
//  OrangeLineTracker Watch App
//
//  Controller for watch face complications
//  Provides timeline entries for ClockKit complications
//

import ClockKit
import SwiftUI

// MARK: - ComplicationController

/// Controller for managing watch face complications
/// Provides complication descriptors and timeline entries for ClockKit
/// - Validates: Requirements 9.1, 9.2, 9.3, 9.4
class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Properties
    
    /// Shared instance for accessing complication data
    static let shared = ComplicationController()
    
    /// Current complication data to display
    /// This should be updated by the BackgroundRefreshManager
    var currentData: ComplicationData?
    
    /// Storage service for accessing user preferences
    private let storageService: StorageServiceProtocol
    
    // MARK: - Initialization
    
    override init() {
        self.storageService = StorageService()
        super.init()
        loadCurrentData()
    }
    
    /// Creates a ComplicationController with a custom storage service (for testing)
    init(storageService: StorageServiceProtocol) {
        self.storageService = storageService
        super.init()
        loadCurrentData()
    }
    
    // MARK: - CLKComplicationDataSource
    
    /// Returns the complication descriptors for all supported complication families
    /// - Validates: Requirements 9.1, 9.3
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "OrangeLineArrival",
                displayName: "Orange Line Arrival",
                supportedFamilies: supportedComplicationFamilies
            )
        ]
        handler(descriptors)
    }
    
    /// Returns the supported complication families
    /// - Validates: Requirement 9.3 - support multiple complication sizes
    var supportedComplicationFamilies: [CLKComplicationFamily] {
        [
            .graphicCorner,
            .graphicCircular,
            .graphicRectangular,
            .modularSmall,
            .utilitarianSmall
        ]
    }
    
    /// Handles complication selection (tap to open app)
    /// - Validates: Requirement 9.4 - tap to open app main interface
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // This method is called when the user taps on a complication
        // The app will be launched automatically by the system
    }
    
    /// Returns the current timeline entry for the specified complication
    /// - Parameters:
    ///   - complication: The complication requesting the entry
    ///   - handler: Completion handler with the timeline entry
    /// - Validates: Requirements 9.2, 9.3
    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        let data = currentData ?? createDefaultComplicationData()
        let template = createTemplate(for: complication.family, with: data)
        
        if let template = template {
            let entry = CLKComplicationTimelineEntry(
                date: Date(),
                complicationTemplate: template
            )
            handler(entry)
        } else {
            handler(nil)
        }
    }
    
    /// Returns timeline entries after the specified date
    /// - Parameters:
    ///   - complication: The complication requesting entries
    ///   - date: The date after which to return entries
    ///   - limit: Maximum number of entries to return
    ///   - handler: Completion handler with the timeline entries
    func getTimelineEntries(
        for complication: CLKComplication,
        after date: Date,
        limit: Int,
        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void
    ) {
        // For real-time transit data, we don't provide future entries
        // The complication will be updated via background refresh
        handler(nil)
    }
    
    /// Returns the time travel directions supported by the complication
    func getTimelineEndDate(
        for complication: CLKComplication,
        withHandler handler: @escaping (Date?) -> Void
    ) {
        // No future timeline entries
        handler(nil)
    }
    
    /// Returns the privacy behavior for the complication
    func getPrivacyBehavior(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void
    ) {
        // Transit data is not sensitive, show on lock screen
        handler(.showOnLockScreen)
    }
    
    // MARK: - Template Creation
    
    /// Creates a complication template for the specified family
    /// - Parameters:
    ///   - family: The complication family
    ///   - data: The complication data to display
    /// - Returns: A complication template, or nil if the family is not supported
    /// - Validates: Requirements 9.2, 9.3
    func createTemplate(
        for family: CLKComplicationFamily,
        with data: ComplicationData
    ) -> CLKComplicationTemplate? {
        switch family {
        case .graphicCorner:
            return createGraphicCornerTemplate(with: data)
        case .graphicCircular:
            return createGraphicCircularTemplate(with: data)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(with: data)
        case .modularSmall:
            return createModularSmallTemplate(with: data)
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate(with: data)
        default:
            return nil
        }
    }
    
    /// Creates a graphic corner template
    /// Shows station abbreviation + arrival minutes with stale indicator if needed
    /// - Validates: Requirements 9.3, 9.7
    private func createGraphicCornerTemplate(with data: ComplicationData) -> CLKComplicationTemplate {
        // Use stale-aware display text for error indication
        let displayText = data.fullDisplayTextWithStaleIndicator()
        let textProvider = CLKSimpleTextProvider(text: displayText)
        
        // Use different color for error/stale states
        if data.isErrorState {
            textProvider.tintColor = .gray
        } else if data.isStale() {
            textProvider.tintColor = .yellow  // Warning color for stale data
        } else {
            textProvider.tintColor = .orange
        }
        
        let imageProvider = CLKFullColorImageProvider(
            fullColorImage: createTrainImage(size: CGSize(width: 20, height: 20))
        )
        
        return CLKComplicationTemplateGraphicCornerTextImage(
            textProvider: textProvider,
            imageProvider: imageProvider
        )
    }
    
    /// Creates a graphic circular template
    /// Shows arrival minutes in large font with stale indicator if needed
    /// - Validates: Requirements 9.3, 9.7
    private func createGraphicCircularTemplate(with data: ComplicationData) -> CLKComplicationTemplate {
        // Use stale-aware display text
        let arrivalText = data.displayTextWithStaleIndicator()
        let textProvider = CLKSimpleTextProvider(text: arrivalText)
        
        // Use different color for error/stale states
        if data.isErrorState {
            textProvider.tintColor = .gray
        } else if data.isStale() {
            textProvider.tintColor = .yellow
        } else {
            textProvider.tintColor = .orange
        }
        
        return CLKComplicationTemplateGraphicCircularStackText(
            line1TextProvider: CLKSimpleTextProvider(text: data.stationShortName),
            line2TextProvider: textProvider
        )
    }
    
    /// Creates a graphic rectangular template
    /// Shows station name + direction + arrival time (most complete info) with stale indicator
    /// - Validates: Requirements 9.3, 9.7
    private func createGraphicRectangularTemplate(with data: ComplicationData) -> CLKComplicationTemplate {
        let headerTextProvider = CLKSimpleTextProvider(text: data.stationShortName)
        
        // Use different color for error/stale states
        if data.isErrorState {
            headerTextProvider.tintColor = .gray
        } else if data.isStale() {
            headerTextProvider.tintColor = .yellow
        } else {
            headerTextProvider.tintColor = .orange
        }
        
        let directionText = data.direction == .mountainView ? "→ MTV" : "→ ALR"
        let body1TextProvider = CLKSimpleTextProvider(text: directionText)
        
        // Use stale-aware detailed display text
        let arrivalText = data.detailedDisplayTextWithStaleIndicator()
        let body2TextProvider = CLKSimpleTextProvider(text: arrivalText)
        
        if data.isErrorState {
            body2TextProvider.tintColor = .gray
        } else if data.isStale() {
            body2TextProvider.tintColor = .yellow
        } else {
            body2TextProvider.tintColor = .orange
        }
        
        return CLKComplicationTemplateGraphicRectangularStandardBody(
            headerTextProvider: headerTextProvider,
            body1TextProvider: body1TextProvider,
            body2TextProvider: body2TextProvider
        )
    }
    
    /// Creates a modular small template
    /// Shows arrival minutes (compatible with older watch faces) with stale indicator
    /// - Validates: Requirements 9.3, 9.7
    private func createModularSmallTemplate(with data: ComplicationData) -> CLKComplicationTemplate {
        // Use stale-aware display text
        let arrivalText = data.displayTextWithStaleIndicator()
        let textProvider = CLKSimpleTextProvider(text: arrivalText)
        let line1Provider = CLKSimpleTextProvider(text: data.stationShortName)
        
        return CLKComplicationTemplateModularSmallStackText(
            line1TextProvider: line1Provider,
            line2TextProvider: textProvider
        )
    }
    
    /// Creates a utilitarian small template
    /// Shows station abbreviation + minutes (compact display) with stale indicator
    /// - Validates: Requirements 9.3, 9.7
    private func createUtilitarianSmallTemplate(with data: ComplicationData) -> CLKComplicationTemplate {
        // Use stale-aware full display text
        let displayText = data.fullDisplayTextWithStaleIndicator()
        let textProvider = CLKSimpleTextProvider(text: displayText)
        
        // Use different color for error/stale states
        if data.isErrorState {
            textProvider.tintColor = .gray
        } else if data.isStale() {
            textProvider.tintColor = .yellow
        } else {
            textProvider.tintColor = .orange
        }
        
        return CLKComplicationTemplateUtilitarianSmallFlat(
            textProvider: textProvider
        )
    }
    
    // MARK: - Helper Methods
    
    /// Creates a simple train icon image for complications using SF Symbols
    private func createTrainImage(size: CGSize) -> UIImage {
        // Use SF Symbol directly - available on watchOS
        let config = UIImage.SymbolConfiguration(pointSize: size.width * 0.8, weight: .medium)
        if let tramImage = UIImage(systemName: "tram.fill", withConfiguration: config) {
            return tramImage.withTintColor(.orange, renderingMode: .alwaysOriginal)
        }
        // Fallback to an empty image if SF Symbol is not available
        return UIImage()
    }
    
    /// Loads the current complication data from storage
    private func loadCurrentData() {
        let storage = storageService
        var mutableStorage = storage
        mutableStorage.load()
        
        if let station = storage.selectedStation,
           let direction = storage.selectedDirection {
            // Create placeholder data with station info
            // Actual arrival time will be updated by background refresh
            currentData = ComplicationData(
                stationShortName: station.shortName,
                minutesUntilArrival: nil,
                direction: direction,
                lastUpdated: Date()
            )
        }
    }
    
    /// Creates default complication data when no data is available
    /// - Returns: ComplicationData with error state showing "--"
    /// - Validates: Requirement 9.7 - show "--" when no data available
    private func createDefaultComplicationData() -> ComplicationData {
        return ComplicationData.errorState()
    }
    
    /// Creates complication data for network error with cached data
    /// - Parameters:
    ///   - cachedData: Previously cached complication data
    ///   - error: The error that occurred
    /// - Returns: Cached data marked as stale, or error state if no cache
    /// - Validates: Requirement 9.7 - show cached data + stale indicator on network error
    func createNetworkErrorComplicationData(
        cachedData: ComplicationData?,
        error: Error
    ) -> ComplicationData {
        if let cached = cachedData {
            // Return cached data - it will show stale indicator via isStale()
            // The lastUpdated timestamp remains unchanged, so isStale() will return true
            return cached
        }
        // No cached data available, return error state
        return ComplicationData.errorState()
    }
    
    /// Updates the complication data and requests a timeline reload
    /// - Parameter data: The new complication data
    func updateComplicationData(_ data: ComplicationData) {
        currentData = data
        reloadComplications()
    }
    
    /// Requests a reload of all active complications
    func reloadComplications() {
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }
    
    /// Extends the timeline for all active complications
    func extendComplications() {
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            server.extendTimeline(for: complication)
        }
    }
}

// MARK: - Complication Timeline Entry Helper

extension ComplicationController {
    
    /// Creates a timeline entry for the specified date and data
    /// - Parameters:
    ///   - date: The date for the timeline entry
    ///   - family: The complication family
    ///   - data: The complication data
    /// - Returns: A timeline entry, or nil if the template cannot be created
    func createTimelineEntry(
        date: Date,
        family: CLKComplicationFamily,
        data: ComplicationData
    ) -> CLKComplicationTimelineEntry? {
        guard let template = createTemplate(for: family, with: data) else {
            return nil
        }
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
}

// MARK: - Complication Descriptor Helpers

extension ComplicationController {
    
    /// Returns the complication descriptors synchronously
    /// Useful for testing and synchronous access
    func getComplicationDescriptorsSync() -> [CLKComplicationDescriptor] {
        [
            CLKComplicationDescriptor(
                identifier: "OrangeLineArrival",
                displayName: "Orange Line Arrival",
                supportedFamilies: supportedComplicationFamilies
            )
        ]
    }
    
    /// Returns the current timeline entry synchronously
    /// Useful for testing and synchronous access
    func getCurrentTimelineEntrySync(for family: CLKComplicationFamily) -> CLKComplicationTimelineEntry? {
        let data = currentData ?? createDefaultComplicationData()
        guard let template = createTemplate(for: family, with: data) else {
            return nil
        }
        return CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    }
}
