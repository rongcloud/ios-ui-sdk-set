//
//  RCMessageSendingContext.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/18.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageSendingContext.h"
#import "RCIMThreadLock.h"
@interface RCMessageSendingContext()
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, RCMessageModel *> *sendingMessages;
@property (nonatomic, strong) RCIMThreadLock *lock;
@end
@implementation RCMessageSendingContext
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lock = [RCIMThreadLock new];
        self.sendingMessages = [NSMutableDictionary dictionary];
    }
    return self;
}

// 添加发送中的消息
- (void)addSendingMessage:(RCMessageModel *)message {
    if (message.messageId >0 && message.messageDirection == MessageDirection_SEND) {
        [self.lock performWriteLockBlock:^{
            if (self.sendingMessages[@(message.messageId)] == nil) {
                self.sendingMessages[@(message.messageId)] = message;
            }
        }];
    }
}

// 更新消息发送成功状态
- (BOOL)updateMessageSendSuccess:(RCMessage *)message {
    if (message.messageId >0 && message.messageDirection == MessageDirection_SEND) {
        __block RCMessageModel *model = nil;
        [self.lock performReadLockBlock:^{
            model = self.sendingMessages[@(message.messageId)];
        }];
        if (!model) {
            return NO;
        }
        model.sentStatus = SentStatus_SENT;
        if (model.messageId > 0) {
            if (message) {
                model.sentTime = message.sentTime;
                model.messageUId = message.messageUId;
                model.content = message.content;
            }
        }
        
        [self.lock performWriteLockBlock:^{
            self.sendingMessages[@(message.messageId)] = nil;
        }];
        return YES;
    }
    return NO;
}

@end
