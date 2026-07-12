import SwiftUI

/// 解锁界面：生物识别 / 独立密码
struct LockView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPasswordSheet = false
    @State private var passwordInput = ""
    @State private var errorText = ""

    var body: some View {
        ZStack {
            Color.ylBackground.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.ylGreen)
                Text("毅练")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.ylText)
                Text("私密训练 · 控时训练")
                    .font(.system(size: 15))
                    .foregroundColor(.ylTextSecondary)
                Spacer()
                Button(action: attemptBio) {
                    Label("点击解锁", systemImage: "faceid")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Color.ylGreen).foregroundColor(.black).cornerRadius(24)
                }
                .padding(.horizontal, 32)
                if LocalAuthManager.shared.isLockConfigured {
                    Button(action: { showPasswordSheet = true }) {
                        Text("使用密码")
                            .foregroundColor(.ylTextSecondary)
                    }
                }
                if !errorText.isEmpty {
                    Text(errorText).foregroundColor(.ylRed).font(.system(size: 14))
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
                // 首次进入：直接解锁并提示设置
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
        NavigationView {
            VStack(spacing: 20) {
                SecureField("输入密码", text: $pwd)
                    .textFieldStyle(.roundedBorder).padding(.horizontal)
                SecureField("确认密码", text: $confirm)
                    .textFieldStyle(.roundedBorder).padding(.horizontal)
                if !err.isEmpty { Text(err).foregroundColor(.red).font(.system(size: 14)) }
                Button("确认") {
                    if pwd.count < 4 { err = "密码至少4位"; return }
                    if pwd != confirm { err = "两次输入不一致"; return }
                    if onSubmit(pwd) { dismiss() }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .navigationTitle("设置隐私密码")
            .padding(.top, 24)
        }
    }
}
