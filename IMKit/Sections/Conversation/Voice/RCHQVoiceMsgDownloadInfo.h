//
//  RCHQVoiceMsgDownloadInfo.h
//  RongIMKit
//
//  Created by Zhaoqianyu on 2019/5/22.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    RCHQDownloadStatusWaiting = 0,
    RCHQDownloadStatusSuccess = 1,
    RCHQDownloadStatusDownloading = 2,
    RCHQDownloadStatusFailed = 3,
} RCHQDownloadStatus;

@interface RCHQVoiceMsgDownloadInfo : NSObject

@property (nonatomic, strong) RCMessage *hqVoiceMsg;

@property (nonatomic, assign) RCHQDownloadStatus status;

@end

NS_ASSUME_NONNULL_END
