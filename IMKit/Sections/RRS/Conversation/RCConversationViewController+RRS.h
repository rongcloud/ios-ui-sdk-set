//
//  RCConversationViewController+RRS.h
//  RongIMKit
//
//  Created by RobinCui on 2025/6/3.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationViewController.h"
#import <RongIMLibCore/RongIMLibCore.h>
NS_ASSUME_NONNULL_BEGIN

@interface RCConversationViewController (RRS)
- (void)rrs_observeReadReceiptV5;
- (void)rrs_didReceiveMessageReadReceiptResponses:(NSArray<RCReadReceiptResponseV5 *> *)responses;
@end

NS_ASSUME_NONNULL_END
