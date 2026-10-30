//
//  RCConversationModel+RRS.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/13.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationModel+RRS.h"

@implementation RCConversationModel (RRS)
- (BOOL)rrs_couldFetchConversationReadReceipt {
    if (self.conversationType != ConversationType_PRIVATE) {
        return NO;
    }
    if (self.lastestMessageDirection != MessageDirection_SEND) {
        return NO;
    }
    if (!self.needReceipt) {
        return NO;
    }
    return YES;
}

- (BOOL)rrs_shouldFetchConversationReadReceipt {
    if (![self rrs_couldFetchConversationReadReceipt]) {
        return NO;
    }
    return YES;
}

- (RCMessageIdentifier *)rrs_messageIdentifier {
    if (self.targetId.length == 0 ||
        self.latestMessageUId.length == 0 ||
        self.conversationType < ConversationType_PRIVATE ||
        self.conversationType > ConversationType_INVALID) {
        return nil;
    }
    RCConversationIdentifier *identifier = [[RCConversationIdentifier alloc] init];
    identifier.type = self.conversationType;
    identifier.targetId = self.targetId;
    identifier.channelId = self.channelId;
    return [[RCMessageIdentifier alloc] initWithConversationIdentifier:identifier
                                                            messageUId:self.latestMessageUId];
}
@end
