//
//  Line.swift
//  OrangeLineTracker Watch App
//
//  VTA line model supporting all light rail and bus lines
//

import Foundation

/// VTA 线路模型
/// Represents a VTA transit line (light rail or bus)
/// - Validates: Requirements 1.1, 1.2, 1.3
struct Line: Identifiable, Codable, Equatable {
    /// 线路唯一标识（511.org API 中的 LineRef）
    /// Unique identifier for the line (LineRef from 511.org API)
    let id: String
    
    /// 线路显示名称（如 "Orange Line", "Blue Line", "22"）
    /// Display name for the line
    let name: String
    
    /// 线路短名称（用于 Widget 显示）
    /// Short name for widget display
    let shortName: String
    
    /// 线路类型
    /// Type of the line (light rail or bus)
    let type: LineType
    
    /// 线路颜色（十六进制）
    /// Line color in hexadecimal format
    let colorHex: String
    
    /// 线路的两个方向
    /// The two directions of the line
    let directions: [LineDirection]
    
    /// 线路上的所有站点
    /// All stations on this line
    let stations: [Station]
}

/// 线路类型
/// Type of VTA transit line
/// - Validates: Requirements 1.1
enum LineType: String, Codable, Equatable, CaseIterable {
    /// 轻轨 (Light Rail)
    case lightRail = "light_rail"
    
    /// 公交 (Bus)
    case bus = "bus"
}

/// 线路方向
/// Represents a direction of travel on a line
/// - Validates: Requirements 1.3
struct LineDirection: Codable, Equatable {
    /// 方向 ID（"N", "S", "E", "W" 等）
    /// Direction identifier (e.g., "N", "S", "E", "W")
    let id: String
    
    /// 终点站名称
    /// Name of the terminal station (headsign)
    let headsign: String
}
