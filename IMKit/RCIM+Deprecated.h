//
//  RCIM+Deprecated.h
//  RongIMKit
//
//  Created by Sin on 2020/7/2.
//  Copyright © 2020 RongCloud. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "RCIM.h"

/*!
 *  \~chinese
 RCIM 的废弃接口，配置已被移动到 RCKitConfig 类中
 
 *  \~english
 Obsolete interface of  RCIM, configuration has been moved to RCKitConfig class
 */
@interface RCIM (Deprecated)
#pragma mark - Config

#pragma mark Message Notification
/*!
 *  \~chinese
 是否关闭所有的本地通知，默认值是NO

 @discussion 当App处于后台时，默认会弹出本地通知提示，您可以通过将此属性设置为YES，关闭所有的本地通知。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether to turn off all local notifications. default value is NO.

 @ discussion When App is in the background, local notification prompts pop up by default. You can turn off all local notifications by setting this property to YES,.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL disableMessageNotificaiton __deprecated_msg("Use RCKitConfigCenter.message.disableMessageNotificaiton");

/*!
 *  \~chinese
 是否关闭所有的前台消息提示音，默认值是NO

 @discussion 当App处于前台时，默认会播放消息提示音，您可以通过将此属性设置为YES，关闭所有的前台消息提示音。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether to disable all foreground message tones. The default value is NO.

 @ discussion When App is in the foreground, the default message tone is played, and you can turn off all foreground message tones by setting this property to YES,.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL disableMessageAlertSound __deprecated_msg("Use RCKitConfigCenter.message.disableMessageAlertSound");

/*!
 *  \~chinese
 是否开启发送输入状态，默认值是 YES，开启之后在输入消息的时候对方可以看到正在输入的提示(目前只支持单聊)
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether to enable the send input status. The default value is YES. After it is enabled, the other party can see the prompt being entered when the message is entered (only single chat is supported).
 @ discussion When swift calls the macro definition RCKitConfigCenter, if an error is reported. It is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL enableTypingStatus __deprecated_msg("Use RCKitConfigCenter.message.enableTypingStatus");

/*!
 *  \~chinese
 开启已读回执功能的会话类型，默认为 单聊、群聊和讨论组

 @discussion 这些会话类型的消息在会话页面显示了之后会发送已读回执。目前仅支持单聊、群聊和讨论组。

 OC 需转成 NSNumber 传入（例如 @[ @(ConversationType_PRIVATE) ]），
 Swift 需获取到 rawValue 传入（例如 [ RCConversationType.ConversationType_PRIVATE.rawValue ]）。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 The conversation type for which the read receipt function is enabled. The default value is single chat, group chat and discussion group.

 @ discussion Messages of these conversation types send a read receipt after the conversation page is displayed. Currently, only single chat, group chat and discussion groups are supported.

  OC shall be transferred to NSNumber (for example, @ [@ (ConversationType_PRIVATE)]).
 Swift shall get the input from rawValue (for example, [RCConversationType.ConversationType_PRIVATE.rawValue]).
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, copy) NSArray *enabledReadReceiptConversationTypeList __deprecated_msg(
   "Use RCKitConfigCenter.message.enabledReadReceiptConversationTypeList");

/*!
 *  \~chinese
 设置群组、讨论组发送已读回执请求的有效时间，单位是秒，默认值是 120s。

 @discussion 用户在群组或讨论组中发送消息，退出会话页面再次进入时，如果超过设置的时间，则不再显示已读回执的按钮。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Set the valid time (in seconds) for groups and discussion groups to send read receipt requests. The default value is 120s.

  @ discussion The user sends a message in a group or discussion group. When the conversation page is exited and re-entered, if the set time is exceeded, the button for the read receipt is no longer displayed.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) NSUInteger maxReadRequestDuration __deprecated_msg(
  "Use RCKitConfigCenter.message.maxReadRequestDuration");

/*!
 *  \~chinese
 是否开启多端同步未读状态的功能，默认值是 YES

 @discussion 开启之后，用户在其他端上阅读过的消息，当前客户端会清掉该消息的未读数。目前仅支持单聊、群聊、讨论组。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether to enable multi-port synchronization of unread status. The default value is YES.

 @ discussion After it  is enabled, the current client clears the unread of the message that the user has read on the other end. At present, only single chat, group chat and discussion groups are supported.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL enableSyncReadStatus __deprecated_msg(
 "Use RCKitConfigCenter.message.enableSyncReadStatus");

/*!
 *  \~chinese
 是否开启消息@提醒功能（只支持群聊和讨论组, App需要实现群成员数据源groupMemberDataSource），默认值是 YES。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether to enable the message @ reminder feature (only group chat and discussion groups are supported. App shall implement the group member data source groupMemberDataSource), default value is YES.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL enableMessageMentioned __deprecated_msg(
"Use RCKitConfigCenter.message.enableMessageMentioned");

/*!
 *  \~chinese
 是否开启消息撤回功能，默认值是 YES。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether to enable message recall. The default value is YES.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL enableMessageRecall __deprecated_msg(
"Use RCKitConfigCenter.message.enableMessageRecall");

/*!
 *  \~chinese
 消息可撤回的最大时间，单位是秒，默认值是120s。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 The maximum time that a message can be recalled, in seconds, with a default value of 120s.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) NSUInteger maxRecallDuration __deprecated_msg(
"Use RCKitConfigCenter.message.maxRecallDuration");

/*!
 *  \~chinese
 是否在会话页面和会话列表界面显示未注册的消息类型，默认值是 YES

 @discussion App不断迭代开发，可能会在以后的新版本中不断增加某些自定义类型的消息，但是已经发布的老版本无法识别此类消息。
 针对这种情况，可以预先定义好未注册的消息的显示，以提升用户体验（如提示当前版本不支持，引导用户升级版本等）

 未注册的消息，可以通过RCConversationViewController中的rcUnkownConversationCollectionView:cellForItemAtIndexPath:和rcUnkownConversationCollectionView:layout:sizeForItemAtIndexPath:方法定制在会话页面的显示。
 未注册的消息，可以通过修改unknown_message_cell_tip字符串资源定制在会话列表界面的显示。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法 
 
 *  \~english
 Whether to display unregistered message types on the conversation page and conversation list interface. The default value is YES.

 @ discussion App continues to iterate and may continue to add some custom types of messages in future versions, but older versions that have been released do not recognize such messages.
  For this situation, you can pre-define the display of unregistered messages to enhance the user experience (such as prompting that the current version is not supported, guiding users to upgrade the version, etc.).

 For unregistered messages, you can customize the display on the conversation page through the rcUnkownConversationCollectionView:cellForItemAtIndexPath: and rcUnkownConversationCollectionView:layout:sizeForItemAtIndexPath: methods in RCConversationViewController.
  For unregistered messages, you can customize the display in the conversation list interface by modifying the unknown_message_cell_tip string resource.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL showUnkownMessage __deprecated_msg(
"Use RCKitConfigCenter.message.showUnkownMessage");

/*!
 *  \~chinese
 未注册的消息类型是否显示本地通知，默认值是NO

 @discussion App不断迭代开发，可能会在以后的新版本中不断增加某些自定义类型的消息，但是已经发布的老版本无法识别此类消息。
 针对这种情况，可以预先定义好未注册的消息的显示，以提升用户体验（如提示当前版本不支持，引导用户升级版本等）

 未注册的消息，可以通过修改unknown_message_notification_tip字符串资源定制本地通知的显示。

 @warning **deprecated**
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether local notifications are displayed for unregistered message types. The default value is NO.

 @ discussion App continues to iterate and may continue to add some custom types of messages in future versions, but older versions that have been released do not recognize such messages.
  In view of this situation, you can pre-define the display of unregistered messages to enhance the user experience (such as prompting that the current version is not supported, guiding users to upgrade the version, etc.).

 For unregistered messages, you can customize the display of local notifications by modifying the unknown_message_notification_tip string resource.

  @ warning ** is obsolete, please do not use it. **
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig. 
 */
@property (nonatomic, assign) BOOL showUnkownMessageNotificaiton __deprecated_msg(
"Use RCKitConfigCenter.message.showUnkownMessageNotificaiton");

/*!
 *  \~chinese
 语音消息的最大长度

 @discussion 默认值是60s，有效值为不小于5秒，不大于60秒
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Maximum length of voice message.

 @ discussion The default value is 60s, and the valid values are not less than 5 seconds and not more than 60 seconds.
 @ discussion When swift call the macro definition RCKitConfigCenter, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) NSUInteger maxVoiceDuration __deprecated_msg(
"Use RCKitConfigCenter.message.maxVoiceDuration");

/*!
 *  \~chinese
 APP是否独占音频

 @discussion 默认是NO,录音结束之后会调用AVAudioSession 的 setActive:NO ，
 恢复其他后台APP播放的声音，如果设置成YES,不会调用 setActive:NO，这样不会中断当前APP播放的声音
 (如果当前APP 正在播放音频，这时候如果调用SDK 的录音，可以设置这里为YES)
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether APP occupies audio exclusively

 @ discussion The default vaue NO. AVAudioconversation's setActive:NO is called to restore the sound played by other backend APP after recording ends. If it is set to YES, setActive:NO will not be called so that the sound played by the current APP will not be interrupted.
 (If the current APP is playing audio, if you call the recording of SDK, you can set this to YES).
 @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL isExclusiveSoundPlayer __deprecated_msg(
"Use RCKitConfigCenter.message.isExclusiveSoundPlayer");

/*!
 *  \~chinese
 选择媒体资源时，是否包含视频文件，默认值是NO

 @discussion 默认是不包含
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 When selecting media resources, whether to include video files. The default value is NO.

 @ discussion It is not contained by default
 @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL isMediaSelectorContainVideo __deprecated_msg(
"Use RCKitConfigCenter.message.isMediaSelectorContainVideo");

/**
 *  \~chinese
 GIF 消息自动下载的大小 size, 单位 KB
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 GIF message automatic download size, unit KB.
 @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) NSInteger GIFMsgAutoDownloadSize __deprecated_msg(
"Use RCKitConfigCenter.message.GIFMsgAutoDownloadSize");

/*!
 *  \~chinese
 是否开启合并转发功能，默认值是NO，开启之后可以合并转发消息(目前只支持单聊和群聊)
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether to enable merge forwarding. The default value is that you can merge and forward messages when NO, is enabled (currently, only single chat and group chat are supported).
 @ discussion When swift call the macro definition RCKitConfigCenter, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL enableSendCombineMessage __deprecated_msg(
"Use RCKitConfigCenter.message.enableSendCombineMessage");

/*!
 *  \~chinese
 是否开启阅后即焚功能，默认值是NO，开启之后可以在聊天页面扩展板中使用阅后即焚功能(目前只支持单聊)

 @discussion 目前 IMKit 仅支持文本、语音、图片、小视频消息。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether to enable the burn-after-reading feature. The default value is that you can use the post-burn feature in the chat page expansion board after NO, is enabled (currently, only single chat is supported).

 @ discussion Currently IMKit only supports text, voice, image and small video messages.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) BOOL enableDestructMessage __deprecated_msg(
"Use RCKitConfigCenter.message.enableDestructMessage");

/*!
 *  \~chinese
 消息撤回后可重新编辑的时间，单位是秒，默认值是 300s。

 @discussion 目前消息撤回后重新编辑仅为本地操作，卸载重装或者更换设备不会同步。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 The time, in seconds, that a message can be re-edited after it is recalled. The default value is 300s.

  @ discussion After the current message is recalled, re-editing is only a local operation. Uninstalling and reinstalling or replacing the device will not be synchronized.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig. 
 */
@property (nonatomic, assign) NSUInteger reeditDuration __deprecated_msg(
"Use RCKitConfigCenter.message.reeditDuration");

/*!
 *  \~chinese
 是否支持消息引用功能，默认值是YES ，聊天页面长按消息支持引用（目前仅支持文本消息、文件消息、图文消息、图片消息、引用消息的引用）
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether the message reference function is supported. The default value is YES. Chat page hold message supports references (currently, only text message, file message, image message, image message and reference message are supported).
 @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
*/
@property (nonatomic, assign) BOOL enableMessageReference __deprecated_msg(
"Use RCKitConfigCenter.message.enableMessageReference");

/**
 *  \~chinese
小视频的最长录制时间，单位是秒，默认值是 10s。

@discussion 在集成了融云小视频功能后，可以通过此方法来设置小视频的最长录制时间。录制时间最长不能超过 2 分钟。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 The maximum recording time of a small video (in seconds). The default value is 10 seconds.

 @ discussion This method is used to set the maximum recording time for small videos after integrating RongCloud small video feature. The maximum recording time cannot be more than 2 minutes.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) NSUInteger sightRecordMaxDuration __deprecated_msg(
"Use RCKitConfigCenter.message.sightRecordMaxDuration");

#pragma mark Avatar

/*!
 *  \~chinese
 SDK中全局的导航按钮字体颜色

 @discussion 默认值为[UIColor whiteColor]
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Global navigation button font color in SDK.

 @ discussion The default value is [UIColor whiteColor].
 @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, strong) UIColor *globalNavigationBarTintColor __deprecated_msg(
"Use RCKitConfigCenter.ui.globalNavigationBarTintColor");

/*!
 *  \~chinese
 SDK会话列表界面中显示的头像形状，矩形或者圆形

 @discussion 默认值为矩形，即RC_USER_AVATAR_RECTANGLE
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Avatar shape displayed in the SDK conversation list interface, including rectangle or circle

 @ discussion The default value is rectangle, that is, RC_USER_AVATAR_RECTANGLE.
 @ discussion When swift call the macro definition RCKitConfigCenter, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) RCUserAvatarStyle globalConversationAvatarStyle __deprecated_msg(
"Use RCKitConfigCenter.ui.globalConversationAvatarStyle");

/*!
 *  \~chinese
 SDK会话列表界面中显示的头像大小，高度必须大于或者等于36

 @discussion 默认值为46*46
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 The size of the portrait displayed in the SDK conversation list interface must be greater than or equal to 36.

 @ discussion The default value is 46*46.
 @ discussion swift  When  the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) CGSize globalConversationPortraitSize __deprecated_msg(
"Use RCKitConfigCenter.ui.globalConversationPortraitSize");

/*!
 *  \~chinese
 SDK会话页面中显示的头像形状，矩形或者圆形

 @discussion 默认值为矩形，即RC_USER_AVATAR_RECTANGLE
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Avatar shape, rectangle or circle displayed on the SDK conversation page.

 @ discussion The default value is rectangle, that is, RC_USER_AVATAR_RECTANGLE.
 @ discussion swift  When  the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) RCUserAvatarStyle globalMessageAvatarStyle __deprecated_msg(
"Use RCKitConfigCenter.ui.globalMessageAvatarStyle");

/*!
 *  \~chinese
 SDK会话页面中显示的头像大小

 @discussion 默认值为40*40
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 The size of the portrait displayed on the SDK conversation page.

 @ discussion The default value is 40*40.
 @ discussion When swift call the macro definition RCKitConfigCenter, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) CGSize globalMessagePortraitSize __deprecated_msg(
"Use RCKitConfigCenter.ui.globalMessagePortraitSize");

/*!
 *  \~chinese
 SDK会话列表界面和会话页面的头像的圆角曲率半径

 @discussion 默认值为4，只有当头像形状设置为矩形时才会生效。
 参考RCIM的globalConversationAvatarStyle和globalMessageAvatarStyle。
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 The radius of fillet curvature of the portrait of the SDK conversation list interface and conversation page.

 @ discussion The default value is 4, which takes effect only if the portrait shape is set to rectangle.
  Refer to RCIM's globalConversationAvatarStyle and globalMessageAvatarStyle.
  @ discussion swift When the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
 */
@property (nonatomic, assign) CGFloat portraitImageViewCornerRadius __deprecated_msg(
"Use RCKitConfigCenter.ui.portraitImageViewCornerRadius");

/*!
 *  \~chinese
是否支持暗黑模式，默认值是NO，开启之后 UI 支持暗黑模式，可以跟随系统切换
 @discussion swift 如果调用宏定义 RCKitConfigCenter 报错，替换为 RCKitConfig 的单例构造方法
 
 *  \~english
 Whether dark mode is supported. The default value is NO. After it is enabled,  the UI supports dark mode and can switch with the system.
 @ discussion swift  When  the macro definition RCKitConfigCenter is called, if an error is reported, it is replaced with the singleton construction method of RCKitConfig.
*/
@property (nonatomic, assign) BOOL enableDarkMode __deprecated_msg(
"Use RCKitConfigCenter.ui.enableDarkMode");
@end
