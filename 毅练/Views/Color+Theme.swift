import SwiftUI

extension Color {
    // MARK: - 既有语义色（资源中已改为低饱和目标值）
    static let ylBackground = Color("YLBackground")
    static let ylBackground2 = Color("YLBackground2")
    static let ylGreen = Color("YLGreen")
    static let ylYellow = Color("YELLOW")
    static let ylRed = Color("YLRed")
    static let ylPurple = Color("YLPurple")
    static let ylText = Color("YLText")
    static let ylTextSecondary = Color("YLTextSecondary")

    // MARK: - 功能色
    static let ylSuccess = Color("YLGreen")   // #5ECF89 低饱和绿
    static let ylWarning = Color("YLRed")     // #FF6B57 橙红
    static let ylInfo = Color("YELLOW")       // 暖橙黄

    // MARK: - Hex 初始化
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

extension LinearGradient {
    /// 平静期：低饱和绿渐变
    static let ylCalm = LinearGradient(
        colors: [Color(hex: 0x5ECF89), Color(hex: 0x3FB574)],
        startPoint: .top, endPoint: .bottom)

    /// 控制期：暖橙黄渐变（Apple Fitness 风，不刺眼）
    static let ylControl = LinearGradient(
        colors: [Color(hex: 0xFFC15E), Color(hex: 0xFF9F45)],
        startPoint: .top, endPoint: .bottom)

    /// 停止·恢复：橙红渐变（非纯红，降低交感神经刺激）
    static let ylStop = LinearGradient(
        colors: [Color(hex: 0xFF6B57), Color(hex: 0xC0392B)],
        startPoint: .top, endPoint: .bottom)

    /// 释放：紫浅→深渐变
    static let ylRelease = LinearGradient(
        colors: [Color(hex: 0xB57EDC), Color(hex: 0x6A2DA8)],
        startPoint: .top, endPoint: .bottom)

    /// 深色玻璃主题背景
    static let ylDark = LinearGradient(
        colors: [Color(hex: 0x1C1C1E), Color(hex: 0x2C2C2E)],
        startPoint: .top, endPoint: .bottom)
}
