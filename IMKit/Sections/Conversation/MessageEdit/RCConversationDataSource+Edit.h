//
//  RCConversationDataSource+Edit.h
//  RongIMKit
//
//  Created by Lang on 2025/7/26.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationDataSource.h"
#import <RongIMLibCore/RCErrorCode.h>
#import <RongIMLibCore/RCReferenceMessage.h>
@class RCMessageResult;

NS_ASSUME_NONNULL_BEGIN

@interface RCConversationDataSource (Edit)

/// 获取最新的引用消息，主要为了获取被引用消息的编辑状态和内容
- (void)edit_refreshReferenceMessage:(NSArray<RCMessage *> *)messages
                            complete:(void (^)(NSArray<RCMessage *> * messages))complete;

/// 更新被引用消息编辑状态，包含（撤回、删除等）
- (void)edit_setUIReferenceMessagesEditStatus:(RCReferenceMessageStatus)status
                        forMessageUIds:(NSArray<NSString *> *)messageUIds;

/// 更新消息已编辑的状态
- (void)edit_refreshUIMessagesEditedStatus:(NSArray<RCMessageModel *> *)models;

@end

NS_ASSUME_NONNULL_END
