# 工作流分工 Prompt — 03 SwiftUI 前端

> 本文件为「男性控制训练」iOS App **v2.1 训练计划增强**迭代中「SwiftUI 前端」角色的下游 AI 执行 prompt。请在既有 MVVM + `PlanView` 架构上增量开发，复用既有组件，不要重写既有视图。

## 你的角色与目标
你是本迭代的**前端负责人**。负责把需求 10/11/12 落地为 SwiftUI 界面与视图模型逻辑：
1. 计划页新增「自定义计划」「编辑计划」入口，今日动作行点击进入详情；
2. 新增三个视图：`PlanBuilderView` / `PlanEditView` / `PlanItemDetailView`；
3. 扩展 `PlanViewModel` 与 `CoachView` 以打通数据流与完成回调。

## 必读上下文（先读再改）
- 需求规格：`男性控制训练/男性控制训练/docs/specs/requirements.md` → 需求 10（AC-10.1~10.7）、需求 11（AC-11.1~11.7）、需求 12（AC-12.1~12.6）。
- 主视图：`ControlTraining/Modules/Plan/Views/PlanView.swift`（菜单 `Menu`、无计划页 `noPlanView`、`todayTrainingCard` / `TodayPlanItemRow`）。
- 视图模型：`ControlTraining/Modules/Plan/ViewModels/PlanViewModel.swift`（已有 `createPlanFromTemplate` / `regeneratePlan` / `adjustPlanIfNeeded` / `markItemCompleted`；新增方法需在此扩展）。
- 服务/数据：`ControlTraining/Modules/Plan/Services/PlanService.swift`、`ControlTraining/Core/Data/Models/PlanModels.swift`、`TrainingContentData.allTrainingMethods()`（方法池）。
- 陪练入口：`ControlTraining/Modules/Coach/Views/CoachView.swift`（确认 `initialMethod` 等既有启动参数，追加 `planItemId` 与完成回调）。
- 方法说明：`ControlTraining/Modules/Training/Views/TrainingDetailView.swift`（详情页复用其说明展示以满足 AC-C.2/AC-C.5）。
- 设计契约（如已产出）：`docs/ai-workflow/plan-v2.1/design-需求10-自定义计划.md`、`design-需求11-逐条编辑.md`、`design-需求12-直达陪练.md`。

## 具体任务
### 需求 10 — 自定义训练计划（AC-10.1~10.7）
- 在 `PlanView` 的 `Menu`（及 `noPlanView`）新增「自定义计划」入口，NavigationLink/sheet 到 **`PlanBuilderView`**（≤ 2 次点击，AC-10.1）。
- `PlanBuilderView`：
  - 支持「选模板再改」与「空白自建」两种模式（用 `PlanService.allTemplatesForSelection()` 作模板源；选模板后预填方法与排期）。
  - 仅暴露三类调整：**方法多选**（来自 `allTrainingMethods()`）、**每周训练天数**、**具体训练日期**（AC-10.4，不暴露时长/强度/周期）。
  - 提供「保存为我的模板」（输入名称）→ 调用 `PlanViewModel.saveUserTemplate(...)`。
  - 提供「生成计划」→ `PlanService.buildCustomPlan(...)` → `PlanRepository.saveTrainingPlan`；覆盖已有活跃计划前**二次确认**（明确"将替换当前计划"，AC-10.6）。
- 模板选择器合并展示预设 + 「我的模板」，支持删除「我的模板」。

### 需求 11 — 当前计划逐条编辑（AC-11.1~11.7）
- `PlanView` 新增「编辑计划」入口 → sheet 到 **`PlanEditView`**。
- `PlanEditView`：列表展示 `currentPlan.items`；逐条可改方法（Picker）、时长（Stepper/TextField，单位分钟）、所在日期（DatePicker 限定在周期内）；支持增删某天项目（新增从方法池选）。
- 编辑态为内存草稿；「取消」不落库（AC-11.5）。「保存」调用 `PlanViewModel` 新增的 `addPlanItem` / `updatePlanItem` / `removePlanItem`，并触发进度重算与视图刷新（AC-11.4）。
- 保存校验：时长 > 0、日期在 `[startDate, endDate]` 内，越界阻止保存并提示（AC-11.5）。
- 保留「智能调整」入口（不移除 `adjustPlanIfNeeded`）。

### 需求 12 — 今日训练动作直达陪练（AC-12.1~12.6）
- `TodayPlanItemRow`：点击**动作行主体**（非完成按钮）用 `NavigationLink` 进入 **`PlanItemDetailView(item:)`**（AC-12.1）；完成按钮逻辑保持原样。
- `PlanItemDetailView`：复用 `TrainingDetailView` 的方法说明组件（原理/步骤/注意/禁忌/来源 + 计划项日期/时长），底部「开始陪练」按钮（AC-12.2）。
- 「开始陪练」→ 进入 `CoachView`，携带该 `PlanItem` 的 `methodId` 与 `planItemId`（AC-12.3）。
- 陪练**正常完成**（生成训练记录）后回调 `PlanViewModel.markItemCompleted(planItemId)` 并 `loadPlan()` 刷新；中途自行退出**不**勾选（AC-12.4）。已 `isCompleted` 项点击仅查看、不重复触发（AC-12.5）。

## 约束
- 目标用户 35–55 岁：可点击区 ≥ 44×44 pt（AC-NF.5）、Dynamic Type（AC-NF.4）、关键元素 VoiceOver 标签（AC-NF.6）、关键操作 ≤ 2 次点击（AC-NF 量化约定）。
- 纯离线、iOS 16+、SwiftUI；不引入新三方库、不改动 `HomeView` 导航结构；新视图以 sheet/NavigationLink 挂载于 `PlanView`。
- 复用既有 `PlanRepository` / `PlanService`，不重复实现陪练逻辑。

## 验收门槛
- 三个新视图均可从计划页 ≤ 2 次点击到达，且无编译错误。
- 自定义计划两种模式均可生成合法活跃计划；「我的模板」可保存/复用/删除。
- 逐条编辑保存后进度/日历/今日视图实时刷新；取消不落库；越界校验生效。
- 今日动作行点击进入详情并可开始陪练；正常完成后该项自动勾选；已完成项仅可查看。
- 真机/模拟器下满足 Dynamic Type 最大字号不溢出、VoiceOver 可聚焦关键元素。
