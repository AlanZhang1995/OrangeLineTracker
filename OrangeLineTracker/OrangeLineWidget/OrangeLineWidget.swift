//
//  OrangeLineWidget.swift
//  OrangeLineWidget
//
//  Watch face complication widget for Orange Line arrival times
//

import WidgetKit
import SwiftUI

// MARK: - App Group

private let appGroupIdentifier = "group.com.orangelinetracker"

// MARK: - Storage Keys

private enum WidgetStorageKeys {
    static let selectedStationName = "selectedStationName"
    static let selectedStationShortName = "selectedStationShortName"
    static let selectedDirection = "selectedDirection"
    static let cachedArrivalMinutes = "cachedArrivalMinutes"
    static let lastUpdateTime = "lastUpdateTime"
}

// MARK: - Timeline Entry

struct OrangeLineEntry: TimelineEntry {
    let date: Date
    let stationName: String
    let stationShortName: String
    let direction: String
    let arrivalMinutes: Int?
    let isStale: Bool
    
    static var placeholder: OrangeLineEntry {
        OrangeLineEntry(
            date: Date(),
            stationName: "Milpitas",
            stationShortName: "MLPT",
            direction: "E",
            arrivalMinutes: 5,
            isStale: false
        )
    }
    
    static var noData: OrangeLineEntry {
        OrangeLineEntry(
            date: Date(),
            stationName: "--",
            stationShortName: "--",
            direction: "--",
            arrivalMinutes: nil,
            isStale: true
        )
    }
}

// MARK: - Timeline Provider

struct OrangeLineProvider: TimelineProvider {
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    func placeholder(in context: Context) -> OrangeLineEntry {
        OrangeLineEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (OrangeLineEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<OrangeLineEntry>) -> Void) {
        let entry = loadCurrentEntry()
        
        // Refresh every 2 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 2, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadCurrentEntry() -> OrangeLineEntry {
        guard let defaults = sharedDefaults else {
            return OrangeLineEntry.noData
        }
        
        let stationName = defaults.string(forKey: WidgetStorageKeys.selectedStationName) ?? "--"
        let stationShortName = defaults.string(forKey: WidgetStorageKeys.selectedStationShortName) ?? "--"
        let direction = defaults.string(forKey: WidgetStorageKeys.selectedDirection) ?? "--"
        
        var arrivalMinutes: Int? = nil
        if defaults.object(forKey: WidgetStorageKeys.cachedArrivalMinutes) != nil {
            arrivalMinutes = defaults.integer(forKey: WidgetStorageKeys.cachedArrivalMinutes)
        }
        
        // Check if data is stale (older than 5 minutes)
        var isStale = true
        if let lastUpdateTimestamp = defaults.object(forKey: WidgetStorageKeys.lastUpdateTime) as? TimeInterval {
            let lastUpdate = Date(timeIntervalSince1970: lastUpdateTimestamp)
            isStale = Date().timeIntervalSince(lastUpdate) > 300 // 5 minutes
        }
        
        return OrangeLineEntry(
            date: Date(),
            stationName: stationName,
            stationShortName: stationShortName,
            direction: direction,
            arrivalMinutes: arrivalMinutes,
            isStale: isStale
        )
    }
}

// MARK: - Widget Views

struct OrangeLineWidgetEntryView: View {
    var entry: OrangeLineEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(entry: entry)
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryInline:
            InlineView(entry: entry)
        case .accessoryCorner:
            CornerView(entry: entry)
        default:
            CircularView(entry: entry)
        }
    }
}

// MARK: - Circular Complication

struct CircularView: View {
    let entry: OrangeLineEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 0) {
                if let minutes = entry.arrivalMinutes, !entry.isStale {
                    Text("\(minutes)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("min")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else {
                    // 大字显示站名缩写
                    Text(entry.stationShortName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    // 小字显示方向
                    Text(entry.direction == "E" ? "→东" : "←西")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Rectangular Complication

struct RectangularView: View {
    let entry: OrangeLineEntry
    
    /// 方向显示文本
    private var directionText: String {
        switch entry.direction {
        case "E": return "→ Alum Rock"
        case "W": return "← Mountain View"
        default: return entry.direction
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // 大字显示站名
                Text(entry.stationName)
                    .font(.headline)
                    .foregroundColor(.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // 小字显示方向
                Text(directionText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let minutes = entry.arrivalMinutes, !entry.isStale {
                VStack(alignment: .trailing) {
                    Text("\(minutes)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("--")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Inline Complication

struct InlineView: View {
    let entry: OrangeLineEntry
    
    /// 方向简写
    private var directionShort: String {
        entry.direction == "E" ? "→" : "←"
    }
    
    var body: some View {
        if let minutes = entry.arrivalMinutes, !entry.isStale {
            // 站名 方向 时间
            Label("\(entry.stationShortName) \(directionShort) \(minutes)min", systemImage: "tram.fill")
        } else {
            // 站名 方向
            Label("\(entry.stationShortName) \(directionShort)", systemImage: "tram.fill")
        }
    }
}

// MARK: - Corner Complication

struct CornerView: View {
    let entry: OrangeLineEntry
    
    /// 方向简写
    private var directionShort: String {
        entry.direction == "E" ? "→" : "←"
    }
    
    var body: some View {
        ZStack {
            if let minutes = entry.arrivalMinutes, !entry.isStale {
                Text("\(minutes)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            } else {
                // 显示站名缩写
                Text(entry.stationShortName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .widgetLabel {
            // 大字站名，小字方向
            Text("\(entry.stationShortName) \(directionShort)")
        }
    }
}

// MARK: - Widget Configuration

struct OrangeLineWidget: Widget {
    let kind: String = "OrangeLineWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OrangeLineProvider()) { entry in
            OrangeLineWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Orange Line")
        .description("显示 VTA Orange Line 到站时间")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    OrangeLineWidget()
} timeline: {
    OrangeLineEntry.placeholder
    OrangeLineEntry.noData
}
