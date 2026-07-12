import Foundation
import LocalAuthentication
import Security

/// 隐私认证：Face ID / Touch ID + Keychain 独立密码
final class LocalAuthManager {
    static let shared = LocalAuthManager()
    private let passwordKey = "com.yilian.lockPassword"

    /// 是否已设置锁
    var isLockConfigured: Bool {
        return readPassword() != nil
    }

    /// 设置独立密码（首次）
    func setPassword(_ pwd: String) {
        guard let data = pwd.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: passwordKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func verifyPassword(_ pwd: String) -> Bool {
        guard let stored = readPassword() else { return false }
        return stored == pwd
    }

    private func readPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: passwordKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 生物识别验证
    func authenticateWithBiometrics(reason: String = "解锁以进入训练", completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error?.localizedDescription)
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, err in
            DispatchQueue.main.async {
                completion(success, err?.localizedDescription)
            }
        }
    }
}
