import SwiftUI

/// 7分调整等待：红背景 + 呼吸圆 + 倒计时 + 随时可点的回落按钮 + 双指长按
struct StopWaitingView: View {
    let countdown: Int
    let cycle: Int
    let totalCycles: Int
    let onFallBackConfirmed: () -> Void
    let onDoubleFingerHold: () -> Void
    let onEjaculated: () -> Void         // 右上角：中途射精，结束并记录

    var body: some View {
        ZStack {
            // 双指长按手势只挂在背景层，绝不覆盖内容/按钮，避免拦截点击
            Color.ylRed
                .ignoresSafeArea()
                .gesture(
                    LongPressGesture(minimumDuration: 1.0)
                        .simultaneously(with: LongPressGesture(minimumDuration: 1.0))
                        .onEnded { _ in onDoubleFingerHold() }
                )
            // 右上角：中途射精按钮（独立层，不受背景手势影响）
            VStack {
                HStack {
                    Spacer()
                    Button(action: onEjaculated) {
                        Text("我已射精")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(16)
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
            VStack(spacing: 24) {
                Spacer()
                Text("停止一切刺激")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Text("第 \(cycle) / \(totalCycles) 轮")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                BreathingCircle(inhale: 4, exhale: 6, color: .green, showCountdown: countdown)
                Text("硬度略降完全正常")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Button(action: onFallBackConfirmed) {
                    Text("回落完成，继续刺激")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(24)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}
