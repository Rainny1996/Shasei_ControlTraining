# 🎯 Bug 修复任务分配

> 项目：男性控制训练 iOS（ControlTraining）
> 测试平台：iPhone 15 Pro / LiveContainer · iOS 17
> 生成日期：2026-07-11 · **状态：✅ 已完结 · 4/4 Bug 已修复并通过 `docs/reviews/v5.9-BUG修复复查报告.md` 源码复查，已发布 v0.0.2（详见文档底部）**

---

## 分配一览

| Bug | 标题 | 严重度 | 指派 AI | 涉及文件数 |
|-----|------|--------|---------|-----------|
| #1 | 评估完成不跳转 | 🟠 P1 | 编码实现AI | 2 个文件 |
| #2 | 智能调整按钮失效 | 🟡 P2 | 编码实现AI | 2 个文件 |
| #3 | 挤压技术图标空白 | 🟡 P2 | 编码实现AI | 1 个文件 |
| #4 | 密码/FaceID 冷启动失效 | 🔴 P0 | 编码实现AI（架构 AI 已审方案） | 3 个文件 |

---

## 任务卡片

---
### #1：评估完成后不跳转

**目标**：`AssessmentView` 提交评估后，自动关闭 sheet 并回到 `PlanView` 展示已生成的计划。

| 项目 | 内容 |
|------|------|
| **指派** | 编码实现AI |
| **优先级** | 🟠 P1 |
| **预计工作量** | 10 分钟 |
| **涉及文件** | `ControlTraining/Modules/Plan/Views/AssessmentView.swift` |
| | `ControlTraining/Modules/Plan/ViewModels/AssessmentViewModel.swift` |
| **方案** | 在 `AssessmentView` 中注入 `@Environment(\.dismiss)`，`AssessmentViewModel.submitAssessment()` 完成后通过回调或监听 `assessmentCompleted` 调用 `dismiss()` |
| **验收条件** | 点击"生成训练计划"后 sheet 自动关闭，回到 `PlanView` 显示新计划 |

---
### #2：智能调整按钮失效

**目标**：点击右上角菜单"智能调整"后，按钮有视觉反馈并能正常执行调整逻辑。

| 项目 | 内容 |
|------|------|
| **指派** | 编码实现AI |
| **优先级** | 🟡 P2 |
| **预计工作量** | 30 分钟 |
| **涉及文件** | `ControlTraining/Modules/Plan/ViewModels/PlanViewModel.swift` |
| | `ControlTraining/Core/Data/Repositories/TrainingRepository.swift` |
| **说明** | `TrainingRepository` 当前缺少 `fetchRecentRecords()` 的真实实现。当前扩展方法在 `PlanViewModel.swift:238-242` 硬编码返回 `[]`，需要挪到 `TrainingRepository.swift` 并实现 Core Data 查询逻辑。`adjustPlanIfNeeded()` 调用成功后建议加一个 loading 指示或 toast |
| **验收条件** | 有训练记录时点击"智能调整"可正常执行调整逻辑；无记录时按钮不报错 |

---
### #3：挤压技术图标空白

**目标**：训练方法列表中"挤压技术"显示正确的 SF Symbol 图标。

| 项目 | 内容 |
|------|------|
| **指派** | 编码实现AI |
| **优先级** | 🟡 P2 |
| **预计工作量** | 2 分钟（改 1 个字符串） |
| **涉及文件** | `ControlTraining/Core/Data/Models/TrainingModels.swift` |
| **方案** | 第 18 行 `case .squeeze: return "hand.press.fill"`（SF Symbols 6，需 iOS 19+）替换为 `"rectangle.compress.vertical"`（SF Symbols 4，iOS 15+ 可用） |
| **验收条件** | 挤压技术显示图标而非空白 |

---
### #4：密码/FaceID 冷启动失效

**目标**：用户设置密码/FaceID 后，再次冷启动 APP 应弹出锁屏界面，而非直接进入主界面。

| 项目 | 内容 |
|------|------|
| **指派** | **编码实现AI**（架构 AI 已审查确认方案） |
| **优先级** | 🔴 P0（安全漏洞） |
| **预计工作量** | 10 分钟 |
| **涉及文件** | `ControlTraining/App/ControlTrainingApp.swift`（AppState.init） |
| | `ControlTraining/App/ContentView.swift`（LockScreenView.onAppear） |
| | `ControlTraining/Core/AppDelegate.swift`（删除冗余调用） |
| **根因** | `AppState.isLocked` 初始化为 `false`（ControlTrainingApp.swift:37），冷启动时无任何代码检查安全状态 |

#### 架构 AI 确认的 3 处精确改动

**改动①** — `ControlTrainingApp.swift`：`AppState.init()` 末尾加 1 行

```swift
init() {
    loadState()
    setupSecurityProtection()
    setupNotificationObservers()
    isLocked = SecurityService.shared.isSecurityEnabled()  // ← 新增
}
```

**改动②** — `ContentView.swift`：`LockScreenView.onAppear` 中 `.none` 模式自动放行

```swift
// 原代码（第 125-131 行）
.onAppear {
    authMode = SecurityService.shared.getAuthMode()
    
    // 如果是生物识别模式，自动触发
    if authMode == .biometric || authMode == .biometricAndPassword {
        tryBiometricAuth()
    }
}

// 改为
.onAppear {
    authMode = SecurityService.shared.getAuthMode()
    
    // 无保护模式直接放行（防止竞态/数据异常卡死）
    guard authMode != .none else {
        appState.isLocked = false
        return
    }
    
    // 如果是生物识别模式，自动触发
    if authMode == .biometric || authMode == .biometricAndPassword {
        tryBiometricAuth()
    }
}
```

**改动③** — `AppDelegate.swift`：删除 `applicationWillEnterForeground` 中的冗余调用

```swift
// 第 23-26 行
// ❌ 删除整个 applicationWillEnterForeground 方法体
// 锁屏认证由 LockScreenView.onAppear 统一管理
```

| **验收条件** | 1. 设密码/开启 FaceID 后杀掉 APP 重新打开 → 显示锁屏（生物识别自动弹出或数字键盘）<br>2. 未设密码 → 正常进入主界面<br>3. 后台切回 → 仍锁定（已有逻辑，不变）<br>4. 锁屏状态下 `.none` 模式不会导致卡死 |

---

## AI 指令模板

### 给编码实现AI 的完整 prompt

请复制以下内容发送给编码实现AI：

```
你需要修复男性控制训练 iOS App 的 4 个 bug，按优先级从高到低依次执行。

项目路径：d:\Project\男性控制训练\男性控制训练
源码目录：ControlTraining/
版本规则：所有改动以增量方式输出，修复完成后版本号推进至 v0.0.2

==================== 按顺序执行以下 4 个任务 ====================

【任务 #4 · 🔴 P0 安全漏洞】密码/FaceID 冷启动失效

目标：用户设置密码/FaceID 后，冷启动 APP 应弹出锁屏，而非直接进入。
涉及 3 个文件，共 3 处精确改动：

改动① — ControlTrainingApp.swift
在 AppState.init() 末尾添加：
  isLocked = SecurityService.shared.isSecurityEnabled()

改动② — ContentView.swift（LockScreenView.onAppear）
在第 125 行附近，将：
  .onAppear {
      authMode = SecurityService.shared.getAuthMode()
      if authMode == .biometric || authMode == .biometricAndPassword {
          tryBiometricAuth()
      }
  }
改为：
  .onAppear {
      authMode = SecurityService.shared.getAuthMode()
      guard authMode != .none else {
          appState.isLocked = false
          return
      }
      if authMode == .biometric || authMode == .biometricAndPassword {
          tryBiometricAuth()
      }
  }

改动③ — AppDelegate.swift
删除 applicationWillEnterForeground 中 SecurityService.shared.authenticateIfNeeded() 的调用。
锁屏认证统一由 LockScreenView.onAppear 管理。

验收条件：
- 设密码/开启 FaceID 后杀掉 APP 重新打开 → 显示锁屏
- 未设密码 → 正常进入主界面
- 后台切回 → 仍锁定（已有逻辑，不变）
- 锁屏状态下 .none 模式不会导致卡死

==============================================================

【任务 #1 · 🟠 P1 功能异常】评估完成后不跳转

目标：AssessmentView 提交评估后，sheet 自动关闭回到 PlanView。
涉及文件：
  - ControlTraining/Modules/Plan/Views/AssessmentView.swift
  - ControlTraining/Modules/Plan/ViewModels/AssessmentViewModel.swift

方案：
1. 在 AssessmentViewModel 中增加 dismiss 回调（例如 @Published var shouldDismiss: Bool）
2. AssessmentView 注入 @Environment(\.dismiss) 或接收闭包
3. submitAssessment() 完成后触发 dismiss

验收条件：点击"生成训练计划"后 sheet 自动关闭，PlanView 显示新计划

==============================================================

【任务 #2 · 🟡 P2 功能缺失】智能调整按钮失效

涉及文件：
  - ControlTraining/Modules/Plan/ViewModels/PlanViewModel.swift（第 238-242 行扩展存根）
  - ControlTraining/Core/Data/Repositories/TrainingRepository.swift

方案：
1. 在 TrainingRepository.swift 中实现 fetchRecentRecords(limit:) 方法，从 Core Data 查询最近训练记录
2. 删除 PlanViewModel.swift 末尾的 extension TrainingRepository 硬编码存根

验收条件：
- 有训练记录时点击"智能调整"可正常执行调整逻辑
- 无记录时按钮不报错

==============================================================

【任务 #3 · 🟡 P2 UI 瑕疵】挤压技术图标空白

涉及文件：
  - ControlTraining/Core/Data/Models/TrainingModels.swift

方案：
第 18 行 case .squeeze: return "hand.press.fill"（SF Symbols 6，需 iOS 19+）
改为：case .squeeze: return "rectangle.compress.vertical"（iOS 15+ 可用）

验收条件：训练方法列表中"挤压技术"显示图标而非空白

==============================================================

通用约束：
- 以增量方式修改，不重构
- 不改动 project.yml / .github/workflows / preview/
- 每个功能改动均保留原注释，仅修改目标代码行
```

---

> **当前状态**：✅ 4/4 Bug 已全部修复并通过 `docs/reviews/v5.9-BUG修复复查报告.md` 源码复查（含编译验证），已发布为 **v0.0.2**（2026-07-11）
> **执行顺序**：#4 (P0) → #1 (P1) → #2 (P2) → #3 (P2)（已全部完成）
> **版本管理**：v0.0.X → 当前 **v0.0.2**（`preview/versions/v0.0.2.html`）
