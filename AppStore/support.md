# VTA Transit Tracker - Support / 支持

---

## English

### Frequently Asked Questions

#### Q: Why is there no arrival time showing?
**A:** This can happen for several reasons:
- The station may be a terminus (end of line) - trains depart from there, not arrive
- Service may be outside operating hours (typically 7am-8pm)
- There may be a temporary API issue - try refreshing

#### Q: How do I add the widget to my watch face?
**A:** 
1. Long press on your watch face
2. Tap "Edit"
3. Swipe to the complications area
4. Tap a complication slot
5. Scroll to find "VTA Transit"
6. Select your preferred style

#### Q: Why does the widget show "Old" or "Cached"?
**A:** This indicates the data hasn't been refreshed recently. watchOS limits background refresh frequency. The data will update when you open the app or when the system allows a background refresh.

#### Q: How do I set up Time Rules?
**A:**
1. Open the app → Settings
2. Enable "Auto Switch"
3. Tap "Configure Rules"
4. Add a new rule with your desired time, line, station, and direction

#### Q: Can I use my own API key?
**A:** Yes! Get a free API key from [511.org](https://511.org/open-data/token), then enter it in Settings → API Key Settings.

#### Q: Why should I use my own API key?
**A:** The app includes shared API keys that may hit rate limits during peak usage. Using your own key ensures reliable access.

### Troubleshooting

#### App not refreshing
- Check your internet connection
- Try force-closing and reopening the app
- Ensure Background App Refresh is enabled in Watch settings

#### Widget not updating
- watchOS controls widget refresh timing
- Open the app to force an immediate update
- Check that the app has the correct station selected

### Contact

For bug reports or feature requests, please open an issue on GitHub:
https://github.com/AlanZhang1995/OrangeLineTracker/issues

---

## 中文

### 常见问题

#### 问：为什么没有显示到站时间？
**答：** 这可能有几个原因：
- 该站可能是终点站 - 列车从那里发车，而不是到达
- 可能在运营时间之外（通常是早7点到晚8点）
- 可能是临时的 API 问题 - 尝试刷新

#### 问：如何将小组件添加到表盘？
**答：**
1. 长按表盘
2. 点击"编辑"
3. 滑动到复杂功能区域
4. 点击一个复杂功能位置
5. 滚动找到"VTA Transit"
6. 选择你喜欢的样式

#### 问：为什么小组件显示"旧"或"缓存"？
**答：** 这表示数据最近没有刷新。watchOS 限制后台刷新频率。当你打开应用或系统允许后台刷新时，数据会更新。

#### 问：如何设置时间规则？
**答：**
1. 打开应用 → 设置
2. 启用"自动切换"
3. 点击"配置规则"
4. 添加新规则，设置所需的时间、线路、站点和方向

#### 问：我可以使用自己的 API 密钥吗？
**答：** 可以！从 [511.org](https://511.org/open-data/token) 获取免费 API 密钥，然后在设置 → API 密钥设置中输入。

#### 问：为什么要使用自己的 API 密钥？
**答：** 应用包含的共享 API 密钥在高峰期可能会达到速率限制。使用自己的密钥可确保可靠访问。

### 故障排除

#### 应用不刷新
- 检查网络连接
- 尝试强制关闭并重新打开应用
- 确保在手表设置中启用了后台应用刷新

#### 小组件不更新
- watchOS 控制小组件刷新时间
- 打开应用以强制立即更新
- 检查应用是否选择了正确的站点

### 联系方式

如需报告错误或提出功能请求，请在 GitHub 上提交 issue：
https://github.com/AlanZhang1995/OrangeLineTracker/issues
