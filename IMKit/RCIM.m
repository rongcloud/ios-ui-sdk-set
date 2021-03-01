//
//  RCIM.m
//  RongIMKit
//
//  Created by xugang on 15/1/13.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCIM.h"
#import "RCKitUtility.h"
#import "RCLocalNotification.h"
#import "RCOldMessageNotificationMessage.h"
#import "RCSystemSoundPlayer.h"
#import "RCUserInfoCacheManager.h"
#import "RCUserInfoUpdateMessage.h"
#import "RongExtensionKit.h"
#import "RongIMKitExtensionManager.h"
#import "RCHQVoiceMsgDownloadManager.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#import "RCIM+Deprecated.h"
#import <AVFoundation/AVFoundation.h>
#import "RCResendManager.h"
#import <RongDiscussion/RongDiscussion.h>
#import <RongPublicService/RongPublicService.h>

NSString *const RCKitDispatchMessageNotification = @"RCKitDispatchMessageNotification";
NSString *const RCKitDispatchTypingMessageNotification = @"RCKitDispatchTypingMessageNotification";
NSString *const RCKitSendingMessageNotification = @"RCKitSendingMessageNotification";
NSString *const RCKitDispatchConnectionStatusChangedNotification = @"RCKitDispatchConnectionStatusChangedNotification";
NSString *const RCKitDispatchRecallMessageNotification = @"RCKitDispatchRecallMessageNotification";

NSString *const RCKitDispatchDownloadMediaNotification = @"RCKitDispatchDownloadMediaNotification";
NSString *const RCKitDispatchMessageReceiptRequestNotification = @"RCKitDispatchMessageReceiptRequestNotification";

NSString *const RCKitDispatchMessageReceiptResponseNotification = @"RCKitDispatchMessageReceiptResponseNotification";
NSString *const RCKitMessageDestructingNotification = @"RCKitMessageDestructingNotification";
NSString *const RCKitDispatchConversationStatusChangeNotification =
    @"RCKitDispatchConversationStatusChangeNotification";

@interface RCIM () <RCIMClientReceiveMessageDelegate, RCConnectionStatusChangeDelegate, RCMessageDestructDelegate,
                    RCConversationStatusChangeDelegate>
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, strong) NSDate *notificationQuietBeginTime;
@property (nonatomic, strong) NSDate *notificationQuietEndTime;
@property (nonatomic, assign) BOOL hasNotifydExtensionModuleUserId;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, strong) NSMutableArray *downloadingMeidaMessageIds;

@end

static RCIM *__rongUIKit = nil;
@implementation RCIM

+ (instancetype)sharedRCIM {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (__rongUIKit == nil) {
            __rongUIKit = [[RCIM alloc] init];
            __rongUIKit.userInfoDataSource = nil;
            __rongUIKit.groupUserInfoDataSource = nil;
            __rongUIKit.groupInfoDataSource = nil;
            __rongUIKit.receiveMessageDelegate = nil;
            __rongUIKit.enableMessageAttachUserInfo = NO;
            __rongUIKit.enablePersistentUserInfoCache = NO;
            __rongUIKit.hasNotifydExtensionModuleUserId = NO;
            __rongUIKit.automaticDownloadHQVoiceMsgEnable = YES;
            __rongUIKit.downloadingMeidaMessageIds = [[NSMutableArray alloc] init];
            [[RongIMKitExtensionManager sharedManager] loadAllExtensionModules];
        }
    });
    return __rongUIKit;
}

- (void)setCurrentUserInfo:(RCUserInfo *)currentUserInfo {
    [[RCIMClient sharedRCIMClient] setCurrentUserInfo:currentUserInfo];
    if (currentUserInfo) {
        [[RCUserInfoCacheManager sharedManager] updateUserInfo:currentUserInfo forUserId:currentUserInfo.userId];
        [RCUserInfoCacheManager sharedManager].currentUserId = currentUserInfo.userId;
    }
}

- (RCUserInfo *)currentUserInfo {
    return [RCIMClient sharedRCIMClient].currentUserInfo;
}

- (void)setGroupUserInfoDataSource:(id<RCIMGroupUserInfoDataSource>)groupUserInfoDataSource {
    _groupUserInfoDataSource = groupUserInfoDataSource;
    if (groupUserInfoDataSource) {
        [RCUserInfoCacheManager sharedManager].groupUserInfoEnabled = YES;
    }
}

- (void)initWithAppKey:(NSString *)appKey {
    if ([self.appKey isEqual:appKey]) {
        NSLog(@"Warning:请不要重复调用Init！！！");
        return;
    }

    self.appKey = appKey;
    [[RCIMClient sharedRCIMClient] initWithAppKey:appKey];

    [self registerMessageType:[RCOldMessageNotificationMessage class]];
    // listen receive message
    [[RCIMClient sharedRCIMClient] setReceiveMessageDelegate:self object:nil];
    [[RCIMClient sharedRCIMClient] setRCConnectionStatusChangeDelegate:self];
    [[RCIMClient sharedRCIMClient] setRCMessageDestructDelegate:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetNotificationQuietStatus)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetNotificationQuietStatus)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetNotificationQuietStatus)
                                                 name:@"RCLibDispatchResetNotificationQuietStatusNotification"
                                               object:nil];

    [self registerMessageType:RCUserInfoUpdateMessage.class];
    [RCUserInfoCacheManager sharedManager].appKey = appKey;

    [[RongIMKitExtensionManager sharedManager] initWithAppKey:appKey];
    [[RCIMClient sharedRCIMClient] setRCConversationStatusChangeDelegate:self];
}

- (void)resetNotificationQuietStatus {
    [[RCIMClient sharedRCIMClient] getNotificationQuietHours:^(NSString *startTime, int spansMin) {
        NSDateFormatter *dateFormatter = [self getDateFormatter];
        if (startTime && startTime.length != 0) {
            self.notificationQuietBeginTime = [dateFormatter dateFromString:startTime];
            self.notificationQuietEndTime = [self.notificationQuietBeginTime dateByAddingTimeInterval:spansMin * 60];
        } else {
            self.notificationQuietBeginTime = nil;
            self.notificationQuietEndTime = nil;
        }
    }
        error:^(RCErrorCode status){

        }];
}

- (BOOL)checkNoficationQuietStatus {
    BOOL isNotificationQuiet = NO;
    if (self.notificationQuietBeginTime && self.notificationQuietEndTime) {
        NSDateFormatter *dateFormatter = [self getDateFormatter];
        NSString *nowDateString = [dateFormatter stringFromDate:[NSDate date]];
        NSDate *nowDate = [dateFormatter dateFromString:nowDateString];
        long long beginTime = self.notificationQuietBeginTime.timeIntervalSince1970;
        long long nowTime = nowDate.timeIntervalSince1970;
        long long endTime = self.notificationQuietEndTime.timeIntervalSince1970;
        if (nowTime < beginTime) {
            nowTime = nowTime + 24 * 60 * 60;
        }
        if (nowTime > beginTime && nowTime < endTime) {
            isNotificationQuiet = YES;
        }
    }
    return isNotificationQuiet;
}

- (NSDateFormatter *)getDateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm:ss"];
    });
    return dateFormatter;
}

- (void)registerMessageType:(Class)messageClass {
    [[RCIMClient sharedRCIMClient] registerMessageType:messageClass];
}

- (void)connectWithToken:(NSString *)token
                dbOpened:(void (^)(RCDBErrorCode code))dbOpenedBlock
                 success:(void (^)(NSString *userId))successBlock
                   error:(void (^)(RCConnectErrorCode status))errorBlock {
    [self connectWithToken:token timeLimit:-1 dbOpened:dbOpenedBlock success:successBlock error:errorBlock];
}

- (void)connectWithToken:(NSString *)token
               timeLimit:(int)timeLimit
                dbOpened:(void (^)(RCDBErrorCode code))dbOpenedBlock
                 success:(void (^)(NSString *userId))successBlock
                   error:(void (^)(RCConnectErrorCode errorCode))errorBlock {
    self.hasNotifydExtensionModuleUserId = NO;
    self.token = token;
    [[RCIMClient sharedRCIMClient] connectWithToken:token
        timeLimit:timeLimit
        dbOpened:^(RCDBErrorCode code) {
            if (dbOpenedBlock != nil) {
                dbOpenedBlock(code);
            }
        }
        success:^(NSString *userId) {
            [RCUserInfoCacheManager sharedManager].currentUserId = userId;
            if (successBlock) {
                successBlock(userId);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!self.hasNotifydExtensionModuleUserId) {
                    self.hasNotifydExtensionModuleUserId = YES;
                    NSString *userId = [[RCIMClient sharedRCIMClient].currentUserInfo.userId copy];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [[RongIMKitExtensionManager sharedManager] didConnect:userId];
                    });
                }
            });
        }
        error:^(RCConnectErrorCode status) {
            NSString *userId = [[RCIMClient sharedRCIMClient].currentUserInfo.userId copy];
            if (userId) {
                [RCUserInfoCacheManager sharedManager].currentUserId = userId;
            }
            if (errorBlock != nil)
                errorBlock(status);
        }];
    if ([RCIMClient sharedRCIMClient].currentUserInfo.userId.length > 0) {
        self.currentUserInfo = [RCIMClient sharedRCIMClient].currentUserInfo;
    }
}

/**
 *  断开连接。
 *
 *  @param isReceivePush 是否接收回调。
 */
- (void)disconnect:(BOOL)isReceivePush {
    self.hasNotifydExtensionModuleUserId = NO;
    [[RongIMKitExtensionManager sharedManager] didDisconnect];
    [[RCIMClient sharedRCIMClient] disconnect:isReceivePush];
}

/**
 *  断开连接。
 */
- (void)disconnect {
    [self disconnect:YES];
}

/**
 *  Log out。不会接收到push消息。
 */
- (void)logout {
    [self disconnect:NO];
}

- (void)postLocalNotificationIfNeed:(RCMessage *)message {
    if (message.isOffLine || message.messageConfig.disableNotification) {
        return;
    }
    NSDictionary *dictionary = [RCKitUtility getNotificationUserInfoDictionary:message];
    if ([RCIMClient sharedRCIMClient].sdkRunningMode == RCSDKRunningMode_Background) {
        if (message.content.mentionedInfo.isMentionedMe) {
            [[RCLocalNotification defaultCenter] postLocalNotificationWithMessage:message userInfo:dictionary];
        } else {
            if (!RCKitConfigCenter.message.disableMessageNotificaiton && ![self checkNoficationQuietStatus]) {
                if (message.conversationType == ConversationType_Encrypted) {
                    [[RCLocalNotification defaultCenter]
                        postLocalNotification:RCLocalizedString(@"receive_new_message")
                                     userInfo:dictionary];
                } else {
                    [[RCIMClient sharedRCIMClient] getConversationNotificationStatus:message.conversationType
                        targetId:message.targetId
                        success:^(RCConversationNotificationStatus nStatus) {
                            if (NOTIFY == nStatus) {
                                [[RCLocalNotification defaultCenter] postLocalNotificationWithMessage:message userInfo:dictionary];
                            }
                        }
                        error:^(RCErrorCode status){

                        }];
                }
            }
        }
    }
}

- (void)onReceived:(RCMessage *)message left:(int)nLeft object:(id)object {

    if ([self.receiveMessageDelegate respondsToSelector:@selector(interceptMessage:)]) {
        if ([self.receiveMessageDelegate interceptMessage:message]) {
            return;
        }
    }
    if (!message) {
        return;
    }
    if (message.content.senderUserInfo.userId) {
        if (![message.content.senderUserInfo.userId
                isEqualToString:[RCIMClient sharedRCIMClient].currentUserInfo.userId]) {
            if (message.content.senderUserInfo.name.length > 0 ||
                message.content.senderUserInfo.portraitUri.length > 0) {
                if (message.content.senderUserInfo.portraitUri == nil ||
                    [RCUtilities isLocalPath:message.content.senderUserInfo.portraitUri]) {
                    RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager]
                        getUserInfoFromCacheOnly:message.content.senderUserInfo.userId];
                    if (userInfo) {
                        message.content.senderUserInfo.portraitUri = [userInfo.portraitUri copy];
                    }
                }
                [[RCUserInfoCacheManager sharedManager] updateUserInfo:message.content.senderUserInfo
                                                             forUserId:message.content.senderUserInfo.userId];
            }
        }
    }

    if ([message.content isMemberOfClass:[RCUserInfoUpdateMessage class]]) {
        RCUserInfoUpdateMessage *userInfoMesasge = (RCUserInfoUpdateMessage *)message.content;
        if ([userInfoMesasge.userInfoList count] > 0) {
            for (RCUserInfo *userInfo in userInfoMesasge.userInfoList) {
                if (![userInfo.userId isEqualToString:[RCIMClient sharedRCIMClient].currentUserInfo.userId] &&
                    ![[RCUserInfoCacheManager sharedManager] getUserInfo:userInfo.userId]) {
                    if (userInfo.name.length > 0 || userInfo.portraitUri.length > 0) {
                        [[RCUserInfoCacheManager sharedManager] updateUserInfo:userInfo forUserId:userInfo.userId];
                    }
                }
            }
        }
        return;
    }

    if ([message.content isKindOfClass:RCHQVoiceMessage.class] && nLeft == 0 &&
        self.automaticDownloadHQVoiceMsgEnable) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[RCHQVoiceMsgDownloadManager defaultManager] pushVoiceMsgs:@[ message ] priority:NO];
        });
    }

    if (message.conversationType == ConversationType_APPSERVICE ||
        message.conversationType == ConversationType_PUBLICSERVICE) {
        if (![RCIM sharedRCIM].publicServiceInfoDataSource) {
            if (![[RCIMClient sharedRCIMClient] getConversation:message.conversationType targetId:message.targetId]) {
                //如果收到了公众账号消息, 但是没有取到相应的公众账号信息, 导致没有创建会话, 这时候先不进行任何UI刷新
                return;
            }
        }
    }

    NSDictionary *dic_left = @{ @"left" : @(nLeft) };
    if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMReceiveMessage:left:)]) {
        [self.receiveMessageDelegate onRCIMReceiveMessage:message left:nLeft];
    }

    // dispatch message
    [[RongIMKitExtensionManager sharedManager] onMessageReceived:message];

    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchMessageNotification
                                                        object:message
                                                      userInfo:dic_left];
    //发出去的消息，不需要本地铃声和通知
    if (message.messageDirection == MessageDirection_SEND) {
        return;
    }

    BOOL isCustomMessageAlert = YES;

    if (!([[message.content class] persistentFlag] & MessagePersistent_ISPERSISTED)) {
        isCustomMessageAlert = NO;
    }
    if (RCKitConfigCenter.message.showUnkownMessageNotificaiton && message.messageId > 0 && !message.content) {
        isCustomMessageAlert = YES;
    }
    if (0 == nLeft && [RCIMClient sharedRCIMClient].sdkRunningMode == RCSDKRunningMode_Foreground &&
        !RCKitConfigCenter.message.disableMessageAlertSound && ![self checkNoficationQuietStatus] && isCustomMessageAlert) {
        //获取接受到会话
        if ([[RongIMKitExtensionManager sharedManager] handleAlertForMessageReceived:message]) {
            return;
        }
        if (message.content.mentionedInfo.isMentionedMe) {
            BOOL appConsumed = NO;
            if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomAlertSound:)]) {
                appConsumed = [self.receiveMessageDelegate onRCIMCustomAlertSound:message];
            }
            if (!appConsumed) {
                // 非讨论组通知消息，并且消息未设置为静默才响铃
                if (![message.content isKindOfClass:[RCDiscussionNotificationMessage class]] && !message.messageConfig.disableNotification) {
                    [[RCSystemSoundPlayer defaultPlayer] playSoundByMessage:message
                                                              completeBlock:^(BOOL complete) {
                        if (complete) {
                            [self setExclusiveSoundPlayer];
                        }
                    }];
                }
            }
        } else {
            
            [[RCIMClient sharedRCIMClient] getConversationNotificationStatus:message.conversationType
                                                                    targetId:message.targetId
                                                                     success:^(RCConversationNotificationStatus nStatus) {
                
                if (NOTIFY == nStatus) {
                    BOOL appComsumed = NO;
                    if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomAlertSound:)]) {
                        appComsumed = [self.receiveMessageDelegate onRCIMCustomAlertSound:message];
                    }
                    if (!appComsumed) {
                        
                        if (![message.content isKindOfClass:[RCDiscussionNotificationMessage class]] && !message.messageConfig.disableNotification) {
                            [[RCSystemSoundPlayer defaultPlayer] playSoundByMessage:message
                                                                      completeBlock:^(BOOL complete) {
                                if (complete) {
                                    [self setExclusiveSoundPlayer];
                                }
                            }];
                        }
                    }
                }
                
            }
                                                                       error:^(RCErrorCode status){
                
            }];
        }
    }
    if (nLeft == 0 && isCustomMessageAlert) {
        //聊天室消息不做本地通知
        if (ConversationType_CHATROOM == message.conversationType)
            return;
        [self postLocalNotificationIfNeed:message];
    }
}

- (void)setExclusiveSoundPlayer {
    if (RCKitConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance] setActive:NO
                                       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }
}

- (void)messageDidRecall:(RCMessage *)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchRecallMessageNotification
                                                        object:@(message.messageId)
                                                      userInfo:nil];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMMessageRecalled:)]) {
        [self.receiveMessageDelegate onRCIMMessageRecalled:message.messageId];
    }
#pragma clang diagnostic pop
    
    if ([self.receiveMessageDelegate respondsToSelector:@selector(messageDidRecall:)]) {
        [self.receiveMessageDelegate messageDidRecall:message];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self postLocalNotificationIfNeed:message];
    });
}

- (void)onMessageReceiptResponse:(RCConversationType)conversationType
                        targetId:(NSString *)targetId
                      messageUId:(NSString *)messageUId
                      readerList:(NSDictionary *)userIdList {
    NSDictionary *statusDic = @{
        @"targetId" : targetId,
        @"conversationType" : @(conversationType),
        @"messageUId" : messageUId,
        @"readerList" : userIdList
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchMessageReceiptResponseNotification
                                                        object:statusDic
                                                      userInfo:nil];
}

- (void)onMessageReceiptRequest:(RCConversationType)conversationType
                       targetId:(NSString *)targetId
                     messageUId:(NSString *)messageUId {
    if (messageUId) {
        NSDictionary *statusDic =
            @{ @"targetId" : targetId,
               @"conversationType" : @(conversationType),
               @"messageUId" : messageUId };
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchMessageReceiptRequestNotification
                                                            object:statusDic
                                                          userInfo:nil];
    }
}

/**
 *  网络状态变化。
 *
 *  @param status 网络状态。
 */
- (void)onConnectionStatusChanged:(RCConnectionStatus)status {
    if (status == ConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT || status == ConnectionStatus_SignOut ||
        status == ConnectionStatus_TOKEN_INCORRECT) {
        self.hasNotifydExtensionModuleUserId = NO;
        [[RongIMKitExtensionManager sharedManager] didDisconnect];
    }

    if (ConnectionStatus_NETWORK_UNAVAILABLE != status && ConnectionStatus_UNKNOWN != status &&
        ConnectionStatus_Unconnected != status) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchConnectionStatusChangedNotification
                                                            object:[NSNumber numberWithInteger:status]];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(delayNotifyUnConnectedStatus) withObject:nil afterDelay:5];
        });
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == ConnectionStatus_Connected && !self.hasNotifydExtensionModuleUserId) {
            self.hasNotifydExtensionModuleUserId = YES;
            NSString *userId = [[RCIMClient sharedRCIMClient].currentUserInfo.userId copy];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[RongIMKitExtensionManager sharedManager] didConnect:userId];
            });
        }
    });

    if ([self.connectionStatusDelegate respondsToSelector:@selector(onRCIMConnectionStatusChanged:)]) {
        [self.connectionStatusDelegate onRCIMConnectionStatusChanged:status];
    }
}

/*!
 获取当前SDK的连接状态

 @return 当前SDK的连接状态
 */
- (RCConnectionStatus)getConnectionStatus {
    return [[RCIMClient sharedRCIMClient] getConnectionStatus];
}

- (void)delayNotifyUnConnectedStatus {
    RCConnectionStatus status = [[RCIMClient sharedRCIMClient] getConnectionStatus];
    if (ConnectionStatus_NETWORK_UNAVAILABLE == status || ConnectionStatus_UNKNOWN == status ||
        ConnectionStatus_Unconnected == status) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchConnectionStatusChangedNotification
                                                            object:[NSNumber numberWithInteger:status]];
    }
}

#pragma mark - UserInfo&GroupInfo&GroupUserInfo
- (void)setenablePersistentUserInfoCache:(BOOL)enablePersistentUserInfoCache {
    _enablePersistentUserInfoCache = enablePersistentUserInfoCache;
    NSString *userId = [[RCIMClient sharedRCIMClient].currentUserInfo.userId copy];
    if (enablePersistentUserInfoCache && userId) {
        [RCUserInfoCacheManager sharedManager].currentUserId = userId;
    }
}

- (RCUserInfo *)getUserInfoCache:(NSString *)userId {
    return [[RCUserInfoCacheManager sharedManager] getUserInfoFromCacheOnly:userId];
}

- (void)refreshUserInfoCache:(RCUserInfo *)userInfo withUserId:(NSString *)userId {
    //    [[RCUserInfoCacheManager sharedManager] clearUserInfoNetworkCacheOnly:userId];
    [[RCUserInfoCacheManager sharedManager] updateUserInfo:userInfo forUserId:userId];
}

- (void)clearUserInfoCache {
    [[RCUserInfoCacheManager sharedManager] clearAllUserInfo];
}

- (RCGroup *)getGroupInfoCache:(NSString *)groupId {
    return [[RCUserInfoCacheManager sharedManager] getGroupInfoFromCacheOnly:groupId];
}

- (void)refreshGroupInfoCache:(RCGroup *)groupInfo withGroupId:(NSString *)groupId {
    [[RCUserInfoCacheManager sharedManager] updateGroupInfo:groupInfo forGroupId:groupId];
}

- (void)clearGroupInfoCache {
    [[RCUserInfoCacheManager sharedManager] clearAllGroupInfo];
}

- (RCUserInfo *)getGroupUserInfoCache:(NSString *)userId withGroupId:(NSString *)groupId {
    return [[RCUserInfoCacheManager sharedManager] getUserInfoFromCacheOnly:userId inGroupId:groupId];
}

- (void)refreshGroupUserInfoCache:(RCUserInfo *)userInfo withUserId:(NSString *)userId withGroupId:(NSString *)groupId {
    [[RCUserInfoCacheManager sharedManager] updateUserInfo:userInfo forUserId:userId inGroup:groupId];
}

- (void)clearGroupUserInfoCache {
    [[RCUserInfoCacheManager sharedManager] clearAllGroupUserInfo];
}

- (RCMessage *)sendMessage:(RCConversationType)conversationType
                  targetId:(NSString *)targetId
                   content:(RCMessageContent *)content
               pushContent:(NSString *)pushContent
                  pushData:(NSString *)pushData
                   success:(void (^)(long messageId))successBlock
                     error:(void (^)(RCErrorCode nErrorCode, long messageId))errorBlock {
    if (targetId == nil || content == nil) {
        if (errorBlock) {
            errorBlock(INVALID_PARAMETER, 0);
        }
        NSLog(@"Parameters error");
        return nil;
    }
    content = [self beforeSendMessage:content];
    if (!content) {
        return nil;
    }

    [self attachCurrentUserInfo:content];

    RCMessage *rcMessage = [[RCIMClient sharedRCIMClient] sendMessage:conversationType
                                                             targetId:targetId
                                                              content:content
                                                          pushContent:pushContent
                                                             pushData:pushData
                                                              success:^(long messageId) {
        [self postSendMessageSentNotification:targetId
                             conversationType:conversationType
                                    messageId:messageId
                                      content:content];
        [self sendMessageComplete:content status:0];
        if (successBlock) {
            successBlock(messageId);
        }
    } error:^(RCErrorCode nErrorCode, long messageId) {
        if (nErrorCode == RC_MSG_REPLACED_SENSITIVE_WORD) {
            [self postSendMessageSentNotification:targetId
                                 conversationType:conversationType
                                        messageId:messageId
                                          content:content];
            [self sendMessageComplete:content status:0];
            if (successBlock) {
                successBlock(messageId);
            }
        } else {
            [self postSendMessageErrorNotification:targetId
                                  conversationType:conversationType
                                         messageId:messageId
                                             error:nErrorCode
                                           content:content];
            [self sendMessageComplete:content status:nErrorCode];
            if (errorBlock) {
                errorBlock(nErrorCode, messageId);
            }
        }
    }];

    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                        object:rcMessage
                                                      userInfo:nil];
    return rcMessage;
}

- (RCMessage *)sendMessage:(RCMessage *)message
               pushContent:(NSString *)pushContent
                  pushData:(NSString *)pushData
              successBlock:(void (^)(RCMessage *successMessage))successBlock
                errorBlock:(void (^)(RCErrorCode nErrorCode, RCMessage *errorMessage))errorBlock {
    if (message.targetId == nil || message.content == nil) {
        if (errorBlock) {
            errorBlock(INVALID_PARAMETER, message);
        }
        NSLog(@"Parameters error");
        return nil;
    }
    message.content = [self beforeSendMessage:message.content];
    if (!message.content) {
        return nil;
    }

    [self attachCurrentUserInfo:message.content];

    RCMessage *rcMessage = [[RCIMClient sharedRCIMClient] sendMessage:message pushContent:pushContent pushData:pushData successBlock:^(RCMessage *successMessage) {
        [self postSendMessageSentNotification:successMessage.targetId
                             conversationType:successMessage.conversationType
                                    messageId:successMessage.messageId
                                      content:successMessage.content];
        [self sendMessageComplete:successMessage.content status:0];
        if (successBlock) {
            successBlock(successMessage);
        }
    } errorBlock:^(RCErrorCode nErrorCode, RCMessage *errorMessage) {
        if (nErrorCode == RC_MSG_REPLACED_SENSITIVE_WORD) {
            [self postSendMessageSentNotification:errorMessage.targetId
                                 conversationType:errorMessage.conversationType
                                        messageId:errorMessage.messageId
                                          content:errorMessage.content];
            [self sendMessageComplete:errorMessage.content status:0];
            if (successBlock) {
                successBlock(errorMessage);
            }
        } else {
            [self postSendMessageErrorNotification:errorMessage.targetId
                                  conversationType:errorMessage.conversationType
                                         messageId:errorMessage.messageId
                                             error:nErrorCode
                                           content:errorMessage.content];
            [self sendMessageComplete:errorMessage.content status:nErrorCode];
            if (errorBlock) {
                errorBlock(nErrorCode, errorMessage);
            }
        }
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                        object:rcMessage
                                                      userInfo:nil];
    return rcMessage;
}

- (RCMessage *)sendDirectionalMessage:(RCConversationType)conversationType
                             targetId:(NSString *)targetId
                         toUserIdList:(NSArray *)userIdList
                              content:(RCMessageContent *)content
                          pushContent:(NSString *)pushContent
                             pushData:(NSString *)pushData
                              success:(void (^)(long messageId))successBlock
                                error:(void (^)(RCErrorCode nErrorCode, long messageId))errorBlock {
    if (targetId == nil || content == nil) {
        if (errorBlock) {
            errorBlock(INVALID_PARAMETER, 0);
        }
        NSLog(@"Parameters error");
        return nil;
    }
    content = [self beforeSendMessage:content];
    if (!content) {
        return nil;
    }
    [self attachCurrentUserInfo:content];

    RCMessage *rcMessage = [[RCIMClient sharedRCIMClient] sendDirectionalMessage:conversationType
    targetId:targetId
    toUserIdList:userIdList
    content:content
    pushContent:pushContent
    pushData:pushData
    success:^(long messageId) {
        [self postSendMessageSentNotification:targetId
                             conversationType:conversationType
                                    messageId:messageId
                                      content:content];
        [self sendMessageComplete:content status:0];
        if (successBlock) {
            successBlock(messageId);
        }
    }
    error:^(RCErrorCode nErrorCode, long messageId) {
        if (nErrorCode == RC_MSG_REPLACED_SENSITIVE_WORD) {
            [self postSendMessageSentNotification:targetId
                                 conversationType:conversationType
                                        messageId:messageId
                                          content:content];
            [self sendMessageComplete:content status:0];
            if (successBlock) {
                successBlock(messageId);
            }
        } else {
            [self postSendMessageErrorNotification:targetId
                                  conversationType:conversationType
                                         messageId:messageId
                                             error:nErrorCode
                                           content:content];
            [self sendMessageComplete:content status:nErrorCode];
            if (errorBlock) {
                errorBlock(nErrorCode, messageId);
            }
        }
    }];

    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                        object:rcMessage
                                                      userInfo:nil];
    return rcMessage;
}

- (void)downloadMediaMessage:(long)messageId
                    progress:(void (^)(int progress))progressBlock
                     success:(void (^)(NSString *mediaPath))successBlock
                       error:(void (^)(RCErrorCode errorCode))errorBlock
                      cancel:(void (^)(void))cancelBlock {
    if ([self.downloadingMeidaMessageIds containsObject:@(messageId)]) {
        return;
    }

    [self.downloadingMeidaMessageIds addObject:@(messageId)];

    [[RCIMClient sharedRCIMClient] downloadMediaMessage:messageId
        progress:^(int progress) {
            NSDictionary *statusDic =
                @{ @"messageId" : @(messageId),
                   @"type" : @"progress",
                   @"progress" : @(progress) };
            [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchDownloadMediaNotification
                                                                object:nil
                                                              userInfo:statusDic];
            if (progressBlock) {
                progressBlock(progress);
            }
        }
        success:^(NSString *mediaPath) {
            [self.downloadingMeidaMessageIds removeObject:@(messageId)];

            NSDictionary *statusDic = @{ @"messageId" : @(messageId), @"type" : @"success", @"mediaPath" : mediaPath };
            [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchDownloadMediaNotification
                                                                object:nil
                                                              userInfo:statusDic];
            if (successBlock) {
                successBlock(mediaPath);
            }
        }
        error:^(RCErrorCode errorCode) {
            [self.downloadingMeidaMessageIds removeObject:@(messageId)];

            NSDictionary *statusDic = @{ @"messageId" : @(messageId), @"type" : @"error", @"errorCode" : @(errorCode) };
            [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchDownloadMediaNotification
                                                                object:nil
                                                              userInfo:statusDic];
            if (errorBlock) {
                errorBlock(errorCode);
            }
        }
        cancel:^{
            [self.downloadingMeidaMessageIds removeObject:@(messageId)];

            NSDictionary *statusDic = @{ @"messageId" : @(messageId), @"type" : @"cancel" };
            [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchDownloadMediaNotification
                                                                object:nil
                                                              userInfo:statusDic];
            if (cancelBlock) {
                cancelBlock();
            }
        }];
}

- (BOOL)cancelDownloadMediaMessage:(long)messageId {
    return [[RCIMClient sharedRCIMClient] cancelDownloadMediaMessage:messageId];
}

- (RCMessage *)sendMediaMessage:(RCConversationType)conversationType
                       targetId:(NSString *)targetId
                        content:(RCMessageContent *)content
                    pushContent:(NSString *)pushContent
                       pushData:(NSString *)pushData
                       progress:(void (^)(int progress, long messageId))progressBlock
                        success:(void (^)(long messageId))successBlock
                          error:(void (^)(RCErrorCode errorCode, long messageId))errorBlock
                         cancel:(void (^)(long messageId))cancelBlock {
    if (targetId == nil || content == nil) {
        if (errorBlock) {
            errorBlock(INVALID_PARAMETER, 0);
        }
        NSLog(@"Parameters error");
        return nil;
    }
    content = [self beforeSendMessage:content];
    if (!content) {
        return nil;
    }
    [self attachCurrentUserInfo:content];

    RCMessage *rcMessage = [[RCIMClient sharedRCIMClient] sendMediaMessage:conversationType
    targetId:targetId
    content:content
    pushContent:pushContent
    pushData:pushData
    progress:^(int progress, long messageId) {
        NSDictionary *statusDic = @{
            @"targetId" : targetId,
            @"conversationType" : @(conversationType),
            @"messageId" : @(messageId),
            @"sentStatus" : @(SentStatus_SENDING),
            @"progress" : @(progress)
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                            object:nil
                                                          userInfo:statusDic];
        if (progressBlock) {
            progressBlock(progress, messageId);
        }
    }
    success:^(long messageId) {
        [self postSendMessageSentNotification:targetId
                             conversationType:conversationType
                                    messageId:messageId
                                      content:content];
        [self sendMessageComplete:content status:0];
        if (successBlock) {
            successBlock(messageId);
        }
    }
    error:^(RCErrorCode errorCode, long messageId) {
        [self postSendMessageErrorNotification:targetId
                              conversationType:conversationType
                                     messageId:messageId
                                         error:errorCode
                                       content:content];
        [self sendMessageComplete:content status:errorCode];
        if (errorBlock) {
            errorBlock(errorCode, messageId);
        }
    }
    cancel:^(long messageId) {
        NSDictionary *statusDic = @{
            @"targetId" : targetId,
            @"conversationType" : @(conversationType),
            @"messageId" : @(messageId),
            @"sentStatus" : @(SentStatus_CANCELED),
            @"content" : content
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                            object:nil
                                                          userInfo:statusDic];
        if (cancelBlock) {
            cancelBlock(messageId);
        }
    }];

    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                        object:rcMessage
                                                      userInfo:nil];

    return rcMessage;
}

- (RCMessage *)sendMediaMessage:(RCMessage *)message
                    pushContent:(NSString *)pushContent
                       pushData:(NSString *)pushData
                       progress:(void (^)(int progress, RCMessage *progressMessage))progressBlock
                   successBlock:(void (^)(RCMessage *successMessage))successBlock
                     errorBlock:(void (^)(RCErrorCode nErrorCode, RCMessage *errorMessage))errorBlock
                         cancel:(void (^)(RCMessage *cancelMessage))cancelBlock {
    if (message.targetId == nil || message.content == nil) {
        if (errorBlock) {
            errorBlock(INVALID_PARAMETER, message);
        }
        NSLog(@"Parameters error");
        return nil;
    }
    message.content = [self beforeSendMessage:message.content];
    if (!message.content) {
        return nil;
    }
    [self attachCurrentUserInfo:message.content];
    
    RCMessage *rcMessage = [[RCIMClient sharedRCIMClient] sendMediaMessage:message pushContent:pushContent pushData:pushData progress:^(int progress, RCMessage *progressMessage) {
        NSDictionary *statusDic = @{
            @"targetId" : progressMessage.targetId,
            @"conversationType" : @(progressMessage.conversationType),
            @"messageId" : @(progressMessage.messageId),
            @"sentStatus" : @(SentStatus_SENDING),
            @"progress" : @(progress)
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                            object:nil
                                                          userInfo:statusDic];
        if (progressBlock) {
            progressBlock(progress, progressMessage);
        }
    } successBlock:^(RCMessage *successMessage) {
        [self postSendMessageSentNotification:successMessage.targetId
                             conversationType:successMessage.conversationType
                                    messageId:successMessage.messageId
                                      content:successMessage.content];
        [self sendMessageComplete:successMessage.content status:0];
        if (successBlock) {
            successBlock(successMessage);
        }
    } errorBlock:^(RCErrorCode nErrorCode, RCMessage *errorMessage) {
        [self postSendMessageErrorNotification:errorMessage.targetId
                              conversationType:errorMessage.conversationType
                                     messageId:errorMessage.messageId
                                         error:nErrorCode
                                       content:errorMessage.content];
        [self sendMessageComplete:errorMessage.content status:nErrorCode];
        if (errorBlock) {
            errorBlock(nErrorCode, errorMessage);
        }
    }  cancel:^(RCMessage *cancelMessage) {
        NSDictionary *statusDic = @{
            @"targetId" : cancelMessage.targetId,
            @"conversationType" : @(cancelMessage.conversationType),
            @"messageId" : @(cancelMessage.messageId),
            @"sentStatus" : @(SentStatus_CANCELED),
            @"content" : cancelMessage.content
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                            object:nil
                                                          userInfo:statusDic];
        if (cancelBlock) {
            cancelBlock(cancelMessage);
        }
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                        object:rcMessage
                                                      userInfo:nil];
    return rcMessage;
}

- (BOOL)cancelSendMediaMessage:(long)messageId {
    BOOL isCanceled = [[RCIMClient sharedRCIMClient] cancelSendMediaMessage:messageId];
    if (isCanceled && [[RCResendManager sharedManager] needResend:messageId]) {
        [[RCResendManager sharedManager] removeResendMessage:messageId];
    }
    return isCanceled;
}

- (RCMessageContent *)beforeSendMessage:(RCMessageContent *)content {
    if ([self.sendMessageDelegate respondsToSelector:@selector(willSendIMMessage:)]) {
        content = [self.sendMessageDelegate willSendIMMessage:content];
    }
    return content;
}

- (void)postSendMessageSentNotification:(NSString *)targetId
                       conversationType:(RCConversationType)conversationType
                              messageId:(long)messageId
                                content:(RCMessageContent *)content {
    NSDictionary *statusDic = @{
        @"targetId" : targetId,
        @"conversationType" : @(conversationType),
        @"messageId" : @(messageId),
        @"sentStatus" : @(SentStatus_SENT),
        @"content" : content
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                        object:nil
                                                      userInfo:statusDic];
}

- (void)postSendMessageErrorNotification:(NSString *)targetId
                        conversationType:(RCConversationType)conversationType
                               messageId:(long)messageId
                                   error:(RCErrorCode)nErrorCode
                                 content:(RCMessageContent *)content {
    [[RCResendManager sharedManager] addResendMessageIfNeed:messageId error:nErrorCode];
    NSDictionary *statusDic = @{
        @"targetId" : targetId,
        @"conversationType" : @(conversationType),
        @"messageId" : @(messageId),
        @"sentStatus" : @(SentStatus_FAILED),
        @"error" : @(nErrorCode),
        @"content" : content
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                        object:nil
                                                      userInfo:statusDic];
}

- (void)sendMessageComplete:(RCMessageContent *)messageContent status:(NSInteger)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.sendMessageDelegate respondsToSelector:@selector(didSendIMMessage:status:)]) {
            [self.sendMessageDelegate didSendIMMessage:messageContent status:status];
        }
    });
}

#pragma mark - 消息阅后即焚

- (void)onMessageDestructing:(RCMessage *)message remainDuration:(long long)remainDuration {
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitMessageDestructingNotification
                                                        object:nil
                                                      userInfo:@{
                                                          @"message" : message,
                                                          @"remainDuration" : @(remainDuration)
                                                      }];
}

#pragma mark - Discussion
- (void)sendUserInfoUpdateMessageForDiscussion:(NSString *)discussionId userIdList:(NSArray *)userIdList {
    NSMutableArray *userInfoList = [[NSMutableArray alloc] init];
    for (NSString *userId in userIdList) {
        RCUserInfo *cacheUserInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:userId];
        if (cacheUserInfo.name.length > 0 || cacheUserInfo.portraitUri.length > 0) {
            [userInfoList addObject:cacheUserInfo];
        }
    }
    RCUserInfoUpdateMessage *message = [[RCUserInfoUpdateMessage alloc] initWithUserInfoList:userInfoList];
    [self attachCurrentUserInfo:message];

    [[RCIMClient sharedRCIMClient] sendMessage:ConversationType_DISCUSSION
        targetId:discussionId
        content:message
        pushContent:nil
        pushData:nil
        success:^(long messageId) {

        }
        error:^(RCErrorCode nErrorCode, long messageId){

        }];
}

- (void)createDiscussion:(NSString *)name
              userIdList:(NSArray *)userIdList
                 success:(void (^)(RCDiscussion *discussion))successBlock
                   error:(void (^)(RCErrorCode status))errorBlock {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[RCDiscussionClient sharedDiscussionClient] createDiscussion:name
        userIdList:userIdList
        success:^(RCDiscussion *discussion) {
            [self sendUserInfoUpdateMessageForDiscussion:discussion.discussionId userIdList:discussion.memberIdList];
            if (successBlock) {
                successBlock(discussion);
            }
        }
        error:^(RCErrorCode status) {
            if (errorBlock) {
                errorBlock(status);
            }
        }];
#pragma clang diagnostic pop
}

- (void)addMemberToDiscussion:(NSString *)discussionId
                   userIdList:(NSArray *)userIdList
                      success:(void (^)(RCDiscussion *discussion))successBlock
                        error:(void (^)(RCErrorCode status))errorBlock {
    [self sendUserInfoUpdateMessageForDiscussion:discussionId userIdList:userIdList];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[RCDiscussionClient sharedDiscussionClient] addMemberToDiscussion:discussionId
        userIdList:userIdList
        success:^(RCDiscussion *discussion) {
            if (successBlock) {
                successBlock(discussion);
            }
        }
        error:^(RCErrorCode status) {
            if (errorBlock) {
                errorBlock(status);
            }
        }];
#pragma clang diagnostic pop
}

- (void)removeMemberFromDiscussion:(NSString *)discussionId
                            userId:(NSString *)userId
                           success:(void (^)(RCDiscussion *discussion))successBlock
                             error:(void (^)(RCErrorCode status))errorBlock {
    [self sendUserInfoUpdateMessageForDiscussion:discussionId userIdList:@[ userId ]];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[RCDiscussionClient sharedDiscussionClient] removeMemberFromDiscussion:discussionId
        userId:userId
        success:^(RCDiscussion *discussion) {
            if (successBlock) {
                successBlock(discussion);
            }
        }
        error:^(RCErrorCode status) {
            if (errorBlock) {
                errorBlock(status);
            }
        }];
#pragma clang diagnostic pop
}

- (void)quitDiscussion:(NSString *)discussionId
               success:(void (^)(RCDiscussion *discussion))successBlock
                 error:(void (^)(RCErrorCode status))errorBlock {
    [self sendUserInfoUpdateMessageForDiscussion:discussionId userIdList:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[RCDiscussionClient sharedDiscussionClient] quitDiscussion:discussionId
        success:^(RCDiscussion *discussion) {
            if (successBlock) {
                successBlock(discussion);
            }
        }
        error:^(RCErrorCode status) {
            if (errorBlock) {
                errorBlock(status);
            }
        }];
#pragma clang diagnostic pop
}

- (void)getDiscussion:(NSString *)discussionId
              success:(void (^)(RCDiscussion *discussion))successBlock
                error:(void (^)(RCErrorCode status))errorBlock {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[RCDiscussionClient sharedDiscussionClient] getDiscussion:discussionId
        success:^(RCDiscussion *discussion) {
            if (successBlock) {
                successBlock(discussion);
            }
        }
        error:^(RCErrorCode status) {
            if (errorBlock) {
                errorBlock(status);
            }
        }];
#pragma clang diagnostic pop
}

- (void)setDiscussionName:(NSString *)discussionId
                     name:(NSString *)discussionName
                  success:(void (^)(void))successBlock
                    error:(void (^)(RCErrorCode status))errorBlock {
    [self sendUserInfoUpdateMessageForDiscussion:discussionId userIdList:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[RCDiscussionClient sharedDiscussionClient] setDiscussionName:discussionId
        name:discussionName
        success:^{
            if (successBlock) {
                successBlock();
            }
        }
        error:^(RCErrorCode status) {
            if (errorBlock) {
                errorBlock(status);
            }
        }];
#pragma clang diagnostic pop
}

- (void)setDiscussionInviteStatus:(NSString *)discussionId
                           isOpen:(BOOL)isOpen
                          success:(void (^)(void))successBlock
                            error:(void (^)(RCErrorCode status))errorBlock {
    [self sendUserInfoUpdateMessageForDiscussion:discussionId userIdList:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[RCDiscussionClient sharedDiscussionClient] setDiscussionInviteStatus:discussionId
        isOpen:isOpen
        success:^{
            if (successBlock) {
                successBlock();
            }
        }
        error:^(RCErrorCode status) {
            if (errorBlock) {
                errorBlock(status);
            }
        }];
#pragma clang diagnostic pop
}

- (void)setScheme:(NSString *)scheme forExtensionModule:(NSString *)moduleName {
    [[RongIMKitExtensionManager sharedManager] setScheme:scheme forModule:moduleName];
}

- (BOOL)openExtensionModuleUrl:(NSURL *)url {
    return [[RongIMKitExtensionManager sharedManager] onOpenUrl:url];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)attachCurrentUserInfo:(RCMessageContent *)content {
    if ([RCIM sharedRCIM].enableMessageAttachUserInfo && !content.senderUserInfo) {
        content.senderUserInfo = [[RCUserInfo alloc] init];
        content.senderUserInfo.userId = [RCIMClient sharedRCIMClient].currentUserInfo.userId;
        content.senderUserInfo.name = [RCIMClient sharedRCIMClient].currentUserInfo.name;
        if ([RCUtilities isLocalPath:[RCIMClient sharedRCIMClient].currentUserInfo.portraitUri]) {
            content.senderUserInfo.portraitUri = nil;
        } else {
            content.senderUserInfo.portraitUri = [RCIMClient sharedRCIMClient].currentUserInfo.portraitUri;
        }
        content.senderUserInfo.extra = [RCIMClient sharedRCIMClient].currentUserInfo.extra;
    }
}


- (void)conversationStatusDidChange:(NSArray<RCConversationStatusInfo *> *)conversationStatusInfos {
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchConversationStatusChangeNotification
                                                        object:conversationStatusInfos
                                                      userInfo:nil];
}

@end
