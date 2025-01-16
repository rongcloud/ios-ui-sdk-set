//
//  RCMJRefreshConfig.m
//
//  Created by Frank on 2018/11/27.
//  Copyright © 2018 小码哥. All rights reserved.
//

#import "RCMJRefreshConfig.h"

static RCMJRefreshConfig *mj_RefreshConfig = nil;

@implementation RCMJRefreshConfig

+ (instancetype)defaultConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mj_RefreshConfig = [[self alloc] init];
    });
    return mj_RefreshConfig;
}

@end
