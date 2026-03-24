//
//  RCMessageReadDetailViewConfig.m
//  RongIMKit
//
//  Created by Lang on 10/15/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageReadDetailViewConfig.h"
#import "RCKitCommonDefine.h"


@implementation RCMessageReadDetailViewConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置默认值
        _tabHeight = 42.0;
        _pageSize = 100;
    }
    return self;
}

- (void)setPageSize:(NSInteger)pageSize {
    _pageSize = MIN(MAX(pageSize, 1), 100);
}

@end

