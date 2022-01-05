//
//  RCEmojiBoardView.h
//  RongExtensionKit
//
//  Created by Heq.Shinoda on 14-5-29.
//  Copyright (c) 2014 RongCloud. All rights reserved.
//

#import "RCEmoticonTabSource.h"
#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>

@class RCPageControl;
@class RCEmojiBoardView;

/*!
 *  \~chinese
 表情输入的回调
 
 *  \~english
 Callback for facial expression input 
 */
@protocol RCEmojiViewDelegate <NSObject>
@optional

/*!
 *  \~chinese
 点击表情的回调

 @param emojiView 表情输入的View
 @param string    点击的表情对应的字符串编码
 
 *  \~english
 Callback for click the facial expression.

 @param emojiView View of facial expression input.
 @param string The string encoding corresponding to the clicked expression
 */
- (void)didTouchEmojiView:(RCEmojiBoardView *)emojiView touchedEmoji:(NSString *)string;

/*!
 *  \~chinese
 点击发送按钮的回调

 @param emojiView  表情输入的View
 @param sendButton 发送按钮
 
 *  \~english
 Callback for clicking the send button.

 @param emojiView View of facial expression input.
 @param sendButton Send button.
 */
- (void)didSendButtonEvent:(RCEmojiBoardView *)emojiView sendButton:(UIButton *)sendButton;

@end

/*!
 *  \~chinese
 表情输入的View
 
 *  \~english
 View of facial expression input
 */
@interface RCEmojiBoardView : UIView <UIScrollViewDelegate>

/*!
 *  \~chinese
 当前的会话类型
 
 *  \~english
 Current conversation type
 */
@property (nonatomic, assign) RCConversationType conversationType;

/*!
 *  \~chinese
 当前的会话ID
 
 *  \~english
 Current conversation ID
 */
@property (nonatomic, strong) NSString *targetId;

/*!
 *  \~chinese
 表情背景的View
 
 *  \~english
 View of facial expression background
 */
@property (nonatomic, strong) UIScrollView *emojiBackgroundView;

/*!
 *  \~chinese
 表情输入的回调
 
 *  \~english
 Callback for facial expression input
 */
@property (nonatomic, weak) id<RCEmojiViewDelegate> delegate;

/*!
 *  \~chinese
 表情区域的大小
 
 *  \~english
 The size of the expression area
 */
@property (nonatomic, assign, readonly) CGSize contentViewSize;

/**
 *  \~chinese
 *  init
 *
 *  @param frame            frame
 *  @param delegate         实现RCEmojiViewDelegate的实体
 
 *  \~english
 * init.
 *
 * @param frame frame.
 * @param delegate entities that implement RCEmojiViewDelegate
 */
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<RCEmojiViewDelegate>)delegate;
/*!
 *  \~chinese
 加载表情Label
 
 *  \~english
 Load emoji lable
 */
- (void)loadLabelView;

/*!
 *  \~chinese
发送按钮是否可点击
 
 *  \~english
 Is the send button clickable
 */
- (void)enableSendButton:(BOOL)enableSend;
/**
 *  \~chinese
 *  添加表情包（普通开发者调用添加表情包）
 *
 *  @param viewDataSource 每页表情的数据源代理，当滑动需要加载表情页时会回调代理的方法，您需要返回表情页的view
 
 *  \~english
 * Add emojis (called by ordinary developers to add emojis).
 *
 * @param viewDataSource  The data source agent of each emoji page. When you shall load the emoji page, you will call back the method of the proxy and shall return the view of the emoji page.
 */
- (void)addEmojiTab:(id<RCEmoticonTabSource>)viewDataSource;
/**
 *  \~chinese
 *  添加Extention表情包(用于第三方表情厂商添加表情包)
 *
 *  @param viewDataSource 每页表情的数据源代理，当滑动需要加载表情页时会回调代理的方法，您需要返回表情页的view
 
 *  \~english
 * Add Extention emojis (for third-party emoji manufacturers to add emojis).
 *
 * @param viewDataSource The data source agent of each emoji page. When you shall load the emoji page, you will call back the method of the proxy and shall return the view of the emoji page.
 */
- (void)addExtensionEmojiTab:(id<RCEmoticonTabSource>)viewDataSource;

/**
 *  \~chinese
 *  重新加载通过扩展方式加载的表情包，（调用这个方法会回调RCExtensionModule 协议实现的扩展通过 addEmojiTab
 * 加入的表情包不会重写加载）
 
 *  \~english
 * Reload the emoji package loaded through the extension. (calling this method will call back the extension implemented by the RCExtensionModule protocol through addEmojiTab.
 * Added emojis will not be rewritten and loaded).
 */
- (void)reloadExtensionEmoticonTabSource;

@end
