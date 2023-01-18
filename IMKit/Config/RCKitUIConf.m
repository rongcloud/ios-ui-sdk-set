//
//  RCKitUIConf.m
//  RongIMKit
//
//  Created by Sin on 2020/6/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCKitUIConf.h"

@implementation RCKitUIConf
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.globalNavigationBarTintColor = [UIColor blackColor];
        self.globalConversationAvatarStyle = RC_USER_AVATAR_RECTANGLE;
        self.globalConversationPortraitSize = CGSizeMake(46, 46);
        self.globalMessageAvatarStyle = RC_USER_AVATAR_RECTANGLE;
        self.globalMessagePortraitSize = CGSizeMake(40, 40);
        self.portraitImageViewCornerRadius = 5;
    }
    return self;
}

- (void)setGlobalConversationPortraitSize:(CGSize)globalConversationPortraitSize {
    CGFloat width = globalConversationPortraitSize.width;
    CGFloat height = globalConversationPortraitSize.height;

    if (height < 36.0f) {
        height = 36.0f;
    }

    _globalConversationPortraitSize.width = width;
    _globalConversationPortraitSize.height = height;
}

- (void)setGlobalMessagePortraitSize:(CGSize)globalMessagePortraitSize {
    CGFloat width = globalMessagePortraitSize.width;
    CGFloat height = globalMessagePortraitSize.height;

    _globalMessagePortraitSize.width = width;
    _globalMessagePortraitSize.height = height;
}
@end
