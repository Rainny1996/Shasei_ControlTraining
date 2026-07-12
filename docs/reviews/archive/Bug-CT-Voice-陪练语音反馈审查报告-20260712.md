# 陪练语音反馈代码审查报告（Bug-CT-Voice-20260712）

**审查对象**：实时语音陪练模块（`CoachView` / `CoachViewModel` / `AudioService` / `VoiceGuideService` / `AppDelegate` / `Info.plist`）
**审查依据**：用户提交的两项使用反馈
**审查方式**：静态源码审查（Windows 环境，无法真机编译验证）
**审查日期**：2026-07-12

---

## 一、反馈摘要

| 编号 | 用户反馈 | 严重度 |
|------|----------|--------|
| B1 | 进入实时语音陪练后，数字一直卡在 **3** 不变 | 高（功能不可用） |
| B2 | 陪练进行中**关闭屏幕，语音立刻停止**，无法在熄屏/后台继续播报 | 高（核心场景失效） |

---

## 二、Bug 1：倒计时/进度数字卡在 3

### 现象
进入陪练 → "准备开始"倒计时界面后，大号数字恒为 `3`，且全程不切换阶段、不进入训练视图，但底层训练逻辑其实在跑（定时器在 tick）。

### 根因（高置信）
`CoachViewModel` 是 `ObservableObject`，但其 `@Published` 属性（`countdownSeconds`、`sessionPhase`、`progress` 等）的变更**从未被 SwiftUI 观察到**，导致视图只渲染了初始帧。

证据链：
- `CoachView.swift:18` — `coachViewModel` 用 `@State` 持有（`@State private var coachViewModel: CoachViewModel?`）。`@State` 仅在**引用被整体替换**时触发重绘，不会响应对象内部 `@Published` 变化。
- `CoachView.swift:27` — 把实例以普通值传入：`trainingSessionView(method: method, viewModel: viewModel)`。
- `CoachView.swift:182` — `trainingSessionView(method: TrainingMethod, viewModel: CoachViewModel)` 形参为**普通 `let`，未加 `@ObservedObject` / `@EnvironmentObject`**。
- `CoachView.swift:184` — `switch viewModel.sessionPhase` 只在构建时求值一次；因不被观察，`sessionPhase` 从 `.preparing` 变为 `.training` 后**界面不切换**，永远停留在"准备"页。
- `CoachView.swift:220` — `CountdownTimerView(seconds: viewModel.countdownSeconds)` 绑定的是未被观察的值。
- `TrainingTimerView.swift:145` — `CountdownTimerView` 的 `seconds` 是 `let`，仅靠 `.onChange(of: seconds)`（`TrainingTimerView.swift:175`）刷新；父视图不重绘，`seconds` 永不变 → 数字恒为初始 `3`。

> 结论：B1 是**纯 UI 观察缺失**缺陷。底层 `tickPreparation` / `tickTraining` 定时器正常递减，训练会"静默"完成并落库，但用户看到的是冻结在 `3` 的界面。这也解释了为何既有单测（直接断言 `vm.sessionPhase` / `countdownSeconds`）全绿——逻辑正确但视图未绑定。

### 修复建议（B1）
将 `CoachViewModel` 以可观察方式注入会话视图树，二选一：
- **方案 A（推荐，最小改动）**：把 `coachViewModel` 改为 `@StateObject`，并让 `trainingSessionView` 及其子视图（`preparingView` / `trainingInProgressView` / `pausedView` / `completedView`）通过 `.environmentObject(viewModel)` 注入，各子视图用 `@EnvironmentObject var viewModel: CoachViewModel` 声明。
- **方案 B**：抽取独立 `CoachSessionView` 结构体，持有 `@ObservedObject var viewModel: CoachViewModel`，在 `CoachView.body` 中 `CoachSessionView(viewModel: viewModel)` 实例化。

修复后 `countdownSeconds` / `sessionPhase` 变化会驱动 `CountdownTimerView` 与阶段切换实时刷新。

---

## 三、Bug 2：熄屏后语音停止

### 现象
陪练进行中按电源键熄屏（应用进入后台），语音引导立即中断，无法在后台/熄屏下继续播报。

### 根因（高置信）
**`Info.plist` 缺少 `UIBackgroundModes: audio` 声明**，iOS 在应用进入后台即挂起音频会话，`AVSpeechSynthesizer` 随之停止。

证据：
- `Info.plist`（全文 1–49 行）**无任何 `UIBackgroundModes` / `audio` 键**。这是后台音频续播的硬性前置条件，缺失即无权在后台播放。
- `AppDelegate.swift:37-40` — 启动时正确设置了分类 `setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .allowBluetooth, .mixWithOthers])`，方向正确，但**没有配套的 `UIBackgroundModes: audio`**，后台仍会被系统挂起。
- `AudioService.swift:122-128` — `configureBackgroundPlayback()` 仅 `setActive(true)`，未重复设置分类（分类本身会保留，这一处不是主因，但锁屏若使会话失效则恢复不全）。

> 机制：声明 `UIBackgroundModes: audio` 后，系统会将"正在播放音频"的应用保持在后台运行态，主 RunLoop 与 `Timer` 继续工作，`AVSpeechSynthesizer` 的 TTS 即可在熄屏下续播（与听书/导航类 App 同机制）。

### 关联缺陷（B2-副）：熄屏即误存"部分记录"
`CoachViewModel.swift:184-197` 监听 `UIApplication.willResignActiveNotification` 并在回调里调用 `savePartialRecordOnBackground()`（`CoachViewModel.swift:200-211`），写入 `isPartial=true` 的训练记录。

- `willResignActive` 在**熄屏、切 App、来电**等场景都会触发，并非"强制退出"。
- 后果：只要熄屏就开始训练就被标记为"中途放弃（partial）"，与 B2 期望的"熄屏继续"直接矛盾，且会产生错误统计。
- 建议：不要在该通知里落 partial 记录；可改为仅在确实终止（`applicationWillTerminate` / `sceneDidDiscard` 或带宽限的后台任务）时保存，或在 B2 修复后确认语音持续期间不应判定为中断。

### 修复建议（B2）
1. **必做**：在 `Info.plist` 增加：
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>audio</string>
   </array>
   ```
2. 验证 `AppDelegate` 的 `.playback` + `.spokenAudio` 分类在熄屏下保持激活；若锁屏会令会话失效，在 `interruptionNotification` 的 `.ended` 分支重新 `setCategory` + `setActive`（目前 `.ended` 仅 `break`，见 `CoachViewModel.swift:169-177`，可补恢复逻辑）。
3. **建议**：收紧 `setupBackgroundObserver`，避免熄屏即写 partial 记录（见 B2-副）。

---

## 四、修复优先级与验证建议

| 项 | 改动文件 | 优先级 | 验证方式 |
|----|----------|--------|----------|
| B1 视图观察 | `CoachView.swift`（注入 `@ObservedObject` / `@EnvironmentObject`） | P0 | 真机：进入陪练，确认 3→2→1→训练→完成 全程 UI 刷新；补一条 XCUI 断言倒计时数值变化 |
| B2 后台模式 | `Info.plist` | P0 | 真机：陪练中熄屏，确认语音持续；重新亮屏后界面状态一致 |
| B2-副 误存 partial | `CoachViewModel.swift:184-211` | P1 | 真机：熄屏再亮屏，确认**无**新增 `isPartial` 记录 |

**额外提示**：修复 B1 后，原 `tests-需求12` 单测（直接读 `vm` 属性）仍绿，但需补**进程内 SwiftUI 集成测试 / XCUI** 才能覆盖"UI 是否随 `@Published` 刷新"——这正是计划文档中标注的 UI/真机覆盖缺口。

---

## 五、结论
两项反馈均为**真实缺陷且根因明确**：B1 是 `CoachViewModel` 未被 SwiftUI 观察导致的界面冻结（逻辑正常、显示卡死）；B2 是 `Info.plist` 缺失 `UIBackgroundModes: audio` 导致熄屏后台音频被系统挂起，并伴随"熄屏即写部分记录"的连带逻辑问题。两者均无需改动核心训练逻辑，修复范围小、风险低。

---

## 六、归档验证附录（2026-07-12 最终核验）

> 以下核验于 `v8.0` 审查周期结束时执行，确认所有缺陷项已在当前源码中关闭。

| 问题编号 | 描述 | 修复状态 | 核验证据 |
|----------|------|----------|----------|
| B1 | 倒计时卡在 3 | ✅ 已关闭 | `CoachSessionView` 以 `@ObservedObject` 持有 `CoachViewModel`，`CoachView.swift:239` |
| B2 | 熄屏停语音 | ✅ 已关闭 | `Info.plist:49-52` 声明 `UIBackgroundModes: audio` |
| B2-副 | 熄屏误存 partial | ✅ 已关闭 | `savePartialRecordOnBackground` / `willResignActiveNotification` 全仓 0 匹配 |

**归档决定**：三缺陷全部确认关闭，本报告归档至 `docs/reviews/archive/`。
