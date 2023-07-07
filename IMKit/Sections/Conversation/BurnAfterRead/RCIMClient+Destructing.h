//
//  RCIMClient+Destructing.h
//  RongIMKit
//
//  Created by Zhaoqianyu on 2018/7/16.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <RongIMLib/RongIMLib.h>
#import "RCMessageCell.h"

@interface RCMessageCell ()
@property (nonatomic, strong) UIView *destructView;
@property (nonatomic, strong) UIButton *destructBtn;
@end

/*!
 消息正在焚烧的Notification

 @discussion 有消息处于焚烧倒计时，IMKit会分发此通知。
 Notification的object为nil，userInfo为NSDictionary对象，
 其中key值分别为@"message"、@"remainDuration"
 对应的value为焚烧的消息对象、该消息剩余的焚烧时间。
 @discussion 如果您使用IMLib请参考RCIMClient的RCMessageDestructDelegate
 */
FOUNDATION_EXPORT NSString *const RCKitMessageDestructingNotification;

@interface RCIMClient (Destructing)

/**
 获取消息的剩余焚烧时间

 @param messageUId 消息UId
 @return 剩余焚烧时间 [return doubleValue]
 @discussion 如果返回 nil 说明该消息不在焚烧队列中
 @discussion 如果您使用IMKit可以使用RCIM中的同名方法
 */
- (NSNumber *)getDestructMessageRemainDuration:(NSString *)messageUId;

@end

