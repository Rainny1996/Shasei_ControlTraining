# 预录语音音频占位目录

VoiceService 优先从此目录加载同名 `.m4a` 文件，缺失则自动降级为系统 TTS。

## 需录制的音频文件（对应 VoiceScripts 文本）
- prepare.m4a          — 训练准备入场语音
- arousalLoop.m4a      — 唤醒阶段循环语音
- arousalTimeout.m4a   — 唤醒超时提醒
- lowArousal.m4a       — 低兴奋区
- lowArousalFinal.m4a  — 最后一轮低兴奋区
- lowArousalTimeout.m4a— 低兴奋区超时
- controlZone.m4a      — 可控区间
- controlZoneFinal.m4a — 最后一轮可控区间
- controlReminder.m4a  — 可控区间轻声提醒
- sevenStopGuide.m4a   — 7分停止完整引导（约30秒）
- fallBack15s.m4a      — 回落剩15秒提示
- squeezeGuide.m4a     — 挤捏法指导
- ejaculateReady.m4a   — 射精许可
- finished.m4a         — 完成

录制要求：中文女声（默认）/ 男声（可选），安静环境，无背景音乐。
注意：App 完全离线，请勿在音频中嵌入任何第三方水印或网络请求。
