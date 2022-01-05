//
//  RCConversationStatusView.h
//  RongIMKit
//
//  Created by RongCloud on 16/9/15.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import "RCConversationModel.h"
#import <UIKit/UIKit.h>

@interface RCConversationStatusView : UIView

@property (nonatomic, strong) UIImageView *conversationNotificationStatusView;

@property (nonatomic, strong) UIImageView *messageReadStatusView;

- (void)updateReadStatus:(RCConversationModel *)model;

- (void)updateNotificationStatus:(RCConversationModel *)model;

- (void)resetDefaultLayout:(RCConversationModel *)reuseModel;

@end
