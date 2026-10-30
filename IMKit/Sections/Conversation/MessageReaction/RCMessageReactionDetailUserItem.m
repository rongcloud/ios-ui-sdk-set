//
//  RCMessageReactionDetailUserItem.m
//  RongIMKit
//
//  Created by RC on 2026/6/12.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionDetailUserItem.h"

@implementation RCMessageReactionDetailUserItem

- (instancetype)initWithUser:(RCMessageReactionUser *)user
                 displayName:(NSString *)displayName
                 portraitUri:(NSString *)portraitUri {
    self = [super init];
    if (self) {
        _user = user;
        _displayName = displayName.copy ?: @"";
        _portraitUri = portraitUri.copy;
    }
    return self;
}

@end
