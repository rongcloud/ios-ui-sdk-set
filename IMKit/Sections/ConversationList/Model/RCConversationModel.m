//
//  RCConversationModel.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCConversationModel.h"

@implementation RCConversationModel
- (instancetype)initWithConversation:(RCConversation *)conversation extend:(id)extend {
    RCConversationModelType modelType = RC_CONVERSATION_MODEL_TYPE_NORMAL;
    if (conversation.conversationType == ConversationType_SYSTEM &&
        [conversation.lastestMessage isMemberOfClass:[RCContactNotificationMessage class]]) {
        //筛选请求添加好友的系统消息，用于生成自定义会话类型的cell
        modelType = RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION;
    } else if (conversation.conversationType == ConversationType_APPSERVICE ||
               conversation.conversationType == ConversationType_PUBLICSERVICE) {
        modelType = RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE;
    }

    return [self init:modelType conversation:conversation extend:extend];
}

- (instancetype)init:(RCConversationModelType)conversationModelType
        conversation:(RCConversation *)conversation
              extend:(NSObject *)extend {
    self = [super init];
    if (self) {
        self.extend = extend;
        self.conversationModelType = conversationModelType;
        self.targetId = conversation.targetId;
        self.channelId = conversation.channelId;
        self.conversationTitle = conversation.conversationTitle;
        self.unreadMessageCount = conversation.unreadMessageCount;
        self.isTop = conversation.isTop;
        self.blockStatus = conversation.blockStatus;
        self.sentStatus = conversation.sentStatus;
        self.receivedTime = conversation.receivedTime;
        self.sentTime = conversation.sentTime;
        self.operationTime = conversation.operationTime;
        self.draft = conversation.draft;
        self.editedMessageDraft = conversation.editedMessageDraft;
        self.objectName = conversation.objectName;
        self.senderUserId = conversation.senderUserId;
        self.receivedStatusInfo = conversation.receivedStatusInfo;
        self.lastestMessageId = conversation.lastestMessageId;
        self.lastestMessageDirection = conversation.lastestMessageDirection;
        self.lastestMessage = conversation.lastestMessage;
        self.conversationType = conversation.conversationType;
        self.mentionedCount = conversation.mentionedCount;
        if (RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE == conversationModelType) {
            // self.conversationTitle = conversation.conversationTitle;
        }
        self.notificationLevel = conversation.notificationLevel;
        self.firstUnreadMsgSendTime = conversation.firstUnreadMsgSendTime;
        self.latestMessageUId = conversation.latestMessageUId;
        self.needReceipt = conversation.latestRCMessage.needReceipt;
    }
    return self;
}

- (void)updateWithMessage:(RCMessage *)message {
    self.targetId = message.targetId;
    self.channelId = message.channelId;
    self.sentStatus = message.sentStatus;
    self.receivedStatusInfo = message.receivedStatusInfo;
    self.receivedTime = message.receivedTime;
    self.sentTime = message.sentTime;
    self.objectName = message.objectName;
    self.senderUserId = message.senderUserId;
    self.lastestMessageId = message.messageId;
    self.lastestMessageDirection = message.messageDirection;
    self.lastestMessage = message.content;
    self.conversationType = message.conversationType;
    if (message.messageDirection == MessageDirection_RECEIVE && NO == message.receivedStatusInfo.isRead &&
        NO == message.receivedStatusInfo.isListened) {
        if (([[message.content class] persistentFlag] & MessagePersistent_ISCOUNTED) == MessagePersistent_ISCOUNTED) {
            self.unreadMessageCount += 1;
        }
        if ([[message.content class] persistentFlag] & MessagePersistent_ISPERSISTED) {
            if (message.content.mentionedInfo.isMentionedMe) {
                self.mentionedCount += 1;
            }
        }
    }
}

- (BOOL)hasUnreadMentioned {
    return self.mentionedCount > 0;
}

- (BOOL)isMatching:(RCConversationType)conversationType targetId:(NSString *)targetId {
    if (self.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION &&
        self.conversationType == conversationType) {
        return YES;
    } else if (self.conversationType == conversationType && [self.targetId isEqualToString:targetId]) {
        return YES;
    }
    return NO;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        RCConversationModel *model = (RCConversationModel *)object;
        if ([self isMatching:model.conversationType targetId:model.targetId]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - setter & getter

- (void)setReceivedStatus:(RCReceivedStatus)receivedStatus {
    self.receivedStatusInfo = [[RCReceivedStatusInfo alloc] initWithReceivedStatus:receivedStatus];
}

- (RCReceivedStatus)receivedStatus {
    RCConversation *conversation = [[RCConversation alloc] init];
    conversation.receivedStatusInfo = self.receivedStatusInfo;
    return conversation.receivedStatus;
}

- (RCReceivedStatusInfo *)receivedStatusInfo {
    if (!_receivedStatusInfo) {
        _receivedStatusInfo = [[RCReceivedStatusInfo alloc] initWithReceivedStatus:0];
    }
    return _receivedStatusInfo;
}

- (void)setDraft:(NSString *)draft {
    if (draft.length) {
        __autoreleasing NSError *error = nil;
        NSData *draftData = [draft dataUsingEncoding:NSUTF8StringEncoding];
        if (!draftData) {
            _draft = draft;
        } else {
            NSDictionary *draftDict =
                [NSJSONSerialization JSONObjectWithData:draftData options:kNilOptions error:&error];
            if (error) {
                _draft = draft;
            } else {
                if ([draftDict isKindOfClass:[NSDictionary class]] &&
                    [draftDict.allKeys containsObject:@"draftContent"]) {
                    _draft = [draftDict objectForKey:@"draftContent"];
                }
            }
        }
    } else {
        _draft = draft;
    }
}

@end
