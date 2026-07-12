import UIKit

/// Taptic Engine 触感反馈封装
final class HapticManager {
    static let shared = HapticManager()

    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let notify = UINotificationFeedbackGenerator()

    func tap() { impact.impactOccurred() }
    func lightTap() { light.impactOccurred() }
    func success() { notify.notificationOccurred(.success) }
    func warning() { notify.notificationOccurred(.warning) }
}
