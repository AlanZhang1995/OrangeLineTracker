# 🚇 VTA Transit Tracker

Apple Watch 应用，实时追踪 VTA 轻轨到站时间。支持 Orange、Blue、Green 三条线路。抬腕即可查看下一班车还有多久到站。

## ✨ 功能特性

### 📱 Watch App
- **多线路支持** - 支持 VTA 全部三条轻轨线路：
  - 🟠 Orange Line (Mountain View ↔ Alum Rock)
  - 🔵 Blue Line (Baypointe ↔ Santa Teresa)
  - 🟢 Green Line (Old Ironsides ↔ Winchester)
- **站点选择** - 下拉菜单选择线路和站点
- **方向选择** - 根据线路显示对应方向
- **实时到站时间** - 从 511.org API 获取实时预测数据
- **动态主题色** - UI 颜色随所选线路变化
- **自动刷新** - 智能刷新策略，车近时刷新更频繁

### ⌚ 表盘 Widget (Complication)
- **多种样式** - 支持 Circular、Rectangular、Inline、Corner 四种表盘样式
- **实时倒计时** - 本地计算倒计时，无需频繁请求 API
- **动态颜色** - Widget 颜色随所选线路变化
- **缓存标识** - 数据过期时显示"旧"/"缓存"标识

### ⏰ 时间规则 (Time Rules)
- **自动切换站点** - 根据时间自动切换显示的站点和方向
- **通勤场景** - 例如：早上显示去公司的站，晚上显示回家的站
- **多规则支持** - 可配置多个时间规则
- **Widget 同步** - 规则变化时 Widget 自动更新

### 🌐 多语言支持 (i18n)
- **中英双语** - 支持中文和英文界面
- **实时切换** - 在设置中切换语言，界面即时更新
- **Widget 同步** - Widget 语言与 App 保持一致
- **默认中文** - 首次安装默认使用中文

### 🔑 API Key 配置
- **自定义 API Key** - 用户可配置自己的 511.org API key
- **避免限流** - 使用自己的 key 避免共享 key 被限流
- **免费获取** - 在 511.org 免费申请，每个 key 60次/小时
- **自动验证** - 输入时自动验证 key 格式

### 🔄 智能刷新策略
基于 15 分钟一班车的频率优化：
| 到站时间 | 刷新间隔 |
|---------|---------|
| ≤ 5 分钟 | 1 分钟 |
| 6-10 分钟 | 3 分钟 |
| 11-15 分钟 | 5 分钟 |
| 16-20 分钟 | 8 分钟 |
| > 20 分钟 | 12 分钟 |
| 无数据/错误 | 3 分钟 |
| 🌙 停运时段 (11pm-6am) | 暂停刷新 |

> ⚠️ watchOS 后台刷新受系统限制（约 15 分钟最小间隔），智能刷新主要影响前台活跃时的刷新频率。

## 🛠 技术栈

- **SwiftUI** - 现代声明式 UI
- **WidgetKit** - 表盘 Widget
- **WatchKit** - watchOS 原生开发
- **511.org API** - VTA 实时数据源
- **App Groups** - Watch App 与 Widget 数据共享

## ⚡ 性能优化

- **Widget 刷新节流** - `WidgetRefreshThrottler` 限制最小 2 秒间隔，避免过度刷新
- **站点数据懒加载** - 按线路懒加载站点数据，未使用的线路不占用内存
- **API Key 轮换** - 5 个备用 key 轮换使用，降低单 key 限流风险
- **夜间暂停刷新** - 停运时段 (11pm-6am) 自动暂停后台刷新

## 📋 系统要求

- watchOS 10.0+
- Xcode 15.0+
- Apple Developer 账号（Widget 功能需要付费账号）

## 🚀 安装

1. 克隆仓库
```bash
git clone https://github.com/AlanZhang1995/OrangeLineTracker.git
```

2. 打开 Xcode 项目
```bash
cd OrangeLineTracker
open OrangeLineTracker/OrangeLineTracker.xcodeproj
```

3. 配置签名
   - 选择你的 Team
   - 修改 Bundle Identifier（如需要）

4. 运行到设备
   - 选择 "OrangeLineTracker Watch App" scheme
   - 选择你的 Apple Watch
   - 按 Cmd+R 运行

## 📖 使用说明

### 选择线路和站点
1. 打开 App → 选择页面
2. 从下拉菜单选择线路（Orange/Blue/Green）
3. 从下拉菜单选择站点
4. 返回到站时间页面查看实时信息

### 添加 Widget 到表盘
1. 长按表盘 → 编辑
2. 滑动到 Complications 区域
3. 选择一个位置，找到 "VTA Transit"
4. 选择想要的样式

### 配置时间规则
1. 打开 App → 设置
2. 启用时间规则
3. 添加规则，设置触发时间、线路、站点、方向
4. 规则会在指定时间自动生效

### 配置 API Key（推荐）
1. 访问 [511.org/open-data/token](https://511.org/open-data/token)
2. 创建免费账户并生成 API token
3. 打开 App → 设置 → API 密钥设置
4. 粘贴你的 API key 并保存

> 💡 配置自己的 API key 可以避免与其他用户共享限额导致的限流问题

## 🗺 支持的线路

### 🟠 Orange Line (28 站)
Mountain View ↔ Alum Rock

### 🔵 Blue Line
Baypointe ↔ Santa Teresa

### 🟢 Green Line
Old Ironsides ↔ Winchester

## 📄 License

MIT License

## 🙏 致谢

- [511.org](https://511.org) - 提供 VTA 实时数据 API
- [VTA](https://www.vta.org) - Santa Clara Valley Transportation Authority
