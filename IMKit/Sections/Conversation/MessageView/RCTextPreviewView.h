//
//  RCTextPreviewView.h
//  RongIMKit
//
//  Created by 张改红 on 2020/7/15.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCAttributedLabel.h"
#import "RCMessageModel.h"
#import "RCBaseScrollView.h"
@protocol RCTextPreviewViewDelegate;

@interface RCTextPreviewView : RCBaseScrollView

+ (void)showText:(NSString *)text messageId:(long)messageId delegate:(id<RCTextPreviewViewDelegate>)delegate;

@end

@protocol RCTextPreviewViewDelegate <NSObject>
@optional
/*!
 点击Cell中URL的回调

 - Parameter url:   点击的URL
 - Parameter model: 消息Cell的数据模型

  点击Cell中的URL，会调用此回调，不会再触发didTapMessageCell:。
 */
- (void)didTapUrlInMessageCell:(NSString *)url model:(RCMessageModel *)model;


/*!
 点击Cell中电话号码的回调

 - Parameter phoneNumber: 点击的电话号码
 - Parameter model:       消息Cell的数据模型

  点击Cell中的电话号码，会调用此回调，不会再触发didTapMessageCell:。
 */
- (void)didTapPhoneNumberInMessageCell:(NSString *)phoneNumber model:(RCMessageModel *)model;
@end
