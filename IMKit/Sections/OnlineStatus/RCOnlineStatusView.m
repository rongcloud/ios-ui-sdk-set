//
//  RCOnlineStatusView.m
//  RongIMKit
//
//  Created by Lang on 11/7/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCOnlineStatusView.h"
#import "RCKitCommonDefine.h"

/// 在线状态指示器尺寸
static const CGFloat kOnlineStatusSize = 6.0;

@implementation RCOnlineStatusView

- (void)setupView {
    [super setupView];
    // 设置圆形
    self.layer.cornerRadius = kOnlineStatusSize / 2.0;
    self.layer.masksToBounds = YES;
    
    self.frame = CGRectMake(0, 0, kOnlineStatusSize, kOnlineStatusSize);
    
    // 默认隐藏
    self.hidden = YES;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(kOnlineStatusSize, kOnlineStatusSize);
}

#pragma mark - Public Methods

- (void)setOnline:(BOOL)isOnline {
    _online = isOnline;
    if (self.hidden) {
        return;
    }
    if (isOnline) {
        // 在线：绿色圆点
        self.backgroundColor = RCDynamicColor(@"success_color", @"0x16D258", @"0x17EA61");
    } else {
        // 离线：灰色圆点
        self.backgroundColor = RCDynamicColor(@"disabled_color", @"0xD9D9D9", @"0xD1D1D1");
    }
}

- (void)reset {
    self.hidden = YES;
    self.backgroundColor = nil;
}

@end

