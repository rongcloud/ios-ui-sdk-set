//
//  RCConversationCSUtil.h
//  RongIMKit
//
//  Created by Sin on 2020/6/16.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCConversationViewController.h"

//聊天页面客服相关功能
@interface RCConversationCSUtil : NSObject
- (instancetype)init:(RCConversationViewController *)chatVC;
/*!
 用户的详细信息，此数据用于上传用户信息到客服后台，数据的nickName和portraitUrl必须填写。
 */
@property (nonatomic, strong) RCCustomerServiceInfo *csInfo;

@property (nonatomic, assign) RCCustomerServiceStatus currentServiceStatus;

//客服开始
- (void)startCustomerService;

- (void)stopCSTimer;

- (void)startNotReciveMessageAlertTimer;
- (void)startNotSendMessageAlertTimer;

- (void)didTapCSPullLeaveMessage:(RCMessageModel *)model;

- (void)customerServiceLeftCurrentViewController;
@end
