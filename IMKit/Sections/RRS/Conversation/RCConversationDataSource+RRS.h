//
//  RCConversationDataSource+RRS.h
//  RongIMKit
//
//  Created by RobinCui on 2025/6/3.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCConversationDataSource (RRS)
- (void)rrs_fetchReadReceiptV5Info:(NSArray <RCMessageModel *>*)models;
- (void)rrs_responseReadReceiptV5Info:(NSDictionary *)dic;
@end

NS_ASSUME_NONNULL_END
