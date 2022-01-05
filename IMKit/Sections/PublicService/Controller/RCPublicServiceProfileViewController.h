//
//  RCPublicServiceProfileViewController.h
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015 litao. All rights reserved.
//

#import "RCThemeDefine.h"
#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>
#import "RCBaseTableViewController.h"
@class RCPublicServiceProfile;
/*!
 *  \~chinese
 公众服务账号信息中的URL点击回调
 
 *  \~english
 Callback for clicking URL in the public service account information 
 */
@protocol RCPublicServiceProfileViewUrlDelegate

/*!
 *  \~chinese
 点击公众服务账号信息的URL回调

 @param url 点击的URL
 
 *  \~english
 Callback for clicking the URL of the public service account information.

 @param url Clicked URL
 */
- (void)gotoUrl:(NSString *)url;

@end

/*!
 *  \~chinese
 公众服务账号信息的ViewController
 
 *  \~english
 ViewController of public service account information
 */
@interface RCPublicServiceProfileViewController : RCBaseTableViewController

/*!
 *  \~chinese
 公众服务账号信息
 
 *  \~english
 Public service account information
 */
@property (nonatomic, strong) RCPublicServiceProfile *serviceProfile;

/*!
 *  \~chinese
 头像显示的形状
 
 *  \~english
 The shape of the portrait
 */
@property (nonatomic) RCUserAvatarStyle portraitStyle;

/*!
 *  \~chinese
 当前界面的是否源于聊天会话页面
 
 *  \~english
 Whether the current interface originates from the chat conversation page
 */
@property (nonatomic) BOOL fromConversation;

@end
