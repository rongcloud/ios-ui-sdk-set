//
//  RCOldMessageNotificationMessage.m
//  RongIMKit
//
//  Created by RongCloud on 15/8/24.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCOldMessageNotificationMessage.h"

@implementation RCOldMessageNotificationMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        // self.type = aType;
    }
    return self;
}

- (NSData *)encode {

    return nil;
}

- (void)decodeWithData:(NSData *)data {
}

+ (RCMessagePersistent)persistentFlag {
    return MessagePersistent_NONE;
}

+ (NSString *)getObjectName {
    return RCOldMessageNotificationMessageTypeIdentifier;
}

#if !__has_feature(objc_arc)
- (void)dealloc {
    [super dealloc];
}
#endif //__has_feature(objc_arc)
@end
