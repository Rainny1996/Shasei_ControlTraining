import Foundation
import AVFoundation
import Combine

/// 语音服务：优先预录音频，失败降级到 AVSpeechSynthesizer
final class VoiceService {
    static let shared = VoiceService()

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var loopTimer: AnyCancellable?
    private var config = TrainingConfig.default

    func updateConfig(_ config: TrainingConfig) {
        self.config = config
    }

    /// 播报单条文本。preferRecording: 是否优先查找同名预录音频（bundle 内 Audio/xxx.m4a）
    func speak(_ text: String, preferRecording: String? = nil, loop: Bool = false, interval: TimeInterval = 0) {
        stopAndClear()
        // 尝试预录音频
        if let key = preferRecording, let url = Bundle.main.url(forResource: key, withExtension: "m4a", subdirectory: "Audio") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.volume = config.voiceVolume
                audioPlayer?.play()
                if loop {
                    scheduleLoop(text: text, interval: interval)
                }
                return
            } catch {
                // 降级 TTS
            }
        }
        speakTTS(text)
        if loop {
            scheduleLoop(text: text, interval: interval)
        }
    }

    private func speakTTS(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.volume = config.voiceVolume
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * config.voiceRate
        synthesizer.speak(utterance)
    }

    private func scheduleLoop(text: String, interval: TimeInterval) {
        loopTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.speak(text, loop: false)
            }
    }

    /// 中断当前播报并清空队列
    func stopAndClear() {
        loopTimer?.cancel()
        loopTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
