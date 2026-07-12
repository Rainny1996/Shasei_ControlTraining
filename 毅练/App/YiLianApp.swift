import SwiftUI

@main
struct YiLianApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    appState.isBlurred = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    if appState.isUnlocked {
                        appState.isBlurred = false
                    }
                }
        }
    }
}

/// 全局应用状态：隐私锁、后台模糊
final class AppState: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var isBlurred: Bool = false
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // 后台立即模糊预览由 willResignActive 处理
    }
}

/// 状态栏隐藏辅助：iOS 16+ 使用 modifier；iOS 15 通过场景代理实现
struct HideStatusBar: ViewModifier {
    let hidden: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.statusBarHidden(hidden)
        } else {
            content
        }
    }
}
