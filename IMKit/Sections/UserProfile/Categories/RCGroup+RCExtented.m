//
//  RCGroup+RCExtented.m
//  RongIMKit
//
//  Created by zgh on 2024/8/29.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroup+RCExtented.h"
#import <objc/runtime.h>

static const void *kRCGroupKey = &kRCGroupKey;

@implementation RCGroup (RCExtented)
@dynamic rc_group;

- (void)setRc_group:(RCGroupInfo *)rc_group {
    objc_setAssociatedObject(self, kRCGroupKey, rc_group, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.groupId = rc_group.groupId;
    if (rc_group.remark.length > 0) {
        self.groupName = rc_group.remark;
    } else {
        self.groupName = rc_group.groupName;
    }
    self.portraitUri = rc_group.portraitUri;
}

- (RCGroupInfo *)rc_group {
    return objc_getAssociatedObject(self, kRCGroupKey);
}

@end
