//
//  RCConversationBaseCell.h
//  RongIMKit
//
//  Created by xugang on 15/1/24.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCConversationModel.h"
#import <UIKit/UIKit.h>

/*!
 *  \~chinese
 会话Cell基类
 
 *  \~english
 Base class of conversation Cell 
 */
@interface RCConversationBaseCell : UITableViewCell

/*!
 *  \~chinese
 会话Cell的数据模型
 
 *  \~english
 Data Model of conversation Cell
 */
@property (nonatomic, strong) RCConversationModel *model;

/*!
 *  \~chinese
 设置会话Cell的数据模型

 @param model 会话Cell的数据模型
 
 *  \~english
 Set the data model for the conversation Cell.

 @param model Data Model of conversation Cell.
 */
- (void)setDataModel:(RCConversationModel *)model;

@end
