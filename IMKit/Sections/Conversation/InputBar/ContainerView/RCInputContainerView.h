//
//  RCInputContainerView.h
//  RongIMKit
//
//  Created by RongCloud on 2020/5/26.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCButton.h"
#import "RCTextView.h"
#import "RCExtensionKitDefine.h"

@protocol RCInputContainerViewDelegate;

@interface RCInputContainerView : UIView
/*!
 *  \~chinese
 语音与文本输入切换的按钮
 
 *  \~english
 Button to switch between voice and text input 
 */
@property (strong, nonatomic) RCButton *switchButton;

/*!
 *  \~chinese
 录制语音消息的按钮
 
 *  \~english
 Buttons to record voice messages
 */
@property (nonatomic, strong) RCButton *recordButton;

/*!
 *  \~chinese
 文本输入框
 
 *  \~english
 Text input box
 */
@property (nonatomic, strong) RCTextView *inputTextView;

/*!
 *  \~chinese
 表情的按钮
 
 *  \~english
 A button with an expression
 */
@property (nonatomic, strong) RCButton *emojiButton;

/*!
 *  \~chinese
 扩展输入的按钮
 
 *  \~english
 extend the input button
 */
@property (nonatomic, strong) RCButton *additionalButton;

@property (nonatomic, assign) KBottomBarStatus currentBottomBarStatus;

/**
 *  \~chinese
 输入框最大输入行数

 @discussion 该变量设置范围为: 1~6, 超过该范围会自动调整为边界值
 
 *  \~english
 Maximum number of input lines in the input box.

 @ discussion This variable is set in the range of: 1 to 6, beyond which it will automatically be adjusted to the boundary value.
 */
@property (nonatomic, assign) NSInteger maxInputLines;

/**
 *  \~chinese
 是否处于阅后即焚模式
 
 *  \~english
 Whether it is in the mode of burning immediately after reading
 */
@property (nonatomic, assign) BOOL destructMessageMode;

@property (nonatomic, weak) id<RCInputContainerViewDelegate> delegate;

- (void)setInputBarStyle:(RCChatSessionInputBarControlStyle)style;

- (void)setBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus;

@end

@protocol RCInputContainerViewDelegate <NSObject>

- (void)inputContainerViewSwitchButtonClicked:(RCInputContainerView *)inputContainerView;

- (void)inputContainerViewEmojiButtonClicked:(RCInputContainerView *)inputContainerView;

- (void)inputContainerViewAdditionalButtonClicked:(RCInputContainerView *)inputContainerView;

- (void)inputContainerView:(RCInputContainerView *)inputContainerView forControlEvents:(UIControlEvents)controlEvents;

- (void)inputContainerView:(RCInputContainerView *)inputContainerView didChangeFrame:(CGRect)frame;

- (BOOL)inputTextView:(UITextView *)inputTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
@end
