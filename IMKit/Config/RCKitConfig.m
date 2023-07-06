//
//  RCKitConfig.m
//  RongIMKit
//
//  Created by Sin on 2020/6/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCKitConfig.h"

@interface RCKitFontConf ()

@end

@implementation RCKitConfig
+ (instancetype)defaultConfig {
    static RCKitConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if(self) {
        self.message = [[RCKitMessageConf alloc] init];
        self.ui = [[RCKitUIConf alloc] init];
        self.font = [[RCKitFontConf alloc] init];
    }
    return self;
}
@end
