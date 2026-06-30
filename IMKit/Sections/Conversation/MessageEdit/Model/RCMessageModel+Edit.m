//
//  RCMessageModel+Edit.m
//  RongIMKit
//
//  Created by Lang on 2025/7/28.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageModel+Edit.h"
#import "RCKitConfig.h"
#import "RCMessageEditUtil.h"

@implementation RCMessageModel (Edit)

- (BOOL)edit_isMessageEditable {
    if (!RCKitConfigCenter.message.enableEditMessage) {
        return NO;
    }
    if (self.conversationType != ConversationType_PRIVATE
        && self.conversationType != ConversationType_GROUP) {
        return NO;
    }
    // 只有文本消息和引用消息可以编辑
    if (![self.content isMemberOfClass:[RCTextMessage class]] &&
        ![self.content isMemberOfClass:[RCReferenceMessage class]]) {
        return NO;
    }
    
    // 只能编辑自己发送的消息
    if (self.messageDirection != MessageDirection_SEND) {
        return NO;
    }
    
    // 只能编辑已发送成功的消息
    if (self.messageUId.length == 0) {
        return NO;
    }
    
    return [RCMessageEditUtil isEditTimeValid:self.sentTime];
}

@end
