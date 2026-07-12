import Foundation

/// 训练阶段状态机状态
enum TrainingState: Equatable {
    case prepare
    case arousal
    case lowArousal(cycle: Int, isFinal: Bool)
    case controlZone(cycle: Int, isFinal: Bool)
    case stopWaiting(cycle: Int, isFinal: Bool)
    case squeeze(cycle: Int)
    case ejaculateReady
    case finished

    var rawStage: String {
        switch self {
        case .prepare: return "prepare"
        case .arousal: return "arousal"
        case .lowArousal: return "lowArousal"
        case .controlZone: return "controlZone"
        case .stopWaiting: return "stopWaiting"
        case .squeeze: return "squeeze"
        case .ejaculateReady: return "ejaculateReady"
        case .finished: return "finished"
        }
    }
}

/// 训练事件（用户操作 / 系统超时）
enum TrainingEvent {
    case prepared            // 我已准备好
    case aroused             // 我已勃起（跳过唤醒）
    case enteredControl      // 我进入4-6分了
    case reachedSeven        // 我到了7分（立刻停止）
    case fallBackConfirmed   // 回落完成，继续刺激
    case squeezeTriggered    // 手动/自动触发挤捏法
    case squeezeDone         // 挤压完成，继续训练
    case squeezeRetry        // 再挤压一次
    case squeezeEnd          // 结束训练
    case ejaculateReady      // 我已准备好射精
    case finish              // 完成
    case timeout             // 超时（10秒监控 / 3分钟唤醒）
    case doubleFingerHold    // 双指长按1秒
    case prematureEjaculation // 未刹车就射精
    case ejaculated            // 中途射精，结束并记录训练
    case continueWaiting      // 回落超时后继续等待（再延长30秒，仅限一次）
}
