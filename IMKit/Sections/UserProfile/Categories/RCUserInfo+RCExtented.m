//
//  RCUserInfo+RCExtented.m
//  RongIMKit
//
//  Created by zgh on 2024/8/29.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCUserInfo+RCExtented.h"
#import <objc/runtime.h>

static const void *kRCFriendInfoKey = &kRCFriendInfoKey;
static const void *kRCUserProfileKey = &kRCUserProfileKey;


@implementation RCUserInfo (RCExtented)
@dynamic rc_profile;
@dynamic rc_friendInfo;

- (void)setRc_profile:(RCUserProfile *)rc_profile {
    objc_setAssociatedObject(self, kRCUserProfileKey, rc_profile, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.userId = rc_profile.userId;
    self.name = rc_profile.name;
    self.portraitUri = rc_profile.portraitUri;
    if (!rc_profile.userExtProfile) {
        return;
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:rc_profile.userExtProfile options:NSJSONWritingPrettyPrinted error:&error];
    if (jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        self.extra = jsonString;
    }
}

- (void)setRc_friendInfo:(RCFriendInfo *)rc_friendInfo {    objc_setAssociatedObject(self, kRCFriendInfoKey, rc_friendInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.userId = rc_friendInfo.userId;
    self.name = rc_friendInfo.name;
    self.alias = rc_friendInfo.remark;
    self.portraitUri = rc_friendInfo.portraitUri;
    if (!rc_friendInfo.extProfile) {
        return;
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:rc_friendInfo.extProfile options:NSJSONWritingPrettyPrinted error:&error];
    if (jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        self.extra = jsonString;
    }
}

- (RCFriendInfo *)rc_friendInfo {
    return objc_getAssociatedObject(self, kRCFriendInfoKey);
}

- (RCUserProfile *)rc_profile {
    return objc_getAssociatedObject(self, kRCUserProfileKey);
}

@end
