//
//  ContentView.swift
//  OrangeLineTracker Watch App
//
//  Main view that organizes the app's page structure using TabView
//  - Validates: Requirements 6.1, 6.6, 10.1, 10.3
//

import SwiftUI
import Combine

// MARK: - ContentView

/// Main view for the OrangeLineTracker app
/// Uses TabView to organize navigation between ArrivalView, LineSelectorView, StationPickerView, and SettingsView
/// - Validates: Requirements 6.1 (large font display), 6.6 (adapt to different Apple Watch screen sizes)
/// - Validates: Requirements 10.1 (display current line name), 10.3 (guide user to select line first)
struct ContentView: View {
    
    // MARK: - State
    
    /// The currently selected tab
    @State private var selectedTab: Tab = .arrival
    
    // MARK: - Environment Objects
    
    /// Main ViewModel for metro data
    @StateObject private var metroViewModel: MetroViewModel
    
    /// ViewModel for line selection and management
    @StateObject private var lineViewModel: LineViewModel
    
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
        
        _lineViewModel = StateObject(wrappedValue: LineViewModel(
            vtaService: vtaService,
            storageService: storageService
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
            
            // Tab 2: Line Selection
            // - Validates: Requirements 10.1, 10.3
            LineSelectorView(viewModel: lineViewModel) { selectedLine in
                // When a line is selected, update MetroViewModel
                // - Validates: Requirements 4.3, 4.5 - navigation flow: Line → Station → Direction → Arrival
                metroViewModel.selectLine(selectedLine)
                
                // Navigate to station picker after line selection
                selectedTab = .stationPicker
            }
            .tag(Tab.linePicker)
            
            // Tab 3: Station Selection
            StationPickerView(viewModel: metroViewModel)
                .tag(Tab.stationPicker)
            
            // Tab 4: Settings
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
            
            // Load lines when app appears
            Task {
                await lineViewModel.loadLines()
                
                // Sync selected line from MetroViewModel to LineViewModel
                if let selectedLine = metroViewModel.selectedLine {
                    lineViewModel.selectedLine = selectedLine
                }
            }
            
            // If no line is selected, guide user to select one first
            // - Validates: Requirement 10.3 - guide user to select line first
            if metroViewModel.selectedLine == nil {
                selectedTab = .linePicker
            }
        }
        .onChange(of: lineViewModel.selectedLine) { _, newLine in
            // Sync line selection from LineViewModel to MetroViewModel
            if let line = newLine, metroViewModel.selectedLine?.id != line.id {
                metroViewModel.selectLine(line)
            }
        }
    }
}

// MARK: - Tab Enum

/// Enum representing the available tabs in the app
/// Tab order: Arrival → Line → Station → Settings
/// - Validates: Requirements 10.1, 10.3 - navigation flow supports line selection
enum Tab: Int, CaseIterable {
    case arrival = 0
    case linePicker = 1
    case stationPicker = 2
    case settings = 3
    
    var title: String {
        switch self {
        case .arrival:
            return "到站时间"
        case .linePicker:
            return "选择线路"
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
        case .linePicker:
            return "tram.circle.fill"
        case .stationPicker:
            return "mappin.circle.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

// MARK: - ArrivalView

/// View for displaying arrival times with large font display
/// Implements pull-to-refresh, loading indicators, and error states
/// Uses Timer for real-time countdown updates and auto-refresh at each minute mark (:00 seconds)
/// - Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.3, 6.1, 6.4, 6.5
/// - Validates: Requirements 10.1 (display current line name), 10.2 (use line color as theme)
struct ArrivalView: View {
    @ObservedObject var viewModel: MetroViewModel
    @ObservedObject private var languageService = LanguageService.shared
    
    /// Current time for countdown calculation, triggers view refresh
    @State private var currentTime = Date()
    
    /// Timer for refreshing at each minute mark (:00 seconds)
    @State private var minuteTimer: Timer?
    
    // MARK: - Computed Properties
    
    /// The color for the current line (parsed from hex)
    /// Falls back to orange if parsing fails
    /// - Validates: Requirement 10.2 - use line color as theme color
    private var lineColor: Color {
        Color(hex: viewModel.lineColorHex) ?? .orange
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Station and direction header
                stationHeader
                
                Divider()
                    .background(lineColor.opacity(0.3))
                
                // Main content area with current time
                mainContent(currentTime: currentTime)
                
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
        .navigationTitle(L10n.arrivalTime)
        .onAppear {
            // Reset current time when view appears
            currentTime = Date()
            
            // Auto-refresh when view appears if we have a station selected
            if viewModel.selectedStation != nil && viewModel.predictions.isEmpty && !viewModel.isLoading {
                Task {
                    await viewModel.refreshPredictions()
                }
            }
            
            // Schedule timer to fire at next minute mark
            scheduleMinuteTimer()
        }
        .onDisappear {
            // Clean up timer when view disappears
            minuteTimer?.invalidate()
            minuteTimer = nil
        }
    }
    
    // MARK: - Minute Timer Scheduling
    
    /// Schedules a timer to fire at the next minute mark (:00 seconds)
    /// Timer is added to .common RunLoop mode to ensure it fires even during scrolling
    private func scheduleMinuteTimer() {
        // Invalidate existing timer
        minuteTimer?.invalidate()
        minuteTimer = nil
        
        // Calculate seconds until next minute mark
        let now = Date()
        let calendar = Calendar.current
        let seconds = calendar.component(.second, from: now)
        let nanoseconds = calendar.component(.nanosecond, from: now)
        
        // Calculate precise time until next minute mark (add small buffer to ensure we're past :00)
        let secondsUntilNextMinute = Double(60 - seconds) - Double(nanoseconds) / 1_000_000_000.0 + 0.1
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        print("ArrivalView: ⏰ Scheduling timer to fire in \(String(format: "%.1f", secondsUntilNextMinute))s (current: \(formatter.string(from: now)))")
        
        // Schedule repeating timer that fires every 60 seconds starting at next minute mark
        let timer = Timer(timeInterval: secondsUntilNextMinute, repeats: false) { _ in
            // This closure captures self, but since ArrivalView is a struct and
            // the timer is invalidated in onDisappear, this is safe
            self.onMinuteMark()
            
            // Reschedule for next minute
            DispatchQueue.main.async {
                self.scheduleMinuteTimer()
            }
        }
        
        // Add timer to .common mode to ensure it fires during scrolling
        RunLoop.main.add(timer, forMode: .common)
        minuteTimer = timer
    }
    
    /// Called at each minute mark (:00 seconds)
    private func onMinuteMark() {
        currentTime = Date()
        
        // Refresh API data at each minute mark
        if viewModel.selectedStation != nil && !viewModel.isLoading {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            print("ArrivalView: 🔄 Auto-refreshing at minute mark \(formatter.string(from: currentTime))")
            Task {
                await viewModel.refreshPredictions()
            }
        }
    }
    
    // MARK: - Station Header
    
    /// Displays the current line, station and direction with quick direction switching
    /// - Validates: Requirements 10.1 (display current line name), 10.2 (use line color as theme)
    @ViewBuilder
    private var stationHeader: some View {
        if let station = viewModel.selectedStation {
            VStack(spacing: 6) {
                // Line name display - Validates: Requirement 10.1
                if let line = viewModel.selectedLine {
                    HStack(spacing: 4) {
                        Image(systemName: line.type == .lightRail ? "tram.fill" : "bus.fill")
                            .font(.caption2)
                        Text(line.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(lineColor)
                }
                
                Text(station.name)
                    .font(.headline)
                    .foregroundColor(lineColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Compact direction picker for quick switching
                // Validates: Requirements 2.1, 2.2, 2.4, 6.3, 5.2, 10.2
                DirectionPickerView(
                    selectedDirectionId: Binding(
                        get: { viewModel.selectedDirectionId },
                        set: { viewModel.selectDirection(byId: $0) }
                    ),
                    lineDirections: viewModel.lineDirections,
                    style: .compact,
                    lineColorHex: viewModel.lineColorHex
                )
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "tram.fill")
                    .font(.title2)
                    .foregroundColor(lineColor.opacity(0.6))
                
                Text(L10n.pleaseSelectStation)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Main Content
    
    /// Main content area showing loading, error, arrival time, or no data state
    /// - Parameter currentTime: Current time for real-time countdown calculation
    @ViewBuilder
    private func mainContent(currentTime: Date) -> some View {
        // Loading indicator - Validates: Requirement 6.4
        if viewModel.isLoading {
            loadingView
        }
        // Error message with cached data fallback
        else if let errorMessage = viewModel.errorMessage {
            if viewModel.isShowingCachedData, let prediction = viewModel.nextPrediction {
                // Show cached prediction with error indicator
                arrivalTimeView(prediction: prediction, isCached: true, currentTime: currentTime)
            } else {
                // Show error state
                errorView(message: errorMessage)
            }
        }
        // Arrival time display - Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 6.1
        else if let prediction = viewModel.nextPrediction {
            arrivalTimeView(prediction: prediction, isCached: false, currentTime: currentTime)
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
                .tint(lineColor)
            
            Text(L10n.loading)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Arrival Time View
    
    /// Large font arrival time display with real-time countdown
    /// - Parameters:
    ///   - prediction: The prediction to display
    ///   - isCached: Whether this is cached data
    ///   - currentTime: Current time for countdown calculation
    /// - Validates: Requirements 4.1, 4.2, 4.3, 4.4, 6.1, 10.2
    private func arrivalTimeView(prediction: Prediction, isCached: Bool, currentTime: Date) -> some View {
        VStack(spacing: 8) {
            // Large font arrival time with real-time countdown - Validates: Requirement 6.1 (48pt+ font)
            Text(prediction.arrivalTimeDisplay(at: currentTime))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(isCached ? lineColor.opacity(0.7) : lineColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            // Show additional predictions if available
            if viewModel.predictions.count > 1 {
                additionalPredictionsView(currentTime: currentTime)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Additional Predictions View
    
    /// Shows the next few predictions after the first one with real-time countdown
    /// - Parameter currentTime: Current time for countdown calculation
    private func additionalPredictionsView(currentTime: Date) -> some View {
        VStack(spacing: 4) {
            Divider()
                .background(Color.secondary.opacity(0.3))
                .padding(.vertical, 4)
            
            Text(L10n.nextTrains)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ForEach(Array(viewModel.predictions.dropFirst().prefix(2))) { prediction in
                HStack {
                    Text(prediction.arrivalTimeDisplay(at: currentTime))
                        .font(.caption)
                        .foregroundColor(lineColor.opacity(0.8))
                    
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
            
            Text(L10n.noTrainInfo)
                .font(.body)
                .foregroundColor(.secondary)
            
            Text(L10n.checkSchedule)
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
            Text(L10n.showingCachedData)
                .font(.caption2)
        }
        .foregroundColor(lineColor.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(lineColor.opacity(0.15))
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
                Text(L10n.refresh)
                    .font(.caption)
            }
        }
        .buttonStyle(.bordered)
        .tint(lineColor)
        .disabled(viewModel.isLoading || viewModel.selectedStation == nil)
    }
}

// MARK: - StationPickerView

/// View for selecting a line and station using dropdown menus
/// Combines line and station selection into one page for simplicity
/// - Validates: Requirements 1.1, 1.2, 1.3, 1.5, 4.1, 4.2, 4.4, 6.2
struct StationPickerView: View {
    @ObservedObject var viewModel: MetroViewModel
    @ObservedObject private var languageService = LanguageService.shared
    
    /// The color for the current line (parsed from hex)
    private var lineColor: Color {
        Color(hex: viewModel.lineColorHex) ?? .orange
    }
    
    /// The stations for the current line, sorted by order
    private var stations: [Station] {
        viewModel.lineStations
    }
    
    /// All available lines
    private var allLines: [Line] {
        viewModel.allLines
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "tram.fill")
                        .font(.title2)
                        .foregroundColor(lineColor)
                    
                    Text(L10n.selectLineAndStation)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.top, 8)
                
                Divider()
                    .background(lineColor.opacity(0.3))
                
                // Line picker dropdown
                linePicker
                
                // Station picker dropdown (only show if line is selected)
                if viewModel.selectedLine != nil && !stations.isEmpty {
                    stationPicker
                }
            }
            .padding()
        }
        .navigationTitle(L10n.selectStation)
        .task {
            // Load lines when view appears
            if viewModel.allLines.isEmpty {
                await viewModel.loadAllLines()
            }
        }
    }
    
    // MARK: - Line Picker
    
    /// Dropdown picker for selecting a line
    private var linePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.line)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker(L10n.line, selection: Binding(
                get: { viewModel.selectedLine?.id ?? "" },
                set: { newId in
                    if let line = allLines.first(where: { $0.id == newId }) {
                        viewModel.selectLine(line)
                    }
                }
            )) {
                Text(L10n.pleaseSelectLine)
                    .tag("")
                
                ForEach(allLines) { line in
                    HStack {
                        Circle()
                            .fill(Color(hex: line.colorHex) ?? .orange)
                            .frame(width: 8, height: 8)
                        Text(line.name)
                    }
                    .tag(line.id)
                }
            }
            .pickerStyle(.navigationLink)
            .tint(lineColor)
        }
    }
    
    // MARK: - Station Picker
    
    /// Dropdown picker for selecting a station
    private var stationPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.station)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(L10n.stationCount(stations.count))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Picker(L10n.station, selection: Binding(
                get: { viewModel.selectedStation?.id ?? stations.first?.id ?? "" },
                set: { newId in
                    if let station = stations.first(where: { $0.id == newId }) {
                        viewModel.selectStation(station)
                    }
                }
            )) {
                ForEach(stations) { station in
                    Text(station.name)
                        .tag(station.id)
                }
            }
            .pickerStyle(.navigationLink)
            .tint(lineColor)
        }
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
    
    /// The color for the current line (parsed from hex)
    /// Falls back to orange if no line selected or parsing fails
    private var lineColor: Color {
        Color(hex: metroViewModel.lineColorHex) ?? .orange
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Time rule section - Validates: Requirement 8.6
                // THE Time_Rule_Manager SHALL 允许用户启用或禁用时间规则功能
                timeRuleSection
                
                // Background refresh settings
                backgroundRefreshSection
                
                // Language settings
                languageSection
                
                // API Key settings
                apiKeySection
            }
            .navigationTitle(L10n.settings)
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
                        .foregroundColor(lineColor)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.autoSwitch)
                            .font(.body)
                        
                        Text(L10n.autoSwitchDesc)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(lineColor)
            
            // Navigation to time rule configuration
            // Only shown when time rule feature is enabled
            if timeRuleViewModel.isTimeRuleEnabled {
                NavigationLink {
                    TimeRuleConfigView(viewModel: timeRuleViewModel)
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(lineColor)
                            .font(.body)
                        
                        Text(L10n.configureRules)
                        
                        Spacer()
                        
                        // Show enabled rule count badge
                        Text(L10n.ruleCount(timeRuleViewModel.enabledRuleCount))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(timeRuleViewModel.enabledRuleCount > 0 ? lineColor : Color.secondary)
                            )
                    }
                }
                
                // Show active rule status if time rules are active
                if timeRuleViewModel.isTimeRuleActive {
                    activeRuleStatusView
                }
            }
        } header: {
            Label(L10n.timeRules, systemImage: "clock.fill")
                .foregroundColor(lineColor)
        } footer: {
            if timeRuleViewModel.isTimeRuleEnabled {
                Text(timeRuleViewModel.configurationSummary)
                    .font(.caption2)
            } else {
                Text(LanguageService.shared.isEnglish
                     ? "Enable to auto-switch commute settings by time"
                     : "启用后可根据时间自动切换通勤设置")
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
                        Text(L10n.activeRule)
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
                                .foregroundColor(lineColor)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Background Refresh Section
    
    /// Section for background refresh settings
    private var backgroundRefreshSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { metroViewModel.storageService.isSmartRefreshEnabled },
                set: { newValue in
                    var storage = metroViewModel.storageService
                    storage.isSmartRefreshEnabled = newValue
                    storage.save()
                    // 重新调度后台刷新
                    BackgroundRefreshManager.shared.resetAndReschedule()
                }
            )) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(lineColor)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.smartRefresh)
                            .font(.body)
                        
                        Text(metroViewModel.storageService.isSmartRefreshEnabled
                             ? L10n.smartRefreshDesc
                             : (LanguageService.shared.isEnglish ? "Random interval (15-60 min)" : "使用随机间隔 (15-60分钟)"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(lineColor)
        } header: {
            Label(L10n.backgroundRefresh, systemImage: "arrow.clockwise")
                .foregroundColor(lineColor)
        } footer: {
            Text(LanguageService.shared.isEnglish
                 ? "Smart refresh adjusts frequency based on train arrival time"
                 : "智能刷新会根据列车到站时间动态调整刷新频率，关闭后使用随机间隔")
                .font(.caption2)
        }
    }
    
    // MARK: - Language Section
    
    /// Section for language settings
    @ObservedObject private var languageService = LanguageService.shared
    
    private var languageSection: some View {
        Section {
            Picker(L10n.language, selection: Binding(
                get: { languageService.currentLanguage },
                set: { languageService.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.navigationLink)
            .tint(lineColor)
        } header: {
            Label(L10n.language, systemImage: "globe")
                .foregroundColor(lineColor)
        }
    }
    
    // MARK: - API Key Section
    
    /// Section for API key configuration
    /// Allows users to enter their own 511.org API key to avoid rate limiting
    private var apiKeySection: some View {
        Section {
            NavigationLink {
                APIKeySettingsView()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .foregroundColor(lineColor)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.apiKey)
                            .font(.body)
                        
                        Text(APIConfig.hasUserAPIKey ? L10n.apiKeyConfigured : L10n.apiKeyNotConfigured)
                            .font(.caption2)
                            .foregroundColor(APIConfig.hasUserAPIKey ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    Image(systemName: APIConfig.hasUserAPIKey ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(APIConfig.hasUserAPIKey ? .green : .orange)
                        .font(.caption)
                }
            }
        } header: {
            Label(L10n.apiKeySettings, systemImage: "key")
                .foregroundColor(lineColor)
        } footer: {
            Text(L10n.apiKeyFooter)
                .font(.caption2)
        }
    }
    
}

// MARK: - TimeRuleConfigView

/// View for configuring time rules
/// Provides full CRUD operations for time-based automatic station/direction switching
/// - Validates: Requirements 8.1 (configure time rules), 8.2 (save trigger time, station, direction), 8.4 (support multiple rules)
struct TimeRuleConfigView: View {
    @ObservedObject var viewModel: TimeRuleViewModel
    @ObservedObject private var languageService = LanguageService.shared
    
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
        .navigationTitle(L10n.timeRules)
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
                
                Text(L10n.noTimeRules)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text(L10n.addRuleHint)
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
                Text(L10n.configuredRules)
                Spacer()
                Text(L10n.ruleCount(viewModel.ruleCount))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } footer: {
            Text(L10n.swipeToDelete)
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
                    
                    Text(L10n.addRule)
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
/// Shows line name/color indicator alongside station info for multi-line support
/// - Validates: Requirements 8.1, 8.2
struct TimeRuleRowView: View {
    /// The rule to display
    let rule: TimeRule
    
    /// Action when enable toggle is tapped
    let onToggleEnabled: () -> Void
    
    /// Action when edit is requested
    let onEdit: () -> Void
    
    /// The color for the rule's line (parsed from hex)
    private var lineColor: Color {
        Color(hex: TimeRuleRowView.getLineColorHex(for: rule.lineId)) ?? .orange
    }
    
    /// Get the line name for display
    private var lineName: String {
        TimeRuleRowView.getLineName(for: rule.lineId)
    }
    
    /// Get the station for this rule (searches across all lines based on lineId)
    private var station: Station? {
        rule.station
    }
    
    /// Get the direction headsign for display
    private var directionHeadsign: String {
        TimeRuleRowView.getDirectionHeadsign(lineId: rule.lineId, directionId: rule.directionId)
    }
    
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
                
                // Rule details - two lines for better readability on small screens
                VStack(alignment: .leading, spacing: 2) {
                    // Line 1: Rule name + trigger time
                    HStack(spacing: 4) {
                        Text(rule.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(rule.isEnabled ? .primary : .secondary)
                            .lineLimit(1)
                        
                        Text(rule.triggerTimeDisplay)
                            .font(.caption2)
                            .foregroundColor(lineColor)
                    }
                    
                    // Line 2: Line color + Station + Direction
                    HStack(spacing: 4) {
                        // Line indicator (color dot)
                        Circle()
                            .fill(lineColor)
                            .frame(width: 6, height: 6)
                        
                        // Station - Validates: Requirement 8.2
                        if let station = station {
                            Text(station.shortName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Direction headsign
                        Text("→\(directionHeadsign)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Edit indicator
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            rule.isEnabled
                ? lineColor.opacity(0.1)
                : Color.clear
        )
        .accessibilityLabel("\(rule.name), \(rule.isEnabled ? L10n.enabledStatus : L10n.disabledStatus), \(rule.triggerTimeDisplay), \(lineName)")
        .accessibilityHint(L10n.doubleTapToEdit)
    }
    
    // MARK: - Static Helper Functions
    
    /// Get the color hex for a line ID
    static func getLineColorHex(for lineId: String) -> String {
        switch lineId {
        case "Orange":
            return "#F7931E"
        case "Blue":
            return "#0072BC"
        case "Green":
            return "#00A651"
        default:
            return "#F7931E"  // Default to Orange
        }
    }
    
    /// Get the line name for a line ID
    static func getLineName(for lineId: String) -> String {
        switch lineId {
        case "Orange":
            return "Orange Line"
        case "Blue":
            return "Blue Line"
        case "Green":
            return "Green Line"
        default:
            return lineId
        }
    }
    
    /// Get the direction headsign for a line and direction
    static func getDirectionHeadsign(lineId: String, directionId: String) -> String {
        switch lineId {
        case "Orange":
            switch directionId {
            case "E": return "Alum Rock"
            case "W": return "Mountain View"
            default: return directionId
            }
        case "Blue":
            switch directionId {
            case "N": return "Baypointe"
            case "S": return "Santa Teresa"
            default: return directionId
            }
        case "Green":
            switch directionId {
            case "N": return "Old Ironsides"
            case "S": return "Winchester"
            default: return directionId
            }
        default:
            return directionId
        }
    }
    
    /// Get stations for a line ID
    static func getStations(for lineId: String) -> [Station] {
        switch lineId {
        case "Orange":
            return OrangeLineStations.stations
        case "Blue":
            return BlueLineStations.stations
        case "Green":
            return GreenLineStations.stations
        default:
            return OrangeLineStations.stations
        }
    }
    
    /// Get directions for a line ID
    static func getDirections(for lineId: String) -> [LineDirection] {
        switch lineId {
        case "Orange":
            return [
                LineDirection(id: "W", headsign: "Mountain View"),
                LineDirection(id: "E", headsign: "Alum Rock")
            ]
        case "Blue":
            return [
                LineDirection(id: "N", headsign: "Baypointe"),
                LineDirection(id: "S", headsign: "Santa Teresa")
            ]
        case "Green":
            return [
                LineDirection(id: "N", headsign: "Old Ironsides"),
                LineDirection(id: "S", headsign: "Winchester")
            ]
        default:
            return [
                LineDirection(id: "W", headsign: "Mountain View"),
                LineDirection(id: "E", headsign: "Alum Rock")
            ]
        }
    }
}

// MARK: - TimeRuleEditView

/// View for adding or editing a time rule
/// Provides line picker, time picker, station picker, direction picker, and enable toggle
/// Supports multi-line: line selection determines available stations and directions
/// - Validates: Requirements 8.1, 8.2, 8.4
struct TimeRuleEditView: View {
    /// Reference to the view model for validation
    @ObservedObject var viewModel: TimeRuleViewModel
    @ObservedObject private var languageService = LanguageService.shared
    
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
    
    /// Selected line ID (default "Orange")
    @State private var selectedLineId: String = "Orange"
    
    /// Selected station ID
    @State private var selectedStationId: String = OrangeLineStations.first.id
    
    /// Selected direction ID
    @State private var selectedDirectionId: String = "E"
    
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
            return L10n.addRule
        case .edit:
            return L10n.editRule
        }
    }
    
    /// The currently selected station
    private var selectedStation: Station? {
        stationsForSelectedLine.first { $0.id == selectedStationId }
    }
    
    /// Stations for the currently selected line
    private var stationsForSelectedLine: [Station] {
        TimeRuleRowView.getStations(for: selectedLineId)
    }
    
    /// Directions for the currently selected line
    private var directionsForSelectedLine: [LineDirection] {
        TimeRuleRowView.getDirections(for: selectedLineId)
    }
    
    /// Color for the currently selected line
    private var lineColor: Color {
        Color(hex: TimeRuleRowView.getLineColorHex(for: selectedLineId)) ?? .orange
    }
    
    /// Available lines for selection
    private var availableLines: [(id: String, name: String, colorHex: String)] {
        [
            (id: "Orange", name: "Orange Line", colorHex: "#F7931E"),
            (id: "Blue", name: "Blue Line", colorHex: "#0072BC"),
            (id: "Green", name: "Green Line", colorHex: "#00A651")
        ]
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
                    
                    // Line picker section - NEW for multi-line support
                    linePickerSection
                    
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
                    lineId: selectedLineId,
                    onDismiss: {
                        showingStationPicker = false
                    }
                )
            }
            .onChange(of: selectedLineId) { oldValue, newValue in
                // When line changes, reset station and direction to first available
                if oldValue != newValue {
                    let newStations = TimeRuleRowView.getStations(for: newValue)
                    let newDirections = TimeRuleRowView.getDirections(for: newValue)
                    
                    if let firstStation = newStations.first {
                        selectedStationId = firstStation.id
                    }
                    if let firstDirection = newDirections.first {
                        selectedDirectionId = firstDirection.id
                    }
                }
            }
        }
    }
    
    // MARK: - Name Section
    
    /// Section for entering rule name
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(L10n.ruleName, systemImage: "tag")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(L10n.ruleNamePlaceholder, text: $name)
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
            Label(L10n.triggerTime, systemImage: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Time picker showing only hour and minute
            DatePicker(
                L10n.triggerTime,
                selection: $triggerTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 80)
        }
    }
    
    // MARK: - Line Picker Section
    
    /// Section for selecting target line
    /// - Validates: Requirement 8.2 (save target line)
    private var linePickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(L10n.targetLine, systemImage: "tram.circle.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Line picker with color indicators
            Picker(L10n.line, selection: $selectedLineId) {
                ForEach(availableLines, id: \.id) { line in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: line.colorHex) ?? .orange)
                            .frame(width: 10, height: 10)
                        Text(line.name)
                    }
                    .tag(line.id)
                }
            }
            .pickerStyle(.navigationLink)
            .tint(lineColor)
        }
    }
    
    // MARK: - Station Picker Section
    
    /// Section for selecting target station
    /// Shows stations for the currently selected line
    /// - Validates: Requirement 8.2 (save target station)
    private var stationPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(L10n.targetStation, systemImage: "tram.fill")
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
                        Text(L10n.selectStation)
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
    /// Shows directions for the currently selected line
    /// - Validates: Requirement 8.2 (save target direction)
    private var directionPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(L10n.targetDirection, systemImage: "arrow.left.arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Direction picker using LineDirection from selected line
            DirectionPickerView(
                selectedDirectionId: $selectedDirectionId,
                lineDirections: directionsForSelectedLine,
                style: .buttons,
                lineColorHex: TimeRuleRowView.getLineColorHex(for: selectedLineId)
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
                
                Text(L10n.enableRule)
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
                Text(L10n.cancel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Save button
            Button(action: saveRule) {
                Text(L10n.save)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(lineColor)
            .disabled(!isValidInput)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Validation
    
    /// Whether the current input is valid
    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidStationId(selectedStationId, for: selectedLineId)
    }
    
    /// Check if a station ID is valid for a given line
    private func isValidStationId(_ stationId: String, for lineId: String) -> Bool {
        let stations = TimeRuleRowView.getStations(for: lineId)
        return stations.contains { $0.id == stationId }
    }
    
    // MARK: - Actions
    
    /// Loads initial values based on edit mode
    private func loadInitialValues() {
        switch mode {
        case .add:
            // Default values for new rule
            name = ""
            triggerTime = TimeRule.createTriggerTime(hour: 8, minute: 0)
            selectedLineId = "Orange"
            selectedStationId = OrangeLineStations.first.id
            selectedDirectionId = "E"
            isEnabled = true
            
        case .edit(let rule):
            // Load existing rule values
            name = rule.name
            triggerTime = rule.triggerTime
            selectedLineId = rule.lineId
            selectedStationId = rule.stationId
            selectedDirectionId = rule.directionId
            isEnabled = rule.isEnabled
        }
    }
    
    /// Validates and saves the rule
    private func saveRule() {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationError = L10n.pleaseEnterRuleName
            return
        }
        
        // Validate station
        guard isValidStationId(selectedStationId, for: selectedLineId) else {
            validationError = L10n.pleaseSelectValidStation
            return
        }
        
        // Check for conflicting time (optional warning)
        if viewModel.hasConflictingRule(triggerTime: triggerTime, excludingRuleId: ruleId) {
            // Allow saving but could show warning
        }
        
        // Create or update rule with lineId and directionId
        let rule: TimeRule
        if let existingId = ruleId {
            // Update existing rule
            rule = TimeRule(
                id: existingId,
                name: trimmedName,
                triggerTime: triggerTime,
                lineId: selectedLineId,
                stationId: selectedStationId,
                directionId: selectedDirectionId,
                isEnabled: isEnabled
            )
        } else {
            // Create new rule
            rule = TimeRule(
                name: trimmedName,
                triggerTime: triggerTime,
                lineId: selectedLineId,
                stationId: selectedStationId,
                directionId: selectedDirectionId,
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

/// View for selecting a station from any VTA line
/// Used within TimeRuleEditView for station selection
/// Supports multi-line: accepts lineId parameter to filter stations
struct StationSelectionView: View {
    /// Binding to the selected station ID
    @Binding var selectedStationId: String
    
    /// The line ID to show stations for
    let lineId: String
    
    /// Callback when view should be dismissed
    let onDismiss: () -> Void
    
    /// Stations for the specified line
    private var stations: [Station] {
        TimeRuleRowView.getStations(for: lineId)
    }
    
    /// Color for the specified line
    private var lineColor: Color {
        Color(hex: TimeRuleRowView.getLineColorHex(for: lineId)) ?? .orange
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(stations) { station in
                    Button(action: {
                        selectedStationId = station.id
                        onDismiss()
                    }) {
                        HStack(spacing: 12) {
                            // Station order indicator
                            ZStack {
                                Circle()
                                    .fill(selectedStationId == station.id ? lineColor : lineColor.opacity(0.3))
                                    .frame(width: 24, height: 24)
                                
                                Text("\(station.order + 1)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedStationId == station.id ? .white : lineColor)
                            }
                            
                            // Station info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(station.name)
                                    .font(.body)
                                    .foregroundColor(selectedStationId == station.id ? lineColor : .primary)
                                    .lineLimit(1)
                                
                                Text(station.shortName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Selection indicator
                            if selectedStationId == station.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(lineColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        selectedStationId == station.id
                            ? lineColor.opacity(0.15)
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
                    .foregroundColor(lineColor)
                }
            }
        }
    }
}

// MARK: - StationSelectionViewInline

/// Inline version of station selection view for use with navigationDestination
/// Avoids nested NavigationStack issues on watchOS
/// Supports multi-line: accepts lineId parameter to filter stations
struct StationSelectionViewInline: View {
    /// Binding to the selected station ID
    @Binding var selectedStationId: String
    
    /// The line ID to show stations for (defaults to "Orange" for backward compatibility)
    var lineId: String = "Orange"
    
    /// Callback when view should be dismissed
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    /// Stations for the specified line
    private var stations: [Station] {
        TimeRuleRowView.getStations(for: lineId)
    }
    
    /// Color for the specified line
    private var lineColor: Color {
        Color(hex: TimeRuleRowView.getLineColorHex(for: lineId)) ?? .orange
    }
    
    var body: some View {
        List {
            ForEach(stations) { station in
                Button(action: {
                    selectedStationId = station.id
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        // Station order indicator
                        ZStack {
                            Circle()
                                .fill(selectedStationId == station.id ? lineColor : lineColor.opacity(0.3))
                                .frame(width: 24, height: 24)
                            
                            Text("\(station.order + 1)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedStationId == station.id ? .white : lineColor)
                        }
                        
                        // Station info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(station.name)
                                .font(.body)
                                .foregroundColor(selectedStationId == station.id ? lineColor : .primary)
                                .lineLimit(1)
                            
                            Text(station.shortName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Selection indicator
                        if selectedStationId == station.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(lineColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    selectedStationId == station.id
                        ? lineColor.opacity(0.15)
                        : Color.clear
                )
            }
        }
        .listStyle(.carousel)
        .navigationTitle(L10n.selectStation)
    }
}

// MARK: - APIKeySettingsView

/// View for configuring the user's 511.org API key
/// Allows users to enter their own API key to avoid rate limiting on shared keys
struct APIKeySettingsView: View {
    @ObservedObject private var languageService = LanguageService.shared
    
    /// The API key input text
    @State private var apiKeyInput: String = ""
    
    /// Whether to show the save confirmation
    @State private var showingSaveConfirmation = false
    
    /// Whether to show the clear confirmation
    @State private var showingClearConfirmation = false
    
    /// Whether the current input is valid
    private var isValidInput: Bool {
        apiKeyInput.isEmpty || APIConfig.isValidAPIKeyFormat(apiKeyInput)
    }
    
    /// Whether the save button should be enabled
    private var canSave: Bool {
        !apiKeyInput.isEmpty && APIConfig.isValidAPIKeyFormat(apiKeyInput)
    }
    
    var body: some View {
        List {
            // Current status section
            statusSection
            
            // API key input section
            inputSection
            
            // Actions section
            actionsSection
            
            // Help section
            helpSection
        }
        .navigationTitle(L10n.apiKey)
        .onAppear {
            // Load existing API key if any
            apiKeyInput = APIConfig.userAPIKey ?? ""
        }
        .alert(L10n.apiKeySaved, isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        }
        .alert(L10n.apiKeyCleared, isPresented: $showingClearConfirmation) {
            Button("OK", role: .cancel) { }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        Section {
            HStack {
                Image(systemName: APIConfig.hasUserAPIKey ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundColor(APIConfig.hasUserAPIKey ? .green : .orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(APIConfig.hasUserAPIKey ? L10n.apiKeyConfigured : L10n.apiKeyNotConfigured)
                        .font(.body)
                        .foregroundColor(APIConfig.hasUserAPIKey ? .green : .orange)
                    
                    if !APIConfig.hasUserAPIKey {
                        Text(LanguageService.shared.isEnglish
                             ? "Shared keys may be rate limited"
                             : "共享密钥可能被限流")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.yourAPIKey)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField(L10n.apiKeyPlaceholder, text: $apiKeyInput)
                    .font(.system(.caption, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                // Validation indicator
                if !apiKeyInput.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: isValidInput ? "checkmark.circle" : "xmark.circle")
                            .foregroundColor(isValidInput ? .green : .red)
                            .font(.caption2)
                        
                        Text(isValidInput
                             ? (LanguageService.shared.isEnglish ? "Valid format" : "格式正确")
                             : L10n.apiKeyInvalid)
                            .font(.caption2)
                            .foregroundColor(isValidInput ? .green : .red)
                    }
                }
            }
        } header: {
            Text(LanguageService.shared.isEnglish ? "Enter API Key" : "输入 API 密钥")
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        Section {
            // Save button
            Button(action: saveAPIKey) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text(L10n.save)
                }
            }
            .disabled(!canSave)
            
            // Clear button (only show if user has a key)
            if APIConfig.hasUserAPIKey {
                Button(role: .destructive, action: clearAPIKey) {
                    HStack {
                        Image(systemName: "trash")
                        Text(L10n.clearAPIKey)
                    }
                }
            }
        }
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(LanguageService.shared.isEnglish
                     ? "How to get your API key:"
                     : "如何获取 API 密钥：")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(LanguageService.shared.isEnglish
                         ? "1. Visit 511.org/open-data/token"
                         : "1. 访问 511.org/open-data/token")
                    Text(LanguageService.shared.isEnglish
                         ? "2. Create a free account"
                         : "2. 创建免费账户")
                    Text(LanguageService.shared.isEnglish
                         ? "3. Generate an API token"
                         : "3. 生成 API 令牌")
                    Text(LanguageService.shared.isEnglish
                         ? "4. Copy and paste here"
                         : "4. 复制粘贴到这里")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text(LanguageService.shared.isEnglish ? "Help" : "帮助")
        }
    }
    
    // MARK: - Actions
    
    private func saveAPIKey() {
        guard canSave else { return }
        APIConfig.userAPIKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        showingSaveConfirmation = true
    }
    
    private func clearAPIKey() {
        APIConfig.clearUserAPIKey()
        apiKeyInput = ""
        showingClearConfirmation = true
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
