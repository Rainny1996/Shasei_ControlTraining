# 实现任务（v2.2 修订版）

> **文档状态**：v2.2（对齐需求 v2.2，新增需求 13 方法专属模式与逐动作语音；含 v2.0 需求 8/9/合规/iCloud/陪练健壮性任务 13–17）
> **最后更新**：2026-07-12
> **图例**：`[x]` 已完成（首轮开发）｜`[ ]` 待办（本版新增/修订）｜每条任务列出覆盖的 `AC-x.y` 以便追溯

## 任务概览
- 首轮已完成：12
- 历史新增/修订：任务 13–17（需求 8/9/合规/iCloud/陪练健壮性，待办）
- 本版新增：任务 18–23（需求 13 方法专属模式与逐动作语音）

---

## 开发任务（首轮，已完成）

- [x] 1. 项目基础架构搭建 — _AC: 7.1, 7.2, 7.3, 7.6_
  - Xcode 项目、SwiftUI+UIKit 混合、MVVM+Clean 目录、Core Data 栈、TabView 框架

- [x] 2. 数据模型层开发 — _AC: 1–7 数据底座, 5.7(selfRating 校验), 7.2(单一加密入口)_
  - Core Data 实体、Repository、加密存储（**须统一 CryptoService 单密钥，规避 BUG-CT-03**）
  - 数据模型单元测试

- [x] 3. 训练方法介绍模块 — _AC: 1.1–1.6_
  - 分类列表+难度筛选、详情页、**收藏(≤2 次点击)**、内置内容数据

- [x] 4. 实时陪练模块 — _AC: 2.1–2.8（2.9/2.10 待补）_
  - 模式选择、倒计时、环形计时器、TTS 语音、呼吸动画、暂停/继续、后台播放、结束记录
  - ⚠️ 缺：**预录音效 + AudioService 统一会话配置（BUG-CT-06）**、来电中断处理（AC-2.9）、部分记录（AC-2.10）

- [x] 5. 个人计划制定模块 — _AC: 3.1–3.8_
  - 评估问卷、计划生成（**按 §2.6.1 映射表**）、日历/进度、手动调整、动态调整+记录、提醒通知、模板

- [x] 6. 每日打卡模块 — _AC: 4.1–4.8_
  - 首页状态、打卡交互、日历热力图、连续统计、补签(默认3次)、成就、**有效打卡定义**

- [x] 7. 复盘功能模块 — _AC: 5.1–5.7_
  - 复盘问卷(1–5)、历史列表、趋势图表、周/月报告、文字备注

- [x] 8. 当前状态分析模块 — _AC: 6.1–6.8_
  - **按 §2.6.2 加权模型**实现综合评分/维度/等级/趋势/建议/薄弱识别/每周重算
  - ⚠️ 须补足单元测试断言（AC-6.8）

- [x] 9. 隐私安全模块 — _AC: 7.1–7.4（7.5 待补）_
  - Face/Touch ID、后台模糊（`scenePhase` 触发，**单一注册点规避 BUG-CT-01**）、密码锁、图标名称合规
  - ⚠️ 缺：iCloud 备份排除（AC-7.5）

- [x] 10. 首页与整体集成 — _AC: 1–7 集成, 9.4(首启引导)_
  - 今日概览、快捷入口、深色/浅色、首次引导（问卷→隐私说明→主页）

- [x] 11. 测试与优化 — _AC: 1–7 质量保障_
  - 业务逻辑单测、UI 测试、性能测试、缺陷修复
  - ⚠️ **修正声明**：v1.0 代码审查指出"无 UI 测试/无集成测试"。现已补齐：`project.yml` 增加 unit-test/ui-testing 两个 target（此前无测试 target，用例从未被构建运行），新增 `ControlTrainingTests/Core/Integration/IntegrationTests.swift`（5 例跨层闭环）+ `ControlTrainingUITests/`（2 例 UI 冒烟），CI 经 `test.yml` 实际运行 166 用例。详见 `docs/reviews/v4.0-测试覆盖审查报告.md`。

## 发布任务（首轮，已完成）

- [x] 12. 应用发布准备 — _AC: C.4, C.3(隐私政策)_
  - App Store 元数据、隐私政策、**最终测试与 Bug 修复**、提交审核
  - ⚠️ 建议补：免责声明页（AC-C.1）、训练方法来源标注（AC-C.2）

---

## 新增 / 修订任务（本版，待办）

- [ ] 13. 数据管理模块（需求 8）— _AC: 8.1–8.5_
  - 加密导出为文件（生物识别/密码确认）
  - 从导出文件恢复（完整性校验）
  - 一键彻底删除（Core Data `viewContext.reset()` + Keychain 清理，规避 BUG-CT-02）
  - 二次确认 + "不可恢复"提示 + 零覆盖（BUG-CT 既有 memset 保留）
  - DataViewModel + DataModule 目录与「我的页」入口

- [ ] 14. 设置与无障碍模块（需求 9）— _AC: 9.1–9.4, NF.4–NF.6_
  - 设置页：提醒开关、生物识别开关、字号偏好(标准/大/超大)、呼吸默认开关
  - 偏好持久化（UserDefaults 键名集中为枚举，呼应 S04）
  - Dynamic Type 全局联动（不重启生效）
  - VoiceOver 标签 + 44pt 触控区适配
  - SettingsViewModel + SettingsModule

- [ ] 15. 合规页面与来源标注（§6）— _AC: C.1–C.5_
  - 免责声明页（AC-C.1）
  - 隐私政策页（AC-C.3）
  - 训练方法详情补充来源标注与禁忌人群字段（AC-C.2 / AC-C.5，关联任务 3 模型 `TrainingMethod.source/contraindication`）

- [ ] 16. iCloud 备份排除（需求 7.5）— _AC: 7.5_
  - Core Data 存储目录添加 `skipBackup` 属性
  - 验证备份不包含数据库

- [ ] 17. 陪练健壮性补全（需求 2 遗漏）— _AC: 2.9, 2.10_
  - 预录关键音效 + `AudioService` 统一音频会话配置（修复 BUG-CT-06）
  - 来电/抢占中断 → 计时暂停 + 手动恢复提示（AC-2.9）
  - 强制退出 → 部分训练记录 `isPartial=true`（AC-2.10，关联模型 `TrainingRecord.isPartial`）

---

## 新增任务（需求 13：方法专属模式与逐动作语音，待办）

> 验收标准见 `requirements.md` 需求 13（AC-13.1~AC-13.10）与 `design-需求13` 设计规格。

- [ ] 18. 数据模型：方法专属模式目录 — _AC: 13.1, 13.3, 13.10_
  - `TrainingModels.swift` 新增 `MethodMode` / `ModeActionStep` 结构体（id/名称/难度/动作步骤数组）
  - `TrainingMethod` 增加 `trainingModes: [MethodMode]` 字段
  - `TrainingRecord` 增加 `modeId` / `modeName`（兼容保留遗留 `TrainingMode` 枚举）
  - `TrainingActionPhase` 扩展分类（收缩/放松/暂停/呼吸/刺激等，用于配色与图标）
  - `TrainingContentData` 为五方法填充专属模式与动作脚本，语音文案与既有方法说明一致

- [ ] 19. 陪练核心：按 MethodMode 生成阶段序列 — _AC: 13.3, 13.4, 13.5_
  - `CoachViewModel` 增加 `init(method:selectedMode:)`，缺省取 `method.trainingModes.first`
  - `generatePhaseSequence()` 用所选 `MethodMode.steps` 循环铺满 `defaultDuration`
  - 计时/进度展示改用步骤 `label`；`announcePhaseTransition()` 播报逐动作语音（替代旧 `announceContract/Relax/Rest` 切换逻辑）

- [ ] 20. 陪练 UI：模式选择改为方法专属并带入 initialMode — _AC: 13.2, 13.6, 13.8_
  - `CoachView`：`selectedMode: TrainingMode` → `selectedMethodMode: MethodMode?`；模式卡片遍历 `method.trainingModes`；完成统计显示模式名；`startTraining()` 传所选模式
  - `TrainingPreparationView`（TrainingDetailView.swift）：模式选择适配 `MethodMode`，补传 `initialMode` 给 `CoachView`
  - `PlanItemDetailView`：由 `item.modeId` 解析 `initialMode` 预选
  - `TrainingTimerView`：动作配色按扩展后的 `TrainingActionPhase` 映射
  - 满足 Dynamic Type / 44pt / VoiceOver

- [ ] 21. 语音服务：逐动作语音 — _AC: 13.4_
  - `VoiceGuideService` 新增 `announceActionInstruction(_ step: ModeActionStep)`，播报 `voiceInstruction` + 可选 `breathInstruction`
  - 保留 `announceActionPhase` 兼容方法；`AudioService` 保留 `announceContract/Relax/Rest` 兼容

- [ ] 22. 计划联动：所选模式持久化与聚合 — _AC: 13.6, 13.7, 13.9_
  - `PlanItem` 增加 `modeId` / `modeName`；`DayDraft` / `UserPlanTemplateDay` 由扁平 `methodIds:[UUID]` **升级为** `methodSelections:[(methodId:UUID, modeId:UUID?)]`（per-method 模式，保留「一日多方法」Q3，**同步改造 需求 10 数据模型**，不推翻其按日分组结构）
  - `PlanService.buildCustomPlan` / `generatePlanFromTemplate` / `draftFromTemplate` / `draftFromUserTemplate` 由 `methodSelections` 生成带 mode 的 `PlanItem`（透传模式）
  - `PlanBuilderView`：每方法选中后提供该方法模式选择（默认首个），写入 `modeIds`
  - `PlanViewModel.commitCustomPlan` / `saveCurrentDraftAsTemplate` 透传所选模式
  - `AnalysisService`：聚合维度由 `mode` 改为 `modeName`（空则回退 `mode.rawValue`）

- [ ] 23. 测试与回归验证 — _AC: 13.1, 13.4, 13.9_
  - 用 code-explorer 全量定位 `TrainingMode` / `TrainingRecord(mode:)` / `selectedMode` / `CoachView` 初始化透传点，确保无遗漏改动
  - 校验 `TrainingMode` 枚举保留后既有 `ModelTests.testTrainingModeEnum` 不受影响；`TrainingRecord(mode:)` 新增参数为可选，确保全量测试编译通过
  - 新增单元测试：模式目录完整性（每方法≥2模式、每模式≥2步骤）、逐动作语音文案非空、计划项模式落库与陪练预选闭环

---

## 缺陷修复追溯（建议纳入跟踪，呼应三版代码审查）

| 缺陷 | 关联任务/AC | 状态 |
|------|-------------|------|
| BUG-CT-01 后台锁双注册 | 任务 9 / §2.4 | v3.0 已关闭 |
| BUG-CT-02 删除后缓存未刷新 | 任务 13 / AC-8.3 | v3.0 已关闭 |
| BUG-CT-03 双加密密钥 | 任务 2 / AC-7.2 / §2.4 | v3.0 已关闭 |
| BUG-CT-04 文件保护重复 | 任务 9 / §2.4 | v1.0 已关闭 |
| BUG-CT-05 selfRating 越界 | 任务 2 / AC-5.7 / §2.2.2 | v1.0 已关闭 |
| BUG-CT-06 音频会话重复 | 任务 17 / AC-2.9 | 待补 |
| S01–S08 建议项 | 任务 14(国际化/日志) 等 | 部分待办 |

> 说明：上述缺陷修复在首轮开发中完成（v3.0 报告整体放行），但未在 spec 任务中显式跟踪；建议后续将"缺陷修复"作为独立跟踪项，形成"需求(AC)→任务→缺陷(BUG)"闭环。
