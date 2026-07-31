//
//  RCUserInfo+RCGroupMember.m
//  RongIMKit
//
//  Created by zgh on 2024/8/29.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCUserInfo+RCGroupMember.h"
#import <objc/runtime.h>

static const void *kRCMemberKey = &kRCMemberKey;

@implementation RCUserInfo (RCGroupMember)
@dynamic rc_member;

- (void)setRc_member:(RCGroupMemberInfo *)rc_member {
    objc_setAssociatedObject(self, kRCMemberKey, rc_member, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.userId = rc_member.userId;
    if (rc_member.nickname.length > 0) {
        self.name = rc_member.nickname;
    } else {
        self.name = rc_member.name;
    }
    self.extra = rc_member.extra;
    self.portraitUri = rc_member.portraitUri;
}

- (RCGroupMemberInfo *)rc_member {
    return objc_getAssociatedObject(self, kRCMemberKey);
}

@end
