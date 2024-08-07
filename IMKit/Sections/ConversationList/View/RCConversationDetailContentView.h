//
//  RCConversationDetailContentView.h
//  RongIMKit
//
//  Created by 岑裕 on 16/9/15.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationModel.h"
#import <UIKit/UIKit.h>
#import "RCBaseImageView.h"
@interface RCConversationDetailContentView : UIView

@property (nonatomic, strong) UILabel *hightlineLabel;

@property (nonatomic, strong) RCBaseImageView *sentStatusView;

@property (nonatomic, strong) UILabel *messageContentLabel;

- (void)updateContent:(RCConversationModel *)model;

- (void)updateContent:(RCConversationModel *)model prefixName:(NSString *)prefixName;

- (void)resetDefaultLayout:(RCConversationModel *)reuseModel;

- (void)updateLayout;
@end
