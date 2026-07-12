# 设计规格 — 需求 12 今日训练动作直达陪练

> 角色：需求/设计负责人 ｜ 迭代：v2.1 ｜ 关联 AC：AC-12.1 ~ AC-12.6
> 必读：`requirements.md` §需求12、`PlanView.swift`（`TodayPlanItemRow`）、`TrainingDetailView.swift`、`CoachView.swift`、`CoachViewModel.swift`、`PlanRepository.markPlanItemCompleted`

## 0. AC 映射一览
| AC | 设计落点 |
|----|----------|
| AC-12.1 | `TodayPlanItemRow` 动作行（非完成按钮）点击 → 进入详情页 |
| AC-12.2 | `PlanItemDetailView` 复用 `TrainingDetailView` 说明 + 计划项信息（日期/时长）+「开始陪练」|
| AC-12.3 | 详情页「开始陪练」→ `CoachView(initialMethod:planItemId:onPlanItemComplete:)` 复用既有陪练 |
| AC-12.4 | 自然完成 → `markPlanItemCompleted(planItemId)`；中途退出（无完整记录）不勾选；幂等 |
| AC-12.5 | 已完成项点击仅查看，不触发新陪练/不重复勾选 |
| AC-12.6 | 入口/行 ≤2 次点击、≥44pt、VoiceOver |

---

## 1. 交互与数据流

```mermaid
flowchart TD
    A[今日训练卡片] -->|点动作行(非完成按钮) AC-12.1| B[PlanItemDetailView]
    B -->|复用 TrainingDetailView 方法说明 AC-12.2/AC-C.2/AC-C.5| C{是否已 completed?}
    C -->|否| D[底部「开始陪练」按钮 AC-12.3]
    C -->|是| E[「已完成」提示, 开始按钮禁用 AC-12.5]
    D -->|点| F[CoachView fullScreenCover<br/>planItemId + initialMethod]
    F -->|自然计时完成| G[saveTrainingRecord isPartial=false]
    G -->|onPlanItemComplete| H[PlanViewModel.markPlanItemCompleted planItemId]
    H -->|幂等| I[刷新计划页(已勾选) AC-12.4]
    F -->|用户中途结束/返回(无完整记录)| J[不触发 onPlanItemComplete AC-12.4]
    E -->|仅查看| K[返回]
```

- **复用而非重写**：详情页方法说明复用 `TrainingDetailView`（已含原理/步骤/注意/禁忌/来源，满足 AC-C.2/AC-C.5），避免重复实现（AC-12.3 精神）。
- **完成判定（关键）**：仅当 `CoachViewModel` 保存了**非 partial** 训练记录（`saveTrainingRecord()`，即自然计时结束）才触发计划项勾选；中途「结束」/返回生成的是 partial 记录，**不**触发（见 §3 改动点 + open-questions Q1）。

---

## 2. 入口改造：`TodayPlanItemRow`（AC-12.1/12.6）

当前 `TodayPlanItemRow` 仅 `onComplete` 闭包（完成按钮），整行 chevron 为装饰。改为：

```swift
struct TodayPlanItemRow: View {
    let item: PlanItem
    let onComplete: () -> Void
    var onTapItem: (() -> Void)? = nil   // 新增：点击行进入详情（AC-12.1）

    var body: some View {
        HStack(spacing: 12) {
            // 完成按钮（保持，区域独立，点击不触发导航）
            Button(action: { if !item.isCompleted { onComplete() } }) { /* ... */ }
                .disabled(item.isCompleted)
                .accessibilityLabel(item.isCompleted ? "已完成" : "标记完成")

            // 训练信息 + chevron 整体作为可点区域（≥44pt）
            Button(action: { onTapItem?() }) {   // 替代原装饰 chevron
                HStack {
                    VStack(alignment: .leading, spacing: 4) { /* methodName + duration */ }
                    Spacer()
                    if item.isCompleted { Text("已完成").foregroundColor(.green) }
                    else { Image(systemName: "chevron.right").foregroundColor(.secondary) }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("查看 \(item.methodName) 详情并开始陪练")
            .accessibilityHint("进入动作详情页")
        }
        // 整卡最小高度 ≥44pt（已有 padding，确认不低于）
    }
}
```

- `PlanView.todayTrainingCard` 传入 `onTapItem: { viewModel.openPlanItemDetail(item) }`（AC-12.1/12.6）。

---

## 3. `CoachView` 契约扩展（AC-12.3/12.4）

### 3.1 初始化签名
```swift
struct CoachView: View {
    var initialMethod: TrainingMethod? = nil
    var planItemId: UUID? = nil                 // 新增：关联计划项
    var onPlanItemComplete: (() -> Void)? = nil // 新增：自然完成回调
    // ...既有 @State 不变
}
```

### 3.2 完成触发点（需小幅改动 `CoachViewModel`）
- `CoachViewModel` 新增发布/闭包属性：
  ```swift
  var onTrainingCompleted: (() -> Void)?   // 仅非 partial 完成触发
  ```
- 在 `saveTrainingRecord()`（非 partial）末尾追加 `onTrainingCompleted?()`（AC-12.4「正常完成」）。
- `savePartialRecordOnBackground()`（强制退出/中途）**不**触发 `onTrainingCompleted`。
- **改动点（呼应 open-questions Q1，已确认）**：当前 `stopTraining()` 调 `completeTraining()` 会生成**非 partial** 记录并触发勾选，与「中途退出不勾选」冲突。建议将 `stopTraining()` 改为保存 **partial** 记录（与后台退出 AC-2.10 一致）且**不**触发 `onTrainingCompleted`；仅 `tickTraining()` 中两处自然结束分支走 `completeTraining()` → 非 partial → 触发。这样「结束」=中途退出不勾选，「自然计时完」=勾选，精确满足 AC-12.4。
- `CoachView` 在 `onAppear`/`completedView` 中，当 `coachViewModel` 完成且非 partial 时调用 `onPlanItemComplete?()`（或直接把 `onPlanItemComplete` 赋给 `coachViewModel.onTrainingCompleted`）。幂等由 `markPlanItemCompleted` 保证（AC-12.4）。

### 3.3 呈现方式
- 详情页以 `.fullScreenCover` 呈现 `CoachView`（与既有 `TrainingDetailView`→`TrainingPreparationView`→`CoachView` 路径一致），保证「复用既有 CoachView 入口」。

---

## 4. `PlanItemDetailView`（AC-12.2/12.5）

建议新增视图，组合复用内容：

```swift
struct PlanItemDetailView: View {
    let item: PlanItem
    let method: TrainingMethod
    @ObservedObject var planViewModel: PlanViewModel
    @ObservedObject var trainingViewModel: TrainingViewModel

    @State private var showCoach = false

    var body: some View {
        VStack(spacing: 0) {
            // 复用既有方法说明展示（满足 AC-C.2/AC-C.5）
            TrainingDetailView(method: method,
                               viewModel: trainingViewModel,
                               onStartCoach: item.isCompleted ? nil : { _ in showCoach = true })  // 见 §5
            // 顶部计划项信息条（日期/时长）
            PlanItemInfoBar(item: item)
            Spacer()
            // 底部固定「开始陪练」
            if item.isCompleted {
                Text("已完成").foregroundColor(.green)   // AC-12.5 仅查看
            } else {
                Button("开始陪练") { showCoach = true }
                    .frame(height: 54).frame(maxWidth: .infinity)
                    .background(Color.accentColor).foregroundColor(.white)
                    .cornerRadius(27)
                    .accessibilityLabel("开始陪练 \(method.name)")
            }
        }
        .fullScreenCover(isPresented: $showCoach) {
            CoachView(initialMethod: method,
                      planItemId: item.id,
                      onPlanItemComplete: { planViewModel.markItemCompleted(item.id) })
        }
    }
}
```

- `PlanItemInfoBar`：展示 `item.date`（格式化）+ `item.duration`（分钟），从 `PlanItem` 既有字段读取，无需新增模型字段。
- 已完成项（`item.isCompleted`）：开始按钮禁用/隐藏，仅查看（AC-12.5）。

---

## 5. `TrainingDetailView` 轻量扩展（复用入口改写）
为让 `PlanItemDetailView` 复用说明但改写启动行为，给 `TrainingDetailView` 增加一个可选闭包（最小改动、范围内）：
```swift
struct TrainingDetailView: View {
    let method: TrainingMethod
    @ObservedObject var viewModel: TrainingViewModel
    var onStartCoach: ((TrainingMethod) -> Void)? = nil   // 新增：非空时替换内部 showStartTraining
    // ...
}
```
- 内部「开始训练」按钮：`onStartCoach?(method) ?? { showStartTraining = true }()`。
- `onStartCoach == nil` 时保持既有训练模块行为不变（向后兼容）。

---

## 6. `PlanViewModel` 契约（AC-12.1/12.4）
```swift
@Published var showPlanItemDetail: Bool = false
@Published var selectedPlanItem: PlanItem?

func openPlanItemDetail(_ item: PlanItem) {       // AC-12.1
    selectedPlanItem = item
    showPlanItemDetail = true
}
// 复用既有：
func markItemCompleted(_ itemId: UUID)            // 已幂等（repository 置 isCompleted=true）
```
- `PlanView` 用 `sheet(isPresented: $showPlanItemDetail)` 呈现 `PlanItemDetailView`（需由 `selectedPlanItem` 解析 `method`：`TrainingContentData.method(id: item.methodId)`）。
- 幂等：repository `markPlanItemCompleted` 直接 `item.isCompleted = true`，重复调用安全（AC-12.4）。

---

## 7. 范围边界
- 不改写陪练计时/语音/阶段逻辑；仅新增 `planItemId` 透传与完成回调。
- 不新增 `PlanItem` 字段（详情信息来自既有 `date/duration/methodId`）。
- 不改 `markPlanItemCompleted` 既有实现（已满足幂等与进度重算）。
- 无障碍：行/按钮 ≥44pt、VoiceOver 标签（AC-12.6）。
