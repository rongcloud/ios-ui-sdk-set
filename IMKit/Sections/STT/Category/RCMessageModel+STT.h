//
//  RCMessageModel+STT.h
//  RongIMKit
//
//  Created by RobinCui on 2025/5/30.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageModel.h"
#import "RCSTTContentViewModel.h"
NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG
#define RCSTTLog(format, ...) \
    NSLog((@"[STT] [%@(%d)] -> "  format), \
[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__, ##__VA_ARGS__);
#else
#define RCSTTLog(...)
#endif

@interface RCMessageModel (STT)

/// STT model
- (RCSpeechToTextInfo *)stt_speechToTextInfo;

/// STT ViewModel
- (RCSTTContentViewModel *)stt_sttViewModel;

/// 语音转文本
- (void)stt_convertSpeedToText:(void(^)(RCErrorCode code))completion;;

/// 隐藏语音转文本
- (void)stt_hideSpeedToText;

/// 是否为语音消息
- (BOOL)stt_isVoiceMessage;

/// 同步消息模型中是 sttInfo [存在消息模型中Content 被替换的情况, 必要时需要同步两边的数据]
/// - Parameter info: 新的sttInfo
- (RCSpeechToTextInfo *)stt_refreshSpeechToTextInfo:(RCSpeechToTextInfo *)info;

/// 标记语音消息已读
- (void)stt_markVoiceMessageListened;

/// 是否正在转化
- (BOOL)stt_isConverting;
@end

NS_ASSUME_NONNULL_END
