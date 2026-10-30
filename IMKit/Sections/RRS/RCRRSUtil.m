//
//  RCRRSUtil.m
//  RongIMKit
//
//  Created by Lang on 10/15/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCRRSUtil.h"
#import <RongIMLibCore/RongIMLibCore.h>

@interface RCReadReceiptInfoV5 ()

/// 会话标识。
@property (nonatomic, strong) RCConversationIdentifier *identifier;

/// 消息唯一 ID。
@property (nonatomic, copy) NSString *messageUId;

/// 未读人数。
@property (nonatomic, assign) NSInteger unreadCount;

/// 已读人数。
@property (nonatomic, assign) NSInteger readCount;

/// 总人数。
@property (nonatomic, assign) NSInteger totalCount;

@end

NS_ASSUME_NONNULL_BEGIN

@implementation RCRRSUtil

+ (RCReadReceiptInfoV5 *)infoFromResponse:(RCReadReceiptResponseV5 *)response {
    if (!response) {
        return nil;
    }
    
    RCReadReceiptInfoV5 *info = [[RCReadReceiptInfoV5 alloc] init];
    info.identifier = response.identifier;
    info.messageUId = response.messageUId;
    info.readCount = response.readCount;
    info.unreadCount = response.unreadCount;
    info.totalCount = response.totalCount;
    return info;
}

+ (BOOL)isSupportReadReceiptV5 {
    return [[RCCoreClient sharedCoreClient] getAppSettings].readReceiptVersion == RCMessageReadReceiptVersion5;
}

@end

NS_ASSUME_NONNULL_END
