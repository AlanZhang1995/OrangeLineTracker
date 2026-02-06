//
//  DirectionPickerView.swift
//  OrangeLineTracker Watch App
//
//  Reusable direction picker component for selecting travel direction on VTA lines
//  - Validates: Requirements 5.1, 5.2, 5.5
//

import SwiftUI

// MARK: - DirectionPickerView

/// A reusable view component for selecting the travel direction on VTA lines
/// Supports both the legacy Direction enum (for backward compatibility) and LineDirection data
/// Can be used in multiple places throughout the app (ArrivalView header, SettingsView, etc.)
/// - Validates: Requirements 5.1 (display direction options), 5.2 (use terminal station names),
///              5.5 (maintain existing direction switching UI)
struct DirectionPickerView: View {
    
    // MARK: - Properties
    
    /// Binding to the currently selected direction ID (e.g., "E", "W", "N", "S")
    @Binding var selectedDirectionId: String
    
    /// The available directions for the current line
    /// If nil, falls back to default Orange Line directions
    var lineDirections: [LineDirection]?
    
    /// Optional callback when direction changes
    var onDirectionChanged: ((String) -> Void)?
    
    /// Display style for the picker
    var style: DirectionPickerStyle
    
    /// Line color for theming (hex string)
    var lineColorHex: String
    
    // MARK: - Computed Properties
    
    /// The effective directions to display
    /// Falls back to Orange Line directions if lineDirections is nil
    private var effectiveDirections: [LineDirection] {
        lineDirections ?? [
            LineDirection(id: "W", headsign: "Mountain View"),
            LineDirection(id: "E", headsign: "Alum Rock")
        ]
    }
    
    /// The line color as a SwiftUI Color
    private var lineColor: Color {
        Color(hex: lineColorHex) ?? .orange
    }
    
    /// The currently selected direction
    private var selectedLineDirection: LineDirection? {
        effectiveDirections.first { $0.id == selectedDirectionId }
    }
    
    // MARK: - Initialization
    
    /// Creates a DirectionPickerView with LineDirection support
    /// - Parameters:
    ///   - selectedDirectionId: Binding to the selected direction ID
    ///   - lineDirections: The available directions for the current line (optional)
    ///   - style: The display style (default: .segmented)
    ///   - lineColorHex: The line color in hex format (default: Orange Line color)
    ///   - onDirectionChanged: Optional callback when direction changes
    init(
        selectedDirectionId: Binding<String>,
        lineDirections: [LineDirection]? = nil,
        style: DirectionPickerStyle = .segmented,
        lineColorHex: String = "#F7931E",
        onDirectionChanged: ((String) -> Void)? = nil
    ) {
        self._selectedDirectionId = selectedDirectionId
        self.lineDirections = lineDirections
        self.style = style
        self.lineColorHex = lineColorHex
        self.onDirectionChanged = onDirectionChanged
    }
    
    // MARK: - Body
    
    var body: some View {
        switch style {
        case .segmented:
            segmentedPickerView
        case .buttons:
            buttonsPickerView
        case .compact:
            compactPickerView
        case .inline:
            inlinePickerView
        }
    }
    
    // MARK: - Segmented Picker View
    
    /// Wheel picker style for watchOS (segmented is not available on watchOS)
    /// - Validates: Requirement 5.1 - display direction options
    private var segmentedPickerView: some View {
        VStack(spacing: 8) {
            // Direction label
            Text(L10n.direction)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Wheel picker (watchOS compatible)
            // Validates: Requirement 5.1 - display direction options
            Picker(L10n.direction, selection: $selectedDirectionId) {
                ForEach(effectiveDirections, id: \.id) { direction in
                    HStack(spacing: 4) {
                        Image(systemName: direction.iconName)
                        // Validates: Requirement 5.2 - use terminal station names
                        Text(direction.shortHeadsign)
                    }
                    .tag(direction.id)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 60)
            .onChange(of: selectedDirectionId) { _, newValue in
                onDirectionChanged?(newValue)
            }
        }
    }
    
    // MARK: - Buttons Picker View
    
    /// Button-based picker with icons and text
    /// - Validates: Requirements 5.1, 5.2, 5.5
    private var buttonsPickerView: some View {
        VStack(spacing: 8) {
            // Direction label
            Text(L10n.selectDirection)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Direction buttons
            // Validates: Requirement 5.1 - display direction options
            HStack(spacing: 12) {
                ForEach(effectiveDirections, id: \.id) { direction in
                    LineDirectionButton(
                        direction: direction,
                        isSelected: selectedDirectionId == direction.id,
                        lineColor: lineColor,
                        action: {
                            selectedDirectionId = direction.id
                            onDirectionChanged?(direction.id)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Compact Picker View
    
    /// Compact single-line picker for use in headers
    /// - Validates: Requirements 5.1, 5.2, 5.5
    private var compactPickerView: some View {
        HStack(spacing: 8) {
            ForEach(effectiveDirections, id: \.id) { direction in
                Button(action: {
                    selectedDirectionId = direction.id
                    onDirectionChanged?(direction.id)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: direction.iconName)
                            .font(.caption2)
                        // Validates: Requirement 5.2 - use terminal station names
                        Text(direction.shortHeadsign)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(selectedDirectionId == direction.id 
                                  ? lineColor 
                                  : lineColor.opacity(0.2))
                    )
                    .foregroundColor(selectedDirectionId == direction.id 
                                     ? .white 
                                     : lineColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Inline Picker View
    
    /// Inline picker for use within lists or forms
    /// - Validates: Requirements 5.1, 5.2, 5.5
    private var inlinePickerView: some View {
        HStack {
            if let currentDirection = selectedLineDirection {
                Image(systemName: currentDirection.iconName)
                    .foregroundColor(lineColor)
                
                // Validates: Requirement 5.2 - use terminal station names
                Text(currentDirection.headsign)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Toggle button
            Button(action: {
                // Toggle to the other direction
                if let currentIndex = effectiveDirections.firstIndex(where: { $0.id == selectedDirectionId }) {
                    let nextIndex = (currentIndex + 1) % effectiveDirections.count
                    let newDirectionId = effectiveDirections[nextIndex].id
                    selectedDirectionId = newDirectionId
                    onDirectionChanged?(newDirectionId)
                }
            }) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundColor(lineColor)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - DirectionPickerStyle

/// Display styles for the DirectionPickerView
enum DirectionPickerStyle {
    /// Segmented control style (default)
    case segmented
    /// Button-based style with icons
    case buttons
    /// Compact style for headers
    case compact
    /// Inline style for lists
    case inline
}

// MARK: - LineDirectionButton

/// Individual direction button component for LineDirection
/// - Validates: Requirements 5.2, 5.5
struct LineDirectionButton: View {
    /// The direction this button represents
    let direction: LineDirection
    
    /// Whether this direction is currently selected
    let isSelected: Bool
    
    /// The line color for theming
    let lineColor: Color
    
    /// Action to perform when button is tapped
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Direction icon
                Image(systemName: direction.iconName)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : lineColor)
                
                // Direction text - use terminal station name
                // Validates: Requirement 5.2 - use terminal station names
                Text(direction.shortHeadsign)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : lineColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? lineColor : lineColor.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(lineColor, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(direction.headsign), \(isSelected ? L10n.selected : L10n.notSelected)")
        .accessibilityHint(isSelected ? L10n.currentlySelected : L10n.doubleTapToSelect)
    }
}

// MARK: - LineDirection Extension

extension LineDirection {
    /// Icon name for the direction based on direction ID
    /// - Validates: Requirement 5.2 - use clear icons to identify direction
    var iconName: String {
        switch id.uppercased() {
        case "W":
            return "arrow.left"
        case "E":
            return "arrow.right"
        case "N":
            return "arrow.up"
        case "S":
            return "arrow.down"
        default:
            return "arrow.right"
        }
    }
    
    /// Short headsign for compact views (first 3 characters or abbreviation)
    var shortHeadsign: String {
        // Common abbreviations for VTA stations
        let abbreviations: [String: String] = [
            "Mountain View": "MTV",
            "Alum Rock": "ALR",
            "Winchester": "WIN",
            "Santa Teresa": "STA",
            "Baypointe": "BAY",
            "Old Ironsides": "OIS"
        ]
        
        if let abbr = abbreviations[headsign] {
            return abbr
        }
        
        // For other stations, use first 3 characters
        if headsign.count > 3 {
            return String(headsign.prefix(3)).uppercased()
        }
        return headsign.uppercased()
    }
}

// MARK: - Direction Extension (Backward Compatibility)

extension Direction {
    /// Icon name for the direction
    /// - Validates: Requirement 5.2 - use clear icons to identify direction
    var iconName: String {
        switch self {
        case .mountainView:
            return "arrow.left"
        case .alumRock:
            return "arrow.right"
        }
    }
    
    /// Short display name for compact views
    var shortDisplayName: String {
        switch self {
        case .mountainView:
            return "MTV"
        case .alumRock:
            return "ALR"
        }
    }
}

// MARK: - Backward Compatible DirectionPickerView

/// Backward compatible initializer using Direction enum
/// This allows existing code to continue working without modification
extension DirectionPickerView {
    /// Creates a DirectionPickerView with backward compatible Direction binding
    /// - Parameters:
    ///   - selectedDirection: Binding to the selected Direction enum
    ///   - style: The display style (default: .segmented)
    ///   - onDirectionChanged: Optional callback when direction changes (receives Direction)
    init(
        selectedDirection: Binding<Direction>,
        style: DirectionPickerStyle = .segmented,
        onDirectionChanged: ((Direction) -> Void)? = nil
    ) {
        // Create a binding that converts between Direction and String
        let directionIdBinding = Binding<String>(
            get: { selectedDirection.wrappedValue.directionId },
            set: { newId in
                if newId == "W" {
                    selectedDirection.wrappedValue = .mountainView
                } else {
                    selectedDirection.wrappedValue = .alumRock
                }
            }
        )
        
        self._selectedDirectionId = directionIdBinding
        self.lineDirections = nil  // Use default Orange Line directions
        self.style = style
        self.lineColorHex = "#F7931E"  // Orange Line color
        
        // Wrap the callback to convert String back to Direction
        if let callback = onDirectionChanged {
            self.onDirectionChanged = { directionId in
                let direction: Direction = directionId == "W" ? .mountainView : .alumRock
                callback(direction)
            }
        } else {
            self.onDirectionChanged = nil
        }
    }
}

// MARK: - Preview

#Preview("Segmented Style - Orange Line") {
    DirectionPickerView(
        selectedDirectionId: .constant("W"),
        lineDirections: [
            LineDirection(id: "W", headsign: "Mountain View"),
            LineDirection(id: "E", headsign: "Alum Rock")
        ],
        style: .segmented,
        lineColorHex: "#F7931E"
    )
    .padding()
}

#Preview("Buttons Style - Blue Line") {
    DirectionPickerView(
        selectedDirectionId: .constant("N"),
        lineDirections: [
            LineDirection(id: "N", headsign: "Baypointe"),
            LineDirection(id: "S", headsign: "Santa Teresa")
        ],
        style: .buttons,
        lineColorHex: "#0072BC"
    )
    .padding()
}

#Preview("Compact Style - Green Line") {
    DirectionPickerView(
        selectedDirectionId: .constant("N"),
        lineDirections: [
            LineDirection(id: "N", headsign: "Old Ironsides"),
            LineDirection(id: "S", headsign: "Winchester")
        ],
        style: .compact,
        lineColorHex: "#008752"
    )
    .padding()
}

#Preview("Inline Style - Backward Compatible") {
    DirectionPickerView(
        selectedDirection: .constant(.mountainView),
        style: .inline
    )
    .padding()
}
