//
//  RCMessageModel+STT.m
//  RongIMKit
//
//  Created by RobinCui on 2025/5/30.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageModel+STT.h"
#import "RCSTTContentViewModel.h"
#import "RCMessageModel+StreamCellVM.h"

@implementation RCMessageModel (STT)

- (void)stt_convertSpeedToText:(void(^)(RCErrorCode code))completion; {
    RCSTTContentViewModel *vm = [self stt_sttViewModel];
    [vm convertAndDisplaySpeedToText:completion];
}

- (void)stt_hideSpeedToText {
    RCSTTContentViewModel *vm = [self stt_sttViewModel];
    [vm hideSpeedToText];
}

- (RCSpeechToTextInfo *)stt_refreshSpeechToTextInfo:(RCSpeechToTextInfo *)info {
    if (![self stt_isVoiceMessage]) {
        return nil;
    }
    RCSpeechToTextInfo *tmp = nil;
    if ([self.content isKindOfClass:[RCHQVoiceMessage class]]) {
        RCHQVoiceMessage *msg = (RCHQVoiceMessage *)self.content;
        tmp = msg.sttInfo;
    } else if ([self.content isKindOfClass:[RCVoiceMessage class]]) {
        RCVoiceMessage *msg = (RCVoiceMessage *)self.content;
        tmp = msg.sttInfo;
    }
    tmp.text = info.text;
    tmp.status = info.status;
    tmp.isVisible = info.isVisible;
    return tmp;
}

- (RCSpeechToTextInfo *)stt_speechToTextInfo {
    if (![self stt_isVoiceMessage]) {
        return nil;
    }
    RCSpeechToTextInfo *info = nil;
    if ([self.content isKindOfClass:[RCHQVoiceMessage class]]) {
        RCHQVoiceMessage *msg = (RCHQVoiceMessage *)self.content;
        info = msg.sttInfo;
    } else if ([self.content isKindOfClass:[RCVoiceMessage class]]) {
        RCVoiceMessage *msg = (RCVoiceMessage *)self.content;
        info = msg.sttInfo;
    }
    return info;
}

- (BOOL)stt_isVoiceMessage {
    BOOL ret = [self.content isKindOfClass:[RCHQVoiceMessage class]] ||[self.content isKindOfClass:[RCVoiceMessage class]];
    return ret;
}

- (RCSTTContentViewModel *)stt_sttViewModel {
    if ([self stt_isVoiceMessage] && [self.cellViewModel isKindOfClass:[RCSTTContentViewModel class]]) {
        return self.cellViewModel;
    }
    return nil;
}

- (void)stt_markVoiceMessageListened {
    if (![self stt_isVoiceMessage]) {
        return;
    }
    if (self.messageDirection == MessageDirection_SEND) {
        return;
    }
    [self.receivedStatusInfo markAsListened];
    [[RCCoreClient sharedCoreClient] setMessageReceivedStatus:self.messageId
                                           receivedStatusInfo:self.receivedStatusInfo
                                                   completion:nil];
}

- (BOOL)stt_isConverting {
    return [[self stt_sttViewModel] isConverting];;
}
@end
