import UIKit
import SwiftUI
import AVFAudio

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 配置通知
        NotificationService.shared.requestAuthorization()
        
        // 配置音频会话
        configureAudioSession()
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // 进入后台时锁定应用
        SecurityService.shared.lockApp()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // 锁屏认证由 LockScreenView.onAppear 统一管理，此处不再重复调用
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return true
    }
    
    // MARK: - Private Methods
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback,
                                                             mode: .spokenAudio,
                                                             options: [.duckOthers, .allowBluetooth, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}