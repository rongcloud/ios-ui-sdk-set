//
//  RCMessageCellNotificationModel.h
//  RongIMKit
//
//  Created by xugang on 15/1/29.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 *  \~chinese
 消息Cell需要更新的状态名
 
 *  \~english
 Status name updated by message Cell
 */
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_BEGIN;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_FAILED;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_SUCCESS;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_CANCELED;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_PROGRESS;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_DATA_IMAGE_KEY_UPDATE;
UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_HASREAD;

UIKIT_EXTERN NSString *const CONVERSATION_CELL_STATUS_SEND_READCOUNT;

#import <Foundation/Foundation.h>

/*!
 *  \~chinese
 消息Cell状态更新通知的数据模型
 
 *  \~english
 Data Model of message Cell status update notification
 */
@interface RCMessageCellNotificationModel : NSObject

/*!
 *  \~chinese
 消息ID
 
 *  \~english
 Message ID
 */
@property (nonatomic) long messageId;

/*!
 *  \~chinese
 更新的状态名
 
 *  \~english
 Updated status name
 */
@property (strong, nonatomic) NSString *actionName;

/*!
 *  \~chinese
 进度
 
 *  \~english
 Progress
 */
@property (nonatomic) NSInteger progress;

@end
