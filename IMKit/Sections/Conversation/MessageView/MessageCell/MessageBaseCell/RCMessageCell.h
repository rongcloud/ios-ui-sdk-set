//
//  RCMessageCell.h
//  RongIMKit
//
//  Created by xugang on 15/1/28.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCContentView.h"
#import "RCMessageBaseCell.h"
#import "RCMessageCellDelegate.h"
#import "RCMessageCellNotificationModel.h"
#import "RCThemeDefine.h"

#define HeadAndContentSpacing 8
#define PortraitViewEdgeSpace 12
#define NameAndContentSpace 2
#define NameHeight 14
@class RCloudImageView;

/*!
 *  \~chinese
 展示的消息Cell类

 @discussion 需要展示用户信息和内容的消息Cell可以继承此类，
 如：RCTextMessageCell、RCImageMessageCell、RCLocationMessageCell、RCVoiceMessageCell、RCRichContentMessageCell等。
 如果您需要显示自定义消息，可以继承此类。
 
 *  \~english
 Displayed message Cell class.

 @ discussion Messages that shall show user information and content Cell can inherit this class.
 E.g. RCTextMessageCell, RCImageMessageCell, RCLocationMessageCell, RCVoiceMessageCell, RCRichContentMessageCell and so on.
  If you shall display custom messages, you can inherit this class.
 */
@interface RCMessageCell : RCMessageBaseCell

/*!
 *  \~chinese
消息发送者的用户头像
 
 *  \~english
 User portrait of the message sender.
*/
@property (nonatomic, strong) RCloudImageView *portraitImageView;

/*!
 *  \~chinese
 消息发送者的用户名称
 
 *  \~english
 The user name of the sender of the message.
 */
@property (nonatomic, strong) UILabel *nicknameLabel;

/*!
 *  \~chinese
 消息内容的View
 
 *  \~english
 View of message content.
 */
@property (nonatomic, strong) RCContentView *messageContentView;

/*!
 *  \~chinese
 消息的背景View
 
 *  \~english
 Background View of the message.
 */
@property (nonatomic, strong) UIImageView *bubbleBackgroundView;

/*!
 *  \~chinese
 显示发送状态的View

 @discussion 其中包含messageFailedStatusView子View。
 
 *  \~english
 View showing sending status.

 @ discussion It contains the messageFailedStatusView child View.
 */
@property (nonatomic, strong) UIView *statusContentView;

/*!
 *  \~chinese
 显示发送失败状态的View
 
 *  \~english
 Display the View of the failed sending status.
 */
@property (nonatomic, strong) UIButton *messageFailedStatusView;

/*!
 *  \~chinese
 消息发送指示View
 
 *  \~english
 Message sending instruction View.
 */
@property (nonatomic, strong) UIActivityIndicatorView *messageActivityIndicatorView;

/*!
 *  \~chinese
 显示的用户头像形状
 
 *  \~english
 The shape of the user portrait displayed.
 */
@property (nonatomic, assign, setter=setPortraitStyle:) RCUserAvatarStyle portraitStyle;

/*!
 *  \~chinese
 显示是否消息回执的Button

 @discussion 仅在群组和讨论组中显示
 
 *  \~english
 Button that shows whether the message is received or not.

 @ discussion It is displayed only in groups and discussion groups.
 */
@property (nonatomic, strong) UIButton *receiptView;

/*!
 *  \~chinese
 消息阅读状态的 Label
 
 *  \~english
 Label of message reading status

 */
@property (nonatomic, strong) UILabel *receiptStatusLabel;

/*!
 *  \~chinese
 设置当前消息Cell的数据模型

 @param model 消息Cell的数据模型
 
 *  \~english
 Set the data model of the current message Cell.

 @param model Data Model of message Cell.
 */
- (void)setDataModel:(RCMessageModel *)model;

/*!
 *  \~chinese
 更新消息发送状态

 @param model 消息Cell的数据模型
 
 *  \~english
 Update message sending status.

 @param model Data Model of message Cell.
 */
- (void)updateStatusContentView:(RCMessageModel *)model;

/*!
 *  \~chinese
 是否显示消息的背景气泡 View

@param show 消息Cell的数据模型
 
 *  \~english
 Whether to display the background bubble View of the message.

 @param show Data Model of message Cell.
*/
- (void)showBubbleBackgroundView:(BOOL)show;

/*!
 *  \~chinese
阅后即焚的回调

@discussion 阅后即焚的消息，每过 1 秒都会触发该回调更新时间
 
 *  \~english
 Callback for burning immediately after reading.

 @ discussion It will trigger the callback to update time every 1 second after reading the burn-after-reading message.
*/
- (void)messageDestructing;

/*!
 *  \~chinese
阅后即焚的 UI 设置
 
 *  \~english
 UI settings for burn-after-reading
*/
- (void)setDestructViewLayout;

/*!
 *  \~chinese
点击消息视图 messageContentView 回调
 
 *  \~english
 Callback for clicking message View messageContentView
*/
- (void)didTapMessageContentView;
@end
