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
    static let arrivalTimestamp = "arrivalTimestamp"  // 到站时间戳
    static let timeRules = "timeRules"  // 时间规则
    static let isTimeRuleEnabled = "isTimeRuleEnabled"  // 时间规则是否启用
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
        var entries: [OrangeLineEntry] = []
        let now = Date()
        
        guard let defaults = sharedDefaults else {
            print("Widget: ❌ No shared defaults available")
            let entry = OrangeLineEntry.noData
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 2, to: now) ?? now
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
            return
        }
        
        // 加载时间规则
        let timeRules = loadTimeRules(from: defaults)
        let isTimeRuleEnabled = defaults.bool(forKey: WidgetStorageKeys.isTimeRuleEnabled)
        
        print("Widget: 🔄 Timeline refresh - TimeRules enabled: \(isTimeRuleEnabled), rules count: \(timeRules.count)")
        
        // 获取当前活跃的规则（基于当前时间）
        let activeRule = isTimeRuleEnabled ? findActiveRule(rules: timeRules, at: now) : nil
        if let rule = activeRule {
            print("Widget: ⏰ Active time rule: \(rule.name) -> \(rule.stationName)")
        } else {
            print("Widget: ⏰ No active time rule")
        }
        
        // 确定当前应该显示的站点信息
        let currentStationInfo = getStationInfo(defaults: defaults, activeRule: activeRule)
        
        // 生成未来 60 分钟的 entries
        // 检查是否有规则会在这段时间内触发
        var lastRuleId: UUID? = activeRule?.id
        
        for minuteOffset in 0..<60 {
            guard let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now) else {
                continue
            }
            
            // 检查这个时间点是否有新规则触发
            var stationInfo = currentStationInfo
            if isTimeRuleEnabled {
                let ruleAtTime = findActiveRule(rules: timeRules, at: entryDate)
                if let rule = ruleAtTime, rule.id != lastRuleId {
                    // 新规则触发，更新站点信息
                    stationInfo = getStationInfoFromRule(rule)
                    lastRuleId = rule.id
                }
            }
            
            // 计算到站时间（如果有缓存的到站时间戳）
            var arrivalMinutes: Int? = nil
            if let arrivalTimestamp = defaults.object(forKey: WidgetStorageKeys.arrivalTimestamp) as? TimeInterval {
                let arrivalDate = Date(timeIntervalSince1970: arrivalTimestamp)
                let remainingSeconds = arrivalDate.timeIntervalSince(entryDate)
                let remainingMinutes = Int(ceil(remainingSeconds / 60))
                // 只有当规则没有变化时才显示到站时间
                // 规则变化后需要等待新的 API 数据
                if lastRuleId == activeRule?.id || activeRule == nil {
                    arrivalMinutes = remainingMinutes > 0 ? remainingMinutes : (remainingMinutes == 0 ? 0 : nil)
                }
            }
            
            // 检查数据是否过期
            var isStale = true
            if let lastUpdateTimestamp = defaults.object(forKey: WidgetStorageKeys.lastUpdateTime) as? TimeInterval {
                let lastUpdate = Date(timeIntervalSince1970: lastUpdateTimestamp)
                isStale = entryDate.timeIntervalSince(lastUpdate) > 300
            }
            
            let entry = OrangeLineEntry(
                date: entryDate,
                stationName: stationInfo.name,
                stationShortName: stationInfo.shortName,
                direction: stationInfo.direction,
                arrivalMinutes: arrivalMinutes,
                isStale: isStale || (lastRuleId != activeRule?.id && activeRule != nil)
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
        
        // 加载时间规则
        let timeRules = loadTimeRules(from: defaults)
        let isTimeRuleEnabled = defaults.bool(forKey: WidgetStorageKeys.isTimeRuleEnabled)
        
        // 获取当前活跃的规则
        let activeRule = isTimeRuleEnabled ? findActiveRule(rules: timeRules, at: date) : nil
        
        // 确定当前应该显示的站点信息
        let stationInfo = getStationInfo(defaults: defaults, activeRule: activeRule)
        
        // 计算到站时间
        var arrivalMinutes: Int? = nil
        if let arrivalTimestamp = defaults.object(forKey: WidgetStorageKeys.arrivalTimestamp) as? TimeInterval {
            let arrivalDate = Date(timeIntervalSince1970: arrivalTimestamp)
            let remainingSeconds = arrivalDate.timeIntervalSince(date)
            let remainingMinutes = Int(ceil(remainingSeconds / 60))
            arrivalMinutes = remainingMinutes > 0 ? remainingMinutes : (remainingMinutes == 0 ? 0 : nil)
        } else if defaults.object(forKey: WidgetStorageKeys.cachedArrivalMinutes) != nil {
            arrivalMinutes = defaults.integer(forKey: WidgetStorageKeys.cachedArrivalMinutes)
        }
        
        // 检查数据是否过期
        var isStale = true
        if let lastUpdateTimestamp = defaults.object(forKey: WidgetStorageKeys.lastUpdateTime) as? TimeInterval {
            let lastUpdate = Date(timeIntervalSince1970: lastUpdateTimestamp)
            isStale = date.timeIntervalSince(lastUpdate) > 300
        }
        
        return OrangeLineEntry(
            date: date,
            stationName: stationInfo.name,
            stationShortName: stationInfo.shortName,
            direction: stationInfo.direction,
            arrivalMinutes: arrivalMinutes,
            isStale: isStale
        )
    }
    
    // MARK: - Time Rule Helpers
    
    /// 从 UserDefaults 加载时间规则
    private func loadTimeRules(from defaults: UserDefaults) -> [WidgetTimeRule] {
        guard let data = defaults.data(forKey: WidgetStorageKeys.timeRules),
              let rules = try? JSONDecoder().decode([WidgetTimeRule].self, from: data) else {
            return []
        }
        return rules.filter { $0.isEnabled }
    }
    
    /// 查找当前时间应该激活的规则
    /// 使用与 TimeRuleService 相同的逻辑：找到最近过去的触发时间对应的规则
    private func findActiveRule(rules: [WidgetTimeRule], at date: Date) -> WidgetTimeRule? {
        guard !rules.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)
        let currentMinutesSinceMidnight = currentHour * 60 + currentMinute
        
        var activeRule: WidgetTimeRule? = nil
        var smallestDiff = Int.max
        
        for rule in rules {
            let ruleMinutes = rule.triggerHour * 60 + rule.triggerMinute
            
            // 计算从规则触发时间到当前时间的差值
            var diff = currentMinutesSinceMidnight - ruleMinutes
            if diff < 0 {
                // 规则时间在当前时间之后，需要加上一天的分钟数
                diff += 24 * 60
            }
            
            // 找到最近触发的规则（差值最小）
            if diff < smallestDiff {
                smallestDiff = diff
                activeRule = rule
            }
        }
        
        return activeRule
    }
    
    /// 获取站点信息（考虑时间规则）
    private func getStationInfo(defaults: UserDefaults, activeRule: WidgetTimeRule?) -> StationInfo {
        if let rule = activeRule {
            print("Widget: 📍 Using time rule station: \(rule.stationName)")
            return getStationInfoFromRule(rule)
        }
        
        // 使用默认存储的站点信息
        let name = defaults.string(forKey: WidgetStorageKeys.selectedStationName) ?? "--"
        let shortName = defaults.string(forKey: WidgetStorageKeys.selectedStationShortName) ?? "--"
        let direction = defaults.string(forKey: WidgetStorageKeys.selectedDirection) ?? "--"
        
        print("Widget: 📍 Using saved station: \(name) (\(shortName)) direction: \(direction)")
        
        return StationInfo(name: name, shortName: shortName, direction: direction)
    }
    
    /// 从规则获取站点信息
    private func getStationInfoFromRule(_ rule: WidgetTimeRule) -> StationInfo {
        return StationInfo(
            name: rule.stationName,
            shortName: rule.stationShortName,
            direction: rule.direction
        )
    }
}

// MARK: - Helper Types

/// 站点信息结构
private struct StationInfo {
    let name: String
    let shortName: String
    let direction: String
}

/// Widget 用的简化版 TimeRule（避免依赖 App 的模型）
private struct WidgetTimeRule: Codable {
    let id: UUID
    let name: String
    let triggerHour: Int
    let triggerMinute: Int
    let stationId: String
    let stationName: String
    let stationShortName: String
    let direction: String
    let isEnabled: Bool
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
                    // 缓存数据显示 "旧" 标识
                    Text(entry.isStale ? "旧" : "min")
                        .font(.system(size: 10))
                        .foregroundColor(entry.isStale ? .yellow : .secondary)
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
                HStack(spacing: 4) {
                    Text(entry.stationName)
                        .font(.headline)
                        .foregroundColor(entry.isStale ? .orange.opacity(0.7) : .orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // 缓存数据标识
                    if entry.isStale && entry.arrivalMinutes != nil {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                
                // 小字显示方向
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
                    // 缓存数据显示 "缓存" 标识
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
    
    /// 方向简写
    private var directionShort: String {
        entry.direction == "E" ? "→" : "←"
    }
    
    var body: some View {
        if let minutes = entry.arrivalMinutes {
            // 站名 方向 时间，缓存数据加 ⏱ 标识
            let cacheIndicator = entry.isStale ? "⏱" : ""
            Label("\(entry.stationShortName) \(directionShort) \(minutes)min\(cacheIndicator)", systemImage: "tram.fill")
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
            if let minutes = entry.arrivalMinutes {
                VStack(spacing: 0) {
                    Text("\(minutes)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(entry.isStale ? .orange.opacity(0.6) : .orange)
                    // 缓存数据显示小字 "旧"
                    if entry.isStale {
                        Text("旧")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                    }
                }
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
