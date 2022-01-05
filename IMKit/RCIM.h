//
//  RCIM.h
//  RongIMKit
//
//  Created by xugang on 15/1/13.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCThemeDefine.h"
#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

@class RCDiscussion,RCPublicServiceProfile;
/*!
 *  \~chinese
 @const 收到消息的Notification

 @discussion 接收到消息后，SDK会分发此通知。

 Notification的object为RCMessage消息对象。
 userInfo为NSDictionary对象，其中key值为@"left"，value为还剩余未接收的消息数的NSNumber对象。

 与RCIMReceiveMessageDelegate的区别:
 RCKitDispatchMessageNotification只要注册都可以收到通知；RCIMReceiveMessageDelegate需要设置监听，并同时只能存在一个监听。
 
 *  \~english
 @ const the Notification that received the message.

 @ discussion When the message is received, SDK distributes this notification.

  The object of Notification is the RCMessage message object.
  UserInfo is the NSDictionary object, where the key value is @ "left" and value is the NSNumber object with the number of messages remaining unreceived.

  Differences from RCIMReceiveMessageDelegate:
  RCKitDispatchMessageNotification can receive notification as long as it registers; RCIMReceiveMessageDelegate shall set listeners, and only one listener can exist at the same time. 
 */
FOUNDATION_EXPORT NSString *const RCKitDispatchMessageNotification;

/*!
 *  \~chinese
 @const 消息被撤回的Notification

 @discussion 消息被撤回后，SDK会分发此通知。

 Notification的object为NSNumber的messageId。

 与RCIMReceiveMessageDelegate的区别:
 RCKitDispatchRecallMessageNotification只要注册都可以收到通知；RCIMReceiveMessageDelegate需要设置监听，并同时只能存在一个监听。
 
 *  \~english
 @ const Notification whose message is recalled.

 @ discussion SDK distributes this notification when the message is recalled.

  The object of Notification is the messageId of NSNumber.

  Differences from RCIMReceiveMessageDelegate:
  RCKitDispatchrecallMessageNotification can receive notification as long as it registers; RCIMReceiveMessageDelegate shall set listeners, and only one listener can exist at the same time.
 */
FOUNDATION_EXPORT NSString *const RCKitDispatchRecallMessageNotification;

/*!
 *  \~chinese
 @const 连接状态变化的Notification

 @discussion SDK连接状态发生变化时，SDK会分发此通知。

 Notification的object为NSNumber对象，对应于RCConnectionStatus的值。

 与RCIMConnectionStatusDelegate的区别:
 RCKitDispatchConnectionStatusChangedNotification只要注册都可以收到通知；RCIMConnectionStatusDelegate需要设置监听，同时只能存在一个监听。
 
 *  \~english
 @ const Notification with changes in connection status.

 @ discussion SDK distributes this notification when the state of the  SDK connection changes.

  The object of Notification is a NSNumber object, which corresponds to the value of RCConnectionStatus.

  Differences from RCIMConnectionStatusDelegate:
  RCKitDispatchConnectionStatusChangedNotification can receive notification as long as it registers; RCIMConnectionStatusDelegate shall set listeners, and only one listener can exist at the same time.
 */
FOUNDATION_EXPORT NSString *const RCKitDispatchConnectionStatusChangedNotification;

/**
 *  \~chinese
 *  收到消息已读回执的响应
 通知的 object 中携带信息如下： @{@"targetId":targetId,
 @"conversationType":@(conversationType),
 @"messageUId": messageUId,
 @"readCount":@(count)};
 
 *  \~english
 * Response to read receipt.
 The information in the object of the notification is as follows: @{@"targetId":targetId,
  @"conversationType":@(conversationType),
  @"messageUId": messageUId,
  @"readCount":@(count)};
 */
FOUNDATION_EXPORT NSString *const RCKitDispatchMessageReceiptResponseNotification;

/**
 *  \~chinese
 *  收到消息已读回执的请求
 通知的 object 中携带信息如下： @{@"targetId":targetId,
 @"conversationType":@(conversationType),
 @"messageUId": messageUId};
 
 *  \~english
 * Received a request for a read receipt.
 The information in the object of the notification is as follows: @ {@ "targetId": targetId.
 @ "conversationType": @ (conversationType).
 @ "messageUId": messageUId}.
 */
FOUNDATION_EXPORT NSString *const RCKitDispatchMessageReceiptRequestNotification;

/*!
 *  \~chinese
 消息正在焚烧的Notification

 @discussion 有消息处于焚烧倒计时，IMKit会分发此通知。
 Notification的object为nil，userInfo为NSDictionary对象，
 其中key值分别为@"message"、@"remainDuration"
 对应的value为焚烧的消息对象、该消息剩余的焚烧时间。
 @discussion 如果您使用IMLib请参考RCIMClient的RCMessageDestructDelegate
 
 *  \~english
 Notification in burning message

 @ discussion When a message is in the countdown to burning. IMKit will distribute this notification.
  The object of Notification is nil,userInfo and the object of NSDictionary.
 Where the key values are @ "message" and @ "remainDuration" respectively.
 The corresponding value is the message object burned and the remaining burning time of the message.
  @ discussion If you use IMLib, please refer to RCIMClient's RCMessageDestructDelegate.
 */
FOUNDATION_EXPORT NSString *const RCKitMessageDestructingNotification;

/*!
 *  \~chinese
@const 收到会话状态同步的 Notification。

@discussion 收到会话状态同步之后，IMLib 会分发此通知。

Notification 的 object 是 RCConversationStatusInfo 对象的数组 ，userInfo 为 nil，

收到这个消息之后可以更新您的会话的状态。

@remarks 事件监听
 
 *  \~english
 @ const receive a Notification with conversation state synchronization.

 @ discussion When receiving the conversation state synchronization, IMLib distributes this notification.

 The object of Notification is an array of RCConversationStatusInfo objects, and userInfo is nil.

 You can update the status of your conversation after receiving this message.

 @ remarks event listener
*/

FOUNDATION_EXPORT NSString *const RCKitDispatchConversationStatusChangeNotification;

#pragma mark - RCIMUserInfoDataSource

/*!
 *  \~chinese
 用户信息提供者

 @discussion SDK需要通过您实现的用户信息提供者，获取用户信息并显示。
 
 *  \~english
 User information provider.

 @ discussion SDK shall get the user information and display it through the user information provider that you implement.
 */
@protocol RCIMUserInfoDataSource <NSObject>

/*!
 *  \~chinese
 SDK 的回调，用于向 App 获取用户信息

 @param userId      用户ID
 @param completion  获取用户信息完成之后需要执行的Block [userInfo:该用户ID对应的用户信息]

 @discussion SDK通过此方法获取用户信息并显示，请在completion中返回该用户ID对应的用户信息。
 在您设置了用户信息提供者之后，SDK在需要显示用户信息的时候，会调用此方法，向您请求用户信息用于显示。
 
 *  \~english
 Callback for SDK, which is used to obtain user information from App.

 @param userId User ID.
 @param completion Get the Block that shall be executed after the user information is completed [userInfo: the user information corresponding to the user ID].

 @ discussion SDK uses this method to obtain user information and display it. Please return the user information corresponding to the user ID in completion.
  After you have set a user information provider, SDK calls this method when it shall display user information, requesting user information from you for display.
 */
- (void)getUserInfoWithUserId:(NSString *)userId completion:(void (^)(RCUserInfo *userInfo))completion;

@end

/**
 *  \~chinese
 公众号信息提供者

 @discussion SDK 需要通过您实现的公众号信息提供者，获取公众号信息并显示。
 
 *  \~english
 Official account information provider.

 @ discussion SDK shall obtain and display the official account information through the official account information provider that you implement.
 */
@protocol RCIMPublicServiceProfileDataSource <NSObject>

/**
 *  \~chinese
 SDK 的回调，用于向 App 获取公众号信息

 @param accountId 公众号 ID
 @param completion  获取公众号信息完成之后需要执行的 Block[profile: 该公众号 ID 对应的公众号信息]

 @discussion SDK 通过此方法获取公众号信息并显示，请在 completion 中返回该公众号 ID 对应的公众号信息。
 在您设置了公众号信息提供者之后，SDK 在需要显示公众号信息的时候，会调用此方法，向您请求公众号信息用于显示。
 
 *  \~english
 Callback for SDK, which is used to obtain official account information from App.

 @param accountId Official account ID.
 @param completion Get the Block [profile:] that shall be executed after the official account information is completed. The official account information corresponding to the official account ID].

 @ discussion SDK uses this method to obtain the official account information and display it. Please return the official account information corresponding to the official account ID in completion.
  After you have set the official account information provider, SDK will call this method when the official account information shall be displayed and request the official account information from you for display.
 */
- (void)getPublicServiceProfile:(NSString *)accountId completion:(void (^)(RCPublicServiceProfile *profile))completion;

/**
 *  \~chinese
 SDK 的回调，用于向 App 同步获取公众号信息

 @param accountId 公众号 ID
 @return 公众号信息
 
 *  \~english
 Callback for SDK, which is used to synchronize the official account information from App.

 @param accountId Official account ID
 @ return official account information.
 */
- (RCPublicServiceProfile *)publicServiceProfile:(NSString *)accountId;

@end

/*!
 *  \~chinese
 群组信息提供者

 @discussion SDK需要通过您实现的群组信息提供者，获取群组信息并显示。
 
 *  \~english
 Group information provider

 @ discussion SDK shall obtain and display the group information through the group information provider that you implement.
 */
@protocol RCIMGroupInfoDataSource <NSObject>

/*!
 *  \~chinese
 SDK 的回调，用于向 App 获取群组信息

 @param groupId     群组ID
 @param completion  获取群组信息完成之后需要执行的Block [groupInfo:该群组ID对应的群组信息]

 @discussion SDK通过此方法获取群组信息并显示，请在completion的block中返回该群组ID对应的群组信息。
 在您设置了群组信息提供者之后，SDK在需要显示群组信息的时候，会调用此方法，向您请求群组信息用于显示。
 
 *  \~english
 Callback for SDK, which is used to obtain group information from App.

 @param groupId Group ID.
 @param completion Get the Block to be executed after the group information is completed [groupInfo: the group information corresponding to the group ID].

 @ discussion SDK obtains the group information and displays it in this method. Please return the group information corresponding to the group ID in the block of completion.
  After you have set the group information provider, SDK will call this method when it shall display the group information and request the group information from you for display.
 */
- (void)getGroupInfoWithGroupId:(NSString *)groupId completion:(void (^)(RCGroup *groupInfo))completion;

@end

/*!
 *  \~chinese
 群名片信息提供者

 @discussion 如果您使用了群名片功能，SDK需要通过您实现的群名片信息提供者，获取用户在群组中的名片信息并显示。
 
 *  \~english
 Group business card information provider.

 @ discussion If you use the group business card function, SDK shall obtain and display the user's business card information in the group through the group business card information provider you implemented.
 */
@protocol RCIMGroupUserInfoDataSource <NSObject>

/*!
 *  \~chinese
 SDK 的回调，用于向 App 获取用户在群组中的群名片信息

 @param userId          用户ID
 @param groupId         群组ID
 @param completion      获取群名片信息完成之后需要执行的Block [userInfo:该用户ID在群组中对应的群名片信息]

 @discussion 如果您使用了群名片功能，SDK需要通过您实现的群名片信息提供者，获取用户在群组中的名片信息并显示。
 
 *  \~english
 Callback for SDK, which is used to obtain the group business card information of a user in a group from App.

 @param userId User ID.
 @param groupId Group ID.
 @param completion The Block to be executed after the group business card information is obtained [userInfo: the group business card information corresponding to the user's ID in the group].

 @ discussion If you use the group business card function, SDK shall obtain and display the user's business card information in the group through the group business card information provider you implemented.
 */
- (void)getUserInfoWithUserId:(NSString *)userId
                      inGroup:(NSString *)groupId
                   completion:(void (^)(RCUserInfo *userInfo))completion;

@end

/*!
 *  \~chinese
 群组成员列表提供者
 
 *  \~english
 Group member list provider
 */
@protocol RCIMGroupMemberDataSource <NSObject>
@optional

/*!
 *  \~chinese
 SDK 的回调，用于向 App 获取当前群组成员列表（需要实现用户信息提供者 RCIMUserInfoDataSource）

 @param groupId     群ID
 @param resultBlock 获取成功之后需要执行的Block [userIdList:群成员ID列表]

 @discussion SDK通过此方法群组中的成员列表，请在resultBlock中返回该群组ID对应的群成员ID列表。
 在您设置了群组成员列表提供者之后，SDK在需要获取群组成员列表的时候，会调用此方法，向您请求群组成员用于显示。
 
 *  \~english
 Callback for SDK, which is used to obtain the list of current group members from App (user information provider RCIMUserInfoDataSource shall be implemented).

 @param groupId Group ID.
 @param resultBlock Get the Block to be executed after success [ID list of userIdList: group members].

 @ discussion SDK uses this method to list the members in the group. Please return the ID list of the group members corresponding to the group ID in resultBlock
  After you have set a group member list provider, SDK will call this method when it shall get a list of group members to ask you for group members to display.
 */
- (void)getAllMembersOfGroup:(NSString *)groupId result:(void (^)(NSArray<NSString *> *userIdList))resultBlock;
@end

#pragma mark - RCIMReceiveMessageDelegate

/*!
 *  \~chinese
 IMKit消息接收的监听器

 @discussion 设置 IMKit 的消息接收监听器请参考 RCIM 的 receiveMessageDelegate 属性。

 @warning 如果您使用 IMKit，可以设置并实现此 Delegate 监听消息接收；
 如果您使用 IMLib，请使用 RCIMClient 中的 RCIMClientReceiveMessageDelegate 监听消息接收，而不要使用此监听器。
 
 *  \~english
 Listeners for IMKit message reception.

 @ discussion Set the message receiving listener of IMKit, please refer to the receiveMessageDelegate attribute of RCIM.

  @ warning If you use IMKit, you can set and implement this Delegate to listen to message reception.
 If you use IMLib, RCIMClientReceiveMessageDelegate in RCIMClient is used to listen to message reception instead of using this listener.
 */
@protocol RCIMReceiveMessageDelegate <NSObject>

/*!
 *  \~chinese
 接收消息的回调方法

 @param message     当前接收到的消息
 @param left        还剩余的未接收的消息数，left>=0

 @discussion 如果您设置了IMKit消息监听之后，SDK在接收到消息时候会执行此方法（无论App处于前台或者后台）。
 其中，left为还剩余的、还未接收的消息数量。比如刚上线一口气收到多条消息时，通过此方法，您可以获取到每条消息，left会依次递减直到0。
 您可以根据left数量来优化您的App体验和性能，比如收到大量消息时等待left为0再刷新UI。
 
 *  \~english
 Callback method for receiving messages.

 @param message Messages currently received.
 @param left The number of unreceived messages left, left > = 0.

 @ discussion If you have set IMKit message listening, SDK will execute this method when it receives a message (regardless of whether the App is in the foreground or in the background).
  Where left is the number of messages that have not yet been received. For example, when you receive multiple messages upon being online, you can get each message in this way, and the left will decrease to 0 in turn.
  You can optimize your App experience and performance based on the number of left, e.g.  waiting for left to be 0 before refreshing UI when you receive a large number of messages.
 */
- (void)onRCIMReceiveMessage:(RCMessage *)message left:(int)left;

@optional

/**
 *  \~chinese
 接收消息的回调方法

 @param message 当前接收到的消息
 @param nLeft 还剩余的未接收的消息数，left>=0
 @param offline 是否是离线消息
 @param hasPackage SDK 拉取服务器的消息以包(package)的形式批量拉取，有 package 存在就意味着远端服务器还有消息尚未被 SDK
 拉取
 @discussion 和上面的 - (void)onRCIMReceived:(RCMessage *)message left:(int)nLeft 功能完全一致，额外把
 offline 和 hasPackage 参数暴露，开发者可以根据 nLeft、offline、hasPackage 来决定何时的时机刷新 UI ；建议当 hasPackage=0
 并且 nLeft=0 时刷新 UI
 @warning 如果使用此方法，那么就不能再使用 RCIM 中 - (void)onRCIMReceived:(RCMessage *)message left:(int)nLeft 的使用，否则会出现重复操作的情形
 
 *  \~english
 Callback method for receiving messages.

 @param message Messages currently received.
 @param message The number of unreceived messages left, left > = 0.
 @param offline Is it an offline message?
 @param hasPackage Messages from the SDK pull server are pulled in batches in the form of packet (package). The presence of package means that there are still messages on the remote server that have not been pushed by SDK.
 @ discussion It is exactly the same as the above-(void) onRCIMReceived: (RCMessage *) message left: (int) nLeft function. In addition, offline and hasPackage parameters are exposed, and developers can decide when to refresh UI based on nLeft, offline and hasPackage. It is recommended that UI is refreshed when hasPackage=0.
 And refresh UI when nLeft=0.
 @ warning If you use this method, you can no longer use the use of-(void) onRCIMReceived: (RCMessage *) message left: (int) nLeft in RCIM, otherwise the operation will be repeated.
 */
- (void)onRCIMReceived:(RCMessage *)message
                  left:(int)nLeft
               offline:(BOOL)offline
            hasPackage:(BOOL)hasPackage;

/*!
 *  \~chinese
 当App处于后台时，接收到消息并弹出本地通知的回调方法

 @param message     接收到的消息
 @param senderName  消息发送者的用户名称
 @return            当返回值为NO时，SDK会弹出默认的本地通知提示；当返回值为YES时，SDK针对此消息不再弹本地通知提示

 @discussion 如果您设置了IMKit消息监听之后，当App处于后台，收到消息时弹出本地通知之前，会执行此方法。
 如果App没有实现此方法，SDK会弹出默认的本地通知提示。
 流程：
 SDK接收到消息 -> App处于后台状态 -> 通过用户/群组/群名片信息提供者获取消息的用户/群组/群名片信息
 -> 用户/群组信息为空 -> 不弹出本地通知
 -> 用户/群组信息存在 -> 回调此方法准备弹出本地通知 -> App实现并返回YES        -> SDK不再弹出此消息的本地通知
                                             -> App未实现此方法或者返回NO -> SDK弹出默认的本地通知提示


 您可以通过RCIM的disableMessageNotificaiton属性，关闭所有的本地通知(此时不再回调此接口)。

 @warning 如果App在后台想使用SDK默认的本地通知提醒，需要实现用户/群组/群名片信息提供者，并返回正确的用户信息或群组信息。
 参考RCIMUserInfoDataSource、RCIMGroupInfoDataSource与RCIMGroupUserInfoDataSource
 
 *  \~english
 Callback for receiving message and popping up the local notification when App is in the background

 @param message Messages received.
 @param senderName The user name of the sender of the message.
 @ return When the return value is NO, SDK will pop up the default local notification prompt; when the return value is YES, SDK will no longer play the local notification prompt for this message.

 @ discussion If you set IMKit message listening, this method will be executed when the App is in the background and the message is received before the local notification pops up.
  If App does not implement this method, SDK pops up the default local notification prompt.
  Process:
  SDK receives message-> App is in background status-> user / group / group business card information obtained through user / group / group business card information provider.
 -> user / group information is empty-> No local notification pops up.
 -> user / group information exists-> call back this method to pop up local notification-> App implementation and return YES-> SDK local notification that this message no longer pops up.
 -> App does not implement this method or returns NO-> SDK pops up the default local notification prompt.


 You can disable all local notifications through the disableMessageNotificaiton attribute of RCIM (this interface is no longer called back at this time).

  @ warning If App wants to use the default local notification reminder of SDK in the background, you shall implement the user / group / group business card information provider and return the correct user information or group information.
  Refer to RCIMUserInfoDataSource, RCIMGroupInfoDataSource and RCIMGroupUserInfoDataSource.
 */
- (BOOL)onRCIMCustomLocalNotification:(RCMessage *)message withSenderName:(NSString *)senderName;

/*!
 *  \~chinese
 当App处于前台时，接收到消息并播放提示音的回调方法

 @param message 接收到的消息
 @return        当返回值为NO时，SDK会播放默认的提示音；当返回值为YES时，SDK针对此消息不再播放提示音

 @discussion 收到消息时播放提示音之前，会执行此方法。
 如果App没有实现此方法，SDK会播放默认的提示音。
 流程：
 SDK接收到消息 -> App处于前台状态 -> 回调此方法准备播放提示音 -> App实现并返回YES        -> SDK针对此消息不再播放提示音
                                                      -> App未实现此方法或者返回NO -> SDK会播放默认的提示音

 您可以通过 RCKitConfigCenter.message.disableMessageAlertSound 属性，关闭所有前台消息的提示音(此时不再回调此接口)。
 
 *  \~english
 Callback method for receiving a message and playing a tone when App is in the foreground.

 @param message Messages received.
 @ return When the return value is NO, SDK will play the default tone; when the return value is YES, SDK will no longer play the tone for this message.

 @ discussion This method is executed before the tone is played when the message is received.
  If App does not implement this method, SDK plays the default tone.
  Process:
  SDK receives message-> App is in foreground state-> call back this method to play cue tone-> App implementation and returns YES-> SDK no longer plays cue tone for this message.
 -> App does not implement this method or returns NO-> SDK will play the default tone.

 You can turn off the tone of all foreground messages through the RCKitConfigCenter.message.disableMessageAlertSound property (this interface is no longer called back at this time).
 */
- (BOOL)onRCIMCustomAlertSound:(RCMessage *)message;

/*!
 *  \~chinese
 消息被撤回的回调方法

 @param messageId 被撤回的消息ID

 @discussion 被撤回的消息会变更为RCRecallNotificationMessage，App需要在UI上刷新这条消息。
 
 *  \~english
 Callback method for recalled message.

 @param messageId recalled message ID.

 @ discussion The message that is recalled will be changed to the RCrecallNotificationMessage and App shall refresh it on the UI.
 */
- (void)onRCIMMessageRecalled:(long)messageId __deprecated_msg("Use RCIM messageDidRecall");

/*!
 *  \~chinese
 消息被撤回的回调方法

 @param message 被撤回的消息

 @discussion 被撤回的消息会变更为RCRecallNotificationMessage，App需要在UI上刷新这条消息。
 @discussion 和上面的 - (void)onRCIMMessageRecalled:(long)messageId 功能完全一致，只能选择其中一个使用。
 
 *  \~english
 Callback method in which the message is recalled.

 @param message recalled news.

 @ discussion The message that is recalled will be changed to the RCrecallNotificationMessage and App shall refresh this message on the UI.
  @ discussion It is exactly the same as the-(void) onRCIMMessagerecalled: (long) messageId function above, so you can only choose one to use.
 */
- (void)messageDidRecall:(RCMessage *)message;

/*!
 *  \~chinese
 当 Kit 收到消息回调的方法

 @param message 接收到的消息
 @return       YES 拦截, 不显示  NO: 不拦截, 显示此消息。
  此处只处理实时收到消息时，在界面上是否显示此消息。
  在重新加载会话页面时，不受此处逻辑控制。
  若要永久不显示此消息，需要从数据库删除该消息，在回调处理中调用 deleteMessages,
  否则在重新加载会话时会将此消息重新加载出来

 @discussion 收到消息，会执行此方法。
 
 *  \~english
 The callback method when Kit receives a message.

 @param message Messages received.
 @ return YES for interception and No for no display: Do not intercept and display this message.
   This only deals with whether the message is displayed on the interface when it is received in real time.
   When the conversation page is reloaded, it is not controlled by the logic here.
   If this message is not displayed permanently , you shall delete the message from the database and call deleteMessages in the callback process.
 Otherwise, this message will be reloaded when the conversation is reloaded.

 @ discussion Receive a message and executes this method.

 */
- (BOOL)interceptMessage:(RCMessage *)message;

@end

#pragma mark - RCIMConnectionStatusDelegate

/*!
 *  \~chinese
 IMKit连接状态的的监听器

 @discussion 设置IMKit的连接状态监听器，请参考RCIM的connectionStatusDelegate属性。

 @warning 如果您使用IMKit，可以设置并实现此Delegate监听消息接收；
 如果您使用IMLib，请使用RCIMClient中的RCIMClientReceiveMessageDelegate监听消息接收，而不要使用此监听器。
 
 *  \~english
 Listeners for IMKit connection status

 @ discussion Set the connection status listener of IMKit, please refer to the connectionStatusDelegate attribute of RCIM.

  @ warning If you use IMKit, you can set and implement this Delegate to listen to message reception.
 If you use IMLib, RCIMClientReceiveMessageDelegate in RCIMClient is used to listen to message reception instead of using this listener. 
 */
@protocol RCIMConnectionStatusDelegate <NSObject>

/*!
 *  \~chinese
 IMKit连接状态的的监听器

 @param status  SDK与融云服务器的连接状态

 @discussion 如果您设置了IMKit消息监听之后，当SDK与融云服务器的连接状态发生变化时，会回调此方法。
 
 *  \~english
 Listeners for IMKit connection status

 @param status Connection status between SDK and CVM.

 @ discussion If you set IMKit message listening, this method will be called back when the connection status between SDK and the cloud server changes.
 */
- (void)onRCIMConnectionStatusChanged:(RCConnectionStatus)status;

@end

#pragma mark - RCIMSendMessageDelegate

/*!
 *  \~chinese
 IMKit消息发送监听器

 @discussion 设置IMKit的消息发送监听器，可以监听消息发送前以及消息发送后的结果。

 @warning 如果您使用IMKit，可以设置并实现此Delegate监听消息发送；
 
 *  \~english
 IMKit message sending listener.

 @ discussion Set the message sending listener of IMKit, which can listen to the results before and after the message is sent.

  @ warning If you use IMKit, you can set and implement this Delegate to listen to message sending.
 */
@protocol RCIMSendMessageDelegate <NSObject>

/*!
 *  \~chinese
 准备发送消息的监听器

 @param messageContent 消息内容

 @return 修改后的消息内容

 @discussion 此方法在消息准备向外发送时会执行，您可以在此方法中对消息内容进行过滤和修改等操作。如果此方法的返回值不为
 nil，SDK 会对外发送返回的消息内容。如果您使用了RCConversationViewController 中的 willSendMessage:
 方法，请不要重复使用此方法。选择其中一种方式实现您的需求即可。
 
 *  \~english
 Listeners ready to send messages.

 @param messageContent Message content.

 @ return modified message content.

 @ discussion This method is executed when the message is ready to be sent out, and you can filter and modify the content of the message in this method. If the return value of this method is not Nil,SDK sends the contents of the returned message to the outside. If you use willSendMessage: in RCConversationViewController.
  Method, do not reuse this method. Choose one of the ways to achieve your requirements.
 */
- (RCMessageContent *)willSendIMMessage:(RCMessageContent *)messageContent;

/*!
 *  \~chinese
 发送消息完成的监听器

 @param messageContent   消息内容

 @param status          发送状态，0表示成功，非0表示失败的错误码

 @discussion 此方法在消息向外发送结束之后会执行。您可以通过此方法监听消息发送情况。如果您使用了
 RCConversationViewController 中的 didSendMessage:content:
 方法，请不要重复使用此方法。选择其中一种方式实现您的需求即可。
 
 *  \~english
 Listeners that complete sending messages.

 @param messageContent Message content.

 @param status Send status. 0: successful; non-0: failed error code.

 @ discussion This method is executed after the message has been sent out. You can use this method to listen to the sending of messages. If you use the.
 DidSendMessage:content: in RCConversationViewController.
  Method, do not reuse this method. Choose one of the ways to achieve your requirements.
 */
- (void)didSendIMMessage:(RCMessageContent *)messageContent status:(NSInteger)status;

@end

#pragma mark - IMKit Core Class

/*!
 *  \~chinese
 融云IMKit核心类

 @discussion 您需要通过sharedRCIM方法，获取单例对象
 
 *  \~english
 RongCloud IMKit core class.

 @ discussion You shall get the singleton object through the sharedRCIM method.
 */
@interface RCIM : NSObject

/*!
 *  \~chinese
 获取融云界面组件IMKit的核心类单例

 @return    融云界面组件IMKit的核心类单例

 @discussion 您可以通过此方法，获取IMKit的单例，访问对象中的属性和方法。
 
 *  \~english
 Get a single instance of the core class of the RongCloud interface component IMKit.

 @ return single instance of the core class of the RongCloud interface component IMKit.

 @ discussion You can use this method to get a singleton of IMKit and access the properties and methods in the object.
 */
+ (instancetype)sharedRCIM;

#pragma mark - SDK init

/*!
 *  \~chinese
 初始化融云SDK

 @param appKey  从融云开发者平台创建应用后获取到的App Key

 @discussion 您在使用融云SDK所有功能（包括显示SDK中或者继承于SDK的View）之前，您必须先调用此方法初始化SDK。
 在App整个生命周期中，您只需要执行一次初始化。

 @warning 如果您使用IMKit，请使用此方法初始化SDK；
 如果您使用IMLib，请使用RCIMClient中的同名方法初始化，而不要使用此方法。
 
 *  \~english
 Initialize RongCloud SDK.

 @param appKey The App Key obtained from the application created by RongCloud developer platform.

 @ discussion You must call this method to initialize the SDK before you can use all the features of the RongCloud SDK (including displaying View in SDK or inheriting from SDK).
  You only shall perform initialization once throughout the App lifecycle.

  @ warning This method is used to initialize SDK if you are using IMKit,
 If you are using IMLib, use the method of the same name in RCIMClient instead of using this method.
 */
- (void)initWithAppKey:(NSString *)appKey;

#pragma mark - connect & disconnect

/*!
 *  \~chinese
与融云服务器建立连接

@param token                   从您服务器端获取的 token (用户身份令牌)
@param dbOpenedBlock                本地消息数据库打开的回调
@param successBlock            连接建立成功的回调 [ userId: 当前连接成功所用的用户 ID]
@param errorBlock              连接建立失败的回调，触发该回调代表 SDK 无法继续重连 [errorCode: 连接失败的错误码]

@discussion 调用该接口，SDK 会在连接失败之后尝试重连，直到连接成功或者出现 SDK 无法处理的错误（如 token 非法）。
如果您不想一直进行重连，可以使用 connectWithToken:timeLimit:dbOpened:success:error: 接口并设置连接超时时间 timeLimit。

@discussion 连接成功后，SDK 将接管所有的重连处理。当因为网络原因断线的情况下，SDK 会不停重连直到连接成功为止，不需要您做额外的连接操作。

对于 errorBlock 需要特定关心 tokenIncorrect 的情况：
一是 token 错误，请您检查客户端初始化使用的 AppKey 和您服务器获取 token 使用的 AppKey 是否一致；
二是 token 过期，是因为您在开发者后台设置了 token 过期时间，您需要请求您的服务器重新获取 token 并再次用新的 token 建立连接。
在此种情况下，您需要请求您的服务器重新获取 token 并建立连接，但是注意避免无限循环，以免影响 App 用户体验。

@warning 如果您使用 IMKit，请使用该方法建立与融云服务器的连接。

此方法的回调并非为原调用线程，您如果需要进行 UI 操作，请注意切换到主线程。
 
 *  \~english
 Establish a connection with the cloud server.

 @param token Token (user identity token) obtained from your server.
 @param dbOpenedBlock Callback for opening the local message database.
 @param successBlock Callback for successful connection establishment [userId: The user ID used for the current successful connection].
 @param errorBlock Callback for failing to establish a connection. Triggering this callback means that SDK cannot continue to reconnect [errorCode: Error code for connection failure].

 @ discussion After this interface is called, SDK will try to reconnect after the connection fails, until the connection is successful or an error that SDK cannot handle (such as illegal token) occurs.
 If you don't want to keep reconnecting, you can use connectWithToken:timeLimit:dbOpened:success:error: interface and set the connection timeout timeLimit

 @ discussion After the connection is successful, SDK will take over all reconnection processing When the connection is disconnected due to network reasons, SDK will keep reconnecting until the connection is successful, and there is no need for you to do any additional connection operations.

 For situations where errorBlock shall be specifically concerned about tokenIncorrect:
 One is the token error. Please check whether the AppKey used by the client initialization is consistent with the AppKey used by your server to obtain the token.
 Second, the token expires because you set the token expiration time in the developer background, and you shall request your server to retrieve the token and establish a connection with the new token again.
 In this case, you shall ask your server to retrieve the token and establish a connection, but be careful to avoid an infinite loop so as not to ensure a good App user experience.

 @ warning If you use IMKit, use this method to establish a connection with the fused CVM.

 The callback for this method is not the original calling thread. If you shall perform a UI operation, please be careful to switch to the main thread.
*/
- (void)connectWithToken:(NSString *)token
                dbOpened:(void (^)(RCDBErrorCode code))dbOpenedBlock
                 success:(void (^)(NSString *userId))successBlock
                   error:(void (^)(RCConnectErrorCode errorCode))errorBlock;

/*!
 *  \~chinese
 与融云服务器建立连接

 @param token                   从您服务器端获取的 token (用户身份令牌)
 @param timeLimit                 SDK 连接的超时时间，单位: 秒
                         timeLimit <= 0，SDK 会一直连接，直到连接成功或者出现 SDK 无法处理的错误（如 token 非法）。
                         timeLimit > 0，SDK 最多连接 timeLimit 秒，超时时返回 RC_CONNECT_TIMEOUT 错误，并不再重连。
 @param dbOpenedBlock                本地消息数据库打开的回调
 @param successBlock            连接建立成功的回调 [ userId: 当前连接成功所用的用户 ID]
 @param errorBlock              连接建立失败的回调，触发该回调代表 SDK 无法继续重连 [errorCode: 连接失败的错误码]

 @discussion 调用该接口，SDK 会在 timeLimit 秒内尝试重连，直到出现下面三种情况之一：
 第一、连接成功，回调 successBlock(userId)。
 第二、超时，回调 errorBlock(RC_CONNECT_TIMEOUT)。
 第三、出现 SDK 无法处理的错误，回调 errorBlock(errorCode)（如 token 非法）。
 
 @discussion 连接成功后，SDK 将接管所有的重连处理。当因为网络原因断线的情况下，SDK 会不停重连直到连接成功为止，不需要您做额外的连接操作。

 对于 errorBlock 需要特定关心 tokenIncorrect 的情况：
 一是 token 错误，请您检查客户端初始化使用的 AppKey 和您服务器获取 token 使用的 AppKey 是否一致；
 二是 token 过期，是因为您在开发者后台设置了 token 过期时间，您需要请求您的服务器重新获取 token 并再次用新的 token 建立连接。
 在此种情况下，您需要请求您的服务器重新获取 token 并建立连接，但是注意避免无限循环，以免影响 App 用户体验。

 @warning 如果您使用 IMKit，请使用 RCIM 中的同名方法建立与融云服务器的连接。

 此方法的回调并非为原调用线程，您如果需要进行 UI 操作，请注意切换到主线程。
 
 *  \~english
 Establish a connection with the cloud server.

 @param token Token (user identity token) obtained from your server.
 @param timeLimit Timeout of SDK connection (in seconds)
 TimeLimit < = 0, the SDK will continue to connect until the connection is successful or an error (such as illegal token) that cannot be handled by the SDK occurs.
                          TimeLimit > 0, SDK can be connected for a maximum of timeLimit seconds. A RC_CONNECT_TIMEOUT error is returned when the timeout occurs, and the connection will not be reconnected
  @param dbOpenedBlock                Callback for opening the local message database.
 @param successBlock Callback for successful connection establishment [userId: The user ID used for the current successful connection].
 @param errorBlock Callback for failed connection establishment. Triggering this callback means that SDK cannot continue to reconnect [errorCode: Error code for connection failure].

 @ discussion This interface is called and SDK will attempt to reconnect within timeLimit seconds until one of the following three situations occurs:
  First, if the connection is successful, call back successBlock (userId).
  Second, call back errorBlock (RC_CONNECT_TIMEOUT) after timeout.
  Third, if there is an error that cannot be handled by SDK, callback errorBlock (errorCode) (such as token is illegal).
  
  @ discussion After the connection is successful, SDK will take over all reconnection processing When the connection is disconnected due to network reasons, SDK will keep reconnecting until the connection is successful, and there is no need for you to do any additional connection operations.

  For situations where errorBlock shall be specifically concerned about tokenIncorrect:
  One is the token error. Please check whether the AppKey used by the client initialization is consistent with the AppKey used by your server to obtain the token.
 Second, the token expires because you set the token expiration time in the developer background, and you shall request your server to retrieve the token and establish a connection with the new token again.
  In this case, you shall ask your server to retrieve the token and establish a connection, but be careful to avoid an infinite loop so as not to ensure a good App user experience.

  @ warning If you use IMKit, use the method with the same name in RCIM to establish a connection with the RongCloud server.

  The callback for this method is not the original calling thread. If you shall perform a UI operation, please be careful to switch to the main thread.
*/
- (void)connectWithToken:(NSString *)token
               timeLimit:(int)timeLimit
                dbOpened:(void (^)(RCDBErrorCode code))dbOpenedBlock
                 success:(void (^)(NSString *userId))successBlock
                   error:(void (^)(RCConnectErrorCode errorCode))errorBlock;

/*!
 *  \~chinese
 断开与融云服务器的连接

 @param isReceivePush   App在断开连接之后，是否还接收远程推送

 @discussion 因为SDK在前后台切换或者网络出现异常都会自动重连，会保证连接的可靠性。
 所以除非您的App逻辑需要登出，否则一般不需要调用此方法进行手动断开。

 @warning 如果您使用IMKit，请使用此方法断开与融云服务器的连接；
 如果您使用IMLib，请使用RCIMClient中的同名方法断开与融云服务器的连接，而不要使用此方法。

 isReceivePush指断开与融云服务器的连接之后，是否还接收远程推送。
 [[RCIM sharedRCIM] disconnect:YES]与[[RCIM sharedRCIM] disconnect]完全一致；
 [[RCIM sharedRCIM] disconnect:NO]与[[RCIM sharedRCIM] logout]完全一致。
 您只需要按照您的需求，使用disconnect:与disconnect以及logout三个接口其中一个即可。
 
 *  \~english
 Disconnect from the RongCloud server.

 @param isReceivePush Does App still receive remote push after being disconnected.

 @ discussion SDK will automatically reconnect because SDK is switched between foreground and background or if there is an exception in the network, which will ensure the reliability of the connection.
  Unless your App logic requires logout, generally you don't need to call this method for manual disconnection.

  @ warning If you use IMKit, please use this method to disconnect from the RongCloud server.
 If you use IMLib, the method of the same name in RCIMClient is used to disconnect from the fused CVM instead of using this method.

  IsReceivePush refers to whether remote push will be received after the connection with the RongCloud server is disconnected.
  [[RCIM sharedRCIM] disconnect:YES] is exactly the same as [[RCIM sharedRCIM] disconnect].
 [[RCIM sharedRCIM] disconnect:NO] is exactly the same as [[RCIM sharedRCIM] logout].
  You only shall use one of the three interfaces of disconnect:, disconnect and logout according to your needs.
 */
- (void)disconnect:(BOOL)isReceivePush;

/*!
 *  \~chinese
 断开与融云服务器的连接，但仍然接收远程推送

 @discussion 因为SDK在前后台切换或者网络出现异常都会自动重连，会保证连接的可靠性。
 所以除非您的App逻辑需要登出，否则一般不需要调用此方法进行手动断开。

 @warning 如果您使用IMKit，请使用此方法断开与融云服务器的连接；
 如果您使用IMLib，请使用RCIMClient中的同名方法断开与融云服务器的连接，而不要使用此方法。

 [[RCIM sharedRCIM] disconnect:YES]与[[RCIM sharedRCIM] disconnect]完全一致；
 [[RCIM sharedRCIM] disconnect:NO]与[[RCIM sharedRCIM] logout]完全一致。
 您只需要按照您的需求，使用disconnect:与disconnect以及logout三个接口其中一个即可。
 
 *  \~english
 Disconnect from the RongCloud server, but still receive remote push.

 @ discussion SDK will automatically reconnect because SDK is switched between foreground and background or if there is an exception in the network, which will ensure the reliability of the connection.
  Unless your App logic requires logout, generally you don't need to call this method for manual disconnection.

  @ warning If you use IMKit, please use this method to disconnect from the RongCloud server.
 If you use IMLib, the method of the same name in RCIMClient is used to disconnect from the fused CVM instead of using this method.

  [[RCIM sharedRCIM] disconnect:YES] is exactly the same as [[RCIM sharedRCIM] disconnect].
 [[RCIM sharedRCIM] disconnect:NO] is exactly the same as [[RCIM sharedRCIM] logout].
  You only shall use one of the three interfaces of disconnect:, disconnect and logout according to your needs.
 */
- (void)disconnect;

/*!
 *  \~chinese
 断开与融云服务器的连接，并不再接收远程推送

 @discussion 因为SDK在前后台切换或者网络出现异常都会自动重连，会保证连接的可靠性。
 所以除非您的App逻辑需要登出，否则一般不需要调用此方法进行手动断开。

 @warning 如果您使用IMKit，请使用此方法断开与融云服务器的连接；
 如果您使用IMLib，请使用RCIMClient中的同名方法断开与融云服务器的连接，而不要使用此方法。

 [[RCIM sharedRCIM] disconnect:YES]与[[RCIM sharedRCIM] disconnect]完全一致；
 [[RCIM sharedRCIM] disconnect:NO]与[[RCIM sharedRCIM] logout]完全一致。
 您只需要按照您的需求，使用disconnect:与disconnect以及logout三个接口其中一个即可。
 
 *  \~english
 Disconnect from the RongCloud server and no longer receive remote push.

 @ discussion SDK will automatically reconnect because SDK is switched between foreground and background or if there is an exception in the network, which will ensure the reliability of the connection.
  Unless your App logic requires logout, generally you don't need to call this method for manual disconnection.

  @ warning If you use IMKit, please use this method to disconnect from the RongCloud server.
 If you use IMLib, the method of the same name in RCIMClient is used to disconnect from the fused CVM instead of using this method.

  [[RCIM sharedRCIM] disconnect:YES] is exactly the same as [[RCIM sharedRCIM] disconnect].
 [[RCIM sharedRCIM] disconnect:NO] is exactly the same as [[RCIM sharedRCIM] logout].
  You only shall use one of the three interfaces of disconnect:, disconnect and logout according to your needs.
 */
- (void)logout;

#pragma mark RCIMConnectionStatusDelegate

/*!
 *  \~chinese
 IMKit连接状态的监听器

 @warning 如果您使用IMKit，可以设置并实现此Delegate监听消息接收；
 如果您使用IMLib，请使用RCIMClient中的RCIMClientReceiveMessageDelegate监听消息接收，而不要使用此方法。
 
 *  \~english
 Listeners for IMKit connection status

 @ warning If you use IMKit, you can set and implement this Delegate to listen to message reception.
 If you are using IMLib,  RCIMClientReceiveMessageDelegate in RCIMClient is used to listen to message reception instead of using this method.
 */
@property (nonatomic, weak) id<RCIMConnectionStatusDelegate> connectionStatusDelegate;

/*!
 *  \~chinese
 获取当前SDK的连接状态

 @return 当前SDK的连接状态
 
 *  \~english
 Get the connection status of the current SDK.

 @ return Connection status of the current SDK.
 */
- (RCConnectionStatus)getConnectionStatus;

#pragma mark - Message receive & send

/*!
 *  \~chinese
 注册自定义的消息类型

 @param messageClass    自定义消息的类，该自定义消息需要继承于RCMessageContent

 @discussion 如果您需要自定义消息，必须调用此方法注册该自定义消息的消息类型，否则SDK将无法识别和解析该类型消息。

 @warning 如果您使用IMKit，请使用此方法注册自定义的消息类型；
 如果您使用IMLib，请使用RCIMClient中的同名方法注册自定义的消息类型，而不要使用此方法。
 
 *  \~english
 Register a custom message type.

 @param messageClass The class of a custom message that shall be inherited from RCMessageContent.

 @ discussion If you need a custom message, you must call this method to register the message type of the custom message, otherwise SDK will not be able to recognize and parse that type of message.

  @ warning This method is used to register custom message types if you are using IMKit,
 If you are using IMLib, the method of the same name in RCIMClient is used to register the custom message type instead of using this method.
 */
- (void)registerMessageType:(Class)messageClass;

#pragma mark RCIMSendMessageDelegate

@property (nonatomic, weak) id<RCIMSendMessageDelegate> sendMessageDelegate;

#pragma mark Message Send
/*!
 *  \~chinese
 发送消息(除图片消息、文件消息外的所有消息)，会自动更新UI

 @param conversationType    发送消息的会话类型
 @param targetId            发送消息的目标会话ID
 @param content             消息的内容
 @param pushContent         接收方离线时需要显示的远程推送内容
 @param pushData            接收方离线时需要在远程推送中携带的非显示数据
 @param successBlock        消息发送成功的回调 [messageId:消息的ID]
 @param errorBlock          消息发送失败的回调 [nErrorCode:发送失败的错误码, messageId:消息的ID]
 @return                    发送的消息实体

 @discussion 当接收方离线并允许远程推送时，会收到远程推送。
 远程推送中包含两部分内容，一是pushContent，用于显示；二是pushData，用于携带不显示的数据。

 SDK内置的消息类型，如果您将pushContent和pushData置为nil，会使用默认的推送格式进行远程推送。
 自定义类型的消息，需要您自己设置pushContent和pushData来定义推送内容，否则将不会进行远程推送。

 @warning 如果您使用IMKit，使用此方法发送消息SDK会自动更新UI；
 如果您使用IMLib，请使用RCIMClient中的同名方法发送消息，不会自动更新UI。
 
 *  \~english
 Send a media file message and update UI automatically.

 @param conversationType The type of conversation in which the message is sent.
 @param targetId The ID of the target conversation that sent the message.
 @param content The content of the message.
 @param pushContent Remote push content that shall be displayed when the receiver is offline.
 @param pushData Non-display data that the receiver shall carry in the remote push when the receiver is offline.
 @param progressBlock Callback for message sending progress update [current sending progress of progress:, 0 < = progress < = 100, ID of messageId: message].
 @param successBlock Callback for message sent successfully [ID of messageId: message].
 @param errorBlock Callback for message sending failure [error code of errorCode: sending failure, ID of messageId: message].
 @param cancelBlock The user canceled the callback sent by the message [ID of the messageId: message].
 @ return sent message entity.

 @ discussion Receive a remote push when the receiver is offline and allows remote push.
  There are two parts in remote push, one is pushContent, for display, the other is pushData for carrying data that is not displayed.

  SDK built-in message type, if you set pushContent and pushData to nil, the default push format will be used for remote push.
  For a custom type of message, you shall set pushContent and pushData to define the push content, otherwise remote push will not be carried out.

  @ warning If you use IMKit, when this method is used to send media file messages, SDK will automatically update UI.
 If you use IMLib, the method of the same name in RCIMClient is used to send a media file message, and UI will not be updated automatically.
 */
- (RCMessage *)sendMessage:(RCConversationType)conversationType
                  targetId:(NSString *)targetId
                   content:(RCMessageContent *)content
               pushContent:(NSString *)pushContent
                  pushData:(NSString *)pushData
                   success:(void (^)(long messageId))successBlock
                     error:(void (^)(RCErrorCode nErrorCode, long messageId))errorBlock;

/*!
 *  \~chinese
 发送消息(除图片消息、文件消息外的所有消息)，会自动更新UI
 
 @param message             将要发送的消息实体（需要保证 message 中的 conversationType，targetId，messageContent 是有效值)
 @param pushContent         接收方离线时需要显示的远程推送内容
 @param pushData            接收方离线时需要在远程推送中携带的非显示数据
 @param successBlock        消息发送成功的回调 [successMessage: 消息实体]
 @param errorBlock          消息发送失败的回调 [nErrorCode: 发送失败的错误码, errorMessage:消息实体]
 @return                    发送的消息实体
 
 @discussion 当接收方离线并允许远程推送时，会收到远程推送。
 远程推送中包含两部分内容，一是pushContent，用于显示；二是pushData，用于携带不显示的数据。

 SDK内置的消息类型，如果您将pushContent和pushData置为nil，会使用默认的推送格式进行远程推送。
 自定义类型的消息，需要您自己设置pushContent和pushData来定义推送内容，否则将不会进行远程推送。
 
 @warning 如果您使用IMKit，使用此方法发送消息SDK会自动更新UI；
 如果您使用IMLib，请使用RCIMClient中的同名方法发送消息，不会自动更新UI。
 
 @remarks 消息操作
 
 *  \~english
 Send messages (all messages except image messages and file messages), and UI will be updated automatically.

 @param message The message entity to be sent (you shall ensure that the conversationType,targetId,messageContent in message is a valid value).
 @param pushContent Remote push content that shall be displayed when the receiver is offline.
 @param pushData Non-display data that the receiver shall carry in the remote push when the receiver is offline.
 @param successBlock Callback for successful message sending [successMessage: Message entity].
 @param errorBlock Callback for failed message sending [nErrorCode: Error code for send failure, errorMessage: message entity].
 @ return sent message entity.

 @ discussion Receive a remote push when the receiver is offline and allows remote push.
  There are two parts in remote push, one is pushContent, for display, the other is pushData for carrying data that is not displayed.

  SDK built-in message type, if you set pushContent and pushData to nil, the default push format will be used for remote push.
  For a custom type of message, you shall set pushContent and pushData to define the push content, otherwise remote push will not be carried out.
  
  @ warning If you use IMKit, when this method is used to send messages, SDK will automatically update UI.
 If you use IMLib, the method of the same name in RCIMClient is used to send a message, and UI will not be updated automatically.
  
  @ remarks message operation
 */
- (RCMessage *)sendMessage:(RCMessage *)message
               pushContent:(NSString *)pushContent
                  pushData:(NSString *)pushData
              successBlock:(void (^)(RCMessage *successMessage))successBlock
                errorBlock:(void (^)(RCErrorCode nErrorCode, RCMessage *errorMessage))errorBlock;

/*!
 *  \~chinese
 发送媒体文件消息，会自动更新UI

 @param conversationType    发送消息的会话类型
 @param targetId            发送消息的目标会话ID
 @param content             消息的内容
 @param pushContent         接收方离线时需要显示的远程推送内容
 @param pushData            接收方离线时需要在远程推送中携带的非显示数据
 @param progressBlock       消息发送进度更新的回调 [progress:当前的发送进度, 0 <= progress <= 100, messageId:消息的ID]
 @param successBlock        消息发送成功的回调 [messageId:消息的ID]
 @param errorBlock          消息发送失败的回调 [errorCode:发送失败的错误码, messageId:消息的ID]
 @param cancelBlock         用户取消了消息发送的回调 [messageId:消息的ID]
 @return                    发送的消息实体

 @discussion 当接收方离线并允许远程推送时，会收到远程推送。
 远程推送中包含两部分内容，一是pushContent，用于显示；二是pushData，用于携带不显示的数据。

 SDK内置的消息类型，如果您将pushContent和pushData置为nil，会使用默认的推送格式进行远程推送。
 自定义类型的消息，需要您自己设置pushContent和pushData来定义推送内容，否则将不会进行远程推送。

 @warning 如果您使用IMKit，使用此方法发送媒体文件消息SDK会自动更新UI；
 如果您使用IMLib，请使用RCIMClient中的同名方法发送媒体文件消息，不会自动更新UI。
 
 *  \~english
 Send a media file message and update UI automatically.

 @param conversationType The type of conversation in which the message is sent.
 @param targetId The ID of the target conversation that sent the message.
 @param content The content of the message.
 @param pushContent Remote push content that shall be displayed when the receiver is offline.
 @param pushData Non-display data that the receiver shall carry in the remote push when the receiver is offline.
 @param progressBlock Callback for message sending progress update [current sending progress of progress:, 0 < = progress < = 100, ID of messageId: message].
 @param successBlock Callback for message sent successfully [ID of messageId: message].
 @param errorBlock Callback for message sending failure [error code of errorCode: sending failure, ID of messageId: message].
 @param cancelBlock The user canceled the callback sent by the message [ID of the messageId: message].
 @ return sent message entity.

 @ discussion Receive a remote push when the receiver is offline and allows remote push.
  There are two parts in remote push, one is pushContent, for display, the other is pushData for carrying data that is not displayed.

  SDK built-in message type, if you set pushContent and pushData to nil, the default push format will be used for remote push.
  For a custom type of message, you shall set pushContent and pushData to define the push content, otherwise remote push will not be carried out.

  @ warning If you use IMKit, when this method is used to send media file messages, SDK will automatically update UI.
 If you use IMLib, the method of the same name in RCIMClient is used to send a media file message, and UI will not be updated automatically. 
 */
- (RCMessage *)sendMediaMessage:(RCConversationType)conversationType
                       targetId:(NSString *)targetId
                        content:(RCMessageContent *)content
                    pushContent:(NSString *)pushContent
                       pushData:(NSString *)pushData
                       progress:(void (^)(int progress, long messageId))progressBlock
                        success:(void (^)(long messageId))successBlock
                          error:(void (^)(RCErrorCode errorCode, long messageId))errorBlock
                         cancel:(void (^)(long messageId))cancelBlock;

/*!
 *  \~chinese
 发送媒体文件消息，会自动更新UI
 
 @param message             将要发送的消息实体（需要保证 message 中的 conversationType，targetId，messageContent 是有效值)
 @param pushContent         接收方离线时需要显示的远程推送内容
 @param pushData            接收方离线时需要在远程推送中携带的非显示数据
 @param progressBlock       消息发送进度更新的回调 [progress:当前的发送进度, 0 <= progress <= 100, progressMessage:消息实体]
 @param successBlock        消息发送成功的回调 [successMessage:消息实体]
 @param errorBlock          消息发送失败的回调 [nErrorCode:发送失败的错误码, errorMessage:消息实体]
 @param cancelBlock         用户取消了消息发送的回调 [cancelMessage:消息实体]
 @return                    发送的消息实体
 
 @discussion 当接收方离线并允许远程推送时，会收到远程推送。
 远程推送中包含两部分内容，一是pushContent，用于显示；二是pushData，用于携带不显示的数据。
 
 SDK内置的消息类型，如果您将pushContent和pushData置为nil，会使用默认的推送格式进行远程推送。
 自定义类型的消息，需要您自己设置pushContent和pushData来定义推送内容，否则将不会进行远程推送。
 
 @warning 如果您使用IMKit，使用此方法发送媒体文件消息SDK会自动更新UI；
 如果您使用IMLib，请使用RCIMClient中的同名方法发送媒体文件消息，不会自动更新UI。
 
 *  \~english
 Send a media file message and update UI automatically.

 @param message The message entity to be sent (you shall ensure that the conversationType,targetId,messageContent in message is a valid value).
 @param pushContent Remote push content that shall be displayed when the receiver is offline.
 @param pushData Non-display data that the receiver shall carry in the remote push when the receiver is offline.
 @param progressBlock Callback for message sending progress update [progress: current sending progress, 0 < = progress < = 100, progressMessage: message entity].
 @param successBlock Callback for successful message sending [successMessage: message entity].
 @param errorBlock Callback for message sending failure [nErrorCode: error code of sending failure, errorMessage: message entity].
 @param cancelBlock User canceled callback for message sending [cancelMessage: message entity].
 @ return sent message entity.

 @ discussion Receive a remote push when the receiver is offline and allows remote push.
  There are two parts in remote push, one is pushContent, for display, the other is pushData for carrying data that is not displayed.
  
  SDK built-in message type, if you set pushContent and pushData to nil, the default push format will be used for remote push.
  For a custom type of message, you shall set pushContent and pushData to define the push content, otherwise remote push will not be carried out.
  
  @ warning If you use IMKit, when this method is used to send media file messages, SDK will automatically update UI.
 If you use IMLib, the method of the same name in RCIMClient is used to send a media file message, and UI will not be updated automatically. 
 */
- (RCMessage *)sendMediaMessage:(RCMessage *)message
                    pushContent:(NSString *)pushContent
                       pushData:(NSString *)pushData
                       progress:(void (^)(int progress, RCMessage *progressMessage))progressBlock
                   successBlock:(void (^)(RCMessage *successMessage))successBlock
                     errorBlock:(void (^)(RCErrorCode nErrorCode, RCMessage *errorMessage))errorBlock
                         cancel:(void (^)(RCMessage *cancelMessage))cancelBlock;

/*!
 *  \~chinese
 取消发送中的媒体信息

 @param messageId           媒体消息的messageId

 @return YES表示取消成功，NO表示取消失败，即已经发送成功或者消息不存在。
 
 *  \~english
 Cancel media information in transmission.

 @param messageId MessageId of media messages.

 @ return YES: cancel successfully, and NO: cancel failed, that is, the message has been sent successfully or the message does not exist.
 */
- (BOOL)cancelSendMediaMessage:(long)messageId;

/*!
 *  \~chinese
 下载消息中的媒体文件

 @param messageId       消息ID
 @param progressBlock   下载进度更新的回调 [progress:当前的发送进度, 0 <= progress <= 100]
 @param successBlock    下载成功的回调 [mediaPath:下载完成后文件在本地的存储路径]
 @param errorBlock      下载失败的回调 [errorCode:下载失败的错误码]
 @param cancelBlock     下载取消的回调

 @discussion 媒体消息仅限于图片消息和文件消息。
 
 *  \~english
 Download the media file in the message.

 @param messageId Message ID.
 @param progressBlock Callback for downloading progress updates [progress: current sending progress, 0 < = progress < = 100].
 @param successBlock Callback for successful download [mediaPath: the local storage path of the file after download is completed].
 @param errorBlock Callback for download failure [errorCode: error code of download failure].
 @param cancelBlock Callback for download cancellation

 @ discussion Media messages are limited to image messages and file messages.
 */
- (void)downloadMediaMessage:(long)messageId
                    progress:(void (^)(int progress))progressBlock
                     success:(void (^)(NSString *mediaPath))successBlock
                       error:(void (^)(RCErrorCode errorCode))errorBlock
                      cancel:(void (^)(void))cancelBlock;

/*!
 *  \~chinese
 取消下载中的媒体信息

 @param messageId 媒体消息的messageId

 @return YES表示取消成功，NO表示取消失败，即已经下载完成或者消息不存在。
 
 *  \~english
 Cancel the media information in the download.

 @param messageId MessageId of media messages.

 @ return YES: cancel successfully; NO: cancel failed, that is, the download has been completed or the message does not exist.
 */
- (BOOL)cancelDownloadMediaMessage:(long)messageId;

/*!
 *  \~chinese
 发送定向消息，会自动更新UI

 @param conversationType 发送消息的会话类型
 @param targetId         发送消息的目标会话ID
 @param userIdList       发送给的用户ID列表
 @param content          消息的内容
 @param pushContent      接收方离线时需要显示的远程推送内容
 @param pushData         接收方离线时需要在远程推送中携带的非显示数据
 @param successBlock     消息发送成功的回调 [messageId:消息的ID]
 @param errorBlock       消息发送失败的回调 [errorCode:发送失败的错误码,
 messageId:消息的ID]

 @return 发送的消息实体

 @discussion 此方法用于在群组和讨论组中发送消息给其中的部分用户，其它用户不会收到这条消息。
 如果您使用IMKit，使用此方法发送定向消息SDK会自动更新UI；
 如果您使用IMLib，请使用RCIMClient中的同名方法发送定向消息，不会自动更新UI。

 @warning 此方法目前仅支持群组和讨论组。
 
 *  \~english
 Send a directed message and update the UI automatically.

 @param conversationType The type of conversation in which the message is sent.
 @param targetId The ID of the target conversation that sent the message.
 @param userIdList ID list of users sent to.
 @param content The content of the message.
 @param pushContent Remote push content that shall be displayed when the receiver is offline.
 @param pushData Non-display data that the receiver shall carry in the remote push when the receiver is offline.
 @param successBlock Callback for message sent successfully [ID of messageId: message].
 @param errorBlock Callback for message sending failure [error code of errorCode: sending failure.
 ID of messageId: message].

 @ return sent message entity.

 @ discussion This method is used to send messages to some of the users in groups and discussion groups, and other users will not receive the message.
  If you use IMKit, to send directed messages using this method, SDK will automatically update UI.
 If you use IMLib, the method of the same name in RCIMClient is used to send a directed message, and the UI will not be updated automatically.

  @ warning This method currently only supports groups and discussion groups.
 */
- (RCMessage *)sendDirectionalMessage:(RCConversationType)conversationType
                             targetId:(NSString *)targetId
                         toUserIdList:(NSArray *)userIdList
                              content:(RCMessageContent *)content
                          pushContent:(NSString *)pushContent
                             pushData:(NSString *)pushData
                              success:(void (^)(long messageId))successBlock
                                error:(void (^)(RCErrorCode nErrorCode, long messageId))errorBlock;

/*!
 *  \~chinese
 发起VoIP语音通话

 @param targetId    要发起语音通话的对方的用户ID

 @warning 旧版本VoIP接口，不再支持，请升级到最新VoIP版本。
 
 *  \~english
 Initiate a VoIP voice call.

 @param targetId The user ID of the other party who wants to initiate a voice call.

 @ warning The old version of VoIP interface is no longer supported. Please upgrade to the latest VoIP version.
 */
//- (void)startVoIPCallWithTargetId:(NSString *)targetId;

#pragma mark RCIMReceiveMessageDelegate
/*!
 *  \~chinese
 IMKit消息接收的监听器

 @warning 如果您使用IMKit，可以设置并实现此Delegate监听消息接收；
 如果您使用IMLib，请使用RCIMClient中的RCIMClientReceiveMessageDelegate监听消息接收，而不要使用此方法。
 
 *  \~english
 Listeners for IMKit message reception.
 @ warning If you use IMKit, you can set and implement this Delegate to listen to message reception.
 If you are using IMLib, use RCIMClientReceiveMessageDelegate in RCIMClient to listen to message reception instead of using this method.
 */
@property (nonatomic, weak) id<RCIMReceiveMessageDelegate> receiveMessageDelegate;


#pragma mark - Discussion

/*!
 *  \~chinese
 创建讨论组

 @param name            讨论组名称
 @param userIdList      用户ID的列表
 @param successBlock    创建讨论组成功的回调 [discussion:创建成功返回的讨论组对象]
 @param errorBlock      创建讨论组失败的回调 [status:创建失败的错误码]
 
 *  \~english
 Create a discussion group.

 @param name Discussion Group name.
 @param userIdList List of user ID.
 @param successBlock Callback for creating a discussion group successfully [discussion: discussion group object returned after successful creation].
 @param errorBlock Callback for failing to create discussion group [statusu: error code for failed creation].
 */
- (void)createDiscussion:(NSString *)name
              userIdList:(NSArray *)userIdList
                 success:(void (^)(RCDiscussion *discussion))successBlock
                   error:(void (^)(RCErrorCode status))errorBlock;

/*!
 *  \~chinese
 讨论组加人，将用户加入讨论组

 @param discussionId    讨论组ID
 @param userIdList      需要加入的用户ID列表
 @param successBlock    讨论组加人成功的回调 [discussion:讨论组加人成功返回的讨论组对象]
 @param errorBlock      讨论组加人失败的回调 [status:讨论组加人失败的错误码]

 @discussion 设置的讨论组名称长度不能超过40个字符，否则将会截断为前40个字符。
 
 *  \~english
 Add people to the discussion group and add users to the discussion group.

 @param discussionId Discussion group ID.
 @param userIdList ID list of users to join.
 @param successBlock Callback for successful joining of discussion group [discussion: discussion group objects returned  after successful joining of discussion group].
 @param errorBlock Callback for failed joining of discussion group [status: error code of  failed joining of discussion group].

 @ discussion The discussion group name set by cannot be more than 40 characters long, otherwise it will be truncated to the first 40 characters.
 */
- (void)addMemberToDiscussion:(NSString *)discussionId
                   userIdList:(NSArray *)userIdList
                      success:(void (^)(RCDiscussion *discussion))successBlock
                        error:(void (^)(RCErrorCode status))errorBlock;

/*!
 *  \~chinese
 讨论组踢人，将用户移出讨论组

 @param discussionId    讨论组ID
 @param userId          需要移出的用户ID
 @param successBlock    讨论组踢人成功的回调 [discussion:讨论组踢人成功返回的讨论组对象]
 @param errorBlock      讨论组踢人失败的回调 [status:讨论组踢人失败的错误码]

 @discussion 如果当前登录用户不是此讨论组的创建者并且此讨论组没有开放加人权限，则会返回错误。

 @warning 不能使用此接口将自己移除，否则会返回错误。
 如果您需要退出该讨论组，可以使用-quitDiscussion:success:error:方法。
 
 *  \~english
 The discussion group kicks people and moves the user out of the discussion group.

 @param discussionId Discussion group ID.
 @param userId ID of the user to be removed.
 @param successBlock Callback for a successful discussion group kicking [discussion group object returned by discussion: discussion group kick].
 @param errorBlock Callback for discussion group kick failure [status: error code of discussion group kicking failure].

 @ discussion An error will be returned if the currently logged in user is not the creator of this discussion group and the discussion group does not have open add permission.

  @ warning It is not permitted to use this interface to remove itself, otherwise an error will be returned
  If you shall exit the discussion group, you can use the-quitDiscussion:success:error: method. 
 */
- (void)removeMemberFromDiscussion:(NSString *)discussionId
                            userId:(NSString *)userId
                           success:(void (^)(RCDiscussion *discussion))successBlock
                             error:(void (^)(RCErrorCode status))errorBlock;

/*!
 *  \~chinese
 退出当前讨论组

 @param discussionId    讨论组ID
 @param successBlock    退出成功的回调 [discussion:退出成功返回的讨论组对象]
 @param errorBlock      退出失败的回调 [status:退出失败的错误码]
 
 *  \~english
 Exit the current discussion group.

 @param discussionId Discussion group ID.
 @param successBlock Callback for successful exit [discussion: discuss group object returned after successful exit].
 @param errorBlock Callback for exit failure [status: error code of exit failure].
 */
- (void)quitDiscussion:(NSString *)discussionId
               success:(void (^)(RCDiscussion *discussion))successBlock
                 error:(void (^)(RCErrorCode status))errorBlock;

/*!
 *  \~chinese
 获取讨论组的信息

 @param discussionId    需要获取信息的讨论组ID
 @param successBlock    获取讨论组信息成功的回调 [discussion:获取的讨论组信息]
 @param errorBlock      获取讨论组信息失败的回调 [status:获取讨论组信息失败的错误码]
 
 *  \~english
 Get information about the discussion group.

 @param discussionId Discussion group ID that shall get information.
 @param successBlock Callback for getting discussion group information successfully [discussion group information obtained by discussion:].
 @param errorBlock Callback for failing to get discussion group information [status: error code of failing to get discussion group information].
 */
- (void)getDiscussion:(NSString *)discussionId
              success:(void (^)(RCDiscussion *discussion))successBlock
                error:(void (^)(RCErrorCode status))errorBlock;

/*!
 *  \~chinese
 设置讨论组名称

 @param discussionId            需要设置的讨论组ID
 @param discussionName          需要设置的讨论组名称，discussionName长度<=40
 @param successBlock            设置成功的回调
 @param errorBlock              设置失败的回调 [status:设置失败的错误码]

 @discussion 设置的讨论组名称长度不能超过40个字符，否则将会截断为前40个字符。
 
 *  \~english
 Set discussion group name.

 @param discussionId Discussion group ID to be set.
 @param discussionName The name of the discussion group to be set. DiscussionName length < = 40.
 @param successBlock Callback for successful setting
 @param errorBlock Callback for failed setting [stauts: error code for failed  setting].

 @ discussion The set discussion group name cannot be more than 40 characters long, otherwise it will be truncated to the first 40 characters.
 */
- (void)setDiscussionName:(NSString *)discussionId
                     name:(NSString *)discussionName
                  success:(void (^)(void))successBlock
                    error:(void (^)(RCErrorCode status))errorBlock;

/*!
 *  \~chinese
 设置讨论组是否开放加人权限

 @param discussionId    论组ID
 @param isOpen          是否开放加人权限
 @param successBlock    设置成功的回调
 @param errorBlock      设置失败的回调[status:设置失败的错误码]

 @discussion 讨论组默认开放加人权限，即所有成员都可以加人。
 如果关闭加人权限之后，只有讨论组的创建者有加人权限。
 
 *  \~english
 Set whether the discussion group is open to addition permission.

 @param discussionId Discussion group ID.
 @param isOpen Whether to open the permission to add people.
 @param successBlock Callback for successful setting
 @param errorBlock Callback for failed setting [error code for failed status: setting].

 @ discussion Discussion group enables add permission by default, that is, all members can add people.
  If the add permission is disabled, only the creator of the discussion group has the add permission.
 */
- (void)setDiscussionInviteStatus:(NSString *)discussionId
                           isOpen:(BOOL)isOpen
                          success:(void (^)(void))successBlock
                            error:(void (^)(RCErrorCode status))errorBlock;

#pragma mark - User info,Group info

/*!
 *  \~chinese
 当前登录的用户的用户信息

 @discussion 与融云服务器建立连接之后，应该设置当前用户的用户信息，用于SDK显示和发送。

 @warning 如果传入的用户信息中的用户ID与当前登录的用户ID不匹配，则将会忽略。
 
 *  \~english
 User information of the currently logged in user.

 @ discussion After a connection with the cloud server is established, you should set the user information of the current user for SDK display and transmission.

  @ warning It will be ignored if the user ID in the incoming user information does not match the currently logged in user ID.
 */
@property (nonatomic, strong) RCUserInfo *currentUserInfo;

/*!
 *  \~chinese
 是否将用户信息和群组信息在本地持久化存储，默认值为NO

 @discussion
 如果设置为NO，则SDK在需要显示用户信息时，会调用用户信息提供者获取用户信息并缓存到Cache，此Cache在App生命周期结束时会被移除，下次启动时会再次通过用户信息提供者获取信息。
 如果设置为YES，则会将获取到的用户信息持久化存储在本地，App下次启动时Cache会仍然有效。
 
 *  \~english
 Whether to persist user information and group information locally. The default value is NO.

 @ discussion
 If it is set to NO, when SDK shall display user information, it will call the user information provider to get the user information and cache it to Cache. This Cache will be removed at the end of the App life cycle. The next time it starts, it will get the information again through the user information provider.
  If set to YES, the acquired user information will be persisted locally, and the Cache will still be valid the next time App starts.
 */
@property (nonatomic, assign) BOOL enablePersistentUserInfoCache;

/*!
 *  \~chinese
 是否在发送的所有消息中携带当前登录的用户信息，默认值为NO

 @discussion 如果设置为YES，则会在每一条发送的消息中携带当前登录用户的用户信息。
 收到一条携带了用户信息的消息，SDK会将其信息加入用户信息的cache中并显示；
 若消息中不携带用户信息，则仍然会通过用户信息提供者获取用户信息进行显示。

 @warning 需要先设置当前登录用户的用户信息，参考RCIM的currentUserInfo。
 
 *  \~english
 Whether to carry the currently logged-in user information in all messages sent. The default value is NO.

 @ discussion If it set to YES, each sent message will carry the user information of the currently logged-in user.
  When you receive a message with the user's information, SDK will add its information to the cache of the user's information and display it.
 If there is no user information in the message, the user information will still be obtained through the user information provider for display.

  @ warning First set the user information of the currently logged-in user first, please refer to the currentUserInfo of RCIM.
 */
@property (nonatomic, assign) BOOL enableMessageAttachUserInfo;

#pragma mark User Info

/*!
 *  \~chinese
 用户信息提供者

 @discussion SDK需要通过您实现的用户信息提供者，获取用户信息并显示。
 
 *  \~english
 User information provider.

 @ discussion SDK shall get the user information and display it through the user information provider that you implement.
 */
@property (nonatomic, weak) id<RCIMUserInfoDataSource> userInfoDataSource;

/*!
 *  \~chinese
 更新SDK中的用户信息缓存

 @param userInfo     需要更新的用户信息
 @param userId       需要更新的用户ID

 @discussion 使用此方法，可以更新SDK缓存的用户信息。
 但是处于性能和使用场景权衡，SDK不会在当前View立即自动刷新（会在切换到其他View的时候再刷新该用户的显示信息）。
 如果您想立即刷新，您可以在会话列表或者会话页面reload强制刷新。
 
 *  \~english
 Update the user information cache in SDK.

 @param userInfo User information to update
 @param userId User ID to update

 @ discussion This method is used to update the user information cached by SDK.
  However, due to the tradeoff between performance and usage scenarios, SDK does not automatically refresh the current View immediately (it will refresh the user's display information when switching to another View).
  If you want to refresh immediately, you can force the refresh in the conversation list or in the conversation page reload.
 */
- (void)refreshUserInfoCache:(RCUserInfo *)userInfo withUserId:(NSString *)userId;

/*!
 *  \~chinese
 获取SDK中缓存的用户信息

 @param userId  用户ID
 @return        SDK中缓存的用户信息
 
 *  \~english
 Get cached user information in SDK.

 @param userId User ID.
 @ return SDK cached user information.
 */
- (RCUserInfo *)getUserInfoCache:(NSString *)userId;

/*!
 *  \~chinese
 清空SDK中所有的用户信息缓存

 @discussion 使用此方法，会清空SDK中所有的用户信息缓存。
 但是处于性能和使用场景权衡，SDK不会在当前View立即自动刷新（会在切换到其他View的时候再刷新所显示的用户信息）。
 如果您想立即刷新，您可以在会话列表或者会话页面reload强制刷新。
 
 *  \~english
 Clear all user information caches in SDK.

 @ discussion This method is used to clear all user information caches in SDK.
  However, due to the tradeoff between performance and usage scenarios, SDK does not automatically refresh the current View immediately (it will refresh the displayed user information when switching to another View).
  If you want to refresh immediately, you can force the refresh in the conversation list or in the conversation page reload.
 */
- (void)clearUserInfoCache;

#pragma mark Group Info
/*!
 *  \~chinese
 群组信息提供者

 @discussion SDK需要通过您实现的群组信息提供者，获取群组信息并显示。
 
 *  \~english
 Group information provider

 @ discussion SDK shall obtain and display the group information through the group information provider that you implement.
 */
@property (nonatomic, weak) id<RCIMGroupInfoDataSource> groupInfoDataSource;

/*!
 *  \~chinese
 更新SDK中的群组信息缓存

 @param groupInfo   需要更新的群组信息
 @param groupId     需要更新的群组ID

 @discussion 使用此方法，可以更新SDK缓存的群组信息。
 但是处于性能和使用场景权衡，SDK不会在当前View立即自动刷新（会在切换到其他View的时候再刷新该群组的显示信息）。
 如果您想立即刷新，您可以在会话列表或者会话页面reload强制刷新。
 
 *  \~english
 Update the group information cache in SDK.

 @param groupInfo Group information that shall be updated.
 @param groupId Group ID that shall be updated.

 @ discussion This method is used to update the group information cached by SDK.
  However, due to the tradeoff between performance and usage scenarios, SDK does not automatically refresh the current View immediately (it will refresh the display information of the group when switching to another View).
  If you want to refresh immediately, you can force the refresh in the conversation list or in the conversation page reload.
 */
- (void)refreshGroupInfoCache:(RCGroup *)groupInfo withGroupId:(NSString *)groupId;

/*!
 *  \~chinese
 获取SDK中缓存的群组信息

 @param groupId     群组ID
 @return            SDK中缓存的群组信息
 
 *  \~english
 Get the group information cached in SDK.

 @param groupId Group ID.
 Group information cached in @ return SDK.
 */
- (RCGroup *)getGroupInfoCache:(NSString *)groupId;

/*!
 *  \~chinese
 清空SDK中所有的群组信息缓存

 @discussion 使用此方法，会清空SDK中所有的群组信息缓存。
 但是处于性能和使用场景权衡，SDK不会在当前View立即自动刷新（会在切换到其他View的时候再刷新所显示的群组信息）。
 如果您想立即刷新，您可以在会话列表或者会话页面reload强制刷新。
 
 *  \~english
 Clear all group information caches in SDK.

 @ discussion This method is used to clear all group information caches in SDK.
  However, due to the tradeoff between performance and usage scenarios, SDK will not automatically refresh the current View immediately (it will refresh the displayed group information when switching to another View).
  If you want to refresh immediately, you can force the refresh in the conversation list or in the conversation page reload. 
 */
- (void)clearGroupInfoCache;

#pragma mark RCIMGroupUserInfoDataSource

/*!
 *  \~chinese
 群名片信息提供者

 @discussion 如果您使用了群名片功能，SDK需要通过您实现的群名片信息提供者，获取用户在群组中的名片信息并显示。
 
 *  \~english
 Group business card information provider.

 @ discussion If you use the group business card function, SDK shall obtain and display the user's business card information in the group through the group business card information provider you implemented.
 */
@property (nonatomic, weak) id<RCIMGroupUserInfoDataSource> groupUserInfoDataSource;

/*!
 *  \~chinese
 获取SDK中缓存的群名片信息

 @param userId      用户ID
 @param groupId     群组ID
 @return            群名片信息
 
 *  \~english
 Get the group business card information cached in SDK.

 @param userId User ID.
 @param groupId Group ID.
 @ return group business card information
 */
- (RCUserInfo *)getGroupUserInfoCache:(NSString *)userId withGroupId:(NSString *)groupId;

/*!
 *  \~chinese
 更新SDK中的群名片信息缓存

 @param userInfo     需要更新的用户信息
 @param userId       需要更新的用户ID
 @param groupId      需要更新群名片信息的群组ID

 @discussion 使用此方法，可以更新SDK缓存的群名片信息。
 但是处于性能和使用场景权衡，SDK不会在当前View立即自动刷新（会在切换到其他View的时候再刷新该群名片的显示信息）。
 如果您想立即刷新，您可以在会话列表或者会话页面reload强制刷新。
 
 *  \~english
 Update the group business card information cache in SDK.

 @param userInfo Updated user information is required.
 @param userId User ID that shall be updated.
 @param groupId Group ID that shall update group business card information.

 @ discussion This method is used to update the group business card information cached by SDK.
  However, due to the tradeoff between performance and usage scenarios, SDK will not automatically refresh the current View immediately (it will refresh the display information of the group business card when switching to another View).
  If you want to refresh immediately, you can force the refresh in the conversation list or in the conversation page reload.
 */
- (void)refreshGroupUserInfoCache:(RCUserInfo *)userInfo withUserId:(NSString *)userId withGroupId:(NSString *)groupId;

/*!
 *  \~chinese
 清空SDK中所有的群名片信息缓存

 @discussion 使用此方法，会清空SDK中所有的群名片信息缓存。
 但是处于性能和使用场景权衡，SDK不会在当前View立即自动刷新（会在切换到其他View的时候再刷新所显示的群名片信息）。
 如果您想立即刷新，您可以在会话列表或者会话页面reload强制刷新。
 
 *  \~english
 Clear all group business card information caches in SDK.

 @ discussion This method is used to clear all group business card information caches in SDK.
  However, due to the tradeoff between performance and usage scenarios, SDK will not automatically refresh the current View immediately (the group business card information displayed will be refreshed when switching to another View).
  If you want to refresh immediately, you can force the refresh in the conversation list or in the conversation page reload. 
 */
- (void)clearGroupUserInfoCache;

#pragma mark RCIMGroupMemberDataSource

/*!
 *  \~chinese
 群成员信息提供者

 @discussion 如果您使用了@功能，SDK需要通过您实现的群用户成员提供者，获取群组中的用户列表。
 
 *  \~english
 Group member information provider.

 @ discussion If you use the @ feature, SDK shall get a list of users in the group through the group user member provider that you implement.
 */
@property (nonatomic, weak) id<RCIMGroupMemberDataSource> groupMemberDataSource;

#pragma mark HQVoice auto download flag

/*!
 *  \~chinese
 在线时是否自动下载高质量语音消息

 @discussion 默认为 YES
 
 *  \~english
 Whether to download high-quality voice messages automatically when online.

 @ discussion The default value is YES.
 */
@property (nonatomic, assign) BOOL automaticDownloadHQVoiceMsgEnable;

#pragma mark - RCIMPublicServiceProfileDataSource

/*!
 *  \~chinese
 公众号信息提供者

 @discussion SDK需要通过您实现公众号信息提供者，获取公众号信息并显示。
 
 *  \~english
 Official account information provider.

 @ discussion SDK shall implement the official account information provider through you, obtain the official account information and display it.
 */
@property (nonatomic, weak) id<RCIMPublicServiceProfileDataSource> publicServiceInfoDataSource;

#pragma mark - embeddedWebViewPreferred
/*!
 *  \~chinese
 点击Cell中的URL时，优先使用WebView还是SFSafariViewController打开。

 @discussion 默认为NO。
 如果设置为YES，将使用WebView打开URL链接，则您需要在App的Info.plist的NSAppTransportSecurity中增加NSAllowsArbitraryLoadsInWebContent和NSAllowsArbitraryLoads字段，并在苹果审核的时候提供额外的说明。
 如果设置为NO，将优先使用SFSafariViewController，在iOS 8及之前的系统中使用WebView，在审核的时候不需要提供额外说明。
 更多内容可以参考：https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW55
 
 *  \~english
 When you click URL in Cell, use WebView or SFSafariViewController to open it first.

  @ discussion The default value is NO.
  If YES is set, the URL link is opened by using WebView and you shall add the NSAllowsArbitraryLoadsInWebContent and NSAllowsArbitraryLoads fields to the NSAppTransportSecurity of App's Info.plist, and provide additional instructions during Apple's audit.
  If NO is set, priority will be given to the use of SFSafariViewController and WebView is used on iOS 8 and previous systems. No additional instructions are required during the audit.
  For more information, please refer to https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW55. 
 */
@property (nonatomic, assign) BOOL embeddedWebViewPreferred;

#pragma mark - Extension module
/*!
 *  \~chinese
 设置Extension Module的URL scheme。
 @param scheme      URL scheme
 @param moduleName  Extension module name

 @discussion
 有些第三方扩展需要打开其他应用（比如使用支付宝进行支付），然后等待返回结果。因此首先要为第三方扩展设置一个URL
 scheme并加入到info.plist中，然后再告诉该扩展模块scheme。
 
 *  \~english
 Set the URL scheme of the Extension Module.
  @param scheme      URL scheme.
 @param moduleName Extension module name.

 @ discussion
 Some third-party extensions shall open other applications (such as using Alipay to make payments) and wait for the results to be returned. So the first step is to set a URL scheme  for the third-party extension, add to the info.plist, and then inform the extension module scheme.
 */
- (void)setScheme:(NSString *)scheme forExtensionModule:(NSString *)moduleName;

/*!
 *  \~chinese
 第三方扩展处理openUrl

 @param url     url
 @return        YES处理，NO未处理。
 
 *  \~english
 Third-party extension for processing openUrl.

 @param url Url.
 @ return YES for processing, NO for no processing.
 */
- (BOOL)openExtensionModuleUrl:(NSURL *)url;

/*!
 *  \~chinese
 获取 SDK 版本号
 @return SDK 版本号
 
 *  \~english
 Get the SDK version number.
 @ return SDK version number
 */
+ (NSString *)getVersion;

@end
