//
//  RCContentView.h
//  RongIMKit
//
//  Created by xugang on 3/31/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 *  \~chinese
 消息内容的View
 
 *  \~english
 View of message content. 
 */
@interface RCContentView : UIView

@property (nonatomic, assign) CGSize contentSize;

/*!
 *  \~chinese
 注册Frame发生变化的回调

 @param eventBlock Frame发生变化的回调
 
 *  \~english
 Callback for registering a change in Frame.

 @param eventBlock Callback for changes in Frame
 */
- (void)registerFrameChangedEvent:(void (^)(CGRect frame))eventBlock;

/*!
 *  \~chinese
 注册Size发生变化的回调

 @param eventBlock Size 发生变化的回调
 
 *  \~english
 Callback for registering a change in Size.

 @param eventBlock  Callback for changes in Size.
 */
- (void)registerSizeChangedEvent:(void (^)(CGSize contentSize))eventBlock;
@end
