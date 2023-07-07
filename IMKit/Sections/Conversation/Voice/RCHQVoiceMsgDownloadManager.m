//
//  RCHQVoiceMsgDownloadManager.m
//  RongIMKit
//
//  Created by Zhaoqianyu on 2019/5/22.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCHQVoiceMsgDownloadManager.h"
#import "RCHQVoiceMsgDownloadInfo.h"
#import "RongIMKit.h"

@interface RCHQVoiceMsgDownloadManager ()

/* UID: all RCHQVoiceMsgDownloadInfo*/

@property (nonatomic, strong) NSMutableDictionary *downloadInfos;

// RCMessage Un
@property (nonatomic, strong) NSMutableArray *downloadMsgs;

// RCMessages
@property (nonatomic, strong) NSMutableArray *priorityMsgs;

@property (nonatomic, strong) NSMutableArray *failedMsgs;

@property (nonatomic, assign) RCNetworkStatus status;

@end

@implementation RCHQVoiceMsgDownloadManager
#pragma mark - Public Methods
+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static RCHQVoiceMsgDownloadManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [RCHQVoiceMsgDownloadManager new];
        manager.downloadInfos = [NSMutableDictionary new];
        manager.downloadMsgs = [NSMutableArray new];
        manager.priorityMsgs = [NSMutableArray new];
        manager.failedMsgs = [NSMutableArray new];
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(networkChanged:)
                                                     name:@"kRCNetworkReachabilityChangedNotification"
                                                   object:nil];
        manager.status = RC_ReachableViaWiFi;
    });
    return manager;
}

- (void)pushVoiceMsgs:(NSArray<RCMessage *> *)voiceMsgs priority:(BOOL)priority {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self pushItemToDataSource:voiceMsgs priority:priority];
        if (self.downloadInfos.allKeys.count == 1) {
            [self startDownload];
        }
    });
}

#pragma mark - Private Methods

- (void)pushItemToDataSource:(NSArray<RCMessage *> *)voiceMsgs priority:(BOOL)priority {
    for (int i = 0; i < voiceMsgs.count; i++) {
        RCMessage *voiceMsg = voiceMsgs[i];
        if ([self.downloadInfos objectForKey:voiceMsg.messageUId]) {
            continue;
        }
        RCHQVoiceMsgDownloadInfo *info = [RCHQVoiceMsgDownloadInfo new];
        info.hqVoiceMsg = voiceMsg;
        info.status = RCHQDownloadStatusWaiting;
        if ([voiceMsg.content isKindOfClass:RCHQVoiceMessage.class]) {
            RCHQVoiceMessage *hqMsg = (RCHQVoiceMessage *)voiceMsg.content;
            if (hqMsg.remoteUrl.length <= 0) {
                info.status = RCHQDownloadStatusFailed;
                [[NSNotificationCenter defaultCenter] postNotificationName:RCHQDownloadStatusChangeNotify object:info];
                continue;
            }
        }
        [self.downloadInfos setObject:info forKey:voiceMsg.messageUId];
        if (priority) {
            [self.priorityMsgs addObject:voiceMsg];
        } else {
            [self.downloadMsgs addObject:voiceMsg];
        }
        if (self.priorityMsgs.count + self.downloadMsgs.count > 100) {
            if (self.downloadMsgs.count > 0) {
                [self.downloadMsgs removeObjectAtIndex:0];
            } else {
                [self.priorityMsgs removeObjectAtIndex:0];
            }
        }
    }
}

- (void)startDownload:(int)times {
    __block RCMessage *downloadMsg = nil;
    NSUInteger priority = 0;
    if (self.priorityMsgs.count > 0) {
        downloadMsg = self.priorityMsgs.lastObject;
        priority = 1;
    } else if (self.downloadMsgs.count > 0) {
        priority = 2;
        downloadMsg = self.downloadMsgs.firstObject;
    } else {
        priority = 3;
        downloadMsg = self.failedMsgs.firstObject;
    }
    if (downloadMsg) {
        if ([[RCIMClient sharedRCIMClient] getCurrentNetworkStatus] != RC_NotReachable) {
            __block RCHQVoiceMsgDownloadInfo *info = [self.downloadInfos objectForKey:downloadMsg.messageUId];
            info.status = RCHQDownloadStatusDownloading;
            [[NSNotificationCenter defaultCenter] postNotificationName:RCHQDownloadStatusChangeNotify object:info];
            [[RCIM sharedRCIM] downloadMediaMessage:downloadMsg.messageId
                progress:^(int progress) {

                }
                success:^(NSString *mediaPath) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        info.status = RCHQDownloadStatusSuccess;
                        ((RCHQVoiceMessage *)info.hqVoiceMsg.content).localPath = mediaPath;
                        [[NSNotificationCenter defaultCenter] postNotificationName:RCHQDownloadStatusChangeNotify
                                                                            object:info];
                        [self downloadEnd:downloadMsg priority:priority];
                    });
                }
                error:^(RCErrorCode errorCode) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        info.status = RCHQDownloadStatusFailed;
                        [[NSNotificationCenter defaultCenter] postNotificationName:RCHQDownloadStatusChangeNotify
                                                                            object:info];
                        if (priority) {
                            [self.priorityMsgs removeObject:downloadMsg];
                        } else {
                            [self.downloadMsgs removeObject:downloadMsg];
                        }
                        [self.failedMsgs addObject:downloadMsg];

                        if (times >= 0) {
                            [self startDownload:times - 1];
                        } else {
                            [self removeDownloadInfo:downloadMsg priority:priority];
                        }
                    });
                }
                cancel:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        info.status = RCHQDownloadStatusFailed;
                        [[NSNotificationCenter defaultCenter] postNotificationName:RCHQDownloadStatusChangeNotify
                                                                            object:info];
                        [self removeDownloadInfo:downloadMsg priority:priority];
                    });
                }];
        } else {
            __block RCHQVoiceMsgDownloadInfo *info = [self.downloadInfos objectForKey:downloadMsg.messageUId];
            info.status = RCHQDownloadStatusFailed;
            [[NSNotificationCenter defaultCenter] postNotificationName:RCHQDownloadStatusChangeNotify object:info];
        }
    }
}

- (void)startDownload {
    [self startDownload:2];
}

- (void)downloadEnd:(RCMessage *)downloadMsg priority:(NSInteger)priority {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (priority == 1) {
            [self.priorityMsgs removeObject:downloadMsg];
        } else if (priority == 2) {
            [self.downloadMsgs removeObject:downloadMsg];
        } else {
            [self.failedMsgs removeObject:downloadMsg];
        }
        [self.downloadInfos removeObjectForKey:downloadMsg.messageUId];
        [self startDownload];
    });
}

- (void)removeDownloadInfo:(RCMessage *)downloadMsg priority:(NSInteger)priority {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (priority == 1) {
            [self.priorityMsgs removeObject:downloadMsg];
        } else if (priority == 2) {
            [self.downloadMsgs removeObject:downloadMsg];
        } else {
            [self.failedMsgs removeObject:downloadMsg];
        }
        [self.downloadInfos removeObjectForKey:downloadMsg.messageUId];
        [self startDownload];
    });
}

- (void)networkChanged:(NSNotification *)note {
    RCNetworkStatus status = [[RCIMClient sharedRCIMClient] getCurrentNetworkStatus];
    self.status = status;
    if (status != RC_NotReachable) {
        [self startDownload];
    }
}

@end
