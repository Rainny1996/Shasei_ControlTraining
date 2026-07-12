# 毅练 (YiLian) — iOS 控时训练 App

基于 PRD 文档开发的 iOS 应用，将"停-动"（Start-Stop）行为训练法数字化，通过语音引导与极简屏幕交互，帮助用户在私密环境中完成行为训练。

## 技术栈
- **SwiftUI** + **MVVM + Combine**
- **Core Data**（NSFileProtectionComplete 文件级加密）
- **AVSpeechSynthesizer** 语音（预录音频优先，TTS 备选）
- **LocalAuthentication**（面容 / 指纹）+ Keychain 密码
- 最低支持 **iOS 15**，适配 iPhone（含 iPad 通用）

## 功能模块
- 训练准备流程（清单淡入）
- 唤醒阶段（可选，设置可关）
- 低兴奋区 / 可控区间 / 7分调整等待
- 停止-挤压法指导 + 自动提醒
- 最终射精许可与完成统计
- 训练记录（列表 + 自绘趋势图）
- 隐私锁（面容/指纹 + 独立密码，假密码留后续版本）
- 设置中心（循环次数、等待时长、唤醒开关、语音参数）

## 目录结构
```
毅练/
├── 毅练.xcodeproj
└── 毅练/
    ├── App/            # App 入口、锁屏/模糊/状态栏逻辑
    ├── Models/         # 状态枚举、配置、Core Data 实体
    ├── StateMachine/   # 训练状态机（单一事实来源）
    ├── Services/       # 语音、计时、存储、认证、触感
    ├── ViewModels/     # MVVM 视图模型
    ├── Views/          # 全部 SwiftUI 视图
    └── Model/          # Core Data 数据模型
```

## 构建与运行
1. 在 **macOS + Xcode 15+** 环境中打开 `毅练/毅练.xcodeproj`。
2. 选择目标设备（iPhone 模拟器或真机）。
3. 真机运行需在 Signing & Capabilities 中配置自己的 Team 与 Bundle ID。
4. `⌘R` 编译运行。

## 语音音频（重要）
`VoiceService` 优先加载 `毅练/毅练/Resources/Audio/<key>.m4a` 预录音频，缺失时自动降级为系统 TTS，不会崩溃。
请按 `VoiceScripts.swift` 中各文本对应的 key 录制音频后放入 `Resources/Audio/` 目录（当前目录为占位）。

## 合规提示（App Store 审核）
- 类别：健康/健身。
- 元数据避免"自慰""早泄"，使用"控时训练""男性健康"。
- 提供免责声明："本品仅为行为训练辅助，不替代专业医疗建议。"
