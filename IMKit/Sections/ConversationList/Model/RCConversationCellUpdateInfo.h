//
//  RCConversationCellUpdateInfo.h
//  RongIMKit
//
//  Created by 岑裕 on 16/9/11.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationModel.h"
#import <Foundation/Foundation.h>

UIKIT_EXTERN NSString *const RCKitConversationCellUpdateNotification;

typedef NS_ENUM(NSUInteger, RCConversationCellUpdateType) {
    RCConversationCell_MessageContent_Update = 1,
    RCConversationCell_SentStatus_Update = 2,
    RCConversationCell_ReceivedStatus_Update = 3,
    RCConversationCell_UnreadCount_Update = 4,
};

@interface RCConversationCellUpdateInfo : NSObject

@property (nonatomic, strong) RCConversationModel *model;
@property (nonatomic, assign) RCConversationCellUpdateType updateType;

@end
