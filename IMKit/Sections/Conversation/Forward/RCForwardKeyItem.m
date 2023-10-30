//
//  RCForwardKeyItem.m
//  RongIMKit
//
//  Created by RobinCui on 2022/12/9.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCForwardKeyItem.h"

@implementation RCForwardKeyItem

- (instancetype)initWithTitle:(NSString *)title key:(NSString *)key
{
    self = [super init];
    if (self) {
        self.title = title;
        self.htmlKey = key;
    }
    return self;
}
@end
