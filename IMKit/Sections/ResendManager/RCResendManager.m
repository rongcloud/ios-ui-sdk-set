//
//  RCResendManager.m
//  RongIMKit
//
//  Created by 孙浩 on 2020/6/1.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCResendManager.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@interface RCResendManager ()

@property (nonatomic, strong) NSMutableArray *messageIds;

@property (nonatomic, strong) RCTSMutableDictionary *messageCacheDict;

@property (nonatomic, strong) NSTimer *resendTimer;

@property (nonatomic, assign) BOOL isProcessing;

@property (nonatomic, strong) NSString *currentUserId;

@end

@implementation RCResendManager

+ (instancetype)sharedManager {
    static RCResendManager *resendManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (resendManager == nil) {
            resendManager = [[RCResendManager alloc] init];
        }
    });
    return resendManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.currentUserId = [RCIM sharedRCIM].currentUserInfo.userId;
        self.messageCacheDict = [[RCTSMutableDictionary alloc] init];
        self.messageIds = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onConnectionStatusChangedNotification:)
                                                     name:RCKitDispatchConnectionStatusChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)needResend:(long)messageId {
    NSString *key = [NSString stringWithFormat:@"%ld", messageId];
    if ([self.messageCacheDict valueForKey:key]) {
        return YES;
    }
    return NO;
}

- (BOOL)isResendErrorCode:(RCErrorCode)code {
    RCConnectionStatus status = [[RCIM sharedRCIM] getConnectionStatus];
    if (ConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT == status ||
        ConnectionStatus_SignOut == status ||
        ConnectionStatus_USER_ABANDON == status ||
        ConnectionStatus_PROXY_UNAVAILABLE == status){
        return NO;
    }
    if (code == RC_CHANNEL_INVALID ||
        code == RC_NETWORK_UNAVAILABLE ||
        code == RC_MSG_RESPONSE_TIMEOUT ||
        code == RC_FILE_UPLOAD_FAILED) {
        return YES;
    }
    return NO;
}

- (void)addResendMessageIfNeed:(long)messageId error:(RCErrorCode)code {
    dispatch_main_async_safe((^{
        if (RCKitConfigCenter.message.enableMessageResend && [self isResendErrorCode:code]) {
            NSString *key = [NSString stringWithFormat:@"%ld", messageId];
            if (![self.messageCacheDict objectForKey:key]) {
                RCMessage *message = [[RCIMClient sharedRCIMClient] getMessage:messageId];
                if(message != nil) {
                    [self.messageCacheDict setObject:message forKey:key];
                    [self.messageIds addObject:key];
                    [self beginResend];
                }
            }
        }
    }));
}

- (void)removeResendMessage:(long)messageId {
    //默认是在主线程
    NSString *key = [NSString stringWithFormat:@"%ld", messageId];
    [self.messageCacheDict removeObjectForKey:key];
    [self.messageIds removeObject:key];
    RCLogI(@"%s messageId is %ld", __FUNCTION__, messageId);
}

- (void)removeAllResendMessage {
    //默认是在主线程
    [self.messageCacheDict removeAllObjects];
    [self.messageIds removeAllObjects];
    self.isProcessing = NO;
}

- (void)beginResend {
    //默认是在主线程
    if (self.isProcessing) {
        return;
    }
    self.isProcessing = YES;
    [self sendAfterTimer];
}

//loop
- (void)sendAfterTimer {
    //默认是在主线程
    self.resendTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(sendFirstMessage) userInfo:nil repeats:NO];
}

- (void)sendFirstMessage {
    //默认是在主线程
    if (self.messageIds.count == 0) {
        self.isProcessing = NO;
        RCLogI(@"%s no message need resend", __FUNCTION__);
        return;
    }
    if ([[RCIM sharedRCIM] getConnectionStatus] != ConnectionStatus_Connected) {
        RCLogI(@"connectionStatus is not connected");
        self.isProcessing = NO;
        return;
    }
    NSString *messageId = [self.messageIds firstObject];
    RCMessage *message = self.messageCacheDict[messageId];
    RCLogI(@"%s messageId is %ld, message is %@", __FUNCTION__, message.messageId, message.objectName);
    [self resendMessage:message];
}

- (void)resendMessage:(RCMessage *)message {
    //默认是在主线程
    RCMessageContent *messageContent = message.content;
    if (message.targetId == nil || messageContent == nil) {
        RCLogI(@"%s targetId or messageContent is nil", __FUNCTION__);
        [self removeResendMessage:message.messageId];
        [self sendAfterTimer];
        return;
    }
    
    NSString *pushContent = nil;
    if (messageContent.destructDuration > 0) {
        pushContent = NSLocalizedStringFromTable(@"BurnAfterRead", @"RongCloudKit", nil);
    }
    
    if ([messageContent isKindOfClass:[RCMediaMessageContent class]]) {
        
        if ([messageContent isMemberOfClass:RCImageMessage.class]) {
            RCImageMessage *imageMessage = (RCImageMessage *)messageContent;
            if (imageMessage.imageUrl) {
                imageMessage.originalImage = [UIImage imageWithContentsOfFile:imageMessage.imageUrl];
            } else {
                imageMessage.originalImage = [UIImage imageWithContentsOfFile:imageMessage.localPath];
            }
        }
        
        [[RCIM sharedRCIM] sendMediaMessage:message pushContent:nil pushData:nil progress:nil successBlock:^(RCMessage *successMessage) {
            dispatch_main_async_safe(^{
                [self removeResendMessage:message.messageId];
                [self sendAfterTimer];
            });
        } errorBlock:^(RCErrorCode nErrorCode, RCMessage *errorMessage) {
            dispatch_main_async_safe(^{
                if (![self isResendErrorCode:nErrorCode]) {
                    [self removeResendMessage:message.messageId];
                    [self postSendMessageErrorNotification:errorMessage error: nErrorCode];
                }
                [self sendAfterTimer];
            });
        } cancel:^(RCMessage *cancelMessage) {
            dispatch_main_async_safe(^{
                [self removeResendMessage:cancelMessage.messageId];
                [self sendAfterTimer];
            });
        }];
    } else {
        [[RCIM sharedRCIM] sendMessage:message pushContent:nil pushData:nil successBlock:^(RCMessage *successMessage) {
            dispatch_main_async_safe(^{
                [self removeResendMessage:message.messageId];
                [self sendAfterTimer];
            });
        } errorBlock:^(RCErrorCode nErrorCode, RCMessage *errorMessage) {
            dispatch_main_async_safe(^{
                if (![self isResendErrorCode:nErrorCode]) {
                    [self removeResendMessage:message.messageId];
                    [self postSendMessageErrorNotification:errorMessage error: nErrorCode];
                }
                [self sendAfterTimer];
            });
        }];
    }
}

- (void)postSendMessageErrorNotification:(RCMessage *)message
                                   error:(RCErrorCode)nErrorCode {
    NSDictionary *statusDic = @{
        @"targetId" : message.targetId,
        @"conversationType" : @(message.conversationType),
        @"messageId" : @(message.messageId),
        @"sentStatus" : @(SentStatus_FAILED),
        @"error" : @(nErrorCode),
        @"content" : message.content,
        @"resend":@"resend"
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                        object:nil
                                                      userInfo:statusDic];
}

- (void)onConnectionStatusChangedNotification:(NSNotification *)status {
    dispatch_main_async_safe(^{
        RCLogI(@"connection status changed");
        RCConnectionStatus connectionStatus = [status.object integerValue];
        switch (connectionStatus) {
            case ConnectionStatus_Connected: {
                if ([self.currentUserId isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]){
                    if (!self.isProcessing) {
                        [self beginResend];
                    }
                }else{
                    self.currentUserId = [RCIM sharedRCIM].currentUserInfo.userId;
                    [self removeAllResendMessage];
                }
            } break;
            //Since 5.3.0 signout/timeout/proxy unavailable 直接显示发送失败
            //Since 5.3.1 kicked 直接显示发送失败
            case ConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT:
            case ConnectionStatus_SignOut:
            case ConnectionStatus_Timeout:
            case ConnectionStatus_PROXY_UNAVAILABLE: {
                [self removeAllResendMessage];
            } break;
            default:
                break;
        }
    });
}

@end
