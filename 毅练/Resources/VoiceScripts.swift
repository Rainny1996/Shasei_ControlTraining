import Foundation

/// 预定义语音文本库（按状态索引）。preferRecording key 对应 Audio/ 目录下同名 m4a。
enum VoiceScripts {
    /// 准备阶段入场语音
    static let prepare = """
    训练即将开始，请确保你处在安静私密的空间，准备好润滑剂。\
    本次训练中，请不要观看任何高刺激度视频或图片，也不要播放成人内容。\
    当你准备就绪，请点击屏幕下方的按钮。
    """

    /// 唤醒阶段循环语音
    static let arousalLoop = """
    缓慢地刺激阴茎，让身体逐渐唤醒。关注触觉而非画面，保持兴奋在较低水平。\
    勃起后，请点击“我已勃起，开始训练”按钮。
    """
    static let arousalTimeout = "你似乎还在准备。无需着急，保持放松，勃起后请点击按钮开始训练。"

    /// 低兴奋区
    static let lowArousal = "开始刺激。当你的快感变得可控，进入4到6分区间时，按下“我进入4-6分了”。"
    static let lowArousalFinal = "这是最后一轮训练。开始刺激，进入4到6分区间时，按下“我进入4-6分了”。完成后你将可以允许自己释放。"
    static let lowArousalTimeout = "你已进入平静期。当快感进入4到6分可控区间时，请按下对应按钮。"

    /// 可控区间
    static let controlZone = "很好，你现在在最佳训练区。享受这种感觉，如果感到兴奋即将失控，立刻按下中央按钮。"
    static let controlZoneFinal = "这是最后一轮的最佳训练区。保持享受，若感到即将失控，立刻按下中央按钮。"
    static let controlReminder = "仍在掌控中吗？随时准备刹车。"

    /// 7分停止完整引导（约30秒）
    static let sevenStopGuide = """
    已到7分。立刻停止所有刺激，手完全离开。跟我做腹式呼吸：吸气，感受腹部鼓起……\
    呼气，尽量拉长到6秒，心里默念“松——”。再来一次……最后一次。\
    接下来，主动放松盆底，想象一块布平铺下去，让整个区域完全下沉。\
    保持不动，自然呼吸。等待兴奋回落。
    """
    static let fallBack15s = "继续放松呼吸，硬度稍微下降是完全正常的。"

    /// 挤捏法
    static let squeezeGuide = """
    我们使用停止-挤压法。用拇指按住龟头下方系带处……\
    现在开始，挤压，保持，同时深呼气……放松。\
    如果你感觉已经回落，可点击按钮继续训练。
    """

    /// 射精许可
    static let ejaculateReady = "你已经完成了训练循环。到达7到8分后，你可以允许自己射精。不要有压力，享受释放的感觉。"

    /// 完成
    static let finished = "训练完成。你做得很好。本次数据已记录。"
}
