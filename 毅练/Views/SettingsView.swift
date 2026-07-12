import SwiftUI

/// 设置中心：循环次数 / 等待时长 / 唤醒开关 / 语音参数 / 隐私锁
struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @State private var showSetPassword = false

    var body: some View {
        NavigationView {
            Form {
                Section("训练参数") {
                    Picker("循环次数", selection: $vm.cycleCount) {
                        Text("2 轮").tag(2)
                        Text("3 轮").tag(3)
                    }
                    Stepper("回落等待：\(vm.fallBackDuration) 秒", value: $vm.fallBackDuration, in: 30...180, step: 10)
                    Toggle("启用唤醒阶段", isOn: $vm.enableArousal)
                    Toggle("可控区间轻声提醒", isOn: $vm.enableControlReminder)
                }
                Section("语音") {
                    Slider(value: $vm.voiceVolume, in: 0...1) { Text("音量") }
                    Text("音量：\(Int(vm.voiceVolume * 100))%").font(.system(size: 13)).foregroundColor(.ylTextSecondary)
                    Slider(value: $vm.voiceRate, in: 0.8...1.2) { Text("语速") }
                    Text("语速：\(String(format: "%.1fx", vm.voiceRate))").font(.system(size: 13)).foregroundColor(.ylTextSecondary)
                    Picker("声线", selection: $vm.voiceGender) {
                        Text("女声").tag(0)
                        Text("男声").tag(1)
                    }
                }
                Section("隐私与安全") {
                    if LocalAuthManager.shared.isLockConfigured {
                        Button("更改隐私密码") { showSetPassword = true }
                        Text("已启用面容 / 密码锁").font(.system(size: 13)).foregroundColor(.ylGreen)
                    } else {
                        Button("设置隐私锁") { showSetPassword = true }
                    }
                    Text("本应用完全离线，无任何网络请求与数据采集。")
                        .font(.system(size: 13)).foregroundColor(.ylTextSecondary)
                }
                Section("免责声明") {
                    Text("本品仅为行为训练辅助工具，不替代专业医疗建议。如有健康疑虑，请咨询医生。")
                        .font(.system(size: 13)).foregroundColor(.ylTextSecondary)
                }
            }
            .navigationTitle("设置")
        }
        .sheet(isPresented: $showSetPassword) {
            PasswordSheet(onSubmit: { pwd in
                LocalAuthManager.shared.setPassword(pwd)
                vm.lockPasswordSet = true
                return true
            })
        }
    }
}
