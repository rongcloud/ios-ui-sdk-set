//
//  RCMessageNotificationHelper.m
//  RongIMKit
//
//  Created by RobinCui on 2022/4/18.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCMessageNotificationHelper.h"
#import "RCIMNotificationDataContext.h"

@implementation RCMessageNotificationHelper
/// 验证消息是否可以通知
/// @param message 消息
/// @param completion 回调
+ (void)checkNotifyAbilityWith:(RCMessage *)message completion:(void (^)(BOOL show))completion {
    if(message.messageConfig.disableNotification) {
        if(completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
        return;
    }
    [RCIMNotificationDataContext queryNotificationLevelWith:message.conversationType
                                                   targetId:message.targetId
                                                  channelId:message.channelId
                                                 completion:^(RCPushNotificationLevel level) {
        BOOL re = [self shouldPushByLevel:level message:message];
        if(completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(re);
            });
        }
    }];
}

+ (BOOL)shouldPushByLevel:(RCPushNotificationLevel)level message:(RCMessage *)message {
    BOOL ret = YES;
    RCMentionedType type = message.content.mentionedInfo.type;
    BOOL isSystemMessage = message.conversationType == ConversationType_SYSTEM;
    BOOL isPrivate = message.conversationType == ConversationType_PRIVATE;
    BOOL isGroupChat = !isPrivate && !isSystemMessage;
    BOOL isMentionMe = message.content.mentionedInfo.isMentionedMe;
    //@消息包好自己, 但又不是 @all 消息
    BOOL isContainMe = isMentionMe && (type != RC_Mentioned_All);
    switch(level) {
           // 全部消息通知（接收全部消息通知 -- 显示指定关闭免打扰功能）
        case RCPushNotificationLevelAllMessage:
            //未设置（向上查询群或者APP级别设置）
        case RCPushNotificationLevelDefault:
            break;
            //群聊，超级群 @所有人 或者 @成员列表有自己 时通知；单聊代表消息不通知
        case RCPushNotificationLevelMention: {
            if(!isGroupChat) {
                ret = NO ;
            } else {
                ret = isMentionMe;
            }
            break;
        }
            //群聊，超级群 @成员列表有自己时通知，@所有人不通知；单聊代表消息不通知
        case RCPushNotificationLevelMentionUsers: { // @消息包含 Me 可显示
            if(!isGroupChat) {
                ret = NO;
            } else {
                ret = isContainMe;
            }
            break;
        }
            //群全员通知
        case RCPushNotificationLevelMentionAll:{ // @all消息可显示
            if(!isGroupChat) {
                ret = NO;
            } else {
                ret = (type == RC_Mentioned_All) ;
            }
            break;
        }
            //消息通知被屏蔽，即不接收消息通知
        case RCPushNotificationLevelBlocked:
            ret = NO;
            break;
        default:
            break;
    }
    RCDLog(@"查询结果 %@-> %@ -> level: %ld", !isGroupChat?@"私聊":@"群聊",ret?@"显示":@"不显示", (long)level)

    return ret;
}
@end
