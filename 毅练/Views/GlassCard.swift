import SwiftUI

/// 玻璃信息卡：原生 Liquid Glass + 圆角，作为所有信息卡基底。
/// 玻璃会折射/模糊其背后的阶段渐变背景，呈现磨砂质感。
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 24

    init(padding: CGFloat = 16, cornerRadius: CGFloat = 24,
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
