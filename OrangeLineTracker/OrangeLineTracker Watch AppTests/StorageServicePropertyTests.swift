//
//  StorageServicePropertyTests.swift
//  OrangeLineTracker Watch AppTests
//
//  Property-based tests for StorageService multi-line support
//

import Foundation
import Testing
@testable import OrangeLineTracker_Watch_App

// MARK: - Property 4: 收藏列表往返一致性

/// Property-based tests for favorite line IDs roundtrip consistency
/// **Feature: vta-all-lines, Property 4: 收藏列表往返一致性**
/// **Validates: Requirements 3.3, 3.4, 7.4**
///
/// Property 4: 对于任意收藏线路列表，保存到 Storage 后再加载，得到的列表必须与原列表相等。
struct FavoriteLineIdsRoundtripPropertyTests {
    
    // MARK: - Test Data Generators
    
    /// Generates a random valid line ID
    private func randomLineId() -> String {
        let lineIds = [
            "Orange Line", "Blue Line", "Green Line",
            "22", "23", "25", "60", "61", "62", "64", "66", "68",
            "70", "71", "72", "73", "77", "81", "82", "83",
            "Test Line \(Int.random(in: 1...100))"
        ]
        return lineIds.randomElement()!
    }
    
    /// Generates a random set of favorite line IDs (0-10 items)
    private func randomFavoriteLineIds() -> Set<String> {
        let count = Int.random(in: 0...10)
        var ids = Set<String>()
        for _ in 0..<count {
            ids.insert(randomLineId())
        }
        return ids
    }
    
    // MARK: - Property 4 Tests
    
    /// Property 4: Favorite line IDs roundtrip consistency
    /// **Validates: Requirements 3.3, 3.4, 7.4**
    /// **Feature: vta-all-lines, Property 4: 收藏列表往返一致性**
    @Test("Property 4: Favorite line IDs roundtrip consistency - 100 iterations")
    func favoriteLineIdsRoundtripConsistency() {
        for iteration in 1...100 {
            // Create a fresh UserDefaults for isolation
            let testDefaults = UserDefaults(suiteName: "test.storage.\(UUID().uuidString)")!
            let storage = StorageService(userDefaults: testDefaults)
            
            // Generate random favorite line IDs
            let originalFavorites = randomFavoriteLineIds()
            
            // Save to storage
            storage.favoriteLineIds = originalFavorites
            storage.save()
            
            // Create a new storage instance and load
            let loadedStorage = StorageService(userDefaults: testDefaults)
            loadedStorage.load()
            
            // Property: loaded favorites must equal original
            #expect(
                loadedStorage.favoriteLineIds == originalFavorites,
                "Iteration \(iteration): Loaded favorites should equal original. Expected \(originalFavorites), got \(loadedStorage.favoriteLineIds)"
            )
            
            // Cleanup
            testDefaults.removePersistentDomain(forName: "test.storage.\(UUID().uuidString)")
        }
    }
    
    /// Property 4: Empty favorite list roundtrip
    /// **Validates: Requirements 3.3, 3.4, 7.4**
    /// **Feature: vta-all-lines, Property 4: 收藏列表往返一致性**
    @Test("Property 4: Empty favorite list roundtrip - 100 iterations")
    func emptyFavoriteListRoundtrip() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.storage.empty.\(UUID().uuidString)")!
            let storage = StorageService(userDefaults: testDefaults)
            
            // Save empty set
            storage.favoriteLineIds = []
            storage.save()
            
            // Load in new instance
            let loadedStorage = StorageService(userDefaults: testDefaults)
            loadedStorage.load()
            
            // Property: empty set should remain empty
            #expect(
                loadedStorage.favoriteLineIds.isEmpty,
                "Iteration \(iteration): Empty favorites should remain empty after roundtrip"
            )
        }
    }
    
    /// Property 4: Single favorite roundtrip
    /// **Validates: Requirements 3.3, 3.4, 7.4**
    /// **Feature: vta-all-lines, Property 4: 收藏列表往返一致性**
    @Test("Property 4: Single favorite roundtrip - 100 iterations")
    func singleFavoriteRoundtrip() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.storage.single.\(UUID().uuidString)")!
            let storage = StorageService(userDefaults: testDefaults)
            
            let singleFavorite = randomLineId()
            storage.favoriteLineIds = [singleFavorite]
            storage.save()
            
            let loadedStorage = StorageService(userDefaults: testDefaults)
            loadedStorage.load()
            
            #expect(
                loadedStorage.favoriteLineIds.count == 1,
                "Iteration \(iteration): Should have exactly 1 favorite"
            )
            #expect(
                loadedStorage.favoriteLineIds.contains(singleFavorite),
                "Iteration \(iteration): Should contain the saved favorite '\(singleFavorite)'"
            )
        }
    }
}

// MARK: - Property 10: 用户选择往返一致性

/// Property-based tests for user selection roundtrip consistency
/// **Feature: vta-all-lines, Property 10: 用户选择往返一致性**
/// **Validates: Requirements 7.1, 7.2, 7.3, 7.5**
///
/// Property 10: 对于任意用户选择（线路 ID、站点 ID、方向），保存到 Storage 后再加载，得到的选择必须与原选择相等。
struct UserSelectionRoundtripPropertyTests {
    
    // MARK: - Test Data Generators
    
    /// Generates a random valid line ID
    private func randomLineId() -> String {
        let lineIds = ["Orange Line", "Blue Line", "Green Line", "22", "60", "Test Line \(Int.random(in: 1...100))"]
        return lineIds.randomElement()!
    }
    
    /// Generates a random direction
    private func randomDirection() -> Direction {
        [Direction.alumRock, Direction.mountainView].randomElement()!
    }
    
    /// Generates a random station from OrangeLineStations
    private func randomStation() -> Station {
        OrangeLineStations.stations.randomElement()!
    }
    
    // MARK: - Property 10 Tests
    
    /// Property 10: Selected line ID roundtrip consistency
    /// **Validates: Requirements 7.1**
    /// **Feature: vta-all-lines, Property 10: 用户选择往返一致性**
    @Test("Property 10: Selected line ID roundtrip consistency - 100 iterations")
    func selectedLineIdRoundtripConsistency() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.lineId.\(UUID().uuidString)")!
            let storage = StorageService(userDefaults: testDefaults)
            
            let originalLineId = randomLineId()
            storage.selectedLineId = originalLineId
            storage.save()
            
            let loadedStorage = StorageService(userDefaults: testDefaults)
            loadedStorage.load()
            
            #expect(
                loadedStorage.selectedLineId == originalLineId,
                "Iteration \(iteration): Selected line ID should be preserved. Expected '\(originalLineId)', got '\(loadedStorage.selectedLineId ?? "nil")'"
            )
        }
    }
    
    /// Property 10: Selected station roundtrip consistency
    /// **Validates: Requirements 7.2**
    /// **Feature: vta-all-lines, Property 10: 用户选择往返一致性**
    @Test("Property 10: Selected station roundtrip consistency - 100 iterations")
    func selectedStationRoundtripConsistency() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.station.\(UUID().uuidString)")!
            let storage = StorageService(userDefaults: testDefaults)
            
            let originalStation = randomStation()
            storage.selectedStation = originalStation
            storage.save()
            
            let loadedStorage = StorageService(userDefaults: testDefaults)
            loadedStorage.load()
            
            #expect(
                loadedStorage.selectedStation?.id == originalStation.id,
                "Iteration \(iteration): Selected station ID should be preserved. Expected '\(originalStation.id)', got '\(loadedStorage.selectedStation?.id ?? "nil")'"
            )
        }
    }
    
    /// Property 10: Selected direction roundtrip consistency
    /// **Validates: Requirements 7.3**
    /// **Feature: vta-all-lines, Property 10: 用户选择往返一致性**
    @Test("Property 10: Selected direction roundtrip consistency - 100 iterations")
    func selectedDirectionRoundtripConsistency() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.direction.\(UUID().uuidString)")!
            let storage = StorageService(userDefaults: testDefaults)
            
            let originalDirection = randomDirection()
            storage.selectedDirection = originalDirection
            storage.save()
            
            let loadedStorage = StorageService(userDefaults: testDefaults)
            loadedStorage.load()
            
            #expect(
                loadedStorage.selectedDirection == originalDirection,
                "Iteration \(iteration): Selected direction should be preserved. Expected '\(originalDirection)', got '\(loadedStorage.selectedDirection?.rawValue ?? "nil")'"
            )
        }
    }
    
    /// Property 10: Combined selection roundtrip consistency
    /// **Validates: Requirements 7.1, 7.2, 7.3, 7.5**
    /// **Feature: vta-all-lines, Property 10: 用户选择往返一致性**
    @Test("Property 10: Combined selection roundtrip consistency - 100 iterations")
    func combinedSelectionRoundtripConsistency() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.combined.\(UUID().uuidString)")!
            let storage = StorageService(userDefaults: testDefaults)
            
            let originalLineId = randomLineId()
            let originalStation = randomStation()
            let originalDirection = randomDirection()
            
            storage.selectedLineId = originalLineId
            storage.selectedStation = originalStation
            storage.selectedDirection = originalDirection
            storage.save()
            
            let loadedStorage = StorageService(userDefaults: testDefaults)
            loadedStorage.load()
            
            #expect(
                loadedStorage.selectedLineId == originalLineId,
                "Iteration \(iteration): Line ID should be preserved"
            )
            #expect(
                loadedStorage.selectedStation?.id == originalStation.id,
                "Iteration \(iteration): Station should be preserved"
            )
            #expect(
                loadedStorage.selectedDirection == originalDirection,
                "Iteration \(iteration): Direction should be preserved"
            )
        }
    }
    
    /// Property 10: Nil selection roundtrip
    /// **Validates: Requirements 7.5**
    /// **Feature: vta-all-lines, Property 10: 用户选择往返一致性**
    @Test("Property 10: Nil selection roundtrip - 100 iterations")
    func nilSelectionRoundtrip() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.nil.\(UUID().uuidString)")!
            let storage = StorageService(userDefaults: testDefaults)
            
            // Set all to nil
            storage.selectedLineId = nil
            storage.selectedStation = nil
            storage.selectedDirection = nil
            storage.save()
            
            let loadedStorage = StorageService(userDefaults: testDefaults)
            loadedStorage.load()
            
            #expect(
                loadedStorage.selectedLineId == nil,
                "Iteration \(iteration): Nil line ID should remain nil"
            )
            #expect(
                loadedStorage.selectedStation == nil,
                "Iteration \(iteration): Nil station should remain nil"
            )
            #expect(
                loadedStorage.selectedDirection == nil,
                "Iteration \(iteration): Nil direction should remain nil"
            )
        }
    }
}

// MARK: - Property 11: 向后兼容性 - 旧数据迁移 (StorageService)

/// Property-based tests for StorageService data migration
/// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
/// **Validates: Requirements 7.6, 7.7, 10.6**
///
/// Property 11: 对于任意 v1 版本的存储数据（仅包含 Orange Line 设置），
/// 迁移后必须正确设置 lineId 为 "Orange Line"，且原有的站点和方向设置保持不变。
struct StorageServiceMigrationPropertyTests {
    
    // MARK: - Test Data Generators
    
    /// Generates a random station from OrangeLineStations
    private func randomStation() -> Station {
        OrangeLineStations.stations.randomElement()!
    }
    
    /// Generates a random direction
    private func randomDirection() -> Direction {
        [Direction.alumRock, Direction.mountainView].randomElement()!
    }
    
    // MARK: - Property 11 Tests
    
    /// Property 11: Migration sets lineId to "Orange Line" for existing users
    /// **Validates: Requirements 7.6, 7.7, 10.6**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Migration sets lineId to Orange Line for existing users - 100 iterations")
    func migrationSetsLineIdForExistingUsers() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.migration.existing.\(UUID().uuidString)")!
            
            // Simulate v1 data: station and direction saved, but no lineId or dataVersion
            let station = randomStation()
            testDefaults.set(station.id, forKey: StorageKeys.selectedStationId)
            testDefaults.set(randomDirection().rawValue, forKey: StorageKeys.selectedDirection)
            // No dataVersion key = v1 data
            
            // Create storage and run migration
            let storage = StorageService(userDefaults: testDefaults)
            storage.load()
            storage.migrateFromV1IfNeeded()
            
            // Property: lineId should be set to "Orange Line"
            #expect(
                storage.selectedLineId == "Orange Line",
                "Iteration \(iteration): Migration should set lineId to 'Orange Line' for existing users"
            )
        }
    }
    
    /// Property 11: Migration preserves existing station selection
    /// **Validates: Requirements 7.6, 7.7, 10.6**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Migration preserves station selection - 100 iterations")
    func migrationPreservesStationSelection() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.migration.station.\(UUID().uuidString)")!
            
            let originalStation = randomStation()
            testDefaults.set(originalStation.id, forKey: StorageKeys.selectedStationId)
            
            let storage = StorageService(userDefaults: testDefaults)
            storage.load()
            storage.migrateFromV1IfNeeded()
            
            // Property: station selection should be preserved
            #expect(
                storage.selectedStation?.id == originalStation.id,
                "Iteration \(iteration): Migration should preserve station selection. Expected '\(originalStation.id)', got '\(storage.selectedStation?.id ?? "nil")'"
            )
        }
    }
    
    /// Property 11: Migration preserves existing direction selection
    /// **Validates: Requirements 7.6, 7.7, 10.6**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Migration preserves direction selection - 100 iterations")
    func migrationPreservesDirectionSelection() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.migration.direction.\(UUID().uuidString)")!
            
            let originalDirection = randomDirection()
            testDefaults.set(originalDirection.rawValue, forKey: StorageKeys.selectedDirection)
            
            let storage = StorageService(userDefaults: testDefaults)
            storage.load()
            storage.migrateFromV1IfNeeded()
            
            // Property: direction selection should be preserved
            #expect(
                storage.selectedDirection == originalDirection,
                "Iteration \(iteration): Migration should preserve direction selection. Expected '\(originalDirection)', got '\(storage.selectedDirection?.rawValue ?? "nil")'"
            )
        }
    }
    
    /// Property 11: Migration is idempotent
    /// **Validates: Requirements 7.6, 7.7, 10.6**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Migration is idempotent - 100 iterations")
    func migrationIsIdempotent() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.migration.idempotent.\(UUID().uuidString)")!
            
            let station = randomStation()
            let direction = randomDirection()
            testDefaults.set(station.id, forKey: StorageKeys.selectedStationId)
            testDefaults.set(direction.rawValue, forKey: StorageKeys.selectedDirection)
            
            let storage = StorageService(userDefaults: testDefaults)
            storage.load()
            
            // Run migration multiple times
            storage.migrateFromV1IfNeeded()
            let lineIdAfterFirst = storage.selectedLineId
            let stationAfterFirst = storage.selectedStation?.id
            let directionAfterFirst = storage.selectedDirection
            
            storage.migrateFromV1IfNeeded()
            storage.migrateFromV1IfNeeded()
            
            // Property: multiple migrations should produce same result
            #expect(
                storage.selectedLineId == lineIdAfterFirst,
                "Iteration \(iteration): Multiple migrations should not change lineId"
            )
            #expect(
                storage.selectedStation?.id == stationAfterFirst,
                "Iteration \(iteration): Multiple migrations should not change station"
            )
            #expect(
                storage.selectedDirection == directionAfterFirst,
                "Iteration \(iteration): Multiple migrations should not change direction"
            )
        }
    }
    
    /// Property 11: Migration does not affect new users (no existing data)
    /// **Validates: Requirements 7.6, 7.7, 10.6**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Migration does not affect new users - 100 iterations")
    func migrationDoesNotAffectNewUsers() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.migration.newuser.\(UUID().uuidString)")!
            
            // No existing data - simulates new user
            let storage = StorageService(userDefaults: testDefaults)
            storage.load()
            storage.migrateFromV1IfNeeded()
            
            // Property: new users should not have lineId auto-set
            // (they should go through the normal line selection flow)
            #expect(
                storage.selectedLineId == nil,
                "Iteration \(iteration): New users should not have lineId auto-set"
            )
            #expect(
                storage.selectedStation == nil,
                "Iteration \(iteration): New users should not have station auto-set"
            )
            #expect(
                storage.selectedDirection == nil,
                "Iteration \(iteration): New users should not have direction auto-set"
            )
        }
    }
    
    /// Property 11: Migration updates data version
    /// **Validates: Requirements 7.6, 7.7, 10.6**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Migration updates data version - 100 iterations")
    func migrationUpdatesDataVersion() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.migration.version.\(UUID().uuidString)")!
            
            // Simulate v1 data
            testDefaults.set(randomStation().id, forKey: StorageKeys.selectedStationId)
            
            let storage = StorageService(userDefaults: testDefaults)
            storage.load()
            
            // Before migration, version should be 0 (not set)
            let versionBefore = testDefaults.integer(forKey: StorageKeys.dataVersion)
            #expect(
                versionBefore == 0,
                "Iteration \(iteration): Version before migration should be 0"
            )
            
            storage.migrateFromV1IfNeeded()
            
            // After migration, version should be 2
            let versionAfter = testDefaults.integer(forKey: StorageKeys.dataVersion)
            #expect(
                versionAfter == 2,
                "Iteration \(iteration): Version after migration should be 2, got \(versionAfter)"
            )
        }
    }
    
    /// Property 11: Combined v1 data migration preserves all settings
    /// **Validates: Requirements 7.6, 7.7, 10.6**
    /// **Feature: vta-all-lines, Property 11: 向后兼容性 - 旧数据迁移**
    @Test("Property 11: Combined v1 data migration preserves all settings - 100 iterations")
    func combinedV1DataMigrationPreservesAllSettings() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.migration.combined.\(UUID().uuidString)")!
            
            // Set up complete v1 data
            let originalStation = randomStation()
            let originalDirection = randomDirection()
            
            testDefaults.set(originalStation.id, forKey: StorageKeys.selectedStationId)
            testDefaults.set(originalDirection.rawValue, forKey: StorageKeys.selectedDirection)
            testDefaults.set(true, forKey: StorageKeys.isTimeRuleEnabled)
            testDefaults.set(false, forKey: StorageKeys.isSmartRefreshEnabled)
            
            let storage = StorageService(userDefaults: testDefaults)
            storage.load()
            storage.migrateFromV1IfNeeded()
            
            // All v1 settings should be preserved
            #expect(
                storage.selectedStation?.id == originalStation.id,
                "Iteration \(iteration): Station should be preserved"
            )
            #expect(
                storage.selectedDirection == originalDirection,
                "Iteration \(iteration): Direction should be preserved"
            )
            #expect(
                storage.isTimeRuleEnabled == true,
                "Iteration \(iteration): isTimeRuleEnabled should be preserved"
            )
            #expect(
                storage.isSmartRefreshEnabled == false,
                "Iteration \(iteration): isSmartRefreshEnabled should be preserved"
            )
            
            // New v2 field should be set
            #expect(
                storage.selectedLineId == "Orange Line",
                "Iteration \(iteration): lineId should be set to 'Orange Line'"
            )
        }
    }
}

// MARK: - Cached Lines Roundtrip Tests

/// Property-based tests for cached lines roundtrip consistency
/// **Feature: vta-all-lines, Property 4: 收藏列表往返一致性 (extended)**
/// **Validates: Requirements 7.4**
struct CachedLinesRoundtripPropertyTests {
    
    // MARK: - Test Data Generators
    
    /// Generates a random Line
    private func randomLine() -> Line {
        let types: [LineType] = [.lightRail, .bus]
        let lineId = ["Orange Line", "Blue Line", "Green Line", "22", "60"].randomElement()!
        
        return Line(
            id: lineId,
            name: lineId,
            shortName: String(lineId.prefix(3)),
            type: types.randomElement()!,
            colorHex: String(format: "%06X", Int.random(in: 0...0xFFFFFF)),
            directions: [
                LineDirection(id: "E", headsign: "Eastbound"),
                LineDirection(id: "W", headsign: "Westbound")
            ],
            stations: []
        )
    }
    
    /// Generates a random array of Lines (0-5 items)
    private func randomLines() -> [Line] {
        let count = Int.random(in: 0...5)
        return (0..<count).map { _ in randomLine() }
    }
    
    // MARK: - Tests
    
    /// Cached lines roundtrip consistency
    /// **Validates: Requirements 7.4**
    @Test("Cached lines roundtrip consistency - 100 iterations")
    func cachedLinesRoundtripConsistency() throws {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.cachedLines.\(UUID().uuidString)")!
            let storage = StorageService(userDefaults: testDefaults)
            
            let originalLines = randomLines()
            storage.cachedLines = originalLines
            storage.save()
            
            let loadedStorage = StorageService(userDefaults: testDefaults)
            loadedStorage.load()
            
            // Property: cached lines should be preserved
            #expect(
                loadedStorage.cachedLines?.count == originalLines.count,
                "Iteration \(iteration): Cached lines count should be preserved. Expected \(originalLines.count), got \(loadedStorage.cachedLines?.count ?? -1)"
            )
            
            if let loadedLines = loadedStorage.cachedLines {
                for (index, originalLine) in originalLines.enumerated() {
                    #expect(
                        loadedLines[index].id == originalLine.id,
                        "Iteration \(iteration): Line \(index) ID should be preserved"
                    )
                    #expect(
                        loadedLines[index].name == originalLine.name,
                        "Iteration \(iteration): Line \(index) name should be preserved"
                    )
                }
            }
        }
    }
    
    /// Nil cached lines roundtrip
    /// **Validates: Requirements 7.4**
    @Test("Nil cached lines roundtrip - 100 iterations")
    func nilCachedLinesRoundtrip() {
        for iteration in 1...100 {
            let testDefaults = UserDefaults(suiteName: "test.cachedLines.nil.\(UUID().uuidString)")!
            let storage = StorageService(userDefaults: testDefaults)
            
            storage.cachedLines = nil
            storage.save()
            
            let loadedStorage = StorageService(userDefaults: testDefaults)
            loadedStorage.load()
            
            #expect(
                loadedStorage.cachedLines == nil,
                "Iteration \(iteration): Nil cached lines should remain nil"
            )
        }
    }
}
