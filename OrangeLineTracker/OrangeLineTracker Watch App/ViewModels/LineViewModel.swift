//
//  LineViewModel.swift
//  OrangeLineTracker Watch App
//
//  ViewModel for line selection and management
//  Supports VTA All Lines feature
//

import Foundation
import SwiftUI
import Combine

// MARK: - LineViewModel

/// ViewModel for line selection and management
/// - Validates: Requirements 2.1, 2.3, 3.1, 3.2, 3.5, 3.6
@MainActor
class LineViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All available lines
    /// - Validates: Requirements 2.1
    @Published var allLines: [Line] = []
    
    /// Favorite line IDs
    /// - Validates: Requirements 3.3, 3.4
    @Published var favoriteLineIds: Set<String> = []
    
    /// Currently selected line
    /// - Validates: Requirements 2.3
    @Published var selectedLine: Line?
    
    /// Loading state
    @Published var isLoading: Bool = false
    
    /// Error message
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let vtaService: VTAServiceProtocol
    private let storageService: StorageServiceProtocol
    
    // MARK: - Computed Properties
    
    /// Favorite lines (sorted by name)
    /// - Validates: Requirements 3.5
    var favoriteLines: [Line] {
        allLines
            .filter { favoriteLineIds.contains($0.id) }
            .sorted { $0.name < $1.name }
    }
    
    /// Non-favorite lines (sorted by name)
    var otherLines: [Line] {
        allLines
            .filter { !favoriteLineIds.contains($0.id) }
            .sorted { $0.name < $1.name }
    }
    
    /// Lines grouped by type (light rail first, then bus)
    /// - Validates: Requirements 2.2
    var linesByType: [LineType: [Line]] {
        Dictionary(grouping: allLines, by: { $0.type })
    }
    
    /// Lines sorted with favorites first, then by type (light rail before bus), then by name
    /// - Validates: Requirements 2.2, 3.5
    var sortedLines: [Line] {
        let favorites = favoriteLines
        let others = otherLines
        
        // Sort others by type (light rail first) then by name
        let sortedOthers = others.sorted { line1, line2 in
            if line1.type != line2.type {
                return line1.type == .lightRail
            }
            return line1.name < line2.name
        }
        
        return favorites + sortedOthers
    }
    
    /// Light rail lines only
    var lightRailLines: [Line] {
        allLines.filter { $0.type == .lightRail }
    }
    
    /// Bus lines only
    var busLines: [Line] {
        allLines.filter { $0.type == .bus }
    }
    
    // MARK: - Initialization
    
    /// Creates a new LineViewModel
    /// - Parameters:
    ///   - vtaService: VTA service for fetching line data
    ///   - storageService: Storage service for persisting preferences
    init(vtaService: VTAServiceProtocol,
         storageService: StorageServiceProtocol) {
        self.vtaService = vtaService
        self.storageService = storageService
        
        // Load saved preferences
        loadFromStorage()
    }
    
    /// Convenience initializer with API key
    /// - Parameters:
    ///   - apiKey: The 511.org API key
    ///   - storageService: Storage service for persisting preferences
    convenience init(apiKey: String, storageService: StorageServiceProtocol? = nil) {
        let storage = storageService ?? StorageService()
        let vta = VTAService(apiKey: apiKey)
        self.init(vtaService: vta, storageService: storage)
    }
    
    // MARK: - Public Methods
    
    /// Loads all available lines from the API
    /// - Validates: Requirements 2.1, 6.1
    func loadLines() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let lines = try await vtaService.fetchAllLines()
            allLines = lines
            
            // Cache lines for offline access
            storageService.cachedLines = lines
            storageService.save()
            
            // Restore selected line if it exists
            if let selectedLineId = storageService.selectedLineId,
               let line = lines.first(where: { $0.id == selectedLineId }) {
                selectedLine = line
            }
            
            print("LineViewModel: ✅ Loaded \(lines.count) lines")
        } catch {
            errorMessage = "无法加载线路数据: \(error.localizedDescription)"
            print("LineViewModel: ❌ Failed to load lines: \(error)")
            
            // Try to use cached data
            if let cachedLines = storageService.cachedLines {
                allLines = cachedLines
                print("LineViewModel: 📦 Using cached lines (\(cachedLines.count) lines)")
            }
        }
        
        isLoading = false
    }
    
    /// Selects a line
    /// - Parameter line: The line to select
    /// - Validates: Requirements 2.3
    func selectLine(_ line: Line) {
        selectedLine = line
        storageService.selectedLineId = line.id
        storageService.save()
        print("LineViewModel: 🚇 Selected line: \(line.name)")
    }
    
    /// Clears the current line selection
    func clearSelection() {
        selectedLine = nil
        storageService.selectedLineId = nil
        storageService.save()
        print("LineViewModel: 🗑️ Cleared line selection")
    }
    
    /// Toggles the favorite status of a line
    /// - Parameter line: The line to toggle
    /// - Validates: Requirements 3.1, 3.2
    func toggleFavorite(_ line: Line) {
        if favoriteLineIds.contains(line.id) {
            favoriteLineIds.remove(line.id)
            print("LineViewModel: ⭐ Removed \(line.name) from favorites")
        } else {
            favoriteLineIds.insert(line.id)
            print("LineViewModel: ⭐ Added \(line.name) to favorites")
        }
        
        storageService.favoriteLineIds = favoriteLineIds
        storageService.save()
    }
    
    /// Checks if a line is a favorite
    /// - Parameter line: The line to check
    /// - Returns: True if the line is a favorite
    /// - Validates: Requirements 3.1
    func isFavorite(_ line: Line) -> Bool {
        favoriteLineIds.contains(line.id)
    }
    
    /// Adds a line to favorites
    /// - Parameter line: The line to add
    /// - Validates: Requirements 3.1
    func addToFavorites(_ line: Line) {
        if !favoriteLineIds.contains(line.id) {
            favoriteLineIds.insert(line.id)
            storageService.favoriteLineIds = favoriteLineIds
            storageService.save()
        }
    }
    
    /// Removes a line from favorites
    /// - Parameter line: The line to remove
    /// - Validates: Requirements 3.2
    func removeFromFavorites(_ line: Line) {
        if favoriteLineIds.contains(line.id) {
            favoriteLineIds.remove(line.id)
            storageService.favoriteLineIds = favoriteLineIds
            storageService.save()
        }
    }
    
    /// Gets a line by ID
    /// - Parameter id: The line ID
    /// - Returns: The line if found
    func line(byId id: String) -> Line? {
        allLines.first { $0.id == id }
    }
    
    // MARK: - Private Methods
    
    /// Loads saved preferences from storage
    private func loadFromStorage() {
        storageService.load()
        favoriteLineIds = storageService.favoriteLineIds
        
        // Load cached lines if available
        if let cachedLines = storageService.cachedLines {
            allLines = cachedLines
        }
        
        // Restore selected line
        if let selectedLineId = storageService.selectedLineId,
           let line = allLines.first(where: { $0.id == selectedLineId }) {
            selectedLine = line
        }
    }
}
