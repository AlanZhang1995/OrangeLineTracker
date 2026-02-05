//
//  LineSelectorView.swift
//  OrangeLineTracker Watch App
//
//  View for selecting VTA lines with favorites support
//  - Validates: Requirements 2.1, 2.2, 2.4, 2.5, 2.6
//

import SwiftUI

// MARK: - LineSelectorView

/// A view for browsing and selecting VTA lines
/// Displays all available lines with favorites at the top, grouped by type
/// - Validates: Requirements 2.1 (display all lines), 2.2 (group by type),
///              2.4 (show color indicator), 2.5 (loading state), 2.6 (error handling)
struct LineSelectorView: View {
    
    // MARK: - Properties
    
    /// ViewModel for line selection and management
    @ObservedObject var viewModel: LineViewModel
    
    /// Callback when a line is selected
    var onLineSelected: ((Line) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                headerView
                
                Divider()
                    .background(Color.orange.opacity(0.3))
                
                // Main content
                mainContent
            }
            .padding()
        }
        .navigationTitle("选择线路")
        .task {
            // Load lines when view appears
            if viewModel.allLines.isEmpty {
                await viewModel.loadLines()
            }
        }
    }
    
    // MARK: - Header View
    
    /// Header showing the view title and line count
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tram.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("选择线路")
                .font(.headline)
                .foregroundColor(.primary)
            
            if !viewModel.allLines.isEmpty {
                Text("共 \(viewModel.allLines.count) 条线路")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Main Content
    
    /// Main content area showing loading, error, or line list
    @ViewBuilder
    private var mainContent: some View {
        // Loading state - Validates: Requirement 2.5
        if viewModel.isLoading {
            loadingView
        }
        // Error state - Validates: Requirement 2.6
        else if let errorMessage = viewModel.errorMessage, viewModel.allLines.isEmpty {
            errorView(message: errorMessage)
        }
        // Line list - Validates: Requirements 2.1, 2.2
        else if !viewModel.allLines.isEmpty {
            lineListView
        }
        // Empty state
        else {
            emptyStateView
        }
    }
    
    // MARK: - Loading View
    
    /// Loading indicator view
    /// - Validates: Requirement 2.5 (show loading indicator)
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(.orange)
            
            Text("加载线路中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Error View
    
    /// Error state display with retry button
    /// - Parameter message: The error message to display
    /// - Validates: Requirement 2.6 (show error message and retry button)
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(.yellow)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            // Retry button - Validates: Requirement 2.6
            Button(action: {
                Task {
                    await viewModel.loadLines()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                    Text("重试")
                        .font(.caption)
                }
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Empty State View
    
    /// View shown when no lines are available
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tram")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("暂无线路数据")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("请检查网络连接后重试")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Retry button
            Button(action: {
                Task {
                    await viewModel.loadLines()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                    Text("刷新")
                        .font(.caption)
                }
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Line List View
    
    /// List of all lines with favorites first, then grouped by type
    /// - Validates: Requirements 2.1, 2.2, 3.5
    private var lineListView: some View {
        VStack(spacing: 16) {
            // Favorites section - Validates: Requirement 3.5 (favorites at top)
            if !viewModel.favoriteLines.isEmpty {
                favoritesSection
            }
            
            // Light rail section - Validates: Requirement 2.2 (light rail first)
            let nonFavoriteLightRail = viewModel.lightRailLines.filter { !viewModel.isFavorite($0) }
            if !nonFavoriteLightRail.isEmpty {
                lineSection(
                    title: "轻轨",
                    icon: "tram.fill",
                    lines: nonFavoriteLightRail.sorted { $0.name < $1.name }
                )
            }
            
            // Bus section - Validates: Requirement 2.2 (bus after light rail)
            let nonFavoriteBus = viewModel.busLines.filter { !viewModel.isFavorite($0) }
            if !nonFavoriteBus.isEmpty {
                lineSection(
                    title: "公交",
                    icon: "bus.fill",
                    lines: nonFavoriteBus.sorted { $0.name < $1.name }
                )
            }
        }
    }
    
    // MARK: - Favorites Section
    
    /// Section displaying favorite lines
    /// - Validates: Requirement 3.5 (favorites at top)
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text("收藏")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            // Favorite lines
            ForEach(viewModel.favoriteLines) { line in
                LineRowView(
                    line: line,
                    isFavorite: true,
                    isSelected: viewModel.selectedLine?.id == line.id,
                    onSelect: {
                        viewModel.selectLine(line)
                        onLineSelected?(line)
                    },
                    onToggleFavorite: {
                        viewModel.toggleFavorite(line)
                    }
                )
            }
        }
    }
    
    // MARK: - Line Section
    
    /// A section of lines with a header
    /// - Parameters:
    ///   - title: Section title
    ///   - icon: SF Symbol name for the icon
    ///   - lines: Lines to display in this section
    private func lineSection(title: String, icon: String, lines: [Line]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            // Lines in this section
            ForEach(lines) { line in
                LineRowView(
                    line: line,
                    isFavorite: viewModel.isFavorite(line),
                    isSelected: viewModel.selectedLine?.id == line.id,
                    onSelect: {
                        viewModel.selectLine(line)
                        onLineSelected?(line)
                    },
                    onToggleFavorite: {
                        viewModel.toggleFavorite(line)
                    }
                )
            }
        }
    }
}

// MARK: - LineRowView

/// Individual line row component
/// Displays line color indicator, name, and favorite button
/// - Validates: Requirements 2.3, 2.4, 3.1, 3.2
struct LineRowView: View {
    
    // MARK: - Properties
    
    /// The line to display
    let line: Line
    
    /// Whether this line is a favorite
    let isFavorite: Bool
    
    /// Whether this line is currently selected
    let isSelected: Bool
    
    /// Action when line is selected
    let onSelect: () -> Void
    
    /// Action when favorite button is tapped
    let onToggleFavorite: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Line color indicator - Validates: Requirement 2.4
                lineColorIndicator
                
                // Line name
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.name)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? lineColor : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Line type indicator
                    Text(line.type == .lightRail ? "轻轨" : "公交")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Favorite button - Validates: Requirements 3.1, 3.2
                favoriteButton
                
                // Selection indicator - Validates: Requirement 2.3
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(lineColor)
                        .font(.body)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? lineColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? lineColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(line.name), \(line.type == .lightRail ? "轻轨" : "公交"), \(isSelected ? "已选择" : "未选择"), \(isFavorite ? "已收藏" : "未收藏")")
        .accessibilityHint(isSelected ? "当前选中的线路" : "双击选择此线路")
    }
    
    // MARK: - Line Color Indicator
    
    /// Color indicator circle for the line
    /// - Validates: Requirement 2.4 (show line color indicator)
    private var lineColorIndicator: some View {
        Circle()
            .fill(lineColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Favorite Button
    
    /// Button to toggle favorite status
    /// - Validates: Requirements 3.1, 3.2
    private var favoriteButton: some View {
        Button(action: {
            onToggleFavorite()
        }) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.body)
                .foregroundColor(isFavorite ? .yellow : .secondary.opacity(0.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "取消收藏" : "添加收藏")
        .accessibilityHint(isFavorite ? "双击从收藏中移除" : "双击添加到收藏")
    }
    
    // MARK: - Computed Properties
    
    /// The color for this line based on its colorHex
    private var lineColor: Color {
        Color(hex: line.colorHex) ?? .orange
    }
}

// MARK: - Color Extension

extension Color {
    /// Creates a Color from a hex string
    /// - Parameter hex: Hex color string (with or without # prefix)
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        
        switch length {
        case 3: // RGB (12-bit)
            let r = Double((rgb >> 8) & 0xF) / 15.0
            let g = Double((rgb >> 4) & 0xF) / 15.0
            let b = Double(rgb & 0xF) / 15.0
            self.init(red: r, green: g, blue: b)
            
        case 6: // RGB (24-bit)
            let r = Double((rgb >> 16) & 0xFF) / 255.0
            let g = Double((rgb >> 8) & 0xFF) / 255.0
            let b = Double(rgb & 0xFF) / 255.0
            self.init(red: r, green: g, blue: b)
            
        case 8: // ARGB (32-bit)
            let a = Double((rgb >> 24) & 0xFF) / 255.0
            let r = Double((rgb >> 16) & 0xFF) / 255.0
            let g = Double((rgb >> 8) & 0xFF) / 255.0
            let b = Double(rgb & 0xFF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
            
        default:
            return nil
        }
    }
}

// MARK: - Preview

#Preview("Line Selector - Loading") {
    let mockService = MockVTAService()
    let viewModel = LineViewModel(
        vtaService: mockService,
        storageService: StorageService()
    )
    viewModel.isLoading = true
    
    return LineSelectorView(viewModel: viewModel)
}

#Preview("Line Selector - Error") {
    let mockService = MockVTAService()
    let viewModel = LineViewModel(
        vtaService: mockService,
        storageService: StorageService()
    )
    viewModel.errorMessage = "网络连接失败，请检查网络设置"
    
    return LineSelectorView(viewModel: viewModel)
}

#Preview("Line Selector - With Lines") {
    let mockService = MockVTAService()
    mockService.mockLines = [
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
            stations: []
        ),
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
            stations: []
        ),
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
            stations: []
        )
    ]
    
    let viewModel = LineViewModel(
        vtaService: mockService,
        storageService: StorageService()
    )
    viewModel.allLines = mockService.mockLines
    
    return LineSelectorView(viewModel: viewModel)
}
