//
//  RCConversationListViewController+RRS.h
//  RongIMKit
//
//  Created by RobinCui on 2025/6/4.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCConversationListViewController (RRS)
- (void)rrs_fetchReadReceiptInfoV5ForVisibleModel;
- (void)rrs_scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)rrs_scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
@end

NS_ASSUME_NONNULL_END
