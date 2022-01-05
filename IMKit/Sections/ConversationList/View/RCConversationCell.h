//
//  RCConversationCell.h
//  RongIMKit
//
//  Created by xugang on 15/1/24.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCConversationBaseCell.h"
#import "RCConversationDetailContentView.h"
#import "RCConversationStatusView.h"
#import "RCMessageBubbleTipView.h"
#import "RCThemeDefine.h"

#import <UIKit/UIKit.h>

#define CONVERSATION_ITEM_HEIGHT 65.0f
@protocol RCConversationCellDelegate;
@class RCloudImageView;

/*!
 *  \~chinese
 会话Cell类
 
 *  \~english
 Conversation Cell class 
 */
@interface RCConversationCell : RCConversationBaseCell

/*!
 *  \~chinese
 会话Cell的点击监听器
 
 *  \~english
 Click listener for conversation Cell
 */
@property (nonatomic, weak) id<RCConversationCellDelegate> delegate;

/*!
 *  \~chinese
 Cell的头像背景View
 
 *  \~english
 Cell's portrait background View
 */
@property (nonatomic, strong) UIView *headerImageViewBackgroundView;

/*!
 *  \~chinese
 Cell头像View
 
 *  \~english
 Cell portrait View
 */
@property (nonatomic, strong) RCloudImageView *headerImageView;

/*!
 *  \~chinese
 会话的标题
 
 *  \~english
 Title of the conversation
 */
@property (nonatomic, strong) UILabel *conversationTitle;

/*!
 *  \~chinese
 会话标题右侧的标签view
 
 *  \~english
 The label view to the right of the conversation title
 */
@property (nonatomic, strong) UIView *conversationTagView;

/*!
 *  \~chinese
 显示最后一条内容的Label
 
 *  \~english
 Show the label of the last item
 */
@property (nonatomic, strong) UILabel *messageContentLabel;

/*!
 *  \~chinese
 显示最后一条消息发送时间的Label
 
 *  \~english
 Label showing the time when the last message is sent
 */
@property (nonatomic, strong) UILabel *messageCreatedTimeLabel;

/*!
 *  \~chinese
 头像右上角未读消息提示的View
 
 *  \~english
 The View of the unread message prompt in the upper right corner of the portrait
 */
@property (nonatomic, strong) RCMessageBubbleTipView *bubbleTipView;

/*!
 *  \~chinese
 会话免打扰状态显示的View
 
 *  \~english
 View that displays conversation do not Disturb status
 */
@property (nonatomic, strong) UIImageView *conversationStatusImageView;

/*!
 *  \~chinese
 Cell中显示的头像形状

 @discussion 默认值为当前IMKit的全局设置值（RCIM中的globalConversationAvatarStyle）。
 
 *  \~english
 Avatar shape displayed in Cell.

 @ discussion The default value is the global setting of the current IMKit (globalConversationAvatarStyle in RCIM).
 */
@property (nonatomic, assign) RCUserAvatarStyle portraitStyle;

/*!
 *  \~chinese
 是否进行新消息提醒

 @discussion 此属性默认会根据会话设置的提醒状态进行设置。
 
 *  \~english
 Whether to make a new message reminder.

 @ discussion This property is set by default based on the reminder status set by the conversation.
 */
@property (nonatomic, assign) BOOL enableNotification;

/*!
 *  \~chinese
 会话中有未读消息时，是否在头像右上角的bubbleTipView中显示数字

 @discussion 默认值为YES。
 
 *  \~english
 RCConversationListViewController willDisplayConversationTableCell:atIndexPath: to set。
 Whether to display numbers in the bubbleTipView at the upper right corner of the portrait when there are unread messages in the conversation.

 @ discussion The default value is YES.
  You can set it in the willDisplayConversationTableCell:atIndexPath: Callback for RCConversationListViewController.
 */
@property (nonatomic, assign) BOOL isShowNotificationNumber;

/*!
 *  \~chinese
 是否在群组和讨论组会话Cell中隐藏发送者的名称
 
 *  \~english
 Whether to hide the sender's name in the group and discussion group conversation Cell.
 */
@property (nonatomic, assign) BOOL hideSenderName;

/*!
 *  \~chinese
 非置顶的Cell的背景颜色
 
 *  \~english
 Background color of untopped Cell.
 */
@property (nonatomic, strong) UIColor *cellBackgroundColor;

/*!
 *  \~chinese
 置顶Cell的背景颜色
 
 *  \~english
 The background color of the top Cell.
 */
@property (nonatomic, strong) UIColor *topCellBackgroundColor;

/*!
 *  \~chinese
 显示内容区的view
 
 *  \~english
 View that displays the content area
 */
@property (nonatomic, strong) RCConversationDetailContentView *detailContentView;

/*!
 *  \~chinese
 显示会话状态的view
 
 *  \~english
 View that displays the conversation state
 */
@property (nonatomic, strong) RCConversationStatusView *statusView;

/*!
 *  \~chinese
 设置Cell中显示的头像形状

 @param portraitStyle 头像形状

 @discussion 此设置仅当前会话Cell有效。
 
 *  \~english
 Set the shape of the portrait displayed in Cell.

 @param portraitStyle Avatar shape.

 @ discussion This setting is valid only for the current conversation Cell.
 */
- (void)setHeaderImagePortraitStyle:(RCUserAvatarStyle)portraitStyle;

/*!
 *  \~chinese
 设置当前会话Cell的数据模型

 @param model 会话Cell的数据模型
 
 *  \~english
 Set the data model for the current conversation Cell.

 @param model Data Model of conversation Cell.
 */
- (void)setDataModel:(RCConversationModel *)model;

@end

/*!
 *  \~chinese
 会话Cell的点击监听器
 
 *  \~english
 Click listener for conversation Cell
 */
@protocol RCConversationCellDelegate <NSObject>

/*!
 *  \~chinese
 点击Cell头像的回调

 @param model 会话Cell的数据模型
 
 *  \~english
 Callback for clicking the Cell portrait.

 @param model Data Model of conversation Cell.
 */
- (void)didTapCellPortrait:(RCConversationModel *)model;

/*!
 *  \~chinese
 长按Cell头像的回调

 @param model 会话Cell的数据模型
 
 *  \~english
 Callback for holding the cell portrait.

 @param model Data Model of conversation Cell.
 */
- (void)didLongPressCellPortrait:(RCConversationModel *)model;

@end
