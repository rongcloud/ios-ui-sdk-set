//
//  RCConversationDetailContentView.h
//  RongIMKit
//
//  Created by RongCloud on 16/9/15.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import "RCConversationModel.h"
#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>

@interface RCConversationDetailContentView : UIView

@property (nonatomic, strong) UILabel *hightlineLabel;

@property (nonatomic, strong) UIImageView *sentStatusView;

@property (nonatomic, strong) UILabel *messageContentLabel;

- (void)updateContent:(RCConversationModel *)model;

- (void)updateContent:(RCConversationModel *)model prefixName:(NSString *)prefixName;

- (void)resetDefaultLayout:(RCConversationModel *)reuseModel;

- (void)updateLayout;
@end
