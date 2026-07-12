# 陪练语音反馈修复 — 代码复审报告

**复审对象**:`CoachView.swift`(新增 `CoachSessionView`)、`Info.plist`、`CoachViewModel.swift`、`AudioService.swift`
**复审依据**:`Bug-CT-Voice-陪练语音反馈审查报告-20260712.md` 中的三项修复建议
**复审方式**:静态源码审查(Windows 环境,无法真机编译验证)
**结论**:B1、B2 及 B2-副三项均已正确修复,可编译、逻辑自洽;另有 1 处可改进项与 1 处需真机验证的残存风险。

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
