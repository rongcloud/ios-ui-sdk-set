//
//  RCConversationModel+RRS.h
//  RongIMKit
//
//  Created by RobinCui on 2025/6/13.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationModel.h"
#import <RongIMLibCore/RongIMLibCore.h>
NS_ASSUME_NONNULL_BEGIN

@interface RCConversationModel (RRS)

/// 是否可以获取回执信息
- (BOOL)rrs_couldFetchConversationReadReceipt;

/// 是否应该获取回执信息
- (BOOL)rrs_shouldFetchConversationReadReceipt;

/// 消息标识
- (RCMessageIdentifier *)rrs_messageIdentifier;
@end

NS_ASSUME_NONNULL_END
