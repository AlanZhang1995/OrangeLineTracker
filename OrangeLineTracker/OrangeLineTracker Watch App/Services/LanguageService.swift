//
//  LanguageService.swift
//  OrangeLineTracker Watch App
//
//  Service for managing app language settings (English/Chinese)
//

import Foundation
import SwiftUI
import Combine

// MARK: - AppLanguage Enum

/// Supported app languages
enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case chinese = "zh"
    
    /// Display name for the language (in its own language)
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
    
    /// Short display name
    var shortName: String {
        switch self {
        case .english: return "EN"
        case .chinese: return "中"
        }
    }
}

// MARK: - Localized Strings

/// All localized strings for the app
enum L10n {
    // MARK: - Common
    static var minutes: String { LanguageService.shared.isEnglish ? "min" : "分钟" }
    static var arriving: String { LanguageService.shared.isEnglish ? "Arriving" : "即将到站" }
    static var boarding: String { LanguageService.shared.isEnglish ? "Boarding" : "进站中" }
    static var scheduled: String { LanguageService.shared.isEnglish ? "Scheduled" : "按计划" }
    static var delayed: String { LanguageService.shared.isEnglish ? "Delayed" : "延误" }
    static var loading: String { LanguageService.shared.isEnglish ? "Loading..." : "加载中..." }
    static var refresh: String { LanguageService.shared.isEnglish ? "Refresh" : "刷新" }
    static var cached: String { LanguageService.shared.isEnglish ? "Cached" : "缓存" }
    static var old: String { LanguageService.shared.isEnglish ? "Old" : "旧" }
    
    // MARK: - Tabs
    static var arrivalTime: String { LanguageService.shared.isEnglish ? "Arrivals" : "到站时间" }
    static var selectLine: String { LanguageService.shared.isEnglish ? "Select Line" : "选择线路" }
    static var selectStation: String { LanguageService.shared.isEnglish ? "Select Station" : "选择站点" }
    static var settings: String { LanguageService.shared.isEnglish ? "Settings" : "设置" }
    
    // MARK: - Arrival View
    static var pleaseSelectStation: String { LanguageService.shared.isEnglish ? "Please select a station" : "请选择站点" }
    static var noTrainInfo: String { LanguageService.shared.isEnglish ? "No train information" : "暂无列车信息" }
    static var checkSchedule: String { LanguageService.shared.isEnglish ? "Please refresh later or check schedule" : "请稍后刷新或检查运营时间" }
    static var showingCachedData: String { LanguageService.shared.isEnglish ? "Showing cached data" : "显示缓存数据" }
    static var nextTrains: String { LanguageService.shared.isEnglish ? "Next trains" : "后续列车" }
    
    // MARK: - Line Selector
    static var lines: String { LanguageService.shared.isEnglish ? "Lines" : "线路" }
    static var lightRail: String { LanguageService.shared.isEnglish ? "Light Rail" : "轻轨" }
    static var bus: String { LanguageService.shared.isEnglish ? "Bus" : "公交" }
    static var favorites: String { LanguageService.shared.isEnglish ? "Favorites" : "收藏" }
    static var allLines: String { LanguageService.shared.isEnglish ? "All Lines" : "全部线路" }
    static var noFavorites: String { LanguageService.shared.isEnglish ? "No favorites yet" : "暂无收藏" }
    static var addFavoriteHint: String { LanguageService.shared.isEnglish ? "Long press a line to add" : "长按线路添加收藏" }
    
    // MARK: - Station Picker
    static var selectLineAndStation: String { LanguageService.shared.isEnglish ? "Select Line & Station" : "选择线路和站点" }
    static var line: String { LanguageService.shared.isEnglish ? "Line" : "线路" }
    static var station: String { LanguageService.shared.isEnglish ? "Station" : "站点" }
    static var pleaseSelectLine: String { LanguageService.shared.isEnglish ? "Please select a line" : "请选择线路" }
    static func stationCount(_ count: Int) -> String {
        LanguageService.shared.isEnglish ? "\(count) stations" : "\(count) 站"
    }
    
    // MARK: - Direction
    static var toEast: String { LanguageService.shared.isEnglish ? "→ East" : "→东" }
    static var toWest: String { LanguageService.shared.isEnglish ? "← West" : "←西" }
    static var toNorth: String { LanguageService.shared.isEnglish ? "↑ North" : "↑北" }
    static var toSouth: String { LanguageService.shared.isEnglish ? "↓ South" : "↓南" }
    
    // MARK: - Settings
    static var autoSwitch: String { LanguageService.shared.isEnglish ? "Auto Switch" : "自动切换" }
    static var autoSwitchDesc: String { LanguageService.shared.isEnglish ? "Auto switch station based on time" : "根据时间自动切换站点和方向" }
    static var configureRules: String { LanguageService.shared.isEnglish ? "Configure Rules" : "配置规则" }
    static func ruleCount(_ count: Int) -> String {
        LanguageService.shared.isEnglish ? "\(count) rules" : "\(count) 条"
    }
    static var smartRefresh: String { LanguageService.shared.isEnglish ? "Smart Refresh" : "智能刷新" }
    static var smartRefreshDesc: String { LanguageService.shared.isEnglish ? "Refresh based on arrival time" : "根据到站时间智能刷新" }
    static var language: String { LanguageService.shared.isEnglish ? "Language" : "语言" }
    static var backgroundRefresh: String { LanguageService.shared.isEnglish ? "Background Refresh" : "后台刷新" }
    
    // MARK: - Time Rule
    static var timeRules: String { LanguageService.shared.isEnglish ? "Time Rules" : "时间规则" }
    static var addRule: String { LanguageService.shared.isEnglish ? "Add Rule" : "添加规则" }
    static var editRule: String { LanguageService.shared.isEnglish ? "Edit Rule" : "编辑规则" }
    static var ruleName: String { LanguageService.shared.isEnglish ? "Rule Name" : "规则名称" }
    static var startTime: String { LanguageService.shared.isEnglish ? "Start Time" : "开始时间" }
    static var endTime: String { LanguageService.shared.isEnglish ? "End Time" : "结束时间" }
    static var weekdays: String { LanguageService.shared.isEnglish ? "Weekdays" : "工作日" }
    static var enabled: String { LanguageService.shared.isEnglish ? "Enabled" : "启用" }
    static var save: String { LanguageService.shared.isEnglish ? "Save" : "保存" }
    static var cancel: String { LanguageService.shared.isEnglish ? "Cancel" : "取消" }
    static var delete: String { LanguageService.shared.isEnglish ? "Delete" : "删除" }
    static var noRules: String { LanguageService.shared.isEnglish ? "No rules configured" : "暂无规则" }
    static var activeRule: String { LanguageService.shared.isEnglish ? "Active Rule" : "当前规则" }
    static var noActiveRule: String { LanguageService.shared.isEnglish ? "No active rule" : "无活动规则" }
    
    // MARK: - Weekday Names
    static var monday: String { LanguageService.shared.isEnglish ? "Mon" : "周一" }
    static var tuesday: String { LanguageService.shared.isEnglish ? "Tue" : "周二" }
    static var wednesday: String { LanguageService.shared.isEnglish ? "Wed" : "周三" }
    static var thursday: String { LanguageService.shared.isEnglish ? "Thu" : "周四" }
    static var friday: String { LanguageService.shared.isEnglish ? "Fri" : "周五" }
    static var saturday: String { LanguageService.shared.isEnglish ? "Sat" : "周六" }
    static var sunday: String { LanguageService.shared.isEnglish ? "Sun" : "周日" }
    
    // MARK: - Updated Time
    static func updatedAt(_ time: String) -> String {
        LanguageService.shared.isEnglish ? "Updated: \(time)" : "更新于 \(time)"
    }
    
    // MARK: - Line Selector Additional
    static var loadingLines: String { LanguageService.shared.isEnglish ? "Loading lines..." : "加载线路中..." }
    static var noLineData: String { LanguageService.shared.isEnglish ? "No line data" : "暂无线路数据" }
    static var checkNetworkRetry: String { LanguageService.shared.isEnglish ? "Check network and retry" : "请检查网络连接后重试" }
    static var retry: String { LanguageService.shared.isEnglish ? "Retry" : "重试" }
    static func totalLines(_ count: Int) -> String {
        LanguageService.shared.isEnglish ? "\(count) lines total" : "共 \(count) 条线路"
    }
    
    // MARK: - Direction Labels
    static var direction: String { LanguageService.shared.isEnglish ? "Direction" : "方向" }
    static var selectDirection: String { LanguageService.shared.isEnglish ? "Select Direction" : "选择方向" }
    
    // MARK: - Time Rule Additional
    static var noTimeRules: String { LanguageService.shared.isEnglish ? "No time rules" : "暂无时间规则" }
    static var addRuleHint: String { LanguageService.shared.isEnglish ? "Add rules to auto-switch commute settings" : "添加规则以自动切换通勤设置" }
    static var configuredRules: String { LanguageService.shared.isEnglish ? "Configured Rules" : "已配置规则" }
    static var swipeToDelete: String { LanguageService.shared.isEnglish ? "Swipe left to delete, tap to edit" : "向左滑动删除规则，点击编辑" }
    static var targetLine: String { LanguageService.shared.isEnglish ? "Target Line" : "目标线路" }
    static var targetStation: String { LanguageService.shared.isEnglish ? "Target Station" : "目标站点" }
    static var targetDirection: String { LanguageService.shared.isEnglish ? "Target Direction" : "目标方向" }
    static var triggerTime: String { LanguageService.shared.isEnglish ? "Trigger Time" : "触发时间" }
    static var enableRule: String { LanguageService.shared.isEnglish ? "Enable Rule" : "启用规则" }
    static var ruleNamePlaceholder: String { LanguageService.shared.isEnglish ? "e.g., Morning Commute" : "例如：早班通勤" }
    static var pleaseEnterRuleName: String { LanguageService.shared.isEnglish ? "Please enter rule name" : "请输入规则名称" }
    static var pleaseSelectValidStation: String { LanguageService.shared.isEnglish ? "Please select a valid station" : "请选择有效的站点" }
    static var done: String { LanguageService.shared.isEnglish ? "Done" : "完成" }
    static var enableAutoSwitchHint: String { LanguageService.shared.isEnglish ? "Enable to auto-switch commute settings by time" : "启用后可根据时间自动切换通勤设置" }
    static var smartRefreshHintOff: String { LanguageService.shared.isEnglish ? "Random interval (15-60 min)" : "使用随机间隔 (15-60分钟)" }
    static var smartRefreshFooter: String { LanguageService.shared.isEnglish ? "Smart refresh adjusts frequency based on train arrival time" : "智能刷新会根据列车到站时间动态调整刷新频率，关闭后使用随机间隔" }
    
    // MARK: - Time Rule Summary
    static var timeRulesDisabled: String { LanguageService.shared.isEnglish ? "Time rules disabled" : "时间规则已禁用" }
    static var noRulesConfigured: String { LanguageService.shared.isEnglish ? "No rules configured" : "未配置规则" }
    static var allRulesDisabled: String { LanguageService.shared.isEnglish ? "All rules disabled" : "所有规则已禁用" }
    static func rulesEnabled(_ count: Int) -> String {
        LanguageService.shared.isEnglish ? "\(count) rules enabled" : "\(count) 条规则已启用"
    }
    
    // MARK: - Widget
    static var widgetOld: String { LanguageService.shared.isEnglish ? "Old" : "旧" }
    static var widgetCached: String { LanguageService.shared.isEnglish ? "Cached" : "缓存" }
    static var widgetMin: String { LanguageService.shared.isEnglish ? "min" : "min" }
    static func directionArrow(_ dir: String) -> String {
        switch dir {
        case "E": return LanguageService.shared.isEnglish ? "→E" : "→东"
        case "W": return LanguageService.shared.isEnglish ? "←W" : "←西"
        case "N": return LanguageService.shared.isEnglish ? "↑N" : "↑北"
        case "S": return LanguageService.shared.isEnglish ? "↓S" : "↓南"
        default: return dir
        }
    }
    
    // MARK: - Error Messages
    static func errorNetworkFailed(_ message: String) -> String {
        LanguageService.shared.isEnglish ? "Network error: \(message)" : "网络连接失败: \(message)"
    }
    static func errorAPI(_ code: Int, _ message: String) -> String {
        LanguageService.shared.isEnglish ? "API error (\(code)): \(message)" : "API 错误 (\(code)): \(message)"
    }
    static func errorParsing(_ message: String) -> String {
        LanguageService.shared.isEnglish ? "Data parsing error: \(message)" : "数据解析错误: \(message)"
    }
    static var errorInvalidAPIKey: String { LanguageService.shared.isEnglish ? "Invalid API key, please check configuration" : "API 密钥无效，请检查配置" }
    static var errorInvalidURL: String { LanguageService.shared.isEnglish ? "Invalid request URL" : "无效的请求地址" }
    
    // MARK: - Accessibility
    static var selected: String { LanguageService.shared.isEnglish ? "selected" : "已选择" }
    static var notSelected: String { LanguageService.shared.isEnglish ? "not selected" : "未选择" }
    static var favorited: String { LanguageService.shared.isEnglish ? "favorited" : "已收藏" }
    static var notFavorited: String { LanguageService.shared.isEnglish ? "not favorited" : "未收藏" }
    static var currentlySelected: String { LanguageService.shared.isEnglish ? "Currently selected" : "当前选中" }
    static var doubleTapToSelect: String { LanguageService.shared.isEnglish ? "Double tap to select" : "双击选择" }
    static var removeFavorite: String { LanguageService.shared.isEnglish ? "Remove from favorites" : "取消收藏" }
    static var addToFavorites: String { LanguageService.shared.isEnglish ? "Add to favorites" : "添加收藏" }
    static var doubleTapToRemove: String { LanguageService.shared.isEnglish ? "Double tap to remove" : "双击从收藏中移除" }
    static var doubleTapToAdd: String { LanguageService.shared.isEnglish ? "Double tap to add" : "双击添加到收藏" }
    static var enabledStatus: String { LanguageService.shared.isEnglish ? "enabled" : "已启用" }
    static var disabledStatus: String { LanguageService.shared.isEnglish ? "disabled" : "已禁用" }
    static var doubleTapToEdit: String { LanguageService.shared.isEnglish ? "Double tap to edit" : "双击编辑规则" }
    
    // MARK: - API Key Settings
    static var apiKey: String { LanguageService.shared.isEnglish ? "API Key" : "API 密钥" }
    static var apiKeySettings: String { LanguageService.shared.isEnglish ? "API Key Settings" : "API 密钥设置" }
    static var yourAPIKey: String { LanguageService.shared.isEnglish ? "Your API Key" : "你的 API 密钥" }
    static var apiKeyPlaceholder: String { LanguageService.shared.isEnglish ? "Enter your 511.org API key" : "输入你的 511.org API 密钥" }
    static var apiKeyConfigured: String { LanguageService.shared.isEnglish ? "Using your API key" : "使用你的 API 密钥" }
    static var apiKeyNotConfigured: String { LanguageService.shared.isEnglish ? "Using shared key (may be rate limited)" : "使用共享密钥（可能被限流）" }
    static var getAPIKey: String { LanguageService.shared.isEnglish ? "Get free API key at 511.org" : "在 511.org 免费获取 API 密钥" }
    static var clearAPIKey: String { LanguageService.shared.isEnglish ? "Clear API Key" : "清除 API 密钥" }
    static var apiKeyInvalid: String { LanguageService.shared.isEnglish ? "Invalid API key format" : "API 密钥格式无效" }
    static var apiKeySaved: String { LanguageService.shared.isEnglish ? "API key saved" : "API 密钥已保存" }
    static var apiKeyCleared: String { LanguageService.shared.isEnglish ? "API key cleared" : "API 密钥已清除" }
    static var apiKeyFooter: String { LanguageService.shared.isEnglish ? "Get your free API key from 511.org to avoid rate limiting" : "从 511.org 获取免费 API 密钥以避免限流" }
}

// MARK: - LanguageService

/// Service for managing app language
class LanguageService: ObservableObject {
    
    /// Shared singleton instance
    static let shared = LanguageService()
    
    /// Storage key for language preference
    private let languageKey = "appLanguage"
    
    /// App Group identifier for sharing with widget
    private let appGroupIdentifier = "group.com.orangelinetracker"
    
    /// UserDefaults instance
    private let userDefaults: UserDefaults
    
    /// Shared UserDefaults for widget
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// Current app language
    @Published var currentLanguage: AppLanguage {
        didSet {
            userDefaults.set(currentLanguage.rawValue, forKey: languageKey)
            // Also save to shared defaults for widget
            sharedDefaults?.set(currentLanguage.rawValue, forKey: languageKey)
        }
    }
    
    /// Convenience property to check if current language is English
    var isEnglish: Bool {
        currentLanguage == .english
    }
    
    /// Convenience property to check if current language is Chinese
    var isChinese: Bool {
        currentLanguage == .chinese
    }
    
    /// Private initializer for singleton
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // Load saved language or default to Chinese
        if let savedLanguage = userDefaults.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Default to Chinese
            self.currentLanguage = .chinese
        }
        
        // Sync to shared defaults on init
        sharedDefaults?.set(currentLanguage.rawValue, forKey: languageKey)
    }
    
    /// Toggle between English and Chinese
    func toggleLanguage() {
        currentLanguage = isEnglish ? .chinese : .english
    }
    
    /// Set language explicitly
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
}
