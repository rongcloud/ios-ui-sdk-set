//
//  RCMessageModel+RRS.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/3.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageModel+RRS.h"
#import "RCKitConfig.h"
#import "RCRRSUtil.h"

@implementation RCMessageModel (RRS)
- (BOOL)rrs_shouldResponseReadReceiptV5 {
    if (![RCRRSUtil isSupportReadReceiptV5]) {
        return NO;
    }
    if (self.messageUId.length == 0) {
        return NO;
    }
    if (!(self.conversationType == ConversationType_GROUP
        || self.conversationType == ConversationType_PRIVATE)) {
        return NO;
    }
    if (![RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.conversationType)]) {
        return NO;
    }
    
    if (self.needReceipt
        && !self.sentReceipt
        && self.messageDirection == MessageDirection_RECEIVE) {
        return YES;
    }
    return NO;
}

- (BOOL)rrs_shouldFetchReadReceiptV5 {
    if (![RCRRSUtil isSupportReadReceiptV5]) {
        return NO;
    }
    if (self.messageUId.length == 0) {
        return NO;
    }
    if (!(self.conversationType == ConversationType_GROUP
        || self.conversationType == ConversationType_PRIVATE)) {
        return NO;
    }
    if (![RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.conversationType)]) {
        return NO;
    }
    if (self.needReceipt && self.messageDirection == MessageDirection_SEND) {
        return YES;
    }
    
    return NO;
}

@end
