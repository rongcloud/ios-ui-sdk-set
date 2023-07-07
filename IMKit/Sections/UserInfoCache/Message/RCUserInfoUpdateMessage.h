//
//  RCUserInfoUpdateMessage.h
//  RongIMKit
//
//  Created by 岑裕 on 16/1/28.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <RongIMLib/RongIMLib.h>

/*!
 用户信息更新消息的类型名
 */
#define RCUserInfoUpdateMessageIdentifier @"RC:UIUMsg"

/*!
 用户信息更新消息类

 @discussion 用户信息更新消息类，此消息不存储不计入未读消息数。
 
 @remarks 信令类消息
 */
@interface RCUserInfoUpdateMessage : RCMessageContent

/*!
 需要更新的用户信息列表
 */
@property (nonatomic, strong) NSArray *userInfoList;

/*!
 初始化用户信息更新消息对象

 @param userInfoList 需要更新的用户信息列表

 @return 用户信息更新消息对象
 */
- (instancetype)initWithUserInfoList:(NSArray *)userInfoList;

@end
