import SwiftUI

/// 根路由：锁屏 → 主页(Tab: 训练 / 记录 / 设置)
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var settings = SettingsViewModel()
    @StateObject private var trainingVM: TrainingViewModel
    @State private var selectedTab: Tab = .train

    init() {
        let cfg = SettingsViewModel().currentConfig()
        _trainingVM = StateObject(wrappedValue: TrainingViewModel(config: cfg))
    }

    enum Tab { case train, records, settings }

    var body: some View {
        ZStack {
            if appState.isUnlocked {
                TabView(selection: $selectedTab) {
                    TrainHomeView(trainingVM: trainingVM, settings: settings, startTraining: startTraining)
                        .tag(Tab.train)
                        .tabItem { Label("训练", systemImage: "figure.walk") }
                    RecordsView()
                        .tag(Tab.records)
                        .tabItem { Label("记录", systemImage: "chart.line.uptrend.xyaxis") }
                    SettingsView()
                        .tag(Tab.settings)
                        .tabItem { Label("设置", systemImage: "gearshape") }
                }
                .tint(.ylSuccess)
                .overlay(
                    trainingVM.isTrainingActive ?
                    TrainingContainerView(vm: trainingVM).ignoresSafeArea() : nil
                )
            } else {
                LockView()
            }
            // 后台模糊遮罩
            if appState.isBlurred && appState.isUnlocked {
                Color.ylBackground
                    .ignoresSafeArea()
                    .overlay(
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 40)).foregroundColor(.ylTextSecondary)
                    )
                    .blur(radius: 20)
            }
        }
        .modifier(HideStatusBar(hidden: trainingVM.isTrainingActive))
    }

    private func startTraining() {
        trainingVM.start()
    }
}

/// 训练主页（未开始时）
struct TrainHomeView: View {
    @ObservedObject var trainingVM: TrainingViewModel
    @ObservedObject var settings: SettingsViewModel
    let startTraining: () -> Void

    var body: some View {
        ZStack {
            LinearGradient.ylDark.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 64)).foregroundColor(.ylSuccess)
                GlassCard {
                    VStack(spacing: 8) {
                        Text("控时训练")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.ylText)
                        Text("跟随语音引导，完成高质量行为训练")
                            .font(.system(size: 15))
                            .foregroundColor(.ylTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
                Spacer()
                CoachButton(title: "开始训练", style: .primary) { startTraining() }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
    }
}
