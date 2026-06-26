//
//  RCCCGroupInfo.m
//  RongContactCard
//
//  Created by 杜立召 on 15/3/19.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCCCGroupInfo.h"

@implementation RCCCGroupInfo
#define KEY_RCDGROUP_INFO_NUMBER @"number"

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        if (decoder == nil) {
            return self;
        }
        //
        self.number = [decoder decodeObjectForKey:KEY_RCDGROUP_INFO_NUMBER];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.number forKey:KEY_RCDGROUP_INFO_NUMBER];
}

@end
