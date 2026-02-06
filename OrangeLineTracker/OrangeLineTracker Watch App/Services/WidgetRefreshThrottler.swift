//
//  WidgetRefreshThrottler.swift
//  OrangeLineTracker Watch App
//
//  Throttles widget refresh calls to avoid excessive reloads
//  Widget reloads are expensive on watchOS, so we limit them
//

import Foundation
import WidgetKit

/// Throttles widget refresh calls to avoid excessive reloads
/// Ensures at least 2 seconds between refreshes
final class WidgetRefreshThrottler {
    
    /// Shared instance
    static let shared = WidgetRefreshThrottler()
    
    /// Minimum interval between refreshes (2 seconds)
    private let minimumInterval: TimeInterval = 2.0
    
    /// Last refresh timestamp
    private var lastRefreshTime: Date?
    
    /// Pending refresh work item
    private var pendingRefresh: DispatchWorkItem?
    
    /// Serial queue for thread safety
    private let queue = DispatchQueue(label: "com.orangelinetracker.widgetrefresh")
    
    private init() {}
    
    /// Request a widget refresh (throttled)
    /// If called multiple times within the minimum interval, only the last call will trigger a refresh
    func requestRefresh() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel any pending refresh
            self.pendingRefresh?.cancel()
            
            let now = Date()
            
            // Check if we can refresh immediately
            if let lastRefresh = self.lastRefreshTime {
                let elapsed = now.timeIntervalSince(lastRefresh)
                if elapsed < self.minimumInterval {
                    // Schedule a delayed refresh
                    let delay = self.minimumInterval - elapsed
                    let workItem = DispatchWorkItem { [weak self] in
                        self?.performRefresh()
                    }
                    self.pendingRefresh = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
                    return
                }
            }
            
            // Refresh immediately
            self.performRefresh()
        }
    }
    
    /// Performs the actual widget refresh
    private func performRefresh() {
        lastRefreshTime = Date()
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// Force an immediate refresh (bypasses throttling)
    /// Use sparingly, only for critical updates
    func forceRefresh() {
        queue.async { [weak self] in
            self?.pendingRefresh?.cancel()
            self?.performRefresh()
        }
    }
}
