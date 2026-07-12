import Foundation
import SwiftUI

/// 设置视图模型：读写 AppStorage
final class SettingsViewModel: ObservableObject {
    @AppStorage("cycleCount") var cycleCount: Int = 2
    @AppStorage("fallBackDuration") var fallBackDuration: Int = 60
    @AppStorage("enableArousal") var enableArousal: Bool = true
    @AppStorage("voiceVolume") var voiceVolume: Double = 0.8
    @AppStorage("voiceRate") var voiceRate: Double = 1.0
    @AppStorage("voiceGender") var voiceGender: Int = 0
    @AppStorage("enableControlReminder") var enableControlReminder: Bool = true
    @AppStorage("lockPasswordSet") var lockPasswordSet: Bool = false

    func currentConfig() -> TrainingConfig {
        var c = TrainingConfig.default
        c.cycleCount = cycleCount
        c.fallBackDuration = fallBackDuration
        c.enableArousal = enableArousal
        c.voiceVolume = Float(voiceVolume)
        c.voiceRate = Float(voiceRate)
        c.voiceGender = voiceGender
        c.enableControlReminder = enableControlReminder
        return c
    }
}
