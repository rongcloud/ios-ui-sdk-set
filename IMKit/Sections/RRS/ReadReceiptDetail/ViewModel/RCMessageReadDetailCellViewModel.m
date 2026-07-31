//
//  RCReadReceiptDetailUserCellViewModel.m
//  RongIMKit
//
//  Created by Lang on 10/15/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageReadDetailCellViewModel.h"
#import "RCKitUtility.h"

@interface RCMessageReadDetailCellViewModel ()

@property (nonatomic, strong) RCUserInfo *userInfo;
@property (nonatomic, assign) long long readTime;

@end

@implementation RCMessageReadDetailCellViewModel

- (instancetype)initWithUserInfo:(RCUserInfo *)userInfo
                        readTime:(long long)readTime {
    self = [super init];
    if (self) {
        _userInfo = userInfo;
        _readTime = readTime;
        _displayReadTime = readTime > 0 ? [RCKitUtility convertMessageTime:self.readTime/1000] : @"";
        _cellHeight = 54;
    }
    return self;
}

@end
