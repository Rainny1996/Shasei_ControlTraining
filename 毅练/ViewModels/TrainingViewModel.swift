import SwiftUI
import Combine

/// 训练视图模型：持有状态机，向视图暴露状态 / 计时 / 语音事件
final class TrainingViewModel: ObservableObject {
    @Published private(set) var machine: TrainingStateMachine
    @Published var isTrainingActive: Bool = false
    @Published var showSqueezePrompt: Bool = false
    @Published var lastSession: TrainingSession?

    private let voice = VoiceService.shared
    private let timer = TimerScheduler.shared
    private let haptic = HapticManager.shared
    private var config: TrainingConfig

    init(config: TrainingConfig) {
        self.config = config
        self.machine = TrainingStateMachine(config: config, voice: VoiceService.shared, timer: TimerScheduler.shared)
    }

    var state: TrainingState { machine.state }
    var countdown: Int { machine.countdownRemaining }
    var cycle: Int { machine.currentCycle }

    // MARK: - 训练控制
    func start() {
        isTrainingActive = true
        UIApplication.shared.isIdleTimerDisabled = true
        voice.updateConfig(config)
        // 重置状态机
        machine = TrainingStateMachine(config: config, voice: voice, timer: timer)
        machine.send(.prepared)
    }

    /// 完成训练并保存记录，但保持训练层显示以呈现 FinishedView
    func end() {
        lastSession = CoreDataStack.shared.insertSession(from: machine)
        machine.send(.finish)
        // 注意：保持 isTrainingActive = true，使 FinishedView 可见
    }

    /// 用户点击"返回主页"，真正退出训练层
    func dismissTraining() {
        isTrainingActive = false
        UIApplication.shared.isIdleTimerDisabled = false
        timer.cancelAll()
        voice.stopAndClear()
    }

    // MARK: - 事件转发
    func onPrepared() { haptic.tap(); machine.send(.prepared) }
    func onAroused() { haptic.tap(); machine.send(.aroused) }
    func onEnteredControl() { haptic.tap(); machine.send(.enteredControl) }
    func onReachedSeven() { haptic.warning(); machine.send(.reachedSeven) }
    func onFallBackConfirmed() { haptic.success(); machine.send(.fallBackConfirmed) }
    func onDoubleFingerHold() { haptic.tap(); machine.send(.doubleFingerHold) }
    func onSqueezeTriggered() { haptic.tap(); machine.send(.squeezeTriggered) }
    func onSqueezeDone() { haptic.success(); machine.send(.squeezeDone) }
    func onSqueezeRetry() { haptic.tap(); machine.send(.squeezeRetry) }
    func onSqueezeEnd() { haptic.warning(); end() }
    func onEjaculateReady() { haptic.tap(); machine.send(.ejaculateReady) }
    func onPremature() { haptic.warning(); machine.send(.prematureEjaculation) }

    // MARK: - 挤捏法弹窗
    func showSqueezePromptIfNeeded() {
        if case .stopWaiting = state {
            showSqueezePrompt = true
        }
    }
    func continueWaiting() { showSqueezePrompt = false; machine.send(.continueWaiting) }
    func trySqueeze() { showSqueezePrompt = false; onSqueezeTriggered() }
}
