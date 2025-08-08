//
//  RCRRSDataContext.h
//  RongIMKit
//
//  Created by RobinCui on 2025/6/13.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCConversationModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCRRSDataContext : NSObject

/// 刷新已缓存数据的会执行系
/// - Parameter conversations: 会话列表
+ (void)refreshConversationsCachedIfNeeded:(NSArray <RCConversationModel *>*)conversations;


/// 使用会话的回执信息刷新缓存
/// - Parameter infoList: 回执信息
+ (void)refreshCacheWithResponse:(NSArray<RCReadReceiptResponseV5 *> *)infoList;
+ (void)refreshCacheWithReceiptInfo:(NSArray<RCReadReceiptInfoV5 *> *)infoList;
@end

NS_ASSUME_NONNULL_END
