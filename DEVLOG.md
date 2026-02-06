# VTA Transit Tracker 开发日志

## 2026-02-06 工作总结

### 完成的功能

#### 1. Widget 刷新节流优化
创建 `WidgetRefreshThrottler` 类，限制 Widget 刷新调用最小间隔为 2 秒：
- 避免短时间内多次调用 `WidgetCenter.shared.reloadAllTimelines()` 造成的性能浪费
- 替换了代码中 13 处直接调用为节流版本
- 提供 `forceRefresh()` 方法用于关键更新时绕过节流

**文件**:
- `OrangeLineTracker/OrangeLineTracker Watch App/Services/WidgetRefreshThrottler.swift` - 新增
- `OrangeLineTracker/OrangeLineTracker Watch App/ViewModels/MetroViewModel.swift` - 使用 `reloadWidgets()` 辅助函数
- `OrangeLineTracker/OrangeLineTracker Watch App/ViewModels/TimeRuleViewModel.swift` - 使用节流刷新
- `OrangeLineTracker/OrangeLineTracker Watch App/Background/BackgroundRefreshManager.swift` - 使用节流刷新

#### 2. 站点数据懒加载
将三条线路的站点数据从启动时全部加载改为按需懒加载：
- `OrangeLineStations.stations` - 首次访问时才初始化 26 个站点
- `BlueLineStations.stations` - 首次访问时才初始化 26 个站点
- `GreenLineStations.stations` - 首次访问时才初始化 26 个站点
- 用户只使用 Orange Line 时，Blue/Green Line 数据不占用内存

**文件**:
- `OrangeLineTracker/OrangeLineTracker Watch App/Models/Station.swift` - 重构为懒加载

---

## 2026-02-05 工作总结 (续)

### 完成的功能

#### 1. 多语言支持 (i18n)
实现了完整的中英双语支持：

**架构**:
- `LanguageService` 单例管理语言状态
- `L10n` 枚举提供所有本地化字符串
- 语言偏好存储在 UserDefaults，同时同步到 App Group 供 Widget 使用

**覆盖范围**:
- 所有 UI 文本（标签、按钮、提示）
- 错误消息（网络错误、API 错误、解析错误等）
- Widget 文本
- 时间规则配置摘要

**文件**:
- `OrangeLineTracker/OrangeLineTracker Watch App/Services/LanguageService.swift` - 新增
- `OrangeLineTracker/OrangeLineTracker Watch App/ContentView.swift` - 更新所有视图使用 L10n
- `OrangeLineTracker/OrangeLineTracker Watch App/Views/LineSelectorView.swift` - 更新
- `OrangeLineTracker/OrangeLineTracker Watch App/Views/DirectionPickerView.swift` - 更新
- `OrangeLineTracker/OrangeLineTracker Watch App/ViewModels/MetroViewModel.swift` - lastUpdatedDisplay 使用 L10n
- `OrangeLineTracker/OrangeLineTracker Watch App/ViewModels/TimeRuleViewModel.swift` - configurationSummary 使用 L10n
- `OrangeLineTracker/OrangeLineTracker Watch App/Services/VTAService.swift` - 错误消息使用 L10n
- `OrangeLineTracker/OrangeLineWidget/OrangeLineWidget.swift` - Widget 支持语言切换

#### 2. UX 优化
- 到站时间显示减去 1 分钟（考虑步行到站台时间）
- 智能刷新默认关闭（使用随机间隔更省电）

#### 3. 修复
- 修复整分钟刷新定时器不可靠的问题
- 修复 Blue/Green Line 站点 ID（使用正确的 GTFS stop_id）

---

## 2026-02-05 工作总结

### 完成的功能

#### 1. VTA 全线路支持
扩展应用从仅支持 Orange Line 到支持全部三条 VTA 轻轨线路：
- 🟠 Orange Line (Mountain View ↔ Alum Rock)
- 🔵 Blue Line (Baypointe ↔ Santa Teresa)  
- 🟢 Green Line (Old Ironsides ↔ Winchester)

**实现**:
- `Line` 模型支持多线路数据结构
- `VTAService.fetchAllLines()` 从 API 获取所有线路
- 动态方向支持（E/W 用于 Orange，N/S 用于 Blue/Green）
- 每条线路独立的站点列表和颜色

#### 2. UI 简化 - 合并线路和站点选择
- 移除独立的线路选择页面
- 将线路和站点选择合并到一个页面，使用下拉菜单
- 3 个 Tab：到站时间 → 选择（线路+站点）→ 设置

#### 3. 动态主题色
- 所有 UI 元素颜色随所选线路变化
- 设置页面颜色也跟随线路颜色
- Widget 颜色随线路变化

#### 4. 时间规则显示优化
- 改为两行布局，更紧凑
- 第一行：规则名称 + 触发时间
- 第二行：线路颜色点 + 站点 + 方向

#### 5. API 测试
新增 5 个 API 测试验证所有线路和方向的数据获取：
- `fetchAllLinesReturnsData()` - 验证三条线路存在
- `fetchPredictionsForAllLinesAllDirections()` - 测试所有线路/方向组合
- `fetchOrangeLineBothDirections()` - Orange Line 双向测试
- `fetchBlueLineBothDirections()` - Blue Line 双向测试
- `fetchGreenLineBothDirections()` - Green Line 双向测试

#### 6. 项目清理
- 移除未使用的 iOS App target 和相关文件
- 保留 Watch App、Widget、Tests

**文件变更**:
- `OrangeLineTracker/OrangeLineTracker Watch App/ContentView.swift` - UI 重构
- `OrangeLineTracker/OrangeLineTracker Watch App/ViewModels/MetroViewModel.swift` - 多线路支持
- `OrangeLineTracker/OrangeLineTracker Watch App/Services/VTAService.swift` - 多线路 API
- `OrangeLineTracker/OrangeLineTracker Watch App/Models/Line.swift` - 线路模型
- `OrangeLineTracker/OrangeLineTracker Watch AppTests/VTAServiceTests.swift` - API 测试
- `OrangeLineTracker/OrangeLineWidget/OrangeLineWidget.swift` - Widget 多线路支持

---

## 2026-02-04 工作总结

### 完成的功能

#### 1. Widget 逻辑大幅简化
将 Widget 从独立的时间规则逻辑改为直接读取 App 当前显示的数据：
- Widget 不再有自己的时间规则判断，直接与 ArrivalView 显示保持一致
- 新增共享存储键：`widget_stationName`, `widget_stationShortName`, `widget_direction`, `widget_arrivalTimestamp`, `widget_lastUpdateTime`
- 移除 `WidgetTimeRule` 结构体（不再需要）
- `updateWidgetData()` 方法改为接收站点和方向参数

**文件**:
- `OrangeLineTracker/OrangeLineWidget/OrangeLineWidget.swift` - 完全重写，只读取共享数据
- `OrangeLineTracker/OrangeLineTracker Watch App/Services/StorageService.swift` - 更新存储键和方法签名
- `OrangeLineTracker/OrangeLineTracker Watch App/ViewModels/MetroViewModel.swift` - 更新 updateWidgetData 调用

#### 2. 智能刷新开关设置
添加了智能后台刷新的开关功能，用户可以在设置中选择：
- **开启（默认）**: 使用基于到站时间的智能刷新策略
- **关闭**: 使用 15-60 分钟的随机刷新间隔

**实现**:
- `StorageService` 添加 `isSmartRefreshEnabled` 设置项
- `BackgroundRefreshManager.calculateRandomRefreshInterval()` - 生成 15-60 分钟随机间隔
- `SettingsView` 添加"智能刷新"开关

**文件**:
- `OrangeLineTracker/OrangeLineTracker Watch App/Services/StorageService.swift`
- `OrangeLineTracker/OrangeLineTracker Watch App/Background/BackgroundRefreshManager.swift`
- `OrangeLineTracker/OrangeLineTracker Watch App/ContentView.swift`

#### 2. 前台刷新改为整分钟刷新
将前台 `ArrivalView` 的刷新逻辑改为在每个整分钟（:00 秒）时触发：
- 计算到下一个整分钟的时间间隔，精确在 :00 秒时刷新
- 每个整分钟刷新 API 并更新倒计时显示
- 使用 `Timer.scheduledTimer` 替代 `Timer.publish`，支持动态调度

**文件**: `OrangeLineTracker/OrangeLineTracker Watch App/ContentView.swift`

#### 3. UI 简化
- 设置页面：移除"方向选择"和"当前设置"部分，只保留时间规则和后台刷新设置
- 站点选择页面：移除底部"已选择"显示区域

**文件**: `OrangeLineTracker/OrangeLineTracker Watch App/ContentView.swift`

---

## 2026-02-03 工作总结

### 完成的功能

#### 1. 智能刷新策略优化
基于 VTA Orange Line 15 分钟一班车的频率，实现了 6 档智能刷新：

| 到站时间 | 刷新间隔 |
|---------|---------|
| ≤ 5 分钟 | 1 分钟 |
| 6-10 分钟 | 3 分钟 |
| 11-15 分钟 | 5 分钟 |
| 16-20 分钟 | 8 分钟 |
| > 20 分钟 | 12 分钟 |
| 无数据/错误 | 3 分钟 |

**文件**: `OrangeLineTracker/OrangeLineTracker Watch App/Background/BackgroundRefreshManager.swift`

#### 2. 夜间停运时段暂停刷新
VTA Orange Line 运营时间约为 6:00 AM - 11:00 PM，在停运时段（11pm-6am）暂停 API 刷新，节省电量。

**实现**:
- `isOutsideServiceHours()` - 检测是否在停运时段
- `calculateNextServiceStartTime()` - 计算下一个运营开始时间
- 停运时段直接调度到第二天 6am

#### 3. README 文档更新
- 更新智能刷新策略表格（6 档）
- 添加 watchOS 后台刷新限制说明
- 添加夜间停运时段说明
- 完整列出全部 28 个 Orange Line 站点

#### 4. Git 回滚操作
执行了 `git reset --hard f441d39` 和 `git push origin main --force` 回滚到指定 commit。

### Git Commits
1. `f441d39` - docs: 添加 README 文档（含全部 28 站点）
2. `86fe93f` - feat: 智能刷新策略扩展至6档，更新README
3. `6afed22` - feat: 夜间停运时段(11pm-6am)暂停刷新

### 关键文件
- `OrangeLineTracker/OrangeLineTracker Watch App/Background/BackgroundRefreshManager.swift` - 后台刷新管理
- `README.md` - 项目文档

### 待办/注意事项
- watchOS 后台刷新受系统限制（约 15 分钟最小间隔），智能刷新主要影响前台活跃时的刷新频率
- 免费开发者账号安装 App 需要在 iPhone 设置中信任开发者证书
- Widget 功能需要付费开发者账号（App Groups 不支持免费账号）

### GitHub 仓库
https://github.com/AlanZhang1995/OrangeLineTracker
