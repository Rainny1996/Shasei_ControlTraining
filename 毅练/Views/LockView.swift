import SwiftUI

/// 解锁界面：生物识别 / 独立密码（玻璃化）
struct LockView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPasswordSheet = false
    @State private var passwordInput = ""
    @State private var errorText = ""

    var body: some View {
        ZStack {
            LinearGradient.ylDark.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                GlassCard {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.ylSuccess)
                        Text("毅练")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.ylText)
                        Text("私密训练 · 控时训练")
                            .font(.system(size: 15))
                            .foregroundColor(.ylTextSecondary)
                    }
                }
                .padding(.horizontal, 40)
                Spacer()
                CoachButton(title: "点击解锁", systemImage: "faceid", style: .primary) { attemptBio() }
                    .padding(.horizontal, 32)
                if LocalAuthManager.shared.isLockConfigured {
                    Button(action: { showPasswordSheet = true }) {
                        Text("使用密码").foregroundColor(.ylTextSecondary)
                    }
                }
                if !errorText.isEmpty {
                    Text(errorText).foregroundColor(.ylWarning).font(.system(size: 14))
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showPasswordSheet) {
            PasswordSheet(onSubmit: verifyPassword)
        }
    }

    private func attemptBio() {
        LocalAuthManager.shared.authenticateWithBiometrics { success, _ in
            if success {
                withAnimation { appState.isUnlocked = true; appState.isBlurred = false }
            } else if !LocalAuthManager.shared.isLockConfigured {
                withAnimation { appState.isUnlocked = true; appState.isBlurred = false }
            }
        }
    }

    private func verifyPassword(_ pwd: String) -> Bool {
        if LocalAuthManager.shared.verifyPassword(pwd) {
            withAnimation { appState.isUnlocked = true; appState.isBlurred = false }
            return true
        }
        errorText = "密码错误"
        return false
    }
}

/// 首次设置密码 Sheet
struct PasswordSheet: View {
    let onSubmit: (String) -> Bool
    @Environment(\.dismiss) var dismiss
    @State private var pwd = ""
    @State private var confirm = ""
    @State private var isSetup: Bool = false
    @State private var err = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                SecureField("输入密码", text: $pwd)
                    .textFieldStyle(.roundedBorder).padding(.horizontal)
                SecureField("确认密码", text: $confirm)
                    .textFieldStyle(.roundedBorder).padding(.horizontal)
                if !err.isEmpty { Text(err).foregroundColor(.ylWarning).font(.system(size: 14)) }
                CoachButton(title: "确认", style: .primary) {
                    if pwd.count < 4 { err = "密码至少4位"; return }
                    if pwd != confirm { err = "两次输入不一致"; return }
                    if onSubmit(pwd) { dismiss() }
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .navigationTitle("设置隐私密码")
            .padding(.top, 24)
        }
    }
}
