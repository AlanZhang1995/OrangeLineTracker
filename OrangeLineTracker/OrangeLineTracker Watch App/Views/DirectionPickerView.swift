//
//  DirectionPickerView.swift
//  OrangeLineTracker Watch App
//
//  Reusable direction picker component for selecting travel direction on the Orange Line
//  - Validates: Requirements 2.1, 2.2, 2.4, 6.3
//

import SwiftUI

// MARK: - DirectionPickerView

/// A reusable view component for selecting the travel direction on the VTA Orange Line
/// Can be used in multiple places throughout the app (ArrivalView header, SettingsView, etc.)
/// - Validates: Requirements 2.1 (display two direction options), 2.2 (set selected direction on tap),
///              2.4 (use clear icons or text to identify direction), 6.3 (use simple buttons or segmented control)
struct DirectionPickerView: View {
    
    // MARK: - Properties
    
    /// Binding to the currently selected direction
    @Binding var selectedDirection: Direction
    
    /// Optional callback when direction changes
    var onDirectionChanged: ((Direction) -> Void)?
    
    /// Display style for the picker
    var style: DirectionPickerStyle
    
    // MARK: - Initialization
    
    /// Creates a DirectionPickerView
    /// - Parameters:
    ///   - selectedDirection: Binding to the selected direction
    ///   - style: The display style (default: .segmented)
    ///   - onDirectionChanged: Optional callback when direction changes
    init(
        selectedDirection: Binding<Direction>,
        style: DirectionPickerStyle = .segmented,
        onDirectionChanged: ((Direction) -> Void)? = nil
    ) {
        self._selectedDirection = selectedDirection
        self.style = style
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
    /// - Validates: Requirement 6.3 - use picker for direction switching
    private var segmentedPickerView: some View {
        VStack(spacing: 8) {
            // Direction label
            Text("方向")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Wheel picker (watchOS compatible)
            // Validates: Requirement 2.1 - display two direction options
            Picker("方向", selection: $selectedDirection) {
                ForEach(Direction.allCases, id: \.self) { direction in
                    HStack(spacing: 4) {
                        Image(systemName: direction.iconName)
                        Text(direction.shortDisplayName)
                    }
                    .tag(direction)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 60)
            .onChange(of: selectedDirection) { _, newValue in
                // Validates: Requirement 2.2 - set selected direction on tap
                onDirectionChanged?(newValue)
            }
        }
    }
    
    // MARK: - Buttons Picker View
    
    /// Button-based picker with icons and text
    /// - Validates: Requirements 2.1, 2.2, 2.4, 6.3
    private var buttonsPickerView: some View {
        VStack(spacing: 8) {
            // Direction label
            Text("选择方向")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Direction buttons
            // Validates: Requirement 2.1 - display two direction options
            HStack(spacing: 12) {
                ForEach(Direction.allCases, id: \.self) { direction in
                    DirectionButton(
                        direction: direction,
                        isSelected: selectedDirection == direction,
                        action: {
                            // Validates: Requirement 2.2 - set selected direction on tap
                            selectedDirection = direction
                            onDirectionChanged?(direction)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Compact Picker View
    
    /// Compact single-line picker for use in headers
    /// - Validates: Requirements 2.1, 2.2, 2.4
    private var compactPickerView: some View {
        HStack(spacing: 8) {
            ForEach(Direction.allCases, id: \.self) { direction in
                Button(action: {
                    // Validates: Requirement 2.2 - set selected direction on tap
                    selectedDirection = direction
                    onDirectionChanged?(direction)
                }) {
                    HStack(spacing: 4) {
                        // Validates: Requirement 2.4 - use clear icons to identify direction
                        Image(systemName: direction.iconName)
                            .font(.caption2)
                        Text(direction.shortDisplayName)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(selectedDirection == direction 
                                  ? Color.orange 
                                  : Color.orange.opacity(0.2))
                    )
                    .foregroundColor(selectedDirection == direction 
                                     ? .white 
                                     : .orange)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Inline Picker View
    
    /// Inline picker for use within lists or forms
    /// - Validates: Requirements 2.1, 2.2, 2.4
    private var inlinePickerView: some View {
        HStack {
            // Validates: Requirement 2.4 - use clear icons to identify direction
            Image(systemName: selectedDirection.iconName)
                .foregroundColor(.orange)
            
            Text(selectedDirection.displayName)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Toggle button
            Button(action: {
                // Validates: Requirement 2.2 - toggle direction on tap
                let newDirection: Direction = selectedDirection == .mountainView ? .alumRock : .mountainView
                selectedDirection = newDirection
                onDirectionChanged?(newDirection)
            }) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundColor(.orange)
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

// MARK: - DirectionButton

/// Individual direction button component
/// - Validates: Requirements 2.2, 2.4
struct DirectionButton: View {
    /// The direction this button represents
    let direction: Direction
    
    /// Whether this direction is currently selected
    let isSelected: Bool
    
    /// Action to perform when button is tapped
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Direction icon
                // Validates: Requirement 2.4 - use clear icons to identify direction
                Image(systemName: direction.iconName)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .orange)
                
                // Direction text
                // Validates: Requirement 2.4 - use clear text to identify direction
                Text(direction.shortDisplayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .orange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.orange : Color.orange.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(direction.displayName), \(isSelected ? "已选择" : "未选择")")
        .accessibilityHint(isSelected ? "当前选中的方向" : "双击选择此方向")
    }
}

// MARK: - Direction Extension

extension Direction {
    /// Icon name for the direction
    /// - Validates: Requirement 2.4 - use clear icons to identify direction
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

// MARK: - Preview

#Preview("Segmented Style") {
    DirectionPickerView(
        selectedDirection: .constant(.alumRock),
        style: .segmented
    )
    .padding()
}

#Preview("Buttons Style") {
    DirectionPickerView(
        selectedDirection: .constant(.mountainView),
        style: .buttons
    )
    .padding()
}

#Preview("Compact Style") {
    DirectionPickerView(
        selectedDirection: .constant(.alumRock),
        style: .compact
    )
    .padding()
}

#Preview("Inline Style") {
    DirectionPickerView(
        selectedDirection: .constant(.mountainView),
        style: .inline
    )
    .padding()
}
