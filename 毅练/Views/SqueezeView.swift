import SwiftUI

/// 停止-挤压法指导：紫色调 + 8秒挤压倒计时环
struct SqueezeView: View {
    let onSqueezeDone: () -> Void
    let onRetry: () -> Void
    let onEnd: () -> Void

    @State private var remaining = 8
    private let timer = TimerScheduler.shared

    var body: some View {
        ZStack {
            Color.ylPurple.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("停止-挤压法")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Text("拇指按在龟头腹侧系带处，食指+中指放在背侧冠状沟，形成 V 字钳。用适中压力挤压 5-10 秒。")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                // 8秒挤压环
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        .frame(width: 160, height: 160)
                    Circle()
                        .trim(from: 0, to: CGFloat(remaining) / 8.0)
                        .stroke(Color.white, lineWidth: 8)
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                    Text("\(remaining)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(spacing: 12) {
                    Button(action: onSqueezeDone) {
                        Text("挤压完成，继续训练")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .foregroundColor(.ylPurple)
                            .cornerRadius(24)
                    }
                    HStack(spacing: 12) {
                        Button(action: onRetry) {
                            Text("再挤压一次")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(24)
                        }
                        Button(action: onEnd) {
                            Text("结束训练")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.red.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(24)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
            Text("若疼痛不适，立即停止")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 12)
        }
        .onAppear {
            timer.scheduleCountdown(from: 8) { r in remaining = r }
        }
    }
}
