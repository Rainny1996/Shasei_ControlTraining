import Foundation
import Combine

/// 统一计时调度：倒计时、周期提醒、单次延时
final class TimerScheduler {
    static let shared = TimerScheduler()

    private var countdownTimer: AnyCancellable?
    private var repeatingTimer: AnyCancellable?
    private var onceTimers: [AnyCancellable] = []

    /// 倒计时（精确到秒），每秒回调剩余秒数（含 0）
    func scheduleCountdown(from total: Int, tick: @escaping (Int) -> Void) {
        cancelAll()
        var remaining = total
        tick(remaining)
        countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                remaining -= 1
                tick(remaining)
                if remaining <= 0 {
                    self?.countdownTimer?.cancel()
                    self?.countdownTimer = nil
                }
            }
    }

    /// 周期重复（如每20秒提醒）
    func scheduleRepeating(seconds: TimeInterval, block: @escaping () -> Void) {
        repeatingTimer = Timer.publish(every: seconds, on: .main, in: .common)
            .autoconnect()
            .sink { _ in block() }
    }

    /// 单次延时（如3分钟超时、10秒监控）
    func scheduleOnce(seconds: TimeInterval, block: @escaping () -> Void) {
        let c = Timer.publish(every: seconds, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { _ in block() }
        onceTimers.append(c)
    }

    func cancelAll() {
        countdownTimer?.cancel()
        repeatingTimer?.cancel()
        onceTimers.forEach { $0.cancel() }
        onceTimers.removeAll()
        countdownTimer = nil
        repeatingTimer = nil
    }
}
