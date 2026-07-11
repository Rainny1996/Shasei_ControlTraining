# UI Preview Changelog

## [v0.0.2] - 2026-07-11

> 本次为 **Bug Fix 迭代版本**，基于 v0.0.1 液态玻璃风格，叠加 4 项用户反馈 Bug 修复（应用侧对应 `docs/reviews/v5.9-BUG修复复查报告.md`）。

### Fixed
- **#4（P0 安全）密码/FaceID 冷启动失效**
  - `AppState.init()` 末尾新增 `isLocked = SecurityService.shared.isSecurityEnabled()`，冷启动正确进入锁屏
  - `LockScreenView.onAppear` 增加 `.none` 模式自动放行（防竞态/数据异常卡死）
  - 移除 `AppDelegate.applicationWillEnterForeground` 中冗余 `authenticateIfNeeded()`（消除双重 Face ID 弹窗）
- **#1（P1）评估完成不跳转** — 提交评估后 sheet 自动关闭并展示已生成计划（`shouldDismiss` 驱动 `@Environment(\.dismiss)`）
- **#2（P2）智能调整按钮失效** — `TrainingRepository.fetchRecentRecords` 实现真实 Core Data 查询，删除残留硬编码存根
- **#3（P2）挤压技术图标空白** — SF Symbol `hand.press.fill`（iOS 19+）改为 `rectangle.compress.vertical`（iOS 15+）

### Preview Files
- `preview/versions/v0.0.2.html`（在 v0.0.1 基础上新增「本次更新」面板，原 `v0.0.1.html` 保留）

---

## [v0.0.1] - 2026-07-11

### Added
- **全新 iOS 27 Liquid Glass（液态玻璃）设计风格预览**
  - 深色渐变背景 + 多层半透明玻璃面板
  - `backdrop-filter: blur()` 毛玻璃效果
  - 动态光照与微动效
  - 自适应颜色系统（默认/着色模式参考）
- 5 个主要页面：首页 / 训练 / 计划 / 状态 / 我的
- 全屏陪练模式（液态玻璃版呼吸动画）
- 训练方法详情覆盖层
- 日历热力图
- 五维能力雷达图与趋势线

### Design Features
- **Glass Surface**: `rgba(255,255,255,0.06–0.18)` 半透明底色 + `backdrop-filter: blur(40–60px)`
- **Depth Layers**: 3 层深度结构（背景 → 次级玻璃 → 主玻璃）
- **Vibrant Accents**: 青绿渐变主色 + 紫粉点缀 + 暖橙珊瑚强调
- **Dynamic Lighting**: `radial-gradient` 模拟光源、hover 时玻璃光晕变化
- **Typography**: `SF Pro Display` / `PingFang SC`，细体字重 + 宽松字距
- **Border Treatment**: 超细 `rgba(255,255,255,0.06–0.12)` 边框模拟玻璃边缘反光

### Technical
- 纯 HTML + CSS + vanilla JS，浏览器直接打开即可预览
- iPhone 15 Pro 尺寸模拟框（390×844pt）
- 无外部依赖
