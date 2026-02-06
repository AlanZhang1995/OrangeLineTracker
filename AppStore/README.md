# VTA Transit Tracker - App Store 上架材料

## 📋 清单

### 必需材料
- [x] App 名称和副标题
- [x] 描述（英文 + 中文）
- [x] 关键词
- [x] 隐私政策
- [x] 支持页面
- [x] 分类和年龄分级
- [x] 审核备注
- [ ] 截图（需要手动截取）
- [x] App 图标（已有 1024x1024）

### 文件列表
| 文件 | 说明 | 状态 |
|------|------|------|
| `metadata.md` | App Store Connect 元数据 | ✅ |
| `description_en.txt` | 英文描述 | ✅ |
| `description_zh.txt` | 中文描述 | ✅ |
| `keywords.txt` | 搜索关键词 | ✅ |
| `privacy_policy.md` | 隐私政策（中英双语） | ✅ |
| `support.md` | 支持页面（中英双语） | ✅ |
| `review_notes.txt` | 审核备注 | ✅ |
| `screenshots/README.md` | 截图指南 | ✅ |

## 📱 截图要求

详见 `screenshots/README.md`

### 需要截取的界面
1. 到站时间主界面（显示倒计时）
2. 线路选择界面
3. 站点/方向选择界面
4. 设置界面
5. Widget 表盘效果

## 🚀 上架步骤

### 1. 准备工作
- [ ] 确认 App 图标 1024x1024 已就绪
- [ ] 截取所有必需截图
- [ ] 将隐私政策和支持页面部署到可访问的 URL

### 2. App Store Connect
1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 点击 "My Apps" → "+" → "New App"
3. 填写基本信息：
   - Platform: watchOS
   - Name: VTA Transit Tracker
   - Primary Language: Chinese (Simplified)
   - Bundle ID: 选择你的 Bundle ID
   - SKU: vta-transit-tracker-watch

### 3. 填写元数据
从 `metadata.md` 复制以下信息：
- 副标题
- 分类
- 年龄分级
- 版权信息

### 4. 添加描述和关键词
- 英文描述：复制 `description_en.txt`
- 中文描述：复制 `description_zh.txt`
- 关键词：复制 `keywords.txt` 中的关键词

### 5. 上传截图
- 至少需要 45mm 尺寸截图
- 按 `screenshots/README.md` 指南截取

### 6. 设置 URL
- 隐私政策 URL
- 支持 URL
- 营销 URL（可选）

### 7. 审核信息
- 复制 `review_notes.txt` 到审核备注

### 8. 提交审核
- 设置价格为免费
- 选择发布方式（手动/自动）
- 提交审核

## ⏱ 预计审核时间

首次提交通常需要 24-48 小时审核。
