//
//  RCContactCardKit.m
//  RongContactCard
//
//  Created by Jue on 2017/1/9.
//  Copyright © 2017年 ios-rongContactCard. All rights reserved.
//

#import "RCContactCardKit.h"
#import "RongContactCardAdaptiveHeader.h"
#import "RCSendCardMessageView.h"
#import "RCSendCardMessageView+internal.h"

@implementation RCContactCardKit

+ (RCContactCardKit *)shareInstance {
    static RCContactCardKit *instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (void)popupSendContactCardView:(RCCCUserInfo *)cardUserInfo targetUserInfo:(RCCCUserInfo *)targetUserInfo {
    RCSendCardMessageView *sendCardView = [[RCSendCardMessageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    RCUserInfo *userInfo = [RCUserInfo new];
    userInfo.userId = cardUserInfo.userId;
    userInfo.name = cardUserInfo.name;
    userInfo.portraitUri = cardUserInfo.portraitUri;
    sendCardView.cardUserInfo = userInfo;
    sendCardView.targetUserInfo = targetUserInfo;
    [[RCKitUtility getKeyWindow] addSubview:sendCardView];
}

/**
 选中通讯录中的某个人，点击确定将名片发送到单聊会话的回调方法

 @param cardUserInfo 选中人的用户信息
 @param targetUserInfo 名片消息的目标会话的用户信息
 @param targetId 指定目标Id
 @param conversationType 指定会话类型
 @param destructDuration 焚烧时间，如果不需要焚烧则传0
 */
- (void)popupSendContactCardView:(RCCCUserInfo *)cardUserInfo
                  targetUserInfo:(RCCCUserInfo *)targetUserInfo
                        targetId:(NSString *)targetId
                conversationType:(RCConversationType)conversationType
                destructDuration:(NSInteger)destructDuration {
    RCSendCardMessageView *sendCardView = [[RCSendCardMessageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    RCUserInfo *userInfo = [RCUserInfo new];
    userInfo.userId = cardUserInfo.userId;
    userInfo.name = cardUserInfo.name;
    userInfo.portraitUri = cardUserInfo.portraitUri;
    sendCardView.cardUserInfo = userInfo;
    sendCardView.targetUserInfo = targetUserInfo;
    sendCardView.targetId = targetId;
    sendCardView.conversationType = conversationType;
    sendCardView.destructDuration = destructDuration;
    [[RCKitUtility getKeyWindow] addSubview:sendCardView];
}

- (void)popupSendContactCardView:(RCCCUserInfo *)cardUserInfo targetGroupInfo:(RCCCGroupInfo *)targetGroupInfo {
    RCSendCardMessageView *sendCardView = [[RCSendCardMessageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    RCUserInfo *userInfo = [RCUserInfo new];
    userInfo.userId = cardUserInfo.userId;
    userInfo.name = cardUserInfo.name;
    userInfo.portraitUri = cardUserInfo.portraitUri;
    sendCardView.cardUserInfo = userInfo;
    sendCardView.targetgroupInfo = targetGroupInfo;
    [[RCKitUtility getKeyWindow] addSubview:sendCardView];
}

@end
