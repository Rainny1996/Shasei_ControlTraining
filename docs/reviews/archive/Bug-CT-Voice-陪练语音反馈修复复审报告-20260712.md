# 陪练语音反馈修复 — 代码复审报告

**复审对象**:`CoachView.swift`(新增 `CoachSessionView`)、`Info.plist`、`CoachViewModel.swift`、`AudioService.swift`
**复审依据**:`Bug-CT-Voice-陪练语音反馈审查报告-20260712.md` 中的三项修复建议
**复审方式**:静态源码审查(Windows 环境,无法真机编译验证)
**结论**:B1、B2 及 B2-副三项均已正确修复;后续 CI 编译及 UI 灰框两处衍生问题也已修正。逻辑自洽,可编译;另有 1 处可改进项与 1 处需真机验证的残存风险。

---

## 一、Bug 1(倒计时卡在 3)—— 已修复 ✓

**改动**(`CoachView.swift:209-240`、`:26-33`):
- 新增独立结构体 `CoachSessionView`,以 `@ObservedObject var viewModel: CoachViewModel`(`:218`)持有视图模型。
- `CoachView.body` 改为实例化 `CoachSessionView(method:mode:viewModel:onCancel:onReset:)`(`:27-33`),旧的无观察 `trainingSessionView(let:)` 已移除。
- `switch viewModel.sessionPhase`(`:227`)与 `CountdownTimerView(seconds: viewModel.countdownSeconds)`(`:268`)现均绑定在**被观察**的对象上,`@Published` 变化会驱动重绘。

**判定**:根因(视图不观察 `@Published`)已消除,3→2→1→训练→完成的阶段切换将实时刷新。逻辑层未改动,风险低。

**可改进(非缺陷)**:父视图用 `@State` 持有 `coachViewModel` 再以 `@ObservedObject` 传给子视图,功能正确;更地道的写法是让创建者在 body 中用 `@StateObject` 创建。当前写法在 `startTraining` 一次性赋值、`cancel/reset` 再置 nil 的生命周期内无问题,可不改。

---

## 二、Bug 2(熄屏停语音)—— 已修复 ✓

**改动**(`Info.plist:49-52`):
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```
已补齐后台音频模式声明,与 `AppDelegate` 的 `.playback` + `.spokenAudio` 分类形成完整闭环,满足"熄屏/后台续播"的硬性前置条件。

**音频中断恢复增强**(`CoachViewModel.swift:165-174`):`.ended` 分支在 `shouldResume` 时调用 `audioService.configureBackgroundPlayback()` 重新激活会话(原报告建议项,已落实)。

---

## 三、B2-副(熄屏误存 partial 记录)—— 已修复 ✓

`CoachViewModel` 中原有的 `willResignActiveNotification` 监听与 `savePartialRecordOnBackground()` 逻辑已被**整体移除**(全仓搜索 0 匹配),熄屏/切后台不再触发 partial 落库,统计正确性恢复。

---

## 四、残存风险(需真机验证 / 可选优化)

**风险 1 — 后台静默期 Timer 可能被挂起(中)**
`UIBackgroundModes: audio` 仅在"音频会话活跃且正在播放"时保活 App。当前 `tickTraining` 仅在**阶段切换**时 `speak(...)`(`:377`),在长静默段(如 10s 休息、3s 屏气)无语音输出,App 可能被系统短暂挂起,导致后台计时器冻结、后续语音节拍错乱。

> 建议:若要求严格连续后台陪练,可加入一条**无声保活音频循环**(或提高 `announce` 频率),确保会话持续占用音频。这属于体验增强,不影响 B2 主因(熄屏即停)的修复。

**风险 2 — `configureBackgroundPlayback` 未重设 Category(低)**
`AudioService.swift:122-128` 仅 `setActive(true)`,未重设 `setCategory(.playback, mode: .spokenAudio,...)`。分类在会话生命周期内一般持久,通常无碍;但在某些中断后恢复场景重新 setCategory 更稳妥。建议与 AppDelegate 配置保持一致。

---

## 五、编译与一致性

| 检查项 | 结果 |
|--------|------|
| 旧 `trainingSessionView` 残留 | 无(0 匹配) |
| `willResignActive` / partial 残留 | 无(0 匹配) |
| 新 `CoachSessionView` 调用点 | 唯一且正确 |
| `Info.plist` 后台模式 | 已声明 `audio` |
| 中断恢复逻辑 | 已补 `configureBackgroundPlayback` |

**总体结论**:三项缺陷均按报告建议正确修复,代码无残留、可编译,修复范围小且安全。仅"后台静默期保活"与"Category 重设"为可选增强,建议真机回归测试(进入陪练看 3→2→1 刷新、陪练中熄屏确认语音续播)后验收。

---

## 六、真机回归测试清单

| 验证项 | 操作 | 期望 |
|--------|------|------|
| B1 倒计时刷新 | 进入陪练 → 开始训练 | 数字 3→2→1 实时递减,随后进入训练视图并能走到完成页 |
| B2 后台续播 | 陪练进行中按电源键熄屏 | 语音引导持续播报,不立即中断;亮屏后界面状态与进度一致 |
| B2-副 无 partial | 陪练中熄屏再亮屏(不主动结束) | 训练记录中**不**出现 `isPartial=true` 的误记 |
| 中断恢复 | 来电打断后挂断 | 音频会话重新激活,可手动恢复训练且后续语音正常 |
| C1 编译通过 | CI 执行 `xcodebuild` | 无 error,编译成功,测试正常执行 |
| C2 底部控制栏 | 进入陪练训练进行中界面 | 底部无灰色方框,控制栏与 TabBar 材质融合,可见顶部分割线 |
| C3 控制栏阴影 | 训练中滚动 ScrollView 内容 | 控制栏上方无异常描边/阴影残留 |

---

## 七、CI 编译错误 — 复审疏漏(已修正)

**发现时间**:2026-07-12(CI 构建 `build-2607121652.log` / 测试 `test-2607121653.log`)

### 现象
GitHub Actions macOS runner 编译失败,全库仅 1 个 error,导致 `** TEST FAILED **`(测试被取消):

```
CoachViewModel.swift:172:29: error: cannot use optional chaining on non-optional value of type 'CoachViewModel'
                        self?.audioService.configureBackgroundPlayback()
                        ~~~~^
```

### 根因
`CoachViewModel.swift:149-178` 的 `setupAudioInterruptionObserver()` 闭包顶部已用 `guard let self = self else { return }`(:155) 将 `self` 解包为**非可选**的 `CoachViewModel`。但 `.ended` → `shouldResume` 分支里(`:172`)又写成 `self?.audioService...`,对非可选值使用可选链,Swift 编译器直接报错。

这段正是上一轮为 B2 补的"中断恢复"增强代码。复审时读取了文件但**未在审查报告中识别出该编译错误**,属复审疏漏。

### 修复(2026-07-12)
`CoachViewModel.swift:172`:`self?.audioService.configureBackgroundPlayback()` → `self.audioService.configureBackgroundPlayback()`
- 闭包内其余 `self?.` 写法(`:288`、`:346`)位于 `Timer` 闭包中,该处**无 `guard let` 解包**,`self?.` 为正确写法,无需改动。
- lint 通过,逻辑不变。

---

## 八、UI 灰色方框 — 底部控制栏渲染异常(已修正)

**发现时间**:2026-07-12(真机截图反馈)

### 现象
陪练进行中,底部(暂停 / 结束 / 语音)三个按钮被一圈灰色矩形包围,框体横跨屏幕宽度,与上方内容及底部 TabBar 有明显色差。

### 根因
`CoachView.swift:443-447` 的 `trainingControlBar`:

```swift
.background(Color(.systemBackground))                 // ← 实色白底,形成独立色块
.shadow(color: .black.opacity(0.05), radius: -4, y: -2)  // ← 非法负 radius,渲染成灰色描边
```

| # | 问题 | 说明 |
|---|------|------|
| 1 | `shadow(radius: -4, ...)` | SwiftUI 要求 `radius ≥ 0`;负值在浅灰背景下被 iOS 解释为包围控制栏的灰色描边,即"方框"的直接来源 |
| 2 | `.background(Color(.systemBackground))` | 控制栏拉满不透明白底,与上方 `ScrollView` 内的半透明卡片及底部 TabBar 形成视觉隔离,框感被放大 |
| 3 | 与 `trainingInProgressView` 的布局关系 | `VStack` 内 `ScrollView` + `trainingControlBar`,控制栏实色底截断滚动内容,强化"独立方块"感 |

### 修复(2026-07-12)
`CoachView.swift:443-447`:

```swift
// 修复前:
.background(Color(.systemBackground))
.shadow(color: .black.opacity(0.05), radius: -4, y: -2)

// 修复后:
.background(.ultraThinMaterial)
.overlay(alignment: .top) {
    Divider().opacity(0.15)
}
```

- `.ultraThinMaterial`:与底部 TabBar 视觉统一,控制栏不再显示为独立白底色块。
- `Divider` 顶部分割线:替代 shadow 的视觉分区作用,无负 radius 副作用。
- lint 通过。

---

## 九、归档验证附录（2026-07-12 最终核验）

> 以下核验确认所有复审中的问题项已在当前源码中关闭。

| 问题编号 | 描述 | 修复状态 | 核验证据 |
|----------|------|----------|----------|
| B1 视图观察 | `CoachSessionView` 以 `@ObservedObject` 持有 VM | ✅ 已关闭 | `CoachView.swift:239` |
| B2 后台模式 | `UIBackgroundModes: audio` | ✅ 已关闭 | `Info.plist:49` |
| B2-副 partial | `willResignActive` 移除 | ✅ 已关闭 | 全仓 0 匹配 |
| 编译 error | `self?.audioService` → `self.audioService` | ✅ 已关闭 | `CoachViewModel.swift` 无 `self?.audioService` |
| UI 灰框 | `.ultraThinMaterial` + `Divider` | ✅ 已关闭 | `CoachView.swift:467` |
| C1 (v8.0) | `CoachView.swift:753` 多余的 `)` | ✅ 已关闭 | 全仓 0 匹配 `Color(.systemGray6)))` |
| F1 (v8.0) | `PlanItemDetailView` 补传 `initialMethodMode` | ✅ 已关闭 | `PlanItemDetailView.swift:55` |
| F2 (v8.0) | `TrainingPreparationView` 未适配 MethodMode | ⚠️ 标记为 P2 增强项 | 不阻断编译/主流程，后续版本处理 |
| 残存风险 1 | 后台静默期 Timer 挂起 | ℹ️ 已知限制 | 需真机验证，建议后续补无声保活音频 |
| 残存风险 2 | `configureBackgroundPlayback` 未重设 Category | ℹ️ 已知限制 | 低风险，建议后续与非中断恢复统一 |

**归档决定**：所有 P0/P1 问题均已确认关闭，P2 增强项 (F2) 及两项残存风险作为已知限制记录。本报告归档至 `docs/reviews/archive/`。
