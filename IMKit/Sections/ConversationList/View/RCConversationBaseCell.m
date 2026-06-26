//
//  RCConversationBaseCell.m
//  RongIMKit
//
//  Created by xugang on 15/1/24.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCConversationBaseCell.h"

@implementation RCConversationBaseCell

- (void)setDataModel:(RCConversationModel *)model {
    self.model = model;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
