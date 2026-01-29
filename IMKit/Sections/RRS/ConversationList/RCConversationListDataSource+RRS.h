//
//  RCConversationListDataSource+RRS.h
//  RongIMKit
//
//  Created by RobinCui on 2025/6/3.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCConversationListDataSource (RRS)
- (void)rrs_didReceiveMessageReadReceiptResponses:(NSArray<RCReadReceiptResponseV5 *> *)responses;
- (void)rrs_refreshCachedAndFetchReceiptInfo:(NSArray <RCConversationModel *>*)conversations;
@end

NS_ASSUME_NONNULL_END
