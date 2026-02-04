//
//  ContentView.swift
//  OrangeLineTracker Watch App
//
//  Main view that organizes the app's page structure using TabView
//  - Validates: Requirements 6.1, 6.6
//

import SwiftUI

// MARK: - ContentView

/// Main view for the OrangeLineTracker app
/// Uses TabView to organize navigation between ArrivalView, StationPickerView, and SettingsView
/// - Validates: Requirements 6.1 (large font display), 6.6 (adapt to different Apple Watch screen sizes)
struct ContentView: View {
    
    // MARK: - State
    
    /// The currently selected tab
    @State private var selectedTab: Tab = .arrival
    
    // MARK: - Environment Objects
    
    /// Main ViewModel for metro data
    @StateObject private var metroViewModel: MetroViewModel
    
    /// ViewModel for time rule management
    @StateObject private var timeRuleViewModel: TimeRuleViewModel
    
    // MARK: - Initialization
    
    init() {
        // Initialize ViewModels with default services
        // API key is loaded from centralized configuration
        let storageService = StorageService()
        let vtaService = VTAService(apiKey: APIConfig.vtaAPIKey)
        let timeRuleService = TimeRuleService(storageService: storageService)
        
        _metroViewModel = StateObject(wrappedValue: MetroViewModel(
            vtaService: vtaService,
            storageService: storageService,
            timeRuleService: timeRuleService
        ))
        
        _timeRuleViewModel = StateObject(wrappedValue: TimeRuleViewModel(
            timeRuleService: timeRuleService,
            storageService: storageService
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Arrival Times Display
            ArrivalView(viewModel: metroViewModel)
                .tag(Tab.arrival)
            
            // Tab 2: Station Selection
            StationPickerView(viewModel: metroViewModel)
                .tag(Tab.stationPicker)
            
            // Tab 3: Settings
            SettingsView(
                metroViewModel: metroViewModel,
                timeRuleViewModel: timeRuleViewModel
            )
                .tag(Tab.settings)
        }
        .tabViewStyle(.verticalPage) // Supports Digital Crown navigation
        .onAppear {
            // Apply time rule if needed when app appears
            metroViewModel.applyTimeRuleIfNeeded()
        }
    }
}

// MARK: - Tab Enum

/// Enum representing the available tabs in the app
enum Tab: Int, CaseIterable {
    case arrival = 0
    case stationPicker = 1
    case settings = 2
    
    var title: String {
        switch self {
        case .arrival:
            return "到站时间"
        case .stationPicker:
            return "选择站点"
        case .settings:
            return "设置"
        }
    }
    
    var systemImage: String {
        switch self {
        case .arrival:
            return "clock.fill"
        case .stationPicker:
            return "tram.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

// MARK: - ArrivalView

/// View for displaying arrival times with large font display
/// Implements pull-to-refresh, loading indicators, and error states
/// - Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.3, 6.1, 6.4, 6.5
struct ArrivalView: View {
    @ObservedObject var viewModel: MetroViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Station and direction header
                stationHeader
                
                Divider()
                    .background(Color.orange.opacity(0.3))
                
                // Main content area
                mainContent
                
                // Cached data indicator - Validates: Requirement 5.5
                if viewModel.isShowingCachedData {
                    cachedDataIndicator
                }
                
                // Last updated time
                if let lastUpdated = viewModel.lastUpdatedDisplay {
                    Text(lastUpdated)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Refresh button - Validates: Requirement 4.6
                refreshButton
            }
            .padding()
        }
        // Pull-to-refresh gesture - Validates: Requirement 6.5
        .refreshable {
            await viewModel.refreshPredictions()
        }
        .navigationTitle("到站时间")
        .onAppear {
            // Auto-refresh when view appears if we have a station selected
            if viewModel.selectedStation != nil && viewModel.predictions.isEmpty && !viewModel.isLoading {
                Task {
                    await viewModel.refreshPredictions()
                }
            }
        }
    }
    
    // MARK: - Station Header
    
    /// Displays the current station and direction with quick direction switching
    @ViewBuilder
    private var stationHeader: some View {
        if let station = viewModel.selectedStation {
            VStack(spacing: 6) {
                Text(station.name)
                    .font(.headline)
                    .foregroundColor(.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Compact direction picker for quick switching
                // Validates: Requirements 2.1, 2.2, 2.4, 6.3
                DirectionPickerView(
                    selectedDirection: Binding(
                        get: { viewModel.selectedDirection },
                        set: { viewModel.selectDirection($0) }
                    ),
                    style: .compact
                )
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "tram.fill")
                    .font(.title2)
                    .foregroundColor(.orange.opacity(0.6))
                
                Text("请选择站点")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Main Content
    
    /// Main content area showing loading, error, arrival time, or no data state
    @ViewBuilder
    private var mainContent: some View {
        // Loading indicator - Validates: Requirement 6.4
        if viewModel.isLoading {
            loadingView
        }
        // Error message with cached data fallback
        else if let errorMessage = viewModel.errorMessage {
            if viewModel.isShowingCachedData, let prediction = viewModel.nextPrediction {
                // Show cached prediction with error indicator
                arrivalTimeView(prediction: prediction, isCached: true)
            } else {
                // Show error state
                errorView(message: errorMessage)
            }
        }
        // Arrival time display - Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 6.1
        else if let prediction = viewModel.nextPrediction {
            arrivalTimeView(prediction: prediction, isCached: false)
        }
        // No data - Validates: Requirement 5.3
        else if viewModel.selectedStation != nil {
            noDataView
        }
    }
    
    // MARK: - Loading View
    
    /// Loading indicator view - Validates: Requirement 6.4
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(.orange)
            
            Text("加载中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Arrival Time View
    
    /// Large font arrival time display
    /// - Parameters:
    ///   - prediction: The prediction to display
    ///   - isCached: Whether this is cached data
    /// - Validates: Requirements 4.1, 4.2, 4.3, 4.4, 6.1
    private func arrivalTimeView(prediction: Prediction, isCached: Bool) -> some View {
        VStack(spacing: 8) {
            // Large font arrival time - Validates: Requirement 6.1 (48pt+ font)
            Text(prediction.arrivalTimeDisplay)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(isCached ? .orange.opacity(0.7) : .orange)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            // Show additional predictions if available
            if viewModel.predictions.count > 1 {
                additionalPredictionsView
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Additional Predictions View
    
    /// Shows the next few predictions after the first one
    private var additionalPredictionsView: some View {
        VStack(spacing: 4) {
            Divider()
                .background(Color.secondary.opacity(0.3))
                .padding(.vertical, 4)
            
            Text("后续列车")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ForEach(Array(viewModel.predictions.dropFirst().prefix(2))) { prediction in
                HStack {
                    Text(prediction.arrivalTimeDisplay)
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.8))
                    
                    Spacer()
                    
                    Text("→ \(prediction.destination)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Error View
    
    /// Error state display - Validates: Requirements 5.1, 5.2, 5.4
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
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - No Data View
    
    /// No train information display - Validates: Requirement 5.3
    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tram")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("暂无列车信息")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("请稍后刷新或检查运营时间")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Cached Data Indicator
    
    /// Indicator showing that cached data is being displayed
    private var cachedDataIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption2)
            Text("显示缓存数据")
                .font(.caption2)
        }
        .foregroundColor(.orange.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
    
    // MARK: - Refresh Button
    
    /// Manual refresh button - Validates: Requirement 4.6
    private var refreshButton: some View {
        Button(action: {
            Task {
                await viewModel.refreshPredictions()
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
        .disabled(viewModel.isLoading || viewModel.selectedStation == nil)
    }
}

// MARK: - StationPickerView

/// View for selecting a station from the Orange Line
/// Uses a compact Picker menu instead of full list for better usability
/// - Validates: Requirements 1.1, 1.2, 1.3, 1.5, 6.2
struct StationPickerView: View {
    @ObservedObject var viewModel: MetroViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with current selection
                VStack(spacing: 8) {
                    Image(systemName: "tram.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("选择站点")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("橙线 \(OrangeLineStations.count) 站")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                Divider()
                    .background(Color.orange.opacity(0.3))
                
                // Station picker menu
                // Validates: Requirements 1.1, 1.2, 1.3
                Picker("站点", selection: Binding(
                    get: { viewModel.selectedStation?.id ?? OrangeLineStations.first.id },
                    set: { newId in
                        if let station = OrangeLineStations.station(byId: newId) {
                            viewModel.selectStation(station)
                        }
                    }
                )) {
                    ForEach(OrangeLineStations.stations) { station in
                        Text(station.name)
                            .tag(station.id)
                    }
                }
                .pickerStyle(.navigationLink)
                .tint(.orange)
                
                // Current selection display
                if let station = viewModel.selectedStation {
                    VStack(spacing: 8) {
                        Divider()
                            .background(Color.orange.opacity(0.3))
                        
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("已选择")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text(station.name)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                            
                            Text(station.shortName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle("选择站点")
    }
}

// MARK: - StationRowView

/// Individual station row in the picker list
/// Displays station name, short name, and selection state
/// - Validates: Requirements 1.2, 1.5
struct StationRowView: View {
    /// The station to display
    let station: Station
    
    /// Whether this station is currently selected
    let isSelected: Bool
    
    /// Action to perform when station is selected
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Station order indicator
                stationOrderIndicator
                
                // Station name and short name
                // Validates: Requirement 1.5 - Display full station name
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? .orange : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(station.shortName)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .orange.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                // Selection indicator
                // Validates: Requirement 1.2 - Highlight selected station
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isSelected
                ? Color.orange.opacity(0.2)
                : Color.clear
        )
        .accessibilityLabel("\(station.name), \(isSelected ? "已选择" : "未选择")")
        .accessibilityHint(isSelected ? "当前选中的站点" : "双击选择此站点")
    }
    
    // MARK: - Station Order Indicator
    
    /// Visual indicator showing the station's position on the line
    private var stationOrderIndicator: some View {
        ZStack {
            // Line segment
            Rectangle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 3)
            
            // Station dot
            Circle()
                .fill(isSelected ? Color.orange : Color.orange.opacity(0.6))
                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
            
            // Terminal station indicator (first or last)
            if station.order == 0 || station.order == OrangeLineStations.count - 1 {
                Circle()
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: 16, height: 16)
            }
        }
        .frame(width: 20, height: 36)
    }
}

// MARK: - SettingsView

/// View for app settings including time rule configuration
/// Provides toggle for enabling/disabling time rule feature and navigation to time rule configuration
/// - Validates: Requirement 8.6 (allow users to enable or disable time rule feature)
struct SettingsView: View {
    @ObservedObject var metroViewModel: MetroViewModel
    @ObservedObject var timeRuleViewModel: TimeRuleViewModel
    
    var body: some View {
        NavigationStack {
            List {
                // Time rule section - Validates: Requirement 8.6
                // THE Time_Rule_Manager SHALL 允许用户启用或禁用时间规则功能
                timeRuleSection
                
                // Direction selection section using DirectionPickerView
                // Validates: Requirements 2.1, 2.2, 2.4, 6.3
                directionSection
                
                // Current settings summary
                currentSettingsSection
            }
            .navigationTitle("设置")
        }
    }
    
    // MARK: - Time Rule Section
    
    /// Section for time rule feature toggle and configuration navigation
    /// - Validates: Requirement 8.6 - allow users to enable or disable time rule feature
    private var timeRuleSection: some View {
        Section {
            // Time rule feature toggle
            // Validates: Requirement 8.6 - enable/disable time rule feature
            Toggle(isOn: Binding(
                get: { timeRuleViewModel.isTimeRuleEnabled },
                set: { timeRuleViewModel.setGlobalTimeRuleEnabled($0) }
            )) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .foregroundColor(.orange)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("自动切换")
                            .font(.body)
                        
                        Text("根据时间自动切换站点和方向")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(.orange)
            
            // Navigation to time rule configuration
            // Only shown when time rule feature is enabled
            if timeRuleViewModel.isTimeRuleEnabled {
                NavigationLink {
                    TimeRuleConfigView(viewModel: timeRuleViewModel)
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(.orange)
                            .font(.body)
                        
                        Text("配置规则")
                        
                        Spacer()
                        
                        // Show enabled rule count badge
                        Text("\(timeRuleViewModel.enabledRuleCount) 条")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(timeRuleViewModel.enabledRuleCount > 0 ? Color.orange : Color.secondary)
                            )
                    }
                }
                
                // Show active rule status if time rules are active
                if timeRuleViewModel.isTimeRuleActive {
                    activeRuleStatusView
                }
            }
        } header: {
            Label("时间规则", systemImage: "clock.fill")
                .foregroundColor(.orange)
        } footer: {
            if timeRuleViewModel.isTimeRuleEnabled {
                Text(timeRuleViewModel.configurationSummary)
                    .font(.caption2)
            } else {
                Text("启用后可根据时间自动切换通勤设置")
                    .font(.caption2)
            }
        }
    }
    
    // MARK: - Active Rule Status View
    
    /// Shows the currently active time rule if any
    private var activeRuleStatusView: some View {
        Group {
            if let activeRule = timeRuleViewModel.currentActiveRule {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("当前生效")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text(activeRule.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(activeRule.triggerTimeDisplay)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Direction Section
    
    /// Section for direction selection using DirectionPickerView
    /// - Validates: Requirements 2.1, 2.2, 2.4, 6.3
    private var directionSection: some View {
        Section {
            DirectionPickerView(
                selectedDirection: Binding(
                    get: { metroViewModel.selectedDirection },
                    set: { metroViewModel.selectDirection($0) }
                ),
                style: .buttons
            )
            .listRowBackground(Color.clear)
        } header: {
            Label("方向", systemImage: "arrow.left.arrow.right")
                .foregroundColor(.orange)
        }
    }
    
    // MARK: - Current Settings Section
    
    /// Section displaying current settings summary
    private var currentSettingsSection: some View {
        Section {
            // Current station
            HStack(spacing: 8) {
                Image(systemName: "tram.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("站点")
                
                Spacer()
                
                if let station = metroViewModel.selectedStation {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(station.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(station.shortName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("未选择")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Current direction
            HStack(spacing: 8) {
                Image(systemName: metroViewModel.selectedDirection.iconName)
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("方向")
                
                Spacer()
                
                Text(metroViewModel.selectedDirection.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Time rule status indicator
            if timeRuleViewModel.isTimeRuleEnabled && timeRuleViewModel.isTimeRuleActive {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("自动切换")
                    
                    Spacer()
                    
                    Text("已启用")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        } header: {
            Label("当前设置", systemImage: "info.circle")
                .foregroundColor(.orange)
        }
    }
}

// MARK: - TimeRuleConfigView

/// View for configuring time rules
/// Provides full CRUD operations for time-based automatic station/direction switching
/// - Validates: Requirements 8.1 (configure time rules), 8.2 (save trigger time, station, direction), 8.4 (support multiple rules)
struct TimeRuleConfigView: View {
    @ObservedObject var viewModel: TimeRuleViewModel
    
    /// State for showing the add rule sheet
    @State private var showingAddRule = false
    
    /// State for the rule being edited (nil when not editing)
    @State private var editingRule: TimeRule?
    
    var body: some View {
        List {
            // Rules list section
            if viewModel.timeRules.isEmpty {
                emptyStateView
            } else {
                rulesSection
            }
            
            // Add rule button section
            addRuleSection
        }
        .navigationTitle("时间规则")
        .sheet(isPresented: $showingAddRule) {
            // Add new rule sheet
            TimeRuleEditView(
                viewModel: viewModel,
                mode: .add,
                onSave: { rule in
                    viewModel.addRule(rule)
                    showingAddRule = false
                },
                onCancel: {
                    showingAddRule = false
                }
            )
        }
        .sheet(item: $editingRule) { rule in
            // Edit existing rule sheet
            TimeRuleEditView(
                viewModel: viewModel,
                mode: .edit(rule),
                onSave: { updatedRule in
                    viewModel.updateRule(updatedRule)
                    editingRule = nil
                },
                onCancel: {
                    editingRule = nil
                }
            )
        }
    }
    
    // MARK: - Empty State View
    
    /// View shown when no rules are configured
    private var emptyStateView: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 36))
                    .foregroundColor(.orange.opacity(0.6))
                
                Text("暂无时间规则")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("添加规则以自动切换通勤设置")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Rules Section
    
    /// Section displaying all configured rules
    /// - Validates: Requirements 8.1, 8.2
    private var rulesSection: some View {
        Section {
            ForEach(viewModel.rulesSortedByTime) { rule in
                TimeRuleRowView(
                    rule: rule,
                    onToggleEnabled: {
                        // Toggle rule enabled state
                        viewModel.toggleRuleEnabled(rule)
                    },
                    onEdit: {
                        // Open edit sheet
                        editingRule = rule
                    }
                )
            }
            // Swipe to delete - Validates: Requirement 8.1 (delete rules)
            .onDelete { offsets in
                // Convert offsets from sorted array to actual rules
                let sortedRules = viewModel.rulesSortedByTime
                let rulesToDelete = offsets.map { sortedRules[$0] }
                for rule in rulesToDelete {
                    viewModel.deleteRule(rule)
                }
            }
        } header: {
            HStack {
                Text("已配置规则")
                Spacer()
                Text("\(viewModel.ruleCount) 条")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } footer: {
            Text("向左滑动删除规则，点击编辑")
                .font(.caption2)
        }
    }
    
    // MARK: - Add Rule Section
    
    /// Section with add rule button
    /// - Validates: Requirement 8.4 (support multiple rules)
    private var addRuleSection: some View {
        Section {
            Button(action: {
                showingAddRule = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    Text("添加规则")
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - TimeRuleRowView

/// Row view for displaying a single time rule in the list
/// - Validates: Requirements 8.1, 8.2
struct TimeRuleRowView: View {
    /// The rule to display
    let rule: TimeRule
    
    /// Action when enable toggle is tapped
    let onToggleEnabled: () -> Void
    
    /// Action when edit is requested
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 8) {
                // Enable/disable toggle indicator
                // Validates: Requirement 8.1 (enable/disable individual rules)
                Button(action: onToggleEnabled) {
                    Image(systemName: rule.isEnabled ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(rule.isEnabled ? .green : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                
                // Rule details
                VStack(alignment: .leading, spacing: 4) {
                    // Rule name
                    Text(rule.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(rule.isEnabled ? .primary : .secondary)
                        .lineLimit(1)
                    
                    // Rule configuration summary
                    HStack(spacing: 4) {
                        // Trigger time - Validates: Requirement 8.2
                        Text(rule.triggerTimeDisplay)
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                        
                        // Station - Validates: Requirement 8.2
                        if let station = OrangeLineStations.station(byId: rule.stationId) {
                            Text(station.shortName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Direction arrow
                        Image(systemName: rule.direction == .mountainView ? "arrow.left" : "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Edit indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            rule.isEnabled
                ? Color.orange.opacity(0.1)
                : Color.clear
        )
        .accessibilityLabel("\(rule.name), \(rule.isEnabled ? "已启用" : "已禁用"), \(rule.triggerTimeDisplay)")
        .accessibilityHint("双击编辑规则")
    }
}

// MARK: - TimeRuleEditView

/// View for adding or editing a time rule
/// Provides time picker, station picker, direction picker, and enable toggle
/// - Validates: Requirements 8.1, 8.2, 8.4
struct TimeRuleEditView: View {
    /// Reference to the view model for validation
    @ObservedObject var viewModel: TimeRuleViewModel
    
    /// Edit mode (add new or edit existing)
    let mode: TimeRuleEditMode
    
    /// Callback when save is requested
    let onSave: (TimeRule) -> Void
    
    /// Callback when cancel is requested
    let onCancel: () -> Void
    
    // MARK: - State
    
    /// Rule name
    @State private var name: String = ""
    
    /// Trigger time (hour and minute)
    @State private var triggerTime: Date = Date()
    
    /// Selected station ID
    @State private var selectedStationId: String = OrangeLineStations.first.id
    
    /// Selected direction
    @State private var selectedDirection: Direction = .alumRock
    
    /// Whether the rule is enabled
    @State private var isEnabled: Bool = true
    
    /// Whether to show station picker
    @State private var showingStationPicker = false
    
    /// Whether initial values have been loaded
    @State private var hasLoadedInitialValues = false
    
    /// Validation error message
    @State private var validationError: String?
    
    // MARK: - Computed Properties
    
    /// The rule ID (for editing) or nil (for adding)
    private var ruleId: UUID? {
        if case .edit(let rule) = mode {
            return rule.id
        }
        return nil
    }
    
    /// Title for the view
    private var title: String {
        switch mode {
        case .add:
            return "添加规则"
        case .edit:
            return "编辑规则"
        }
    }
    
    /// The currently selected station
    private var selectedStation: Station? {
        OrangeLineStations.station(byId: selectedStationId)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Rule name input
                    nameSection
                    
                    // Time picker section - Validates: Requirement 8.2 (trigger time)
                    timePickerSection
                    
                    // Station picker section - Validates: Requirement 8.2 (target station)
                    stationPickerSection
                    
                    // Direction picker section - Validates: Requirement 8.2 (target direction)
                    directionPickerSection
                    
                    // Enable toggle section - Validates: Requirement 8.1 (enable/disable)
                    enableToggleSection
                    
                    // Validation error display
                    if let error = validationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Action buttons
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Only load initial values once to prevent resetting after navigation
                if !hasLoadedInitialValues {
                    loadInitialValues()
                    hasLoadedInitialValues = true
                }
            }
            .navigationDestination(isPresented: $showingStationPicker) {
                StationSelectionViewInline(
                    selectedStationId: $selectedStationId,
                    onDismiss: {
                        showingStationPicker = false
                    }
                )
            }
        }
    }
    
    // MARK: - Name Section
    
    /// Section for entering rule name
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("规则名称", systemImage: "tag")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("例如：早班通勤", text: $name)
                .textFieldStyle(.plain)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                )
        }
    }
    
    // MARK: - Time Picker Section
    
    /// Section for selecting trigger time (hour and minute)
    /// - Validates: Requirement 8.2 (save trigger time)
    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("触发时间", systemImage: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Time picker showing only hour and minute
            DatePicker(
                "时间",
                selection: $triggerTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 80)
        }
    }
    
    // MARK: - Station Picker Section
    
    /// Section for selecting target station
    /// - Validates: Requirement 8.2 (save target station)
    private var stationPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("目标站点", systemImage: "tram.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingStationPicker = true
            }) {
                HStack {
                    if let station = selectedStation {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(station.name)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(station.shortName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("选择站点")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Direction Picker Section
    
    /// Section for selecting target direction
    /// - Validates: Requirement 8.2 (save target direction)
    private var directionPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("目标方向", systemImage: "arrow.left.arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
            
            DirectionPickerView(
                selectedDirection: $selectedDirection,
                style: .buttons
            )
        }
    }
    
    // MARK: - Enable Toggle Section
    
    /// Section for enabling/disabling the rule
    /// - Validates: Requirement 8.1 (enable/disable rules)
    private var enableToggleSection: some View {
        Toggle(isOn: $isEnabled) {
            HStack(spacing: 8) {
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isEnabled ? .green : .secondary)
                
                Text("启用规则")
            }
        }
        .tint(.green)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }
    
    // MARK: - Action Buttons Section
    
    /// Section with save and cancel buttons
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Cancel button
            Button(action: onCancel) {
                Text("取消")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Save button
            Button(action: saveRule) {
                Text("保存")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(!isValidInput)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Validation
    
    /// Whether the current input is valid
    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        viewModel.isValidStationId(selectedStationId)
    }
    
    // MARK: - Actions
    
    /// Loads initial values based on edit mode
    private func loadInitialValues() {
        switch mode {
        case .add:
            // Default values for new rule
            name = ""
            triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 0)
            selectedStationId = OrangeLineStations.first.id
            selectedDirection = .alumRock
            isEnabled = true
            
        case .edit(let rule):
            // Load existing rule values
            name = rule.name
            triggerTime = rule.triggerTime
            selectedStationId = rule.stationId
            selectedDirection = rule.direction
            isEnabled = rule.isEnabled
        }
    }
    
    /// Validates and saves the rule
    private func saveRule() {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationError = "请输入规则名称"
            return
        }
        
        // Validate station
        guard viewModel.isValidStationId(selectedStationId) else {
            validationError = "请选择有效的站点"
            return
        }
        
        // Check for conflicting time (optional warning)
        if viewModel.hasConflictingRule(triggerTime: triggerTime, excludingRuleId: ruleId) {
            // Allow saving but could show warning
        }
        
        // Create or update rule
        let rule: TimeRule
        if let existingId = ruleId {
            // Update existing rule
            rule = TimeRule(
                id: existingId,
                name: trimmedName,
                triggerTime: triggerTime,
                stationId: selectedStationId,
                direction: selectedDirection,
                isEnabled: isEnabled
            )
        } else {
            // Create new rule
            rule = TimeRule(
                name: trimmedName,
                triggerTime: triggerTime,
                stationId: selectedStationId,
                direction: selectedDirection,
                isEnabled: isEnabled
            )
        }
        
        validationError = nil
        onSave(rule)
    }
}

// MARK: - TimeRuleEditMode

/// Mode for the TimeRuleEditView
enum TimeRuleEditMode {
    /// Adding a new rule
    case add
    /// Editing an existing rule
    case edit(TimeRule)
}

// MARK: - StationSelectionView

/// View for selecting a station from the Orange Line
/// Used within TimeRuleEditView for station selection
struct StationSelectionView: View {
    /// Binding to the selected station ID
    @Binding var selectedStationId: String
    
    /// Callback when view should be dismissed
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(OrangeLineStations.stations) { station in
                    Button(action: {
                        selectedStationId = station.id
                        onDismiss()
                    }) {
                        HStack(spacing: 12) {
                            // Station order indicator
                            ZStack {
                                Circle()
                                    .fill(selectedStationId == station.id ? Color.orange : Color.orange.opacity(0.3))
                                    .frame(width: 24, height: 24)
                                
                                Text("\(station.order + 1)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedStationId == station.id ? .white : .orange)
                            }
                            
                            // Station info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(station.name)
                                    .font(.body)
                                    .foregroundColor(selectedStationId == station.id ? .orange : .primary)
                                    .lineLimit(1)
                                
                                Text(station.shortName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Selection indicator
                            if selectedStationId == station.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        selectedStationId == station.id
                            ? Color.orange.opacity(0.15)
                            : Color.clear
                    )
                }
            }
            .listStyle(.carousel)
            .navigationTitle("选择站点")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        onDismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - StationSelectionViewInline

/// Inline version of station selection view for use with navigationDestination
/// Avoids nested NavigationStack issues on watchOS
struct StationSelectionViewInline: View {
    /// Binding to the selected station ID
    @Binding var selectedStationId: String
    
    /// Callback when view should be dismissed
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(OrangeLineStations.stations) { station in
                Button(action: {
                    selectedStationId = station.id
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        // Station order indicator
                        ZStack {
                            Circle()
                                .fill(selectedStationId == station.id ? Color.orange : Color.orange.opacity(0.3))
                                .frame(width: 24, height: 24)
                            
                            Text("\(station.order + 1)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedStationId == station.id ? .white : .orange)
                        }
                        
                        // Station info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(station.name)
                                .font(.body)
                                .foregroundColor(selectedStationId == station.id ? .orange : .primary)
                                .lineLimit(1)
                            
                            Text(station.shortName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Selection indicator
                        if selectedStationId == station.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    selectedStationId == station.id
                        ? Color.orange.opacity(0.15)
                        : Color.clear
                )
            }
        }
        .listStyle(.carousel)
        .navigationTitle("选择站点")
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
