import SwiftUI

/// 统一的玻璃卡片按钮：高 64、圆角 24、点击缩放 95% 回弹、触发轻触 Haptic。
/// 替代各屏散落的默认 Button，营造 iOS 原生质感。
struct CoachButton: View {
    enum Style {
        case primary    // 主操作：深字（用于浅色玻璃上）
        case secondary  // 次操作：白字
        case danger     // 警示：白字
    }

    let title: String
    var systemImage: String? = nil
    let style: Style
    var height: CGFloat = 64
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            HapticManager.shared.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(PressScaleStyle(pressed: $pressed))
        .glassEffect(in: RoundedRectangle(cornerRadius: 24))
    }

    private var foreground: Color {
        switch style {
        case .primary:   return .black
        case .secondary: return .ylText
        case .danger:    return .white
        }
    }
}

/// 点击时整体缩放到 0.95，松开回弹。
private struct PressScaleStyle: ButtonStyle {
    @Binding var pressed: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed = $0 }
    }
}
