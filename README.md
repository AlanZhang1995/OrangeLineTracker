# 🚇 Orange Line Tracker

Apple Watch 应用，实时追踪 VTA Orange Line 轻轨到站时间。抬腕即可查看下一班车还有多久到站。

## ✨ 功能特性

### 📱 Watch App
- **站点选择** - 支持 Orange Line 全部 28 个站点
- **方向选择** - 东向 (Alum Rock) / 西向 (Mountain View)
- **实时到站时间** - 从 511.org API 获取实时预测数据
- **自动刷新** - 智能刷新策略，车近时刷新更频繁

### ⌚ 表盘 Widget (Complication)
- **多种样式** - 支持 Circular、Rectangular、Inline、Corner 四种表盘样式
- **实时倒计时** - 本地计算倒计时，无需频繁请求 API
- **缓存标识** - 数据过期时显示"旧"/"缓存"标识，避免误导用户

### ⏰ 时间规则 (Time Rules)
- **自动切换站点** - 根据时间自动切换显示的站点和方向
- **通勤场景** - 例如：早上显示去公司的站，晚上显示回家的站
- **多规则支持** - 可配置多个时间规则
- **Widget 同步** - 规则变化时 Widget 自动更新

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

> ⚠️ watchOS 后台刷新受系统限制（约 15 分钟最小间隔），智能刷新主要影响前台活跃时的刷新频率。

## 🛠 技术栈

- **SwiftUI** - 现代声明式 UI
- **WidgetKit** - 表盘 Widget
- **WatchKit** - watchOS 原生开发
- **511.org API** - VTA 实时数据源
- **App Groups** - Watch App 与 Widget 数据共享

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

### 添加 Widget 到表盘
1. 长按表盘 → 编辑
2. 滑动到 Complications 区域
3. 选择一个位置，找到 "Orange Line"
4. 选择想要的样式

### 配置时间规则
1. 打开 App → 设置
2. 启用时间规则
3. 添加规则，设置触发时间、站点、方向
4. 规则会在指定时间自动生效

## 🗺 支持的站点

全部 28 个 Orange Line 站点（从西到东）：

| # | 站点 | 缩写 |
|---|-----|-----|
| 1 | Mountain View | MTV |
| 2 | Whisman | WSM |
| 3 | Middlefield | MDF |
| 4 | Bayshore/NASA | NASA |
| 5 | Moffett Park | MFT |
| 6 | Lockheed Martin | LMT |
| 7 | Borregas | BRG |
| 8 | Crossman | CRS |
| 9 | Fair Oaks | FOK |
| 10 | Vienna | VNA |
| 11 | Reamwood | RWD |
| 12 | Old Ironsides | OIS |
| 13 | Great America | GAM |
| 14 | Lick Mill | LML |
| 15 | Champion | CHP |
| 16 | Baypointe | BPT |
| 17 | Cisco Way | CSC |
| 18 | River Oaks | ROK |
| 19 | Tasman | TSM |
| 20 | Orchard | ORC |
| 21 | Alder | ALD |
| 22 | Great Mall | GML |
| 23 | Milpitas | MLP |
| 24 | Cropley | CRP |
| 25 | Hostetter | HST |
| 26 | Berryessa | BRY |
| 27 | Penitencia Creek | PNC |
| 28 | Alum Rock | ALR |

## 📄 License

MIT License

## 🙏 致谢

- [511.org](https://511.org) - 提供 VTA 实时数据 API
- [VTA](https://www.vta.org) - Santa Clara Valley Transportation Authority
