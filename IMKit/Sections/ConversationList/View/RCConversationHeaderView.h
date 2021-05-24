//
//  RCConversationHeaderView.h
//  RongIMKit
//
//  Created by 岑裕 on 16/9/15.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationModel.h"
#import "RCMessageBubbleTipView.h"
#import "RCThemeDefine.h"
#import "RCloudImageView.h"
#import <UIKit/UIKit.h>

@interface RCConversationHeaderView : UIView

@property (nonatomic, strong) RCloudImageView *headerImageView;

@property (nonatomic, assign) RCUserAvatarStyle headerImageStyle;

@property (nonatomic, strong) RCMessageBubbleTipView *bubbleView;

@property (nonatomic, strong) UIView *backgroundView; //向后兼容接口

- (void)updateBubbleUnreadNumber:(int)unreadNumber;

- (void)resetDefaultLayout:(RCConversationModel *)reuseModel;

@end
