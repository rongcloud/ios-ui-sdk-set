//
//  RCTextMessageCell.h
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCAttributedLabel.h"
#import "RCMessageCell.h"

#define Text_Message_Font_Size 17

/*!
 *  \~chinese
 文本消息Cell
 
 *  \~english
 Text message Cell 
 */
@interface RCTextMessageCell : RCMessageCell <RCAttributedLabelDelegate>

/*!
 *  \~chinese
 显示消息内容的Label
 
 *  \~english
 Label for displaying the contents of the message
 */
@property (strong, nonatomic) RCAttributedLabel *textLabel;

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
