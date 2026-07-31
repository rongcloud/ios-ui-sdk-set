//
//  RCMessageReactionUsageInfo.m
//  RongIMKit
//
//  Created by RC on 2026/6/2.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionUsageInfo.h"

static NSString *const RCMessageReactionUsageInfoReactionIdKey = @"reactionId";
static NSString *const RCMessageReactionUsageInfoUseCountKey = @"useCount";
static NSString *const RCMessageReactionUsageInfoLastUsedTimeKey = @"lastUsedTime";

@implementation RCMessageReactionUsageInfo

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)copyWithZone:(NSZone *)zone {
    RCMessageReactionUsageInfo *info = [[[self class] allocWithZone:zone] init];
    info.reactionId = self.reactionId;
    info.useCount = self.useCount;
    info.lastUsedTime = self.lastUsedTime;
    return info;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.reactionId forKey:RCMessageReactionUsageInfoReactionIdKey];
    [coder encodeInteger:self.useCount forKey:RCMessageReactionUsageInfoUseCountKey];
    [coder encodeInt64:self.lastUsedTime forKey:RCMessageReactionUsageInfoLastUsedTimeKey];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.reactionId = [coder decodeObjectOfClass:NSString.class forKey:RCMessageReactionUsageInfoReactionIdKey];
        self.useCount = [coder decodeIntegerForKey:RCMessageReactionUsageInfoUseCountKey];
        self.lastUsedTime = [coder decodeInt64ForKey:RCMessageReactionUsageInfoLastUsedTimeKey];
    }
    return self;
}

@end
