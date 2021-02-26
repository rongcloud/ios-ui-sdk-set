//
//  RCCombineMessageUtility.m
//  RongIMKit
//
//  Created by liyan on 2019/8/26.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCCombineMessageUtility.h"
#import "RCMessageModel.h"
#import "RCKitCommonDefine.h"
@implementation RCCombineMessageUtility

+ (NSString *)getCombineMessagePreviewVCTitle:(RCCombineMessage *)message {
    if (!message) {
        return @"";
    }
    NSString *title = @"";
    if (message.conversationType == ConversationType_GROUP) {
        title = RCLocalizedString(@"GroupChatHistoryTitle");
    } else {
        if (message.nameList && message.nameList.count > 1) {
            title =
                [NSString stringWithFormat:RCLocalizedString(@"ChatHistoryTitleXAndY"),
                                           [message.nameList firstObject], [message.nameList lastObject]];
        } else if (message.nameList && message.nameList.count == 1) {
            title = [NSString stringWithFormat:RCLocalizedString(@"ChatHistoryTitleX"),
                                               [message.nameList firstObject]];
        }
    }
    return title;
}

+ (NSString *)getCombineMessageSummaryTitle:(RCCombineMessage *)message {
    if (!message) {
        return @"";
    }
    NSString *title = @"";
    if (message.conversationType == ConversationType_GROUP) {
        title = RCLocalizedString(@"GroupChatHistory");
    } else {
        if (message.nameList && message.nameList.count > 1) {
            title = [NSString stringWithFormat:RCLocalizedString(@"ChatHistoryForXAndY"),
                                               [message.nameList firstObject], [message.nameList lastObject]];
        } else if (message.nameList && message.nameList.count == 1) {
            title = [NSString stringWithFormat:RCLocalizedString(@"ChatHistoryForX"),
                                               [message.nameList firstObject]];
        }
    }
    return title;
}

+ (NSString *)getCombineMessageSummaryContent:(RCCombineMessage *)message {
    if (!message) {
        return @"";
    }
    if (!message.summaryList) {
        return @"";
    }
    NSMutableString *summaryContent = [[NSMutableString alloc] init];
    for (int i = 0; i < message.summaryList.count; i++) {
        NSString *summary = [message.summaryList objectAtIndex:i];
        [summaryContent appendString:summary];
        if (i < message.summaryList.count - 1) {
            [summaryContent appendString:@"\n"];
        }
    }
    return [summaryContent copy];
}
//消息合并转发的白名单
+ (BOOL)allSelectedCombineForwordMessagesAreLegal:(NSArray<RCMessageModel *> *)allSelectedMessages {
    if (!allSelectedMessages) {
        return NO;
    }
    for (RCMessageModel *model in allSelectedMessages) {
        if (!model) {
            return NO;
        }
        //未成功发送的消息不可转发
        if (model.sentStatus == SentStatus_SENDING || model.sentStatus == SentStatus_FAILED ||
            model.sentStatus == SentStatus_CANCELED) {
            return NO;
        }
        NSArray *whiteList = @[
            RCTextMessageTypeIdentifier,
            @"RC:ImgTextMsg",
            @"RC:StkMsg",
            @"RC:CardMsg",
            RCLocationMessageTypeIdentifier,
            RCSightMessageTypeIdentifier,
            RCImageMessageTypeIdentifier,
            RCFileMessageTypeIdentifier,
            RCCombineMessageTypeIdentifier,
            RCHQVoiceMessageTypeIdentifier,
            RCVoiceMessageTypeIdentifier,
            RCGIFMessageTypeIdentifier,
            @"RC:VCSummary"
        ];
        if (![whiteList containsObject:model.objectName] || model.content.destructDuration > 0) {
            return NO;
        }
    }
    return YES;
}
//消息逐条转发的白名单
+ (BOOL)allSelectedOneByOneForwordMessagesAreLegal:(NSArray<RCMessageModel *> *)allSelectedMessages {
    if (!allSelectedMessages) {
        return NO;
    }
    for (RCMessageModel *model in allSelectedMessages) {
        if (!model) {
            return NO;
        }
        //未成功发送的消息不可转发
        if (model.sentStatus == SentStatus_SENDING || model.sentStatus == SentStatus_FAILED ||
            model.sentStatus == SentStatus_CANCELED) {
            return NO;
        }
        NSArray *whiteList = @[
            RCTextMessageTypeIdentifier,
            @"RC:ImgTextMsg",
            @"RC:StkMsg",
            @"RC:CardMsg",
            RCLocationMessageTypeIdentifier,
            RCSightMessageTypeIdentifier,
            RCImageMessageTypeIdentifier,
            RCFileMessageTypeIdentifier,
            RCCombineMessageTypeIdentifier,
            RCHQVoiceMessageTypeIdentifier,
            RCVoiceMessageTypeIdentifier,
            RCGIFMessageTypeIdentifier,
            RCReferenceMessageTypeIdentifier
        ];
        if (![whiteList containsObject:model.objectName] || model.content.destructDuration > 0) {
            return NO;
        }
    }
    return YES;
}

@end
