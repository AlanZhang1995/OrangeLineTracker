# 截图指南 / Screenshot Guide

## 截图尺寸要求 / Required Sizes

### Apple Watch 截图尺寸
| 设备 | 尺寸 (px) | 必需 |
|------|----------|------|
| 45mm / 49mm Ultra | 410 x 502 | ✅ 是 |
| 44mm | 368 x 448 | 可选 |
| 41mm | 352 x 430 | 可选 |
| 40mm | 324 x 394 | 可选 |

> 注意：App Store Connect 至少需要 45mm 尺寸的截图

## 需要截取的界面 / Screens to Capture

### 1. 到站时间主界面 (Arrivals)
- 显示站点名称
- 显示方向
- 显示倒计时（如 "5 分钟"）
- 显示后续列车时间

### 2. 线路选择界面 (Line Selector)
- 显示三条线路（Orange, Blue, Green）
- 显示线路颜色

### 3. 站点选择界面 (Station Picker)
- 显示线路下拉菜单
- 显示站点下拉菜单
- 显示方向选择

### 4. 设置界面 (Settings)
- 显示语言切换
- 显示时间规则开关
- 显示智能刷新开关

### 5. Widget 表盘 (Complication)
- 显示 Widget 在表盘上的效果
- 建议使用 Modular 或 Infograph 表盘

## 截图步骤 / How to Capture

### 使用模拟器
```bash
# 1. 运行应用到模拟器
xcodebuild -project OrangeLineTracker/OrangeLineTracker.xcodeproj \
  -scheme "OrangeLineTracker Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  build

# 2. 在模拟器中截图
# 菜单: File → Save Screen (Cmd+S)
# 或使用快捷键: Cmd+S
```

### 使用真机
1. 在 Apple Watch 上打开应用
2. 在 iPhone 上打开 Watch 应用
3. 通用 → 截图 → 启用
4. 同时按下数码表冠和侧边按钮
5. 截图保存到 iPhone 相册

## 截图命名规范 / Naming Convention

```
01_arrivals_en.png      - 英文到站时间界面
01_arrivals_zh.png      - 中文到站时间界面
02_line_selector.png    - 线路选择界面
03_station_picker.png   - 站点选择界面
04_settings.png         - 设置界面
05_widget.png           - Widget 表盘截图
```

## 截图优化建议 / Tips

1. **选择有数据的时间** - 在 VTA 运营时间内截图（7am-8pm）
2. **使用真实数据** - 显示真实的到站时间更有说服力
3. **展示不同线路** - 可以用不同线路展示颜色变化
4. **中英文各一套** - 如果支持多语言，建议准备两套截图
5. **保持一致性** - 所有截图使用相同的表盘样式

## App Store Connect 上传

1. 登录 App Store Connect
2. 选择你的 App → App Store → 版本
3. 滚动到 "Apple Watch" 部分
4. 拖拽上传截图
5. 可以为每张截图添加说明文字
