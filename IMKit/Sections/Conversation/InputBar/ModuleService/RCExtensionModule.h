//
//  RCExtensionModule.h
//  RongExtensionKit
//
//  Created by RongCloud on 16/7/2.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import "RCChatSessionInputBarControl.h"
#import "RCEmoticonTabSource.h"
#import "RCExtensionPluginItemInfo.h"
#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

/*!
 *  \~chinese
 RongCloud IM扩展模块协议
 
 *  \~english
 RongCloud IM extension module protocol. 
 */
@protocol RCExtensionModule <NSObject>

/*!
 *  \~chinese
 生成一个扩展模块。
 
 *  \~english
 Generate an extension module.
 */
+ (instancetype)loadRongExtensionModule;

@optional
#pragma mark - SDK status notify
/*!
 *  \~chinese
 初始化融云SDK

 @param appkey   应用的融云Appkey
 
 *  \~english
 Initialize RongCloud SDK.

 @param appkey RongCloud Appkey of the application.
 */
- (void)initWithAppKey:(NSString *)appkey;

/*!
 *  \~chinese
 连接融云IM服务

 @param userId   用户ID
 
 *  \~english
 Connect RongCloud IM service.

 @param userId User ID.
 */
- (void)didConnect:(NSString *)userId;

/*!
 *  \~chinese
 断开融云IM服务
 
 *  \~english
 Disconnect the cloud IM service.
 */
- (void)didDisconnect;

/*!
 *  \~chinese
 销毁扩展模块
 
 *  \~english
 Destroy the extension module
 */
- (void)destroyModule;

/*!
 *  \~chinese
 当前登陆的用户信息变化的回调

 @param userInfo 当前登陆的用户信息
 
 *  \~english
 Callback for changes in the information of currently logged-in users.

 @param userInfo Currently logged in user information.
 */
- (void)didCurrentUserInfoUpdated:(RCUserInfo *)userInfo;

/*!
 *  \~chinese
 处理收到的消息

 @param message  收到的消息
 
 *  \~english
 Process received messages.

 @param message Messages received.
 */
- (void)onMessageReceived:(RCMessage *)message;

/*!
 *  \~chinese
 处理收到消息响铃事件

 @param message  收到的消息

 @return         扩展模块处理的结果，YES为模块处理，SDK不会响铃。NO为模块未处理，SDK会默认处理。
 @discussion
 当应用处在前台时，如果在新来消息的会话内，没有铃声和通知；如果不在该会话内会铃声提示。当应用处在后台时，新来消息会弹出本地通知
 
 *  \~english
 Handle the ringing event of receiving a message.

 @param message Messages received.

  @ return The result of extension module processing. YES indicates that an event is handled by the module, and SDK will not ring. NO indicates that an event is not processed by module, and SDK will handle it by default.
  @ discussion
 When the application is in the foreground, if there is no ringtone and notification in the conversation of the new message; if it is not in the conversation, there will be a ringtone prompt. When the application is in the background, the new message will pop up a local notification
 */
- (BOOL)handleAlertForMessageReceived:(RCMessage *)message;

/*!
 *  \~chinese
 处理收到消息通知事件

 @param message   收到的消息
 @param fromName
 来源名字，如果message是单聊消息就是发送者的名字，如果是群组消息就是群组名，如果是讨论组消息就是讨论组名。
 @param userInfo  LocalNotification userInfo。如果扩展模块要弹本地通知，请一定带上userInfo。

 @return         扩展模块处理的结果，YES为模块处理，SDK不会弹出通知。NO为模块未处理，SDK会默认处理。
 @discussion
 当应用处在前台时，如果在新来消息的会话内，没有铃声和通知；如果不在该会话内会铃声提示。当应用处在后台时，新来消息会弹出本地通知
 
 *  \~english
 Handle notification events of receipt of messages.

 @param message Messages received.
 @ param fromName.
 Source name, if message is a single chat message, it is the name of the sender. If it is a group message, it is a group name. If it is a discussion group message, it is a discussion group name.
  @param userInfo  LocalNotification userInfo。 If the extension module wants to play local notification, make sure to bring userInfo.

  @ return extension module handles the result. YES is handled by the module, and SDK will not pop up notifications. NO indicates that an event is not processed by module, and SDK will handle it by default.
  @ discussion
 When the application is in the foreground, if there is no ringtone and notification in the conversation of the new message; if it is not in the conversation, there will be a ringtone prompt. When the application is in the background, the new message will pop up a local notification
 */
- (BOOL)handleNotificationForMessageReceived:(RCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo;

#pragma mark - App URL
/*!
 *  \~chinese
 设置扩展模块URL scheme。

 @param scheme      URL scheme
 
 *  \~english
 Set the extension module URL scheme.
 URL scheme.

  @param scheme      URL scheme
 */
- (void)setScheme:(NSString *)scheme;

/*!
 *  \~chinese
 处理openUrl请求

 return   是否处理
 
 *  \~english
 Process openUrl requests.

 Whether or not return handles.
 */
- (BOOL)onOpenUrl:(NSURL *)url;

#pragma mark - Input Bar
/*!
 *  \~chinese
 获取会话页面的plugin board item信息。

 @param conversationType  会话类型
 @param targetId          targetId

 @return plugin board item信息列表。

 @discussion 当进入到会话页面时，SDK需要注册扩展面部区域的item。
 
 *  \~english
 Get the plugin board item information for the conversation page.

  @param conversationType  Conversation type
 @param targetId TargetId.

 @ return plugin board item information list.

  @ discussion When entering the conversation page, SDK shall register an item that extends the facial area.
 */
- (NSArray<RCExtensionPluginItemInfo *> *)getPluginBoardItemInfoList:(RCConversationType)conversationType
                                                            targetId:(NSString *)targetId;

/*!
 *  \~chinese
 获取会话输入区的表情tab页

 @param conversationType  会话类型
 @param targetId          targetId

 @return 需要加载的表情tab页列表
 
 *  \~english
 Get the emoji tab page of the conversation input area.

 @param conversationType Conversation type
 @param targetId TargetId.

 @ return shall load a list of emoji tab pages.
 */
- (NSArray<id<RCEmoticonTabSource>> *)getEmoticonTabList:(RCConversationType)conversationType
                                                targetId:(NSString *)targetId;

/*!
 *  \~chinese
 点击表情面板中的加号按钮的回调

 @param emojiView       表情面板
 @param addButton       加号按钮
 @param inputBarControl 表情面板所在的输入工具栏
 
 *  \~english
 Callback for clicking the plus button on the emoji panel.

 @param emojiView Expression panel.
 @param addButton Plus button.
 @param inputBarControl The input toolbar where the emoji panel is located.
 */
- (void)emoticonTab:(RCEmojiBoardView *)emojiView
  didTouchAddButton:(UIButton *)addButton
         inInputBar:(RCChatSessionInputBarControl *)inputBarControl;

/*!
 *  \~chinese
 点击表情面板中的表情包 Icon 按钮的回调

 @param emojiView       表情面板
 @param index           表情包 Icon 的索引
 @param inputBarControl 表情面板所在的输入工具栏
 @param block           是否阻止 SDK 默认的点击处理逻辑
 
 *  \~english
 Callback for clicking the meme Icon button on the emoji panel

 @param emojiView Expression panel.
 @param index Index of meme Icon.
 @param inputBarControl The input toolbar where the emoji panel is located.
 @param block Whether to block SDK's default click processing logic.
 */

- (void)emoticonTab:(RCEmojiBoardView *)emojiView
    didTouchEmotionIconIndex:(int)index
                  inInputBar:(RCChatSessionInputBarControl *)inputBarControl
         isBlockDefaultEvent:(void (^)(BOOL isBlockDefaultEvent))block;

/*!
 *  \~chinese
 点击表情面板中的设置按钮的回调

 @param emojiView       表情面板
 @param settingButton   设置Button
 @param inputBarControl 表情面板所在的输入工具栏
 
 *  \~english
 Callback for clicking the settings button on the emoji panel.

 @param emojiView Expression panel.
 @param settingButton Set Button.
 @param inputBarControl The input toolbar where the emoji panel is located.
 */
- (void)emoticonTab:(RCEmojiBoardView *)emojiView
    didTouchSettingButton:(UIButton *)settingButton
               inInputBar:(RCChatSessionInputBarControl *)inputBarControl;

/*!
 *  \~chinese
 输入框内容发生变化的回调

 @param inputTextView   文本输入框
 @param inputBarControl 文本输入框所在的输入工具栏
 
 *  \~english
 Callback for a change in the content of the input box

 @param inputTextView Text input box.
 @param inputBarControl The input toolbar where the text input box is located.
 */
- (void)inputTextViewDidChange:(UITextView *)inputTextView inInputBar:(RCChatSessionInputBarControl *)inputBarControl;

/*!
 *  \~chinese
 输入工具栏状态发生变化的回调

 @param status           输入工具栏当前状态
 @param inputBarControl  输入工具栏
 
 *  \~english
 Callback for status change  of the input toolbar.

 @param status Enter the current status of the toolbar.
 @param inputBarControl Input Toolbar.
 */

- (void)inputBarStatusDidChange:(KBottomBarStatus)status inInputBar:(RCChatSessionInputBarControl *)inputBarControl;

/*!
 *  \~chinese
 是否需要显示表情加号按钮

 @param inputBarControl  输入工具栏
 
 *  \~english
 Do you shall display the emoji plus button?

 @param inputBarControl Input toolbar.
 */
- (BOOL)isEmoticonAddButtonEnabled:(RCChatSessionInputBarControl *)inputBarControl;

/*!
 *  \~chinese
 是否需要显示表情设置按钮

 @param inputBarControl  输入工具栏
 
 *  \~english
 Do you shall display the emoji setting button?

 @param inputBarControl Input Toolbar.
 */
- (BOOL)isEmoticonSettingButtonEnabled:(RCChatSessionInputBarControl *)inputBarControl;

/*!
 *  \~chinese
 是否正在使用声音通道
 
 *  \~english
 Whether the sound channel is being used.
 */
- (BOOL)isAudioHolding;

/*!
 *  \~chinese
 是否正在使用摄像头
 
 *  \~english
 Whether the camera is being used.
 */
- (BOOL)isCameraHolding;
@end
