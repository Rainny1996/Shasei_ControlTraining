import Foundation

/// 用户设置模型（持久化于 UserDefaults / AppStorage）
struct TrainingConfig: Codable {
    /// 训练循环次数（2 或 3）
    var cycleCount: Int = 2
    /// 7分等待回落时长（秒），默认 60
    var fallBackDuration: Int = 60
    /// 是否启用唤醒阶段
    var enableArousal: Bool = true
    /// 语音音量 0~1，默认 0.8
    var voiceVolume: Float = 0.8
    /// 语音语速倍率 0.8~1.2，默认 1.0
    var voiceRate: Float = 1.0
    /// 声线：0=女声(默认) 1=男声
    var voiceGender: Int = 0
    /// 是否开启每20秒可控区间轻声提醒
    var enableControlReminder: Bool = true

    static let `default` = TrainingConfig()
}
