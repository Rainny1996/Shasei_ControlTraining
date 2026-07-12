import SwiftUI

/// 计划项详情（需求 12 / AC-12.1~12.6）
/// 点击今日动作行进入；复用 `TrainingDetailView` 的方法说明展示（满足 AC-C.2/AC-C.5），
/// 底部提供「开始陪练」按钮，进入既有 `CoachView` 并携带 `planItemId`。
struct PlanItemDetailView: View {
    @State private var item: PlanItem
    let method: TrainingMethod
    @ObservedObject var planViewModel: PlanViewModel
    
    @StateObject private var trainingViewModel = TrainingViewModel()
    @State private var showCoach = false
    @Environment(\.dismiss) private var dismiss
    
    init(item: PlanItem, method: TrainingMethod, planViewModel: PlanViewModel) {
        self._item = State(initialValue: item)
        self.method = method
        self._planViewModel = ObservedObject(initialValue: planViewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 复用既有方法说明（原理/步骤/注意/禁忌/来源）
                TrainingDetailView(
                    method: method,
                    viewModel: trainingViewModel,
                    onStartCoach: item.isCompleted ? nil : { _ in showCoach = true },
                    enableStart: !item.isCompleted
                )
                .frame(maxHeight: .infinity)
                
                // 底部动作栏
                bottomBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .accessibilityLabel("关闭")
                }
            }
            // 开始陪练：全屏呈现既有 CoachView（AC-12.3）
            .fullScreenCover(isPresented: $showCoach, onDismiss: {
                // 刷新本地 item，使已完成态实时更新（AC-12.4）
                if let updated = planViewModel.currentPlan?.items.first(where: { $0.id == item.id }) {
                    item = updated
                }
            }) {
                CoachView(
                    initialMethod: method,
                    planItemId: item.id,
                    initialMethodMode: method.trainingModes.first(where: { $0.id == item.modeId }),
                    onPlanItemComplete: {
                        planViewModel.markItemCompleted(item.id)
                    }
                )
            }
        }
    }
    
    // MARK: - 底部动作栏
    
    @ViewBuilder
    private var bottomBar: some View {
        if item.isCompleted {
            // AC-12.5：已完成项仅查看，不触发新陪练
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("已完成")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.green.opacity(0.1))
            .accessibilityLabel("该训练已完成")
        } else {
            Button(action: { showCoach = true }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("开始陪练")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.accentColor)
                .cornerRadius(27)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .accessibilityLabel("开始陪练 \(method.name)")
        }
    }
}

#Preview {
    let item = PlanItem(
        date: Date(),
        methodId: TrainingContentData.allTrainingMethods()[0].id,
        methodName: TrainingContentData.allTrainingMethods()[0].name,
        duration: 300
    )
    PlanItemDetailView(
        item: item,
        method: TrainingContentData.allTrainingMethods()[0],
        planViewModel: PlanViewModel()
    )
}
