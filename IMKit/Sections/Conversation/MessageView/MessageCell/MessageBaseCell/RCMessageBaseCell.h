//
//  RCMessageBaseCell.h
//  RongIMKit
//
//  Created by xugang on 15/1/28.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCMessageCellDelegate.h"
#import "RCMessageCellNotificationModel.h"
#import "RCMessageModel.h"
#import "RCTipLabel.h"
#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>

/*!
 *  \~chinese
 消息发送状态更新的Notification
 
 *  \~english
 Notification with message sending status updates. 
 */
UIKIT_EXTERN NSString *const KNotificationMessageBaseCellUpdateSendingStatus;

#define TIME_LABEL_HEIGHT 16
#define TIME_LABEL_AND_BASE_CONTENT_VIEW_SPACE 12
#define TIME_LABEL_TOP 8
#define BASE_CONTENT_VIEW_BOTTOM 20 

/*!
 *  \~chinese
 消息Cell基类

 @discussion 消息Cell基类包含了所有消息Cell的必要信息。
 消息Cell基类针对用户头像是否显示，主要可以分为两类的：
 一是提醒类的Cell，不显示用户信息，如：RCTipMessageCell和RCUnknownMessageCell；
 二是展示类的Cell，显示用户信息和内容，如：RCMessageCell以及RCMessageCell的子类。
 
 *  \~english
 Message Cell base class.

 @ discussion message Cell base class contains the necessary information for all message Cell.
  The message Cell base class can be divided into two categories, depending on whether the user's portrait is displayed:
  First, the reminder Cell does not display user information, e.g. RCTipMessageCell and RCUnknownMessageCell.
 Second, the display Cell displays user information and content, e.g. RCMessageCell and subclasses of RCMessageCell.
 */
@interface RCMessageBaseCell : UICollectionViewCell

#pragma mark - overwrite

/*!
 *  \~chinese
 自定义消息Cell的Size

 @param model               要显示的消息model
 @param collectionViewWidth cell所在的collectionView的宽度
 @param extraHeight         cell内容区域之外的高度

 @return 自定义消息Cell的Size

 @discussion 当应用自定义消息时，必须实现该方法来返回cell的Size。
 其中，extraHeight是Cell根据界面上下文，需要额外显示的高度（比如时间、用户名的高度等）。
 一般而言，Cell的高度应该是内容显示的高度再加上extraHeight的高度。
 
 *  \~english
 Size of custom message Cell.

 @param model  Message to display model.
 @param collectionViewWidth  The width of the collectionView where the cell is located.
 @param extraHeight  Height outside the cell content area.

 @ return Size of custom message Cell.

 @ discussion When applying custom messages, you must implement this method to return the Size of cell.
  Where extraHeight is the height that Cell shall display according to the interface context (such as time, height of user name, etc.).
  Generally speaking, the height of Cell should be the height of content display plus the height of extraHeight. 
 */
+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight;

/*!
 *  \~chinese
 消息Cell点击回调
 
 *  \~english
 Message Cell Click callback.
 */
@property (nonatomic, weak) id<RCMessageCellDelegate> delegate;

/*!
 *  \~chinese
 显示时间的Label
 
 *  \~english
 Display the tag of the time.
 */
@property (strong, nonatomic) RCTipLabel *messageTimeLabel;

/*!
 *  \~chinese
 消息Cell的数据模型
 
 *  \~english
 Data Model of message Cell
 */
@property (strong, nonatomic) RCMessageModel *model;

/*!
 *  \~chinese
 Cell显示的View
 
 *  \~english
 View displayed by Cell.
 */
@property (strong, nonatomic) UIView *baseContentView;

/*!
 *  \~chinese
 消息的方向
 
 *  \~english
 The direction of the message.
 */
@property (nonatomic) RCMessageDirection messageDirection;

/*!
 *  \~chinese
 时间Label是否显示
 
 *  \~english
 Does the time tag display.
 */
@property (nonatomic, readonly) BOOL isDisplayMessageTime;

/*!
 *  \~chinese
 是否显示阅读状态
 
 *  \~english
 Whether to display the reading status.
 */
@property (nonatomic) BOOL isDisplayReadStatus;

/*!
 *  \~chinese
 是否允许选择
 
 *  \~english
 Whether to allow selection.
 */
@property (nonatomic) BOOL allowsSelection;

/*!
 *  \~chinese
 初始化消息Cell

 @param frame 显示的Frame
 @return 消息Cell基类对象
 
 *  \~english
 Initialization message Cell.

 @param frame Displayed Frame.
 @ return message Cell base class object.
 */
- (instancetype)initWithFrame:(CGRect)frame;

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
 消息发送状态更新的监听回调

 @param notification 消息发送状态更新的Notification
 
 *  \~english
 listening callback for message sending status updates.

 @param notification Notification with message sending status updates.
 */
- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification;

@end
