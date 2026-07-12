import SwiftUI

/// 训练完成界面：统计 + 建议
struct FinishedView: View {
    let session: TrainingSession?
    let onHome: () -> Void

    private var durationText: String {
        guard let s = session else { return "--" }
        let m = s.totalDuration / 60
        let sec = s.totalDuration % 60
        return "\(m) 分 \(sec) 秒"
    }

    var body: some View {
        ZStack {
            Color.ylBackground.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.ylGreen)
                Text("训练完成")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.ylText)
                VStack(spacing: 14) {
                    StatRow(label: "本次用时", value: durationText)
                    StatRow(label: "停止次数", value: "\(session?.cycleCount ?? 0)")
                    StatRow(label: "是否使用挤压法", value: (session?.usedSqueeze ?? false) ? "是" : "否")
                }
                .padding(24)
                .background(Color.ylBackground2)
                .cornerRadius(20)
                .padding(.horizontal, 32)
                Text("你做得很好。保持规律训练，感受身体掌控力的提升。")
                    .font(.system(size: 15))
                    .foregroundColor(.ylTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                Button(action: onHome) {
                    Text("返回主页")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.ylGreen)
                        .foregroundColor(.black)
                        .cornerRadius(24)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.ylTextSecondary).font(.system(size: 16))
            Spacer()
            Text(value).foregroundColor(.ylText).font(.system(size: 16, weight: .semibold))
        }
    }
}
