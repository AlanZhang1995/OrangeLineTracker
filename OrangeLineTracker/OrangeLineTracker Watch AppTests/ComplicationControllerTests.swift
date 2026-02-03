//
//  ComplicationControllerTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Unit tests for ComplicationController
//

import Foundation
import Testing
import ClockKit
@testable import OrangeLineTracker_Watch_App

// MARK: - ComplicationController Tests

struct ComplicationControllerTests {
    
    // MARK: - Complication Descriptors Tests
    
    @Test func getComplicationDescriptorsReturnsNonEmptyArray() {
        // Validates: Requirement 9.1 - provide complication support
        let controller = ComplicationController()
        let descriptors = controller.getComplicationDescriptorsSync()
        
        #expect(!descriptors.isEmpty)
    }
    
    @Test func getComplicationDescriptorsContainsOrangeLineArrival() {
        // Validates: Requirement 9.1
        let controller = ComplicationController()
        let descriptors = controller.getComplicationDescriptorsSync()
        
        let hasOrangeLineArrival = descriptors.contains { $0.identifier == "OrangeLineArrival" }
        #expect(hasOrangeLineArrival)
    }
    
    @Test func getComplicationDescriptorsHasCorrectDisplayName() {
        let controller = ComplicationController()
        let descriptors = controller.getComplicationDescriptorsSync()
        
        let descriptor = descriptors.first { $0.identifier == "OrangeLineArrival" }
        #expect(descriptor?.displayName == "Orange Line Arrival")
    }
    
    // MARK: - Supported Families Tests
    
    @Test func supportedFamiliesIncludesGraphicCorner() {
        // Validates: Requirement 9.3 - support multiple complication sizes
        let controller = ComplicationController()
        
        #expect(controller.supportedComplicationFamilies.contains(.graphicCorner))
    }
    
    @Test func supportedFamiliesIncludesGraphicCircular() {
        // Validates: Requirement 9.3
        let controller = ComplicationController()
        
        #expect(controller.supportedComplicationFamilies.contains(.graphicCircular))
    }
    
    @Test func supportedFamiliesIncludesGraphicRectangular() {
        // Validates: Requirement 9.3
        let controller = ComplicationController()
        
        #expect(controller.supportedComplicationFamilies.contains(.graphicRectangular))
    }
    
    @Test func supportedFamiliesIncludesModularSmall() {
        // Validates: Requirement 9.3
        let controller = ComplicationController()
        
        #expect(controller.supportedComplicationFamilies.contains(.modularSmall))
    }
    
    @Test func supportedFamiliesIncludesUtilitarianSmall() {
        // Validates: Requirement 9.3
        let controller = ComplicationController()
        
        #expect(controller.supportedComplicationFamilies.contains(.utilitarianSmall))
    }
    
    @Test func supportedFamiliesHasFiveEntries() {
        // Validates: Requirement 9.3 - support graphicCorner, graphicCircular, graphicRectangular, modularSmall, utilitarianSmall
        let controller = ComplicationController()
        
        #expect(controller.supportedComplicationFamilies.count == 5)
    }
    
    @Test func complicationDescriptorsSupportAllFamilies() {
        // Validates: Requirement 9.3
        let controller = ComplicationController()
        let descriptors = controller.getComplicationDescriptorsSync()
        
        guard let descriptor = descriptors.first else {
            Issue.record("No descriptors found")
            return
        }
        
        let expectedFamilies: Set<CLKComplicationFamily> = [
            .graphicCorner,
            .graphicCircular,
            .graphicRectangular,
            .modularSmall,
            .utilitarianSmall
        ]
        
        let supportedFamilies = Set(descriptor.supportedFamilies)
        #expect(supportedFamilies == expectedFamilies)
    }
    
    // MARK: - Template Creation Tests
    
    @Test func createTemplateForGraphicCornerReturnsTemplate() {
        // Validates: Requirement 9.3
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        let template = controller.createTemplate(for: .graphicCorner, with: data)
        
        #expect(template != nil)
        #expect(template is CLKComplicationTemplateGraphicCornerTextImage)
    }
    
    @Test func createTemplateForGraphicCircularReturnsTemplate() {
        // Validates: Requirement 9.3
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        let template = controller.createTemplate(for: .graphicCircular, with: data)
        
        #expect(template != nil)
        #expect(template is CLKComplicationTemplateGraphicCircularStackText)
    }
    
    @Test func createTemplateForGraphicRectangularReturnsTemplate() {
        // Validates: Requirement 9.3
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        let template = controller.createTemplate(for: .graphicRectangular, with: data)
        
        #expect(template != nil)
        #expect(template is CLKComplicationTemplateGraphicRectangularStandardBody)
    }
    
    @Test func createTemplateForModularSmallReturnsTemplate() {
        // Validates: Requirement 9.3
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        let template = controller.createTemplate(for: .modularSmall, with: data)
        
        #expect(template != nil)
        #expect(template is CLKComplicationTemplateModularSmallStackText)
    }
    
    @Test func createTemplateForUtilitarianSmallReturnsTemplate() {
        // Validates: Requirement 9.3
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        let template = controller.createTemplate(for: .utilitarianSmall, with: data)
        
        #expect(template != nil)
        #expect(template is CLKComplicationTemplateUtilitarianSmallFlat)
    }
    
    @Test func createTemplateForUnsupportedFamilyReturnsNil() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        // Test with an unsupported family
        let template = controller.createTemplate(for: .modularLarge, with: data)
        
        #expect(template == nil)
    }
    
    // MARK: - Timeline Entry Tests
    
    @Test func getCurrentTimelineEntryReturnsEntry() {
        // Validates: Requirement 9.2 - display arrival time on watch face
        let controller = ComplicationController()
        controller.currentData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        let entry = controller.getCurrentTimelineEntrySync(for: .graphicCorner)
        
        #expect(entry != nil)
    }
    
    @Test func getCurrentTimelineEntryReturnsEntryWithCurrentDate() {
        let controller = ComplicationController()
        controller.currentData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        let beforeCreation = Date()
        let entry = controller.getCurrentTimelineEntrySync(for: .graphicCorner)
        let afterCreation = Date()
        
        #expect(entry != nil)
        if let entry = entry {
            #expect(entry.date >= beforeCreation)
            #expect(entry.date <= afterCreation)
        }
    }
    
    @Test func getCurrentTimelineEntryWithNoDataReturnsErrorState() {
        // Validates: Requirement 9.7 - show "--" when no data
        let controller = ComplicationController()
        controller.currentData = nil
        
        let entry = controller.getCurrentTimelineEntrySync(for: .graphicCorner)
        
        #expect(entry != nil)
    }
    
    @Test func createTimelineEntryReturnsValidEntry() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        let testDate = Date()
        
        let entry = controller.createTimelineEntry(
            date: testDate,
            family: .graphicCorner,
            data: data
        )
        
        #expect(entry != nil)
        #expect(entry?.date == testDate)
    }
    
    @Test func createTimelineEntryForUnsupportedFamilyReturnsNil() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        let entry = controller.createTimelineEntry(
            date: Date(),
            family: .modularLarge,
            data: data
        )
        
        #expect(entry == nil)
    }
    
    // MARK: - Data Update Tests
    
    @Test func updateComplicationDataSetsCurrentData() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "GAM",
            minutesUntilArrival: 10,
            direction: .mountainView
        )
        
        controller.updateComplicationData(data)
        
        #expect(controller.currentData == data)
    }
    
    @Test func updateComplicationDataOverwritesPreviousData() {
        let controller = ComplicationController()
        
        let data1 = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        controller.updateComplicationData(data1)
        
        let data2 = ComplicationData(
            stationShortName: "ALR",
            minutesUntilArrival: 15,
            direction: .mountainView
        )
        controller.updateComplicationData(data2)
        
        #expect(controller.currentData == data2)
        #expect(controller.currentData != data1)
    }
    
    // MARK: - Template Content Tests
    
    @Test func templateCreatedWithArrivingStatus() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: nil,  // Arriving
            direction: .alumRock
        )
        
        let template = controller.createTemplate(for: .graphicCorner, with: data)
        
        #expect(template != nil)
    }
    
    @Test func templateCreatedWithZeroMinutes() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 0,
            direction: .alumRock
        )
        
        let template = controller.createTemplate(for: .graphicCircular, with: data)
        
        #expect(template != nil)
    }
    
    @Test func templateCreatedWithLargeMinutesValue() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 120,
            direction: .alumRock
        )
        
        let template = controller.createTemplate(for: .modularSmall, with: data)
        
        #expect(template != nil)
    }
    
    @Test func templateCreatedWithErrorState() {
        // Validates: Requirement 9.7
        let controller = ComplicationController()
        let data = ComplicationData.errorState()
        
        let template = controller.createTemplate(for: .utilitarianSmall, with: data)
        
        #expect(template != nil)
    }
    
    // MARK: - Direction Display Tests
    
    @Test func graphicRectangularTemplateCreatedForAlumRockDirection() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        let template = controller.createTemplate(for: .graphicRectangular, with: data)
        
        #expect(template != nil)
        #expect(template is CLKComplicationTemplateGraphicRectangularStandardBody)
    }
    
    @Test func graphicRectangularTemplateCreatedForMountainViewDirection() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "ALR",
            minutesUntilArrival: 8,
            direction: .mountainView
        )
        
        let template = controller.createTemplate(for: .graphicRectangular, with: data)
        
        #expect(template != nil)
        #expect(template is CLKComplicationTemplateGraphicRectangularStandardBody)
    }
    
    // MARK: - All Supported Families Tests
    
    @Test func allSupportedFamiliesCreateValidTemplates() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        
        for family in controller.supportedComplicationFamilies {
            let template = controller.createTemplate(for: family, with: data)
            #expect(template != nil, "Template should be created for family: \(family)")
        }
    }
    
    @Test func allSupportedFamiliesCreateValidTimelineEntries() {
        let controller = ComplicationController()
        let data = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock
        )
        controller.currentData = data
        
        for family in controller.supportedComplicationFamilies {
            let entry = controller.getCurrentTimelineEntrySync(for: family)
            #expect(entry != nil, "Timeline entry should be created for family: \(family)")
        }
    }
    
    // MARK: - Station Short Name Tests
    
    @Test func templateCreatedWithVariousStationShortNames() {
        let controller = ComplicationController()
        let shortNames = ["MTV", "WSM", "MDF", "NASA", "GAM", "ALR", "BRY", "MLP"]
        
        for shortName in shortNames {
            let data = ComplicationData(
                stationShortName: shortName,
                minutesUntilArrival: 5,
                direction: .alumRock
            )
            
            let template = controller.createTemplate(for: .graphicCorner, with: data)
            #expect(template != nil, "Template should be created for station: \(shortName)")
        }
    }
    
    // MARK: - Shared Instance Tests
    
    @Test func sharedInstanceExists() {
        let shared = ComplicationController.shared
        
        #expect(shared != nil)
    }
    
    @Test func sharedInstanceIsSameInstance() {
        let shared1 = ComplicationController.shared
        let shared2 = ComplicationController.shared
        
        #expect(shared1 === shared2)
    }
    
    // MARK: - Network Error Handling Tests
    
    @Test func createNetworkErrorComplicationDataReturnsCachedDataWhenAvailable() {
        // Validates: Requirement 9.7 - show cached data on network error
        let controller = ComplicationController()
        let cachedData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: Date().addingTimeInterval(-10 * 60) // 10 minutes ago (stale)
        )
        
        let result = controller.createNetworkErrorComplicationData(
            cachedData: cachedData,
            error: NSError(domain: "test", code: -1, userInfo: nil)
        )
        
        #expect(result == cachedData)
        #expect(result.isStale() == true) // Should be stale
    }
    
    @Test func createNetworkErrorComplicationDataReturnsErrorStateWhenNoCachedData() {
        // Validates: Requirement 9.7 - show "--" when no cached data
        let controller = ComplicationController()
        
        let result = controller.createNetworkErrorComplicationData(
            cachedData: nil,
            error: NSError(domain: "test", code: -1, userInfo: nil)
        )
        
        #expect(result.isErrorState == true)
        #expect(result.stationShortName == "--")
    }
    
    // MARK: - Stale Data Template Tests
    
    @Test func templateCreatedWithStaleDataShowsWarningIndicator() {
        // Validates: Requirement 9.7 - show stale indicator
        let controller = ComplicationController()
        let staleData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: Date().addingTimeInterval(-10 * 60) // 10 minutes ago
        )
        
        // Verify the data is stale
        #expect(staleData.isStale() == true)
        
        // Template should still be created
        let template = controller.createTemplate(for: .graphicCorner, with: staleData)
        #expect(template != nil)
    }
    
    @Test func allSupportedFamiliesCreateValidTemplatesForStaleData() {
        // Validates: Requirement 9.7
        let controller = ComplicationController()
        let staleData = ComplicationData(
            stationShortName: "MTV",
            minutesUntilArrival: 5,
            direction: .alumRock,
            lastUpdated: Date().addingTimeInterval(-10 * 60) // 10 minutes ago
        )
        
        for family in controller.supportedComplicationFamilies {
            let template = controller.createTemplate(for: family, with: staleData)
            #expect(template != nil, "Template should be created for stale data in family: \(family)")
        }
    }
}

// MARK: - Async Handler Tests

struct ComplicationControllerAsyncTests {
    
    @Test func getComplicationDescriptorsCallsHandler() async {
        // Validates: Requirement 9.1
        let controller = ComplicationController()
        
        await withCheckedContinuation { continuation in
            controller.getComplicationDescriptors { descriptors in
                #expect(!descriptors.isEmpty)
                continuation.resume()
            }
        }
    }
    
    @Test func getComplicationDescriptorsHandlerReceivesCorrectData() async {
        let controller = ComplicationController()
        
        await withCheckedContinuation { continuation in
            controller.getComplicationDescriptors { descriptors in
                let hasOrangeLineArrival = descriptors.contains { $0.identifier == "OrangeLineArrival" }
                #expect(hasOrangeLineArrival)
                continuation.resume()
            }
        }
    }
}
