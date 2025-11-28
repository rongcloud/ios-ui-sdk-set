//
//  RCMessageModel+RRS.h
//  RongIMKit
//
//  Created by RobinCui on 2025/6/3.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import"RCMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCMessageModel (RRS)
- (BOOL)rrs_shouldResponseReadReceiptV5;
- (BOOL)rrs_shouldFetchReadReceiptV5;
@end

NS_ASSUME_NONNULL_END
