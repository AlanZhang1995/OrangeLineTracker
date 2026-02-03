//
//  OrangeLineTrackerApp.swift
//  OrangeLineTracker Watch App
//
//  Main application entry point with dependency injection and lifecycle management
//  - Validates: All requirements through component integration
//

import SwiftUI
import WatchKit
import ClockKit

// MARK: - OrangeLineTrackerApp

/// Main application entry point for the OrangeLineTracker Watch App
/// Configures dependency injection, connects ViewModels with Services,
/// and sets up background refresh handling for complications
/// - Validates: All requirements through component integration
@main
struct OrangeLineTrackerApp: App {
    
    // MARK: - App Delegate
    
    /// WKExtensionDelegate for handling background refresh and lifecycle events
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - Services (Shared Instances)
    
    /// Storage service for persisting user preferences
    /// - Validates: Requirements 1.4, 2.3, 7.1, 7.2, 7.3
    private let storageService: StorageService
    
    /// VTA API service for fetching real-time predictions
    /// - Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
    private let vtaService: VTAService
    
    /// Time rule service for managing automatic station/direction switching
    /// - Validates: Requirements 8.3, 8.4, 8.6, 8.7
    private let timeRuleService: TimeRuleService
    
    // MARK: - ViewModels
    
    /// Main ViewModel for metro data coordination
    /// - Validates: Requirements 1.2, 2.2, 3.1, 4.6, 5.1-5.5, 7.4
    @StateObject private var metroViewModel: MetroViewModel
    
    /// ViewModel for time rule management
    /// - Validates: Requirements 8.1, 8.2, 8.6
    @StateObject private var timeRuleViewModel: TimeRuleViewModel
    
    // MARK: - Initialization
    
    init() {
        // Initialize services with dependency injection
        // Note: In production, the API key should be stored securely (e.g., Keychain or environment variable)
        let apiKey = Self.loadAPIKey()
        
        // Create shared service instances
        let storage = StorageService()
        let vta = VTAService(apiKey: apiKey)
        let timeRule = TimeRuleService(storageService: storage)
        
        // Store service references
        self.storageService = storage
        self.vtaService = vta
        self.timeRuleService = timeRule
        
        // Initialize ViewModels with injected dependencies
        // Using StateObject wrapper for proper SwiftUI lifecycle management
        _metroViewModel = StateObject(wrappedValue: MetroViewModel(
            vtaService: vta,
            storageService: storage,
            timeRuleService: timeRule
        ))
        
        _timeRuleViewModel = StateObject(wrappedValue: TimeRuleViewModel(
            timeRuleService: timeRule,
            storageService: storage
        ))
        
        // Configure shared instances for background refresh
        Self.configureSharedInstances(
            storageService: storage,
            vtaService: vta,
            timeRuleService: timeRule
        )
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            // Main content view with environment objects for ViewModels
            MainContentView(
                metroViewModel: metroViewModel,
                timeRuleViewModel: timeRuleViewModel
            )
            .onAppear {
                // Apply time rule if needed when app appears
                // - Validates: Requirements 8.3, 8.5
                metroViewModel.applyTimeRuleIfNeeded()
                
                // Schedule background refresh for complications
                // - Validates: Requirement 9.5
                BackgroundRefreshManager.shared.scheduleBackgroundRefresh()
            }
        }
    }
    
    // MARK: - Configuration Helpers
    
    /// Loads the API key from configuration
    /// In production, this should load from a secure source
    private static func loadAPIKey() -> String {
        // Try to load from environment or use placeholder
        // In production, use Keychain or secure configuration
        if let apiKey = ProcessInfo.processInfo.environment["VTA_API_KEY"], !apiKey.isEmpty {
            return apiKey
        }
        
        // 511.org API key for VTA real-time data
        return "cfc3474b-61e1-48f4-a177-0c8b8cb27cca"
    }
    
    /// Configures shared instances for background refresh and complications
    private static func configureSharedInstances(
        storageService: StorageService,
        vtaService: VTAService,
        timeRuleService: TimeRuleService
    ) {
        // The BackgroundRefreshManager and ComplicationController use their own
        // instances, but we ensure they're initialized with consistent configuration
        // This is handled through their singleton patterns
    }
}

// MARK: - MainContentView

/// Main content view that wraps ContentView with proper ViewModel injection
/// This separates the view hierarchy from the App struct for cleaner architecture
struct MainContentView: View {
    
    /// Main ViewModel for metro data
    @ObservedObject var metroViewModel: MetroViewModel
    
    /// ViewModel for time rule management
    @ObservedObject var timeRuleViewModel: TimeRuleViewModel
    
    var body: some View {
        TabView {
            // Tab 1: Arrival Times Display
            // - Validates: Requirements 4.1-4.6, 5.1-5.5, 6.1, 6.4, 6.5
            ArrivalView(viewModel: metroViewModel)
            
            // Tab 2: Station Selection
            // - Validates: Requirements 1.1-1.5, 6.2
            StationPickerView(viewModel: metroViewModel)
            
            // Tab 3: Settings
            // - Validates: Requirements 2.1-2.4, 6.3, 8.1-8.7
            SettingsView(
                metroViewModel: metroViewModel,
                timeRuleViewModel: timeRuleViewModel
            )
        }
        .tabViewStyle(.verticalPage) // Supports Digital Crown navigation
    }
}

// MARK: - AppDelegate

/// WKExtensionDelegate implementation for handling background tasks and lifecycle events
/// - Validates: Requirements 9.5 (background refresh for complications)
class AppDelegate: NSObject, WKApplicationDelegate {
    
    // MARK: - Application Lifecycle
    
    /// Called when the application finishes launching
    /// Sets up initial background refresh scheduling
    func applicationDidFinishLaunching() {
        // Schedule initial background refresh for complications
        // - Validates: Requirement 9.5
        BackgroundRefreshManager.shared.applicationDidFinishLaunching()
        
        print("OrangeLineTracker: Application did finish launching")
    }
    
    /// Called when the application becomes active
    /// Refreshes data if needed and applies time rules
    func applicationDidBecomeActive() {
        // Refresh data when app becomes active
        // - Validates: Requirement 9.5
        BackgroundRefreshManager.shared.applicationDidBecomeActive()
        
        print("OrangeLineTracker: Application did become active")
    }
    
    /// Called when the application will resign active
    func applicationWillResignActive() {
        // Schedule next background refresh before going inactive
        BackgroundRefreshManager.shared.scheduleBackgroundRefresh()
        
        print("OrangeLineTracker: Application will resign active")
    }
    
    // MARK: - Background Task Handling
    
    /// Handles background tasks including refresh and URL session tasks
    /// - Parameter backgroundTasks: Set of background tasks to process
    /// - Validates: Requirement 9.5 (periodic background updates)
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Delegate background task handling to BackgroundRefreshManager
        BackgroundRefreshManager.shared.handleBackgroundTasks(backgroundTasks)
        
        print("OrangeLineTracker: Handling \(backgroundTasks.count) background task(s)")
    }
    
    // MARK: - Complication Handling
    
    /// Called when a complication is tapped to launch the app
    /// - Parameter userInfo: Optional user info from the complication
    func handleUserActivity(_ userInfo: [AnyHashable: Any]?) {
        // Handle complication tap - app is launched automatically
        // - Validates: Requirement 9.4 (tap to open app main interface)
        print("OrangeLineTracker: Handling user activity from complication")
    }
}

// MARK: - Complication Entry Point

/// Extension to provide complication configuration
/// This enables the app to provide watch face complications
extension OrangeLineTrackerApp {
    
    /// Returns the complication controller for watch face complications
    /// - Validates: Requirements 9.1-9.7
    static var complicationController: ComplicationController {
        ComplicationController.shared
    }
}

// MARK: - Environment Keys

/// Custom environment key for accessing the MetroViewModel
private struct MetroViewModelKey: EnvironmentKey {
    static let defaultValue: MetroViewModel? = nil
}

/// Custom environment key for accessing the TimeRuleViewModel
private struct TimeRuleViewModelKey: EnvironmentKey {
    static let defaultValue: TimeRuleViewModel? = nil
}

/// Environment values extension for ViewModel access
extension EnvironmentValues {
    /// The MetroViewModel for the current environment
    var metroViewModel: MetroViewModel? {
        get { self[MetroViewModelKey.self] }
        set { self[MetroViewModelKey.self] = newValue }
    }
    
    /// The TimeRuleViewModel for the current environment
    var timeRuleViewModel: TimeRuleViewModel? {
        get { self[TimeRuleViewModelKey.self] }
        set { self[TimeRuleViewModelKey.self] = newValue }
    }
}
