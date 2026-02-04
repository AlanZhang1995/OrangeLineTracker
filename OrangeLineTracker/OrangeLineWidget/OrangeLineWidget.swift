//
//  OrangeLineWidget.swift
//  OrangeLineWidget
//
//  Watch face complication widget for Orange Line arrival times
//  简化版：直接读取 App 写入的当前显示数据，与 ArrivalView 保持一致
//

import WidgetKit
import SwiftUI

// MARK: - App Group

private let appGroupIdentifier = "group.com.orangelinetracker"

// MARK: - Storage Keys (与 App 共享)

private enum WidgetStorageKeys {
    static let stationName = "widget_stationName"
    static let stationShortName = "widget_stationShortName"
    static let direction = "widget_direction"
    static let arrivalTimestamp = "widget_arrivalTimestamp"
    static let lastUpdateTime = "widget_lastUpdateTime"
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
        let entry = loadCurrentEntry(for: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<OrangeLineEntry>) -> Void) {
        let now = Date()
        
        guard let defaults = sharedDefaults else {
            print("Widget: ❌ No shared defaults available")
            let entry = OrangeLineEntry.noData
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: now) ?? now
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
            return
        }
        
        // 读取 App 写入的数据
        let stationName = defaults.string(forKey: WidgetStorageKeys.stationName) ?? "--"
        let stationShortName = defaults.string(forKey: WidgetStorageKeys.stationShortName) ?? "--"
        let direction = defaults.string(forKey: WidgetStorageKeys.direction) ?? "--"
        
        print("Widget: 🔄 Timeline refresh - Station: \(stationName), Direction: \(direction)")
        
        // 生成未来 60 分钟的 entries（每分钟一个，用于倒计时）
        var entries: [OrangeLineEntry] = []
        
        for minuteOffset in 0..<60 {
            guard let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now) else {
                continue
            }
            
            // 计算到站时间（基于 App 写入的到站时间戳）
            var arrivalMinutes: Int? = nil
            if let arrivalTimestamp = defaults.object(forKey: WidgetStorageKeys.arrivalTimestamp) as? TimeInterval {
                let arrivalDate = Date(timeIntervalSince1970: arrivalTimestamp)
                let remainingSeconds = arrivalDate.timeIntervalSince(entryDate)
                let remainingMinutes = Int(ceil(remainingSeconds / 60))
                arrivalMinutes = remainingMinutes >= 0 ? remainingMinutes : nil
            }
            
            // 检查数据是否过期（超过 5 分钟未更新）
            var isStale = true
            if let lastUpdateTimestamp = defaults.object(forKey: WidgetStorageKeys.lastUpdateTime) as? TimeInterval {
                let lastUpdate = Date(timeIntervalSince1970: lastUpdateTimestamp)
                isStale = entryDate.timeIntervalSince(lastUpdate) > 300
            }
            
            let entry = OrangeLineEntry(
                date: entryDate,
                stationName: stationName,
                stationShortName: stationShortName,
                direction: direction,
                arrivalMinutes: arrivalMinutes,
                isStale: isStale
            )
            entries.append(entry)
        }
        
        // 60 分钟后请求新的 timeline
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 60, to: now) ?? now
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentEntry(for date: Date) -> OrangeLineEntry {
        guard let defaults = sharedDefaults else {
            return OrangeLineEntry.noData
        }
        
        let stationName = defaults.string(forKey: WidgetStorageKeys.stationName) ?? "--"
        let stationShortName = defaults.string(forKey: WidgetStorageKeys.stationShortName) ?? "--"
        let direction = defaults.string(forKey: WidgetStorageKeys.direction) ?? "--"
        
        // 计算到站时间
        var arrivalMinutes: Int? = nil
        if let arrivalTimestamp = defaults.object(forKey: WidgetStorageKeys.arrivalTimestamp) as? TimeInterval {
            let arrivalDate = Date(timeIntervalSince1970: arrivalTimestamp)
            let remainingSeconds = arrivalDate.timeIntervalSince(date)
            let remainingMinutes = Int(ceil(remainingSeconds / 60))
            arrivalMinutes = remainingMinutes >= 0 ? remainingMinutes : nil
        }
        
        // 检查数据是否过期
        var isStale = true
        if let lastUpdateTimestamp = defaults.object(forKey: WidgetStorageKeys.lastUpdateTime) as? TimeInterval {
            let lastUpdate = Date(timeIntervalSince1970: lastUpdateTimestamp)
            isStale = date.timeIntervalSince(lastUpdate) > 300
        }
        
        return OrangeLineEntry(
            date: date,
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
                if let minutes = entry.arrivalMinutes {
                    Text("\(minutes)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(entry.isStale ? .orange.opacity(0.6) : .orange)
                    Text(entry.isStale ? "旧" : "min")
                        .font(.system(size: 10))
                        .foregroundColor(entry.isStale ? .yellow : .secondary)
                } else {
                    Text(entry.stationShortName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
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
                HStack(spacing: 4) {
                    Text(entry.stationName)
                        .font(.headline)
                        .foregroundColor(entry.isStale ? .orange.opacity(0.7) : .orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if entry.isStale && entry.arrivalMinutes != nil {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(directionText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let minutes = entry.arrivalMinutes {
                VStack(alignment: .trailing) {
                    Text("\(minutes)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(entry.isStale ? .orange.opacity(0.6) : .orange)
                    Text(entry.isStale ? "缓存" : "min")
                        .font(.caption2)
                        .foregroundColor(entry.isStale ? .yellow : .secondary)
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
    
    private var directionShort: String {
        entry.direction == "E" ? "→" : "←"
    }
    
    var body: some View {
        if let minutes = entry.arrivalMinutes {
            let cacheIndicator = entry.isStale ? "⏱" : ""
            Label("\(entry.stationShortName) \(directionShort) \(minutes)min\(cacheIndicator)", systemImage: "tram.fill")
        } else {
            Label("\(entry.stationShortName) \(directionShort)", systemImage: "tram.fill")
        }
    }
}

// MARK: - Corner Complication

struct CornerView: View {
    let entry: OrangeLineEntry
    
    private var directionShort: String {
        entry.direction == "E" ? "→" : "←"
    }
    
    var body: some View {
        ZStack {
            if let minutes = entry.arrivalMinutes {
                VStack(spacing: 0) {
                    Text("\(minutes)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(entry.isStale ? .orange.opacity(0.6) : .orange)
                    if entry.isStale {
                        Text("旧")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                    }
                }
            } else {
                Text(entry.stationShortName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .widgetLabel {
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
