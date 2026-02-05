//
//  LineViewModelPropertyTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Property-based tests for LineViewModel
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Mock Services for LineViewModel Testing

class LineViewModelMockStorageService: StorageServiceProtocol {
    var selectedStation: Station?
    var selectedDirection: Direction?
    var timeRules: [TimeRule] = []
    var isTimeRuleEnabled: Bool = false
    var isSmartRefreshEnabled: Bool = true
    var cachedArrivalMinutes: Int?
    var lastUpdateTime: Date?
    
    // Line-related properties
    var selectedLineId: String?
    var favoriteLineIds: Set<String> = []
    var cachedLines: [Line]?
    
    var saveCallCount = 0
    var loadCallCount = 0
    
    func save() {
        saveCallCount += 1
    }
    
    func load() {
        loadCallCount += 1
    }
    
    func updateWidgetData(stationName: String, stationShortName: String, direction: String, arrivalMinutes: Int?, arrivalMinutes2: Int? = nil, arrivalMinutes3: Int? = nil, lineId: String? = nil, lineName: String? = nil, lineColor: String? = nil) {
        cachedArrivalMinutes = arrivalMinutes
        lastUpdateTime = Date()
    }
    
    func migrateFromV1IfNeeded() {
        // Mock implementation - no-op for tests
    }
    
    func reset() {
        selectedStation = nil
        selectedDirection = nil
        timeRules = []
        isTimeRuleEnabled = false
        cachedArrivalMinutes = nil
        lastUpdateTime = nil
        selectedLineId = nil
        favoriteLineIds = []
        cachedLines = nil
        saveCallCount = 0
        loadCallCount = 0
    }
}

class LineViewModelMockVTAService: VTAServiceProtocol {
    var mockLines: [Line] = []
    var mockStations: [Station] = []
    var mockPredictions: [Prediction] = []
    var shouldThrowError = false
    
    func fetchAllLines() async throws -> [Line] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockLines
    }
    
    func fetchStations(for lineId: String) async throws -> [Station] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockStations
    }
    
    func fetchPredictions(stationId: String, direction: Direction) async throws -> [Prediction] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockPredictions
    }
    
    func fetchPredictions(lineId: String, stationId: String, directionId: String) async throws -> [Prediction] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockPredictions
    }
}

// MARK: - Test Data Generators

/// Generates random test data for LineViewModel tests
struct LineViewModelTestDataGenerator {
    
    /// Generates a random Line
    static func randomLine() -> Line {
        let types: [LineType] = [.lightRail, .bus]
        let lineId = "Line_\(Int.random(in: 1...1000))"
        let type = types.randomElement()!
        
        return Line(
            id: lineId,
            name: "Test \(lineId)",
            shortName: String(lineId.prefix(5)),
            type: type,
            colorHex: String(format: "%06X", Int.random(in: 0...0xFFFFFF)),
            directions: [
                LineDirection(id: "E", headsign: "Eastbound"),
                LineDirection(id: "W", headsign: "Westbound")
            ],
            stations: []
        )
    }
    
    /// Generates a random array of Lines with mixed types
    static func randomLines(count: Int) -> [Line] {
        var lines: [Line] = []
        for i in 0..<count {
            let type: LineType = i % 3 == 0 ? .lightRail : .bus
            let line = Line(
                id: "Line_\(i)",
                name: "Test Line \(i)",
                shortName: "TL\(i)",
                type: type,
                colorHex: String(format: "%06X", Int.random(in: 0...0xFFFFFF)),
                directions: [
                    LineDirection(id: "E", headsign: "Eastbound"),
                    LineDirection(id: "W", headsign: "Westbound")
                ],
                stations: []
            )
            lines.append(line)
        }
        return lines
    }
    
    /// Generates a random set of favorite line IDs from given lines
    static func randomFavorites(from lines: [Line]) -> Set<String> {
        let count = Int.random(in: 0...min(5, lines.count))
        let shuffled = lines.shuffled()
        return Set(shuffled.prefix(count).map { $0.id })
    }
}

// MARK: - Property 2: 线路类型分组排序

/// Property-based tests for line type grouping and sorting
/// **Feature: vta-all-lines, Property 2: 线路类型分组排序**
/// **Validates: Requirements 2.2**
///
/// Property 2: 对于任意线路列表，按类型分组排序后，轻轨线路必须全部出现在公交线路之前，
/// 且每个分组内部按名称排序。
@MainActor
struct LineTypeGroupingSortingPropertyTests {
    
    /// Property 2: Light rail lines appear before bus lines in sorted list
    /// **Validates: Requirements 2.2**
    /// **Feature: vta-all-lines, Property 2: 线路类型分组排序**
    @Test("Property 2: Light rail lines appear before bus lines - 100 iterations")
    func lightRailLinesAppearBeforeBusLines() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            // Generate random lines with mixed types
            let lineCount = Int.random(in: 5...20)
            let lines = LineViewModelTestDataGenerator.randomLines(count: lineCount)
            mockVTA.mockLines = lines
            
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            
            let sortedLines = viewModel.sortedLines
            
            // Find the last light rail index and first bus index
            var lastLightRailIndex = -1
            var firstBusIndex = sortedLines.count
            
            for (index, line) in sortedLines.enumerated() {
                if line.type == .lightRail {
                    lastLightRailIndex = index
                }
                if line.type == .bus && firstBusIndex == sortedLines.count {
                    firstBusIndex = index
                }
            }
            
            // Property: all light rail lines must appear before all bus lines
            // (unless there are no light rail or no bus lines)
            if lastLightRailIndex >= 0 && firstBusIndex < sortedLines.count {
                #expect(
                    lastLightRailIndex < firstBusIndex,
                    "Iteration \(iteration): Last light rail index (\(lastLightRailIndex)) should be less than first bus index (\(firstBusIndex))"
                )
            }
        }
    }
    
    /// Property 2: Lines within same type are sorted by name
    /// **Validates: Requirements 2.2**
    /// **Feature: vta-all-lines, Property 2: 线路类型分组排序**
    @Test("Property 2: Lines within same type are sorted by name - 100 iterations")
    func linesWithinSameTypeAreSortedByName() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lineCount = Int.random(in: 5...20)
            let lines = LineViewModelTestDataGenerator.randomLines(count: lineCount)
            mockVTA.mockLines = lines
            
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            
            // Check light rail lines are sorted
            let lightRailLines = viewModel.lightRailLines.sorted { $0.name < $1.name }
            let sortedLightRail = viewModel.sortedLines.filter { $0.type == .lightRail }
            
            // Check bus lines are sorted
            let busLines = viewModel.busLines.sorted { $0.name < $1.name }
            let sortedBus = viewModel.sortedLines.filter { $0.type == .bus }
            
            // Property: lines of same type should be sorted by name
            for (index, line) in sortedLightRail.enumerated() {
                if index < lightRailLines.count {
                    #expect(
                        line.id == lightRailLines[index].id,
                        "Iteration \(iteration): Light rail lines should be sorted by name"
                    )
                }
            }
            
            for (index, line) in sortedBus.enumerated() {
                if index < busLines.count {
                    #expect(
                        line.id == busLines[index].id,
                        "Iteration \(iteration): Bus lines should be sorted by name"
                    )
                }
            }
        }
    }
    
    /// Property 2: linesByType groups correctly
    /// **Validates: Requirements 2.2**
    /// **Feature: vta-all-lines, Property 2: 线路类型分组排序**
    @Test("Property 2: linesByType groups correctly - 100 iterations")
    func linesByTypeGroupsCorrectly() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lineCount = Int.random(in: 5...20)
            let lines = LineViewModelTestDataGenerator.randomLines(count: lineCount)
            
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            
            let grouped = viewModel.linesByType
            
            // Count lines by type manually
            let expectedLightRailCount = lines.filter { $0.type == .lightRail }.count
            let expectedBusCount = lines.filter { $0.type == .bus }.count
            
            let actualLightRailCount = grouped[.lightRail]?.count ?? 0
            let actualBusCount = grouped[.bus]?.count ?? 0
            
            #expect(
                actualLightRailCount == expectedLightRailCount,
                "Iteration \(iteration): Light rail count should match. Expected \(expectedLightRailCount), got \(actualLightRailCount)"
            )
            #expect(
                actualBusCount == expectedBusCount,
                "Iteration \(iteration): Bus count should match. Expected \(expectedBusCount), got \(actualBusCount)"
            )
        }
    }
}

// MARK: - Property 3: 收藏操作幂等性

/// Property-based tests for favorite operation idempotency
/// **Feature: vta-all-lines, Property 3: 收藏操作幂等性**
/// **Validates: Requirements 3.1, 3.2**
///
/// Property 3: 对于任意线路和收藏列表，执行收藏操作后该线路必须在收藏列表中；
/// 执行取消收藏操作后该线路必须不在收藏列表中。
@MainActor
struct FavoriteOperationIdempotencyPropertyTests {
    
    /// Property 3: Adding to favorites ensures line is in favorites
    /// **Validates: Requirements 3.1**
    /// **Feature: vta-all-lines, Property 3: 收藏操作幂等性**
    @Test("Property 3: Adding to favorites ensures line is in favorites - 100 iterations")
    func addingToFavoritesEnsuresLineIsInFavorites() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lines = LineViewModelTestDataGenerator.randomLines(count: 10)
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            
            let lineToFavorite = lines.randomElement()!
            
            // Add to favorites (possibly multiple times)
            let addCount = Int.random(in: 1...5)
            for _ in 0..<addCount {
                viewModel.addToFavorites(lineToFavorite)
            }
            
            // Property: line must be in favorites after add operation
            #expect(
                viewModel.isFavorite(lineToFavorite),
                "Iteration \(iteration): Line '\(lineToFavorite.name)' should be in favorites after adding"
            )
            #expect(
                viewModel.favoriteLineIds.contains(lineToFavorite.id),
                "Iteration \(iteration): favoriteLineIds should contain '\(lineToFavorite.id)'"
            )
        }
    }
    
    /// Property 3: Removing from favorites ensures line is not in favorites
    /// **Validates: Requirements 3.2**
    /// **Feature: vta-all-lines, Property 3: 收藏操作幂等性**
    @Test("Property 3: Removing from favorites ensures line is not in favorites - 100 iterations")
    func removingFromFavoritesEnsuresLineIsNotInFavorites() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lines = LineViewModelTestDataGenerator.randomLines(count: 10)
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            
            let lineToUnfavorite = lines.randomElement()!
            
            // First add to favorites
            viewModel.addToFavorites(lineToUnfavorite)
            
            // Remove from favorites (possibly multiple times)
            let removeCount = Int.random(in: 1...5)
            for _ in 0..<removeCount {
                viewModel.removeFromFavorites(lineToUnfavorite)
            }
            
            // Property: line must not be in favorites after remove operation
            #expect(
                !viewModel.isFavorite(lineToUnfavorite),
                "Iteration \(iteration): Line '\(lineToUnfavorite.name)' should not be in favorites after removing"
            )
            #expect(
                !viewModel.favoriteLineIds.contains(lineToUnfavorite.id),
                "Iteration \(iteration): favoriteLineIds should not contain '\(lineToUnfavorite.id)'"
            )
        }
    }
    
    /// Property 3: Toggle favorite is idempotent when called twice
    /// **Validates: Requirements 3.1, 3.2**
    /// **Feature: vta-all-lines, Property 3: 收藏操作幂等性**
    @Test("Property 3: Toggle favorite twice returns to original state - 100 iterations")
    func toggleFavoriteTwiceReturnsToOriginalState() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lines = LineViewModelTestDataGenerator.randomLines(count: 10)
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            
            let line = lines.randomElement()!
            let originalState = viewModel.isFavorite(line)
            
            // Toggle twice
            viewModel.toggleFavorite(line)
            viewModel.toggleFavorite(line)
            
            // Property: state should return to original after two toggles
            #expect(
                viewModel.isFavorite(line) == originalState,
                "Iteration \(iteration): Favorite state should return to original (\(originalState)) after two toggles"
            )
        }
    }
}

// MARK: - Property 5: 收藏线路优先显示

/// Property-based tests for favorite lines priority display
/// **Feature: vta-all-lines, Property 5: 收藏线路优先显示**
/// **Validates: Requirements 3.5**
///
/// Property 5: 对于任意包含收藏和非收藏线路的列表，排序后所有收藏线路的索引必须小于所有非收藏线路的索引。
@MainActor
struct FavoriteLinesPriorityDisplayPropertyTests {
    
    /// Property 5: All favorite lines appear before non-favorite lines
    /// **Validates: Requirements 3.5**
    /// **Feature: vta-all-lines, Property 5: 收藏线路优先显示**
    @Test("Property 5: All favorite lines appear before non-favorite lines - 100 iterations")
    func allFavoriteLinesAppearBeforeNonFavoriteLines() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lineCount = Int.random(in: 5...20)
            let lines = LineViewModelTestDataGenerator.randomLines(count: lineCount)
            let favorites = LineViewModelTestDataGenerator.randomFavorites(from: lines)
            
            mockStorage.favoriteLineIds = favorites
            
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            viewModel.favoriteLineIds = favorites
            
            let sortedLines = viewModel.sortedLines
            
            // Find the last favorite index and first non-favorite index
            var lastFavoriteIndex = -1
            var firstNonFavoriteIndex = sortedLines.count
            
            for (index, line) in sortedLines.enumerated() {
                if favorites.contains(line.id) {
                    lastFavoriteIndex = index
                }
                if !favorites.contains(line.id) && firstNonFavoriteIndex == sortedLines.count {
                    firstNonFavoriteIndex = index
                }
            }
            
            // Property: all favorites must appear before all non-favorites
            if lastFavoriteIndex >= 0 && firstNonFavoriteIndex < sortedLines.count {
                #expect(
                    lastFavoriteIndex < firstNonFavoriteIndex,
                    "Iteration \(iteration): Last favorite index (\(lastFavoriteIndex)) should be less than first non-favorite index (\(firstNonFavoriteIndex))"
                )
            }
        }
    }
    
    /// Property 5: favoriteLines contains only favorites
    /// **Validates: Requirements 3.5**
    /// **Feature: vta-all-lines, Property 5: 收藏线路优先显示**
    @Test("Property 5: favoriteLines contains only favorites - 100 iterations")
    func favoriteLinesContainsOnlyFavorites() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lineCount = Int.random(in: 5...20)
            let lines = LineViewModelTestDataGenerator.randomLines(count: lineCount)
            let favorites = LineViewModelTestDataGenerator.randomFavorites(from: lines)
            
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            viewModel.favoriteLineIds = favorites
            
            // Property: all lines in favoriteLines must be in favorites set
            for line in viewModel.favoriteLines {
                #expect(
                    favorites.contains(line.id),
                    "Iteration \(iteration): Line '\(line.name)' in favoriteLines should be in favorites set"
                )
            }
            
            // Property: favoriteLines count should equal favorites count
            #expect(
                viewModel.favoriteLines.count == favorites.count,
                "Iteration \(iteration): favoriteLines count (\(viewModel.favoriteLines.count)) should equal favorites count (\(favorites.count))"
            )
        }
    }
    
    /// Property 5: otherLines contains only non-favorites
    /// **Validates: Requirements 3.5**
    /// **Feature: vta-all-lines, Property 5: 收藏线路优先显示**
    @Test("Property 5: otherLines contains only non-favorites - 100 iterations")
    func otherLinesContainsOnlyNonFavorites() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lineCount = Int.random(in: 5...20)
            let lines = LineViewModelTestDataGenerator.randomLines(count: lineCount)
            let favorites = LineViewModelTestDataGenerator.randomFavorites(from: lines)
            
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            viewModel.favoriteLineIds = favorites
            
            // Property: no line in otherLines should be in favorites set
            for line in viewModel.otherLines {
                #expect(
                    !favorites.contains(line.id),
                    "Iteration \(iteration): Line '\(line.name)' in otherLines should not be in favorites set"
                )
            }
            
            // Property: otherLines count should equal total minus favorites
            let expectedOtherCount = lines.count - favorites.count
            #expect(
                viewModel.otherLines.count == expectedOtherCount,
                "Iteration \(iteration): otherLines count (\(viewModel.otherLines.count)) should equal \(expectedOtherCount)"
            )
        }
    }
    
    /// Property 5: favoriteLines + otherLines equals allLines
    /// **Validates: Requirements 3.5**
    /// **Feature: vta-all-lines, Property 5: 收藏线路优先显示**
    @Test("Property 5: favoriteLines + otherLines equals allLines - 100 iterations")
    func favoriteLinesAndOtherLinesEqualsAllLines() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lineCount = Int.random(in: 5...20)
            let lines = LineViewModelTestDataGenerator.randomLines(count: lineCount)
            let favorites = LineViewModelTestDataGenerator.randomFavorites(from: lines)
            
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            viewModel.favoriteLineIds = favorites
            
            let combinedCount = viewModel.favoriteLines.count + viewModel.otherLines.count
            
            // Property: combined count should equal allLines count
            #expect(
                combinedCount == lines.count,
                "Iteration \(iteration): favoriteLines + otherLines (\(combinedCount)) should equal allLines count (\(lines.count))"
            )
            
            // Property: all lines should be in either favoriteLines or otherLines
            let favoriteIds = Set(viewModel.favoriteLines.map { $0.id })
            let otherIds = Set(viewModel.otherLines.map { $0.id })
            
            for line in lines {
                let inFavorites = favoriteIds.contains(line.id)
                let inOthers = otherIds.contains(line.id)
                
                #expect(
                    inFavorites || inOthers,
                    "Iteration \(iteration): Line '\(line.name)' should be in either favoriteLines or otherLines"
                )
                #expect(
                    !(inFavorites && inOthers),
                    "Iteration \(iteration): Line '\(line.name)' should not be in both favoriteLines and otherLines"
                )
            }
        }
    }
}

// MARK: - LineViewModel Selection Tests

/// Property-based tests for line selection
@MainActor
struct LineViewModelSelectionPropertyTests {
    
    /// Selection persists to storage
    @Test("Selection persists to storage - 100 iterations")
    func selectionPersistsToStorage() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lines = LineViewModelTestDataGenerator.randomLines(count: 10)
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            
            let lineToSelect = lines.randomElement()!
            viewModel.selectLine(lineToSelect)
            
            // Property: selected line should be stored
            #expect(
                mockStorage.selectedLineId == lineToSelect.id,
                "Iteration \(iteration): Storage should have selected line ID '\(lineToSelect.id)'"
            )
            #expect(
                viewModel.selectedLine?.id == lineToSelect.id,
                "Iteration \(iteration): ViewModel should have selected line '\(lineToSelect.name)'"
            )
            #expect(
                mockStorage.saveCallCount >= 1,
                "Iteration \(iteration): Storage save should have been called"
            )
        }
    }
    
    /// Clear selection removes selection
    @Test("Clear selection removes selection - 100 iterations")
    func clearSelectionRemovesSelection() {
        for iteration in 1...100 {
            let mockStorage = LineViewModelMockStorageService()
            let mockVTA = LineViewModelMockVTAService()
            
            let lines = LineViewModelTestDataGenerator.randomLines(count: 10)
            let viewModel = LineViewModel(vtaService: mockVTA, storageService: mockStorage)
            viewModel.allLines = lines
            
            // First select a line
            let lineToSelect = lines.randomElement()!
            viewModel.selectLine(lineToSelect)
            
            // Then clear selection
            viewModel.clearSelection()
            
            // Property: selection should be cleared
            #expect(
                mockStorage.selectedLineId == nil,
                "Iteration \(iteration): Storage should have nil selected line ID"
            )
            #expect(
                viewModel.selectedLine == nil,
                "Iteration \(iteration): ViewModel should have nil selected line"
            )
        }
    }
}
