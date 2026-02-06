//
//  OrangeLineWidget.swift
//  OrangeLineWidget
//
//  Watch face complication widget for VTA transit arrival times
//  Supports all VTA lines (Orange, Blue, Green) with dynamic colors
//  - Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5, 9.6
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
    static let arrivalTimestamp1 = "widget_arrivalTimestamp1"  // 第一班车
    static let arrivalTimestamp2 = "widget_arrivalTimestamp2"  // 第二班车
    static let arrivalTimestamp3 = "widget_arrivalTimestamp3"  // 第三班车
    static let lastUpdateTime = "widget_lastUpdateTime"
    
    // Line-related keys (VTA All Lines support)
    // - Validates: Requirements 9.1, 9.2, 9.3
    static let lineId = "widget_lineId"
    static let lineName = "widget_lineName"
    static let lineColor = "widget_lineColor"  // Hex color string
    
    // Language preference (shared with main app)
    static let appLanguage = "appLanguage"
}

// MARK: - Widget Localization Helper

/// Helper for widget localization using shared UserDefaults
private struct WidgetL10n {
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    static var isEnglish: Bool {
        let language = sharedDefaults?.string(forKey: WidgetStorageKeys.appLanguage) ?? "zh"
        return language == "en"
    }
    
    static var widgetOld: String { isEnglish ? "Old" : "旧" }
    static var widgetCached: String { isEnglish ? "Cached" : "缓存" }
    static var widgetMin: String { "min" }
    
    static func directionArrow(_ dir: String) -> String {
        switch dir {
        case "E": return isEnglish ? "→E" : "→东"
        case "W": return isEnglish ? "←W" : "←西"
        case "N": return isEnglish ? "↑N" : "↑北"
        case "S": return isEnglish ? "↓S" : "↓南"
        default: return dir
        }
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Creates a Color from a hex string
    /// - Parameter hex: Hex color string (e.g., "#FF8C00" or "FF8C00")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 140, 0) // Default to orange
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Timeline Entry

/// Timeline entry for VTA transit widget
/// - Validates: Requirements 9.1, 9.5
struct OrangeLineEntry: TimelineEntry {
    let date: Date
    let stationName: String
    let stationShortName: String
    let direction: String
    let arrivalMinutes: Int?
    let isStale: Bool
    
    // Line information (VTA All Lines support)
    // - Validates: Requirements 9.1, 9.2, 9.3
    let lineId: String
    let lineName: String
    let lineColorHex: String
    
    /// Computed property for line color
    /// - Validates: Requirement 9.4
    var lineColor: Color {
        Color(hex: lineColorHex)
    }
    
    static var placeholder: OrangeLineEntry {
        OrangeLineEntry(
            date: Date(),
            stationName: "Milpitas",
            stationShortName: "MLPT",
            direction: "E",
            arrivalMinutes: 5,
            isStale: false,
            lineId: "Orange",
            lineName: "Orange Line",
            lineColorHex: "#FF8C00"
        )
    }
    
    static var noData: OrangeLineEntry {
        OrangeLineEntry(
            date: Date(),
            stationName: "--",
            stationShortName: "--",
            direction: "--",
            arrivalMinutes: nil,
            isStale: true,
            lineId: "Orange",
            lineName: "Orange Line",
            lineColorHex: "#FF8C00"
        )
    }
}

// MARK: - Timeline Provider

/// Timeline provider for VTA transit widget
/// - Validates: Requirements 9.5, 9.6
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
        
        // 读取线路信息 (VTA All Lines support)
        // - Validates: Requirements 9.1, 9.2, 9.3
        let lineId = defaults.string(forKey: WidgetStorageKeys.lineId) ?? "Orange"
        let lineName = defaults.string(forKey: WidgetStorageKeys.lineName) ?? "Orange Line"
        let lineColorHex = defaults.string(forKey: WidgetStorageKeys.lineColor) ?? "#FF8C00"
        
        print("Widget: 🔄 Timeline refresh - \(lineName) \(stationName) \(direction)")
        
        // 生成未来 60 分钟的 entries（每分钟一个，用于倒计时）
        var entries: [OrangeLineEntry] = []
        
        for minuteOffset in 0..<60 {
            guard let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now) else {
                continue
            }
            
            // 计算到站时间（尝试 3 班车，自动切换到下一班）
            var arrivalMinutes: Int? = nil
            
            // 读取 3 班车的时间戳
            let timestamp1 = defaults.object(forKey: WidgetStorageKeys.arrivalTimestamp1) as? TimeInterval
            let timestamp2 = defaults.object(forKey: WidgetStorageKeys.arrivalTimestamp2) as? TimeInterval
            let timestamp3 = defaults.object(forKey: WidgetStorageKeys.arrivalTimestamp3) as? TimeInterval
            
            // 按顺序尝试每班车，找到第一个还没过期的
            for timestamp in [timestamp1, timestamp2, timestamp3] {
                guard let ts = timestamp else { continue }
                let arrivalDate = Date(timeIntervalSince1970: ts)
                let remainingSeconds = arrivalDate.timeIntervalSince(entryDate)
                let remainingMinutes = Int(ceil(remainingSeconds / 60))
                if remainingMinutes >= 0 {
                    arrivalMinutes = remainingMinutes
                    break  // 找到有效的就停止
                }
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
                isStale: isStale,
                lineId: lineId,
                lineName: lineName,
                lineColorHex: lineColorHex
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
        
        // 读取线路信息 (VTA All Lines support)
        let lineId = defaults.string(forKey: WidgetStorageKeys.lineId) ?? "Orange"
        let lineName = defaults.string(forKey: WidgetStorageKeys.lineName) ?? "Orange Line"
        let lineColorHex = defaults.string(forKey: WidgetStorageKeys.lineColor) ?? "#FF8C00"
        
        // 计算到站时间（尝试 3 班车，自动切换到下一班）
        var arrivalMinutes: Int? = nil
        
        let timestamp1 = defaults.object(forKey: WidgetStorageKeys.arrivalTimestamp1) as? TimeInterval
        let timestamp2 = defaults.object(forKey: WidgetStorageKeys.arrivalTimestamp2) as? TimeInterval
        let timestamp3 = defaults.object(forKey: WidgetStorageKeys.arrivalTimestamp3) as? TimeInterval
        
        for timestamp in [timestamp1, timestamp2, timestamp3] {
            guard let ts = timestamp else { continue }
            let arrivalDate = Date(timeIntervalSince1970: ts)
            let remainingSeconds = arrivalDate.timeIntervalSince(date)
            let remainingMinutes = Int(ceil(remainingSeconds / 60))
            if remainingMinutes >= 0 {
                arrivalMinutes = remainingMinutes
                break
            }
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
            isStale: isStale,
            lineId: lineId,
            lineName: lineName,
            lineColorHex: lineColorHex
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

/// Circular complication view with dynamic line color
/// - Validates: Requirement 9.4
struct CircularView: View {
    let entry: OrangeLineEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 0) {
                if let minutes = entry.arrivalMinutes {
                    Text("\(minutes)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(entry.isStale ? entry.lineColor.opacity(0.6) : entry.lineColor)
                    Text(entry.isStale ? WidgetL10n.widgetOld : WidgetL10n.widgetMin)
                        .font(.system(size: 10))
                        .foregroundColor(entry.isStale ? .yellow : .secondary)
                } else {
                    Text(entry.stationShortName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(entry.lineColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(directionText)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    /// Direction text based on line type
    private var directionText: String {
        WidgetL10n.directionArrow(entry.direction)
    }
}

// MARK: - Rectangular Complication

/// Rectangular complication view with dynamic line color and direction
/// - Validates: Requirements 9.4, 9.6
struct RectangularView: View {
    let entry: OrangeLineEntry
    
    /// Direction text based on line and direction
    private var directionText: String {
        // Orange Line directions
        if entry.lineId == "Orange" {
            switch entry.direction {
            case "E": return "→ Alum Rock"
            case "W": return "← Mountain View"
            default: return entry.direction
            }
        }
        // Blue Line directions
        else if entry.lineId == "Blue" {
            switch entry.direction {
            case "N": return "↑ Baypointe"
            case "S": return "↓ Santa Teresa"
            default: return entry.direction
            }
        }
        // Green Line directions
        else if entry.lineId == "Green" {
            switch entry.direction {
            case "N": return "↑ Old Ironsides"
            case "S": return "↓ Winchester"
            default: return entry.direction
            }
        }
        return entry.direction
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.stationName)
                        .font(.headline)
                        .foregroundColor(entry.isStale ? entry.lineColor.opacity(0.7) : entry.lineColor)
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
                        .foregroundColor(entry.isStale ? entry.lineColor.opacity(0.6) : entry.lineColor)
                    Text(entry.isStale ? WidgetL10n.widgetCached : WidgetL10n.widgetMin)
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

/// Inline complication view with dynamic direction symbol
/// - Validates: Requirement 9.6
struct InlineView: View {
    let entry: OrangeLineEntry
    
    private var directionShort: String {
        switch entry.direction {
        case "E": return "→"
        case "W": return "←"
        case "N": return "↑"
        case "S": return "↓"
        default: return entry.direction
        }
    }
    
    var body: some View {
        if let minutes = entry.arrivalMinutes {
            let cacheIndicator = entry.isStale ? "⏱" : ""
            Label("\(entry.stationShortName) \(directionShort) \(minutes)\(WidgetL10n.widgetMin)\(cacheIndicator)", systemImage: "tram.fill")
        } else {
            Label("\(entry.stationShortName) \(directionShort)", systemImage: "tram.fill")
        }
    }
}

// MARK: - Corner Complication

/// Corner complication view with dynamic line color
/// - Validates: Requirement 9.4
struct CornerView: View {
    let entry: OrangeLineEntry
    
    private var directionShort: String {
        switch entry.direction {
        case "E": return "→"
        case "W": return "←"
        case "N": return "↑"
        case "S": return "↓"
        default: return entry.direction
        }
    }
    
    var body: some View {
        ZStack {
            if let minutes = entry.arrivalMinutes {
                VStack(spacing: 0) {
                    Text("\(minutes)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(entry.isStale ? entry.lineColor.opacity(0.6) : entry.lineColor)
                    if entry.isStale {
                        Text(WidgetL10n.widgetOld)
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                    }
                }
            } else {
                Text(entry.stationShortName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(entry.lineColor)
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
        .configurationDisplayName("VTA Transit")
        .description("显示 VTA 轻轨到站时间")
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
    // Blue Line preview
    OrangeLineEntry(
        date: Date(),
        stationName: "Diridon",
        stationShortName: "DIRD",
        direction: "N",
        arrivalMinutes: 3,
        isStale: false,
        lineId: "Blue",
        lineName: "Blue Line",
        lineColorHex: "#0066CC"
    )
    // Green Line preview
    OrangeLineEntry(
        date: Date(),
        stationName: "Winchester",
        stationShortName: "WNCH",
        direction: "S",
        arrivalMinutes: 8,
        isStale: false,
        lineId: "Green",
        lineName: "Green Line",
        lineColorHex: "#00AA00"
    )
}
