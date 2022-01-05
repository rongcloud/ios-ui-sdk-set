//
//  RCUnknownMessageCell.h
//  RongIMKit
//
//  Created by xugang on 3/31/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCMessageBaseCell.h"

/*!
 *  \~chinese
 未知消息Cell
 
 *  \~english
 Unknown message Cell 
 */
@interface RCUnknownMessageCell : RCMessageBaseCell

/*!
 *  \~chinese
 提示的Label
 
 *  \~english
 Prompted label
 */
@property (strong, nonatomic) RCTipLabel *messageLabel;

/*!
 *  \~chinese
 设置当前消息Cell的数据模型

 @param model 消息Cell的数据模型
 
 *  \~english
 Set the data model of the current message Cell.

 @param model Data Model of message Cell.
 */
- (void)setDataModel:(RCMessageModel *)model;

@end
