//
//  RCMessageModel+RRS.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/3.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageModel+RRS.h"

@implementation RCMessageModel (RRS)
- (BOOL)rrs_shouldResponseReadReceiptV5 {
    if (self.messageUId.length == 0) {
        return NO;
    }
    if (!(self.conversationType == ConversationType_GROUP
        || self.conversationType == ConversationType_PRIVATE)) {
        return NO;
    }
    
    if (self.needReceipt && !self.sentReceipt && self.messageDirection == MessageDirection_RECEIVE) {
        return YES;
    }
    return NO;
}

- (BOOL)rrs_couldFetchReadReceiptV5 {
    if (self.messageUId.length == 0) {
        return NO;
    }
    if (!(self.conversationType == ConversationType_GROUP
        || self.conversationType == ConversationType_PRIVATE)) {
        return NO;
    }
    if (self.needReceipt && self.messageDirection == MessageDirection_SEND) {
        return YES;
    }
    return NO;
}

- (BOOL)rrs_shouldFetchReadReceiptV5 {
    if ([self rrs_couldFetchReadReceiptV5]) {
        return self.readReceiptCount == 0;
    }
    return NO;
}


@end
