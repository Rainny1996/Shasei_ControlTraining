# 设计规格 — 需求 10 自定义训练计划

> 角色：需求/设计负责人 ｜ 迭代：v2.1 ｜ 关联 AC：AC-10.1 ~ AC-10.7
> 必读：`requirements.md` §需求10、`PlanModels.swift`、`PlanService.swift`、`PlanViewModel.swift`、`PlanRepository.swift`、`PlanView.swift`（TemplateSelectionView）
> 决策状态：open-questions Q1–Q6 已全部确认，本文据此固化。**Q3 关键变更**：自定义阶段支持「同一天多方法」，数据模型由扁平 `selectedMethodIds/trainingDayOffsets` 改为按日分组的 `dayDrafts` / `days`。

## 0. AC 映射一览
| AC | 设计落点 |
|----|----------|
| AC-10.1 | PlanView 顶部 Menu 新增「自定义计划」入口（≤2 次点击）|
| AC-10.2 | 编辑器以「选模板再改」初始化（模板→草稿预填，按日分组）|
| AC-10.3 | 编辑器以「空白自建」初始化（先选目标/难度，再选方法+排期）|
| AC-10.4 | 编辑器仅暴露「方法 / 每周训练天数 / 具体训练日期」，不暴露时长/强度/周期 |
| AC-10.5 | `UserPlanTemplate` 持久化 + 模板库展示预设与「我的」+ 复用/删除 |
| AC-10.6 | 生成计划写入活跃计划（覆盖前二次确认）+ `updateProgress()` |
| AC-10.7 | 编辑器遵循 Dynamic Type / ≥44pt / VoiceOver |

## 1. 交互流程图（两种起点共用编辑器）

```mermaid
flowchart TD
    A[计划页 Menu: 自定义计划] --> B{选择起点}
    B -->|选模板再改| C[模板列表 planTemplates / 我的模板]
    C -->|选定| D[编辑器: 预填 dayDrafts<br/>draftFromTemplate / draftFromUserTemplate]
    B -->|空白自建| E[选目标/难度 goal + difficulty]
    E --> F[编辑器: 空白 dayDrafts=[]]
    D --> G[编辑器 PlanBuilderView]
    F --> G
    G -->|调整每周训练天数/具体日期| G
    G -->|每日设置方法 可多选 Q3| G
    G -->|保存为我的模板| H[命名弹窗 name]
    H -->|确认| I[UserPlanTemplate 持久化 days]
    I --> G
    G -->|生成计划| J{已有活跃计划?}
    J -->|是| K[二次确认: 将替换当前计划]
    K -->|确认| L[写入活跃计划 + updateProgress]
    J -->|否| L
    K -->|取消| G
    L --> M[计划页刷新]
    G -->|取消| M
```

- **共用编辑器** `PlanBuilderView`，内部状态为内存草稿 `PlanDraft`（见 §2.1）。初始数据源不同（模板预填 vs 全空），后续编辑逻辑完全一致（AC-10.2/10.3/10.4）。
- **仅暴露三类控件**：方法（按日多选 sheet）、每周训练天数（Stepper）、具体训练日期（星期多选）。**不出现**时长/强度/周期入口（AC-10.4）。
- **Q3 每日多方法**：每个训练日通过「设置方法」sheet 可勾选多个方法；生成计划时该日每条 (日,方法) 对应一条 `PlanItem`（见 §3）。

## 2. 草稿与数据模型

### 2.1 编辑器内存草稿（不落库）
```swift
struct DayDraft: Identifiable, Hashable {
    let id: UUID
    var dayOffset: Int        // 0...6，相对 plan.startDate 的星期偏移
    var methodIds: [UUID]      // 该日选择的训练方法（≥1，支持多方法，Q3）
}

struct PlanDraft {
    var sourceTemplateId: UUID? = nil
    var name: String = ""
    var goal: TrainingGoal = .endurance
    var difficulty: DifficultyLevel = .beginner
    var dayDrafts: [DayDraft] = []      // 取代原 selectedMethodIds + trainingDayOffsets

    var allMethodIds: [UUID] { /* 去重保序，全部已选方法，供模板保存/展示 */ }
    var trainingDayOffsets: [Int] { dayDrafts.map { $0.dayOffset }.sorted() } // 兼容既有字段命名
}
```
- 由模板初始化：`draftFromTemplate(_:)` 调 `generatePlanFromTemplate` 得 `TrainingPlan`，**按 `date` 相对 `startDate` 的 dayOffset 分组**各 `item.methodId`，保留「一日多方法」（AC-10.2，呼应 Q3）。
- 由空白初始化：`dayDrafts=[]`、`goal/difficulty` 由用户在起点页选择（AC-10.3）。

### 2.2 新增模型：`UserPlanTemplate`（我的模板）
```swift
struct UserPlanTemplateDay: Codable, Identifiable, Hashable {
    let id: UUID
    var dayOffset: Int
    var methodIds: [UUID]      // 该日方法（≥1）
}

struct UserPlanTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    let difficulty: DifficultyLevel
    let frequency: Int              // 每周训练天数（= days.count）
    let goal: TrainingGoal
    let icon: String
    let days: [UserPlanTemplateDay]  // 每日方法（Q3 支持一日多方法）
    var description: String?        // Q5 确认：可选
    let createdAt: Date
    var updatedAt: Date

    var methodIds: [UUID] { /* 全部方法去重，兼容既有字段命名 */ }
    var trainingDayOffsets: [Int] { days.map { $0.dayOffset }.sorted() }
}
```
- 仍满足需求 10「字段至少含 name/difficulty/frequency/goal/icon/methodIds/trainingDayOffsets」：`methodIds`/`trainingDayOffsets` 作为计算属性保留，物理存储为 `days`。
- `frequency = days.count`（每周训练天数，冗余保存便于模板库展示）。

### 2.3 Core Data 实体 `CDUserPlanTemplate`
| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | UUID | 默认 UUID |
| `name` | String | 非空 |
| `difficulty` | String (raw) | `DifficultyLevel` rawValue |
| `frequency` | Integer 16 | = days.count |
| `goal` | String (raw) | `TrainingGoal` rawValue |
| `icon` | String | 默认 `"star.fill"` |
| `daysData` | Binary | JSON 编码 `[UserPlanTemplateDay]`（承载 Q3 每日多方法）|
| `desc` | String? | 可选（Q5）|
| `createdAt`/`updatedAt` | Date | now |

- **iCloud 排除（AC-7.5/AC-NF.7）**：与计划数据同栈，存储文件已在 `DataController` 配置 `excludeFromBackup`。
- 编解码：`CDUserPlanTemplate+CoreDataClass.swift` 以 `JSONEncoder/Decoder` 在 `daysData` 与 `[UserPlanTemplateDay]` 间转换。
- **迁移提示**：v2.1 开发期以 `daysData` 替换旧 `methodIds`/`trainingDayOffsets`（String 列）。该实体为全新功能、无既有用户数据，轻量迁移（加列 + 删列）由 Core Data 自动推断完成。

### 2.4 与既有模型兼容性
| 模型 | 关系 |
|------|------|
| `PlanTemplate`（预设）| in-code 结构体；`draftFromTemplate` 将其生成的 `TrainingPlan` 按日分组为 `dayDrafts`，**保留预设中已有的「一日多方法」**（如标准+ 每日 2 方法）。模板库 UI 将预设与「我的」以两段展示。 |
| `TrainingPlan`/`PlanItem` | `buildCustomPlan` 产物最终转为 `TrainingPlan`，**不改变**既有 `PlanItem` 字段；每个 (日,方法) 一条 `PlanItem`。 |
| `TrainingMethod` | `methodIds` 经 `TrainingContentData.method(id:)` 解析取 `name/defaultDuration` 构造 `PlanItem`。 |

## 3. `PlanService` 扩展点
```swift
extension PlanService {
    /// 由预设模板生成编辑器草稿（按日分组，AC-10.2）
    func draftFromTemplate(_ template: PlanTemplate) -> PlanDraft
    /// 由「我的模板」还原草稿（AC-10.5 复用）
    func draftFromUserTemplate(_ ut: UserPlanTemplate) -> PlanDraft

    /// 由草稿生成自定义计划（Q3 每日可多方法，AC-10.2/10.3/10.6）
    /// - Parameters:
    ///   - dayDrafts: 各训练日及其方法（dayOffset 0...6，methodIds 可含多项）
    ///   - baseTemplate: 选模板再改时传入（仅用于目标描述）
    ///   - goal: 空白自建时的训练目标
    func buildCustomPlan(dayDrafts: [DayDraft],
                         baseTemplate: PlanTemplate? = nil,
                         goal: TrainingGoal? = nil) -> TrainingPlan
}
```
- `buildCustomPlan`：固定 `periodDays = 7`（`startDate` 今日起，`endDate = +7`）；对每个 `day ∈ dayDrafts`，为 `day.methodIds` 中每个方法生成一条 `PlanItem(date: methodId: methodName: duration: method.defaultDuration)`；`updateProgress()`。
- 不修改 `generatePlan`/`generatePlanFromTemplate`/`adjustPlan` 既有逻辑（AC-10.6 兼容）。

## 4. `PlanViewModel` / `PlanRepository` 契约
```swift
// PlanViewModel
func openCustomPlan(from template: PlanTemplate? = nil)
func loadUserTemplates()
func saveCurrentDraftAsTemplate(name: String)   // 以 dayDrafts 构造 UserPlanTemplate
func deleteUserTemplate(_ id: UUID)
func generatePlanFromDraft()                     // 校验 dayDrafts 非空且至少一天有方法

// PlanRepository（复用，无需新增单条方法）
func saveUserTemplate(_ template: UserPlanTemplate)
func fetchUserTemplates() -> [UserPlanTemplate]
func deleteUserTemplate(_ id: UUID)
```
- `generatePlanFromDraft()`：内部 `commitCustomPlan` 调 `buildCustomPlan(dayDrafts:goal:)` → 覆盖写（`deletePlan` 旧活跃计划）→ `saveTrainingPlan` → `loadPlan()`。

## 5. 无障碍与范围边界（AC-10.7）
- 可点元素 ≥44×44pt；每日方法 sheet 内方法行按钮满足。
- 关键控件加 `.accessibilityLabel`（如「周一 已选 凯格尔运动、呼吸训练」）。
- 不引入新三方库/架构；沿用 MVVM + Repository + Core Data。
- **Q4 确认：v2.1 不做模板就地编辑**；「编辑模板」=「选我的模板再改」后另存为新模板（旧的可删）。
- **Q5 确认：模板含 `description` 字段**。

## 决策记录（open-questions Q1–Q6）
- **Q1**：属需求 12，已确认推荐方案（见 design-需求12）。
- **Q2**：固定 7 天周期（不暴露周期入口，呼应 AC-10.4）。
- **Q3**：**不接受「每日 1 方法」** → 自定义阶段支持同一天多方法，数据模型改为 `dayDrafts`/`days`，`buildCustomPlan` 按 (日,方法) 生成 `PlanItem`。
- **Q4**：v2.1 不做模板就地编辑（复用=选模板再改后另存）。
- **Q5**：含 `description` 字段。
- **Q6**：仅实现全量保存（见 design-需求11）。
