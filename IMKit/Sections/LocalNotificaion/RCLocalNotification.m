//
//  RCLocalNotification.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCLocalNotification.h"
#import <UIKit/UIKit.h>
#import <RongIMLib/RongIMLib.h>
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCIM.h"
#import "RCUserInfoCacheManager.h"
#import "RongIMKitExtensionManager.h"
#import "RCKitConfig.h"
#import <RongPublicService/RongPublicService.h>
#import <RongDiscussion/RongDiscussion.h>
#if __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static RCLocalNotification *__rc__LocalNotification = nil;

@interface RCLocalNotification ()

@property (nonatomic, strong) UILocalNotification *localNotification;

@property (nonatomic, assign) BOOL haveLocationSound;
@end

@implementation RCLocalNotification

+ (RCLocalNotification *)defaultCenter {
    @synchronized(self) {
        if (nil == __rc__LocalNotification) {
            __rc__LocalNotification = [[[self class] alloc] init];

            NSString *soundPath =
                [[NSBundle mainBundle] pathForResource:@"RongCloud.bundle/sms-received" ofType:@"caf"];
            if (soundPath.length > 0) {
                __rc__LocalNotification.haveLocationSound = YES;
            }
        }
    }

    return __rc__LocalNotification;
}

- (void)postLocalNotificationWithMessage:(RCMessage *)message userInfo:(NSDictionary *)userInfo {
    [self getNotificationInfo:message result:^(NSString *senderName, NSString *pushContent) {
        if ([[RongIMKitExtensionManager sharedManager] handleNotificationForMessageReceived:message from:senderName userInfo:userInfo]) {
            return;
        }
        
        if ([[RCIM sharedRCIM].receiveMessageDelegate
             respondsToSelector:@selector(onRCIMCustomLocalNotification:withSenderName:)]) {
            if ([[RCIM sharedRCIM].receiveMessageDelegate onRCIMCustomLocalNotification:message
                                                                         withSenderName:senderName])
                return;
        }
        [self postLocalNotification:senderName pushContent:pushContent message:message userInfo:userInfo];
    } errorBlock:^(NSString *errorDescription) {
        NSLog(@"%@", errorDescription);
    }];
}

- (void)postLocalNotification:(NSString *)formatMessage userInfo:(NSDictionary *)userInfo {
    if (nil == _localNotification) {
        _localNotification = [[UILocalNotification alloc] init];
    }

    _localNotification.alertAction = RCLocalizedString(@"LocalNotificationShow");
    formatMessage = [formatMessage stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
    if ([RCIMClient sharedRCIMClient].pushProfile.isShowPushContent) {
        _localNotification.alertBody = formatMessage;
    } else {
        _localNotification.alertBody = RCLocalizedString(@"receive_new_message");
    }
    _localNotification.userInfo = userInfo;

    if (_haveLocationSound) {
        [_localNotification setSoundName:@"RongCloud.bundle/sms-received.caf"];
    } else {
        [_localNotification setSoundName:UILocalNotificationDefaultSoundName];
    }
    // NSDictionary *dict = @{@"key1": [NSString stringWithFormat:@"%d",RC_KIT_LOCAL_NOTIFICATION_TAG]};
    //[localNotify setUserInfo:dict];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] presentLocalNotificationNow:_localNotification];
    });
}

#pragma mark - Private Method
- (void)postLocalNotification:(NSString *)senderName pushContent:(NSString *)pushContent message:(RCMessage *)message userInfo:(NSDictionary *)userInfo {
    RCMessagePushConfig *pushConfig = message.messagePushConfig;
    NSString *title = @"";
    NSString *soundName = @"RongCloud.bundle/sms-received.caf";
    if ([RCIMClient sharedRCIMClient].pushProfile.isShowPushContent || (pushConfig && pushConfig.forceShowDetailContent)) {
        if (pushConfig && [self pushTitleEffectived:pushConfig.pushTitle]) {
            title = pushConfig.pushTitle;
        } else {
            title = senderName;
        }
        if (pushConfig && pushConfig.pushContent && pushConfig.pushContent.length > 0) {
            pushContent = pushConfig.pushContent;
        } else {
            pushContent = [pushContent stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
        }
    } else {
        pushContent = NSLocalizedStringFromTable(@"receive_new_message", @"RongCloudKit", nil);
    }
    
    if (@available(iOS 10.0, *)) {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        if (!message.messagePushConfig.disablePushTitle) {
            content.title = title;
        }
        content.body = pushContent;
        content.userInfo = userInfo;
        if (_haveLocationSound) {
            content.sound = [UNNotificationSound soundNamed:soundName];
        } else {
            content.sound = [UNNotificationSound defaultSound];
        }
        NSString *requestWithIdentifier = message.messageUId;
        if (pushConfig) {
            if (pushConfig.iOSConfig && pushConfig.iOSConfig.apnsCollapseId && pushConfig.iOSConfig.apnsCollapseId.length > 0) {
                requestWithIdentifier = pushConfig.iOSConfig.apnsCollapseId;
            }
            if (pushConfig.iOSConfig && pushConfig.iOSConfig.threadId) {
                content.threadIdentifier = pushConfig.iOSConfig.threadId;
            }
        }
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:requestWithIdentifier content:content trigger:nil];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        }];
    } else {
        if (nil == _localNotification) {
            _localNotification = [[UILocalNotification alloc] init];
        }
        _localNotification.alertAction = NSLocalizedStringFromTable(@"LocalNotificationShow", @"RongCloudKit", nil);
        if (@available(iOS 8.2, *)) {
            if (!message.messagePushConfig.disablePushTitle) {
                _localNotification.alertTitle = title;
            }
        }
        _localNotification.alertBody = pushContent;
        _localNotification.userInfo = userInfo;

        if (_haveLocationSound) {
            [_localNotification setSoundName:soundName];
        } else {
            [_localNotification setSoundName:UILocalNotificationDefaultSoundName];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] presentLocalNotificationNow:_localNotification];
        });
    }
}

- (void)getNotificationInfo:(RCMessage *)message
                     result:(void (^)(NSString *senderName, NSString *pushContent))resultBlock
                 errorBlock:(void (^)(NSString *errorDescription))errorBlock {
    __block NSString *showMessage = nil;
    if (RCKitConfigCenter.message.showUnkownMessageNotificaiton && message.objectName && !message.content) {
        showMessage = NSLocalizedStringFromTable(@"unknown_message_notification_tip", @"RongCloudKit", nil);
    } else if (message.content.mentionedInfo.isMentionedMe) {
        if (!message.content.mentionedInfo.mentionedContent) {
            showMessage = [RCKitUtility formatLocalNotification:message];
        } else {
            showMessage = message.content.mentionedInfo.mentionedContent;
        }
    } else {
        showMessage = [RCKitUtility formatLocalNotification:message];
    }

    if ((ConversationType_GROUP == message.conversationType)) {
        [[RCUserInfoCacheManager sharedManager] getGroupInfo:message.targetId
                                                    complete:^(RCGroup *groupInfo) {
                                                        if (nil == groupInfo) {
                                                            if (errorBlock) {
                                                                NSString *errorDes = @"...................postLocalNotification failed, groupInfo is NULL, please call [[RCIM sharedRCIM] refreshGroupInfoCache:(RCGroup *)groupInfo withGroupId:(NSString *)groupId] ...................";
                                                                errorBlock(errorDes);
                                                            }
                                                            return;
                                                        }
                                                        [[RCUserInfoCacheManager sharedManager]
                                                            getUserInfo:message.senderUserId
                                                               complete:^(RCUserInfo *userInfo) {

                                                                   if (userInfo) {
                                                                       showMessage =
                                                                           [self formatGroupNotification:message
                                                                                                   group:groupInfo
                                                                                                    user:userInfo
                                                                                             showMessage:showMessage];
                                                                       resultBlock(groupInfo.groupName, showMessage);
                                                                   }else {
                                                                       if (errorBlock) {
                                                                           NSString *errorDes = @"...................postLocalNotification failed, groupUserInfo is NULL, please call  [[RCIM sharedRCIM] refreshGroupUserInfoCache:(RCUserInfo *)userInfo withUserId:(NSString *)userId withGroupId:(NSString *)groupId] ...................";
                                                                           errorBlock(errorDes);
                                                                       }
                                                                   }
                                                               }];
                                                    }];

    } else if (ConversationType_DISCUSSION == message.conversationType) {
        [[RCDiscussionClient sharedDiscussionClient] getDiscussion:message.targetId
            success:^(RCDiscussion *discussion) {
                if (nil == discussion) {
                    if (errorBlock) {
                        NSString *errorDes = @"...................postLocalNotification failed, discussion is NULL ...................";
                        errorBlock(errorDes);
                    }
                    return;
                }
                showMessage = [self formatDiscussionNotification:message discussion:discussion showMessage:showMessage];
                resultBlock(discussion.discussionName, showMessage);

            }
            error:^(RCErrorCode status){
                if (errorBlock) {
                    NSString *errorDes = @"...................postLocalNotification failed, getDiscussion error ...................";
                    errorBlock(errorDes);
                }
            }];
    } else if (ConversationType_CUSTOMERSERVICE == message.conversationType) {
        NSString *customeServiceName = [RCKitUtility getDisplayName:message.content.senderUserInfo] ?: @"客服";
        showMessage = [self formatOtherNotification:message name:customeServiceName showMessage:showMessage];
        resultBlock(customeServiceName, showMessage);

    } else if (ConversationType_APPSERVICE == message.conversationType ||
               ConversationType_PUBLICSERVICE == message.conversationType) {
        RCPublicServiceProfile *serviceProfile = nil;
        if ([RCIM sharedRCIM].publicServiceInfoDataSource) {
            serviceProfile = [[RCUserInfoCacheManager sharedManager] getPublicServiceProfile:message.targetId];
        } else {
            serviceProfile =
                [[RCPublicServiceClient sharedPublicServiceClient] getPublicServiceProfile:(RCPublicServiceType)message.conversationType
                                                       publicServiceId:message.targetId];
        }

        if (serviceProfile) {
            showMessage = [self formatOtherNotification:message name:serviceProfile.name showMessage:showMessage];
            resultBlock(serviceProfile.name, showMessage);
        }else {
            if (errorBlock) {
                NSString *errorDes = @"...................postLocalNotification failed, serviceProfile is NULL ...................";
                errorBlock(errorDes);
            }
        }
    } else if (ConversationType_SYSTEM == message.conversationType) {
        [[RCUserInfoCacheManager sharedManager] getUserInfo:message.targetId complete:^(RCUserInfo *userInfo) {
            if (nil == userInfo) {
                if (errorBlock) {
                    NSString *errorDes = @"...................postLocalNotification failed, userInfo is NULL, please call  [[RCIM sharedRCIM] refreshUserInfoCache:(RCUserInfo *)userInfo withUserId:(NSString *)userId] ...................";
                    errorBlock(errorDes);
                }
                return;
            }
            NSString *dispalyName = [RCKitUtility getDisplayName:userInfo];
            showMessage = [self formatOtherNotification:message name:dispalyName showMessage:showMessage];
            resultBlock(dispalyName, showMessage);
        }];
    } else {
        [[RCUserInfoCacheManager sharedManager] getUserInfo:message.targetId complete:^(RCUserInfo *userInfo) {
            if (nil == userInfo) {
                if (errorBlock) {
                    NSString *errorDes = @"...................postLocalNotification failed, userInfo is NULL, please call  [[RCIM sharedRCIM] refreshUserInfoCache:(RCUserInfo *)userInfo withUserId:(NSString *)userId] ...................";
                    errorBlock(errorDes);
                }
                return;
            }
            NSString *dispalyName = [RCKitUtility getDisplayName:userInfo];
            showMessage = [self formatOtherNotification:message name:dispalyName showMessage:showMessage];
            resultBlock(dispalyName, showMessage);
            
        }];
    }
}

- (NSString *)formatGroupNotification:(RCMessage *)message
                                group:(RCGroup *)groupInfo
                                 user:(RCUserInfo *)userInfo
                          showMessage:(NSString *)showMessage {
    if (@available(iOS 8.2, *)) {
        if (message.content.mentionedInfo.isMentionedMe) {
            if (!message.content.mentionedInfo.mentionedContent) {
                showMessage = [NSString
                    stringWithFormat:@"%@%@:%@",
                                     NSLocalizedStringFromTable(@"HaveMentionedForNotification", @"RongCloudKit", nil),
                                     [RCKitUtility getDisplayName:userInfo], showMessage];
            }
        } else if ([message.objectName isEqualToString:@"RC:RcNtf"]) {
            [self formatRecallMessage:message name:userInfo.name];
        } else {
            showMessage = [NSString stringWithFormat:@"%@:%@", [RCKitUtility getDisplayName:userInfo], showMessage];
        }
    } else {
        if (message.content.mentionedInfo.isMentionedMe) {
            if (!message.content.mentionedInfo.mentionedContent) {
                showMessage = [NSString
                    stringWithFormat:@"%@%@(%@):%@",
                                     NSLocalizedStringFromTable(@"HaveMentionedForNotification", @"RongCloudKit", nil),
                               [RCKitUtility getDisplayName:userInfo], groupInfo.groupName, showMessage];
            }
        } else if ([message.objectName isEqualToString:@"RC:RcNtf"]) {
            [self formatRecallMessage:message name:userInfo.name];
        } else {
            showMessage = [NSString stringWithFormat:@"%@(%@):%@", [RCKitUtility getDisplayName:userInfo], groupInfo.groupName, showMessage];
        }
    }
    
    return showMessage;
}

- (NSString *)formatDiscussionNotification:(RCMessage *)message
                                discussion:(RCDiscussion *)discussion
                               showMessage:(NSString *)showMessage {
    if (message.content.mentionedInfo.isMentionedMe) {
        if (!message.content.mentionedInfo.mentionedContent) {
            showMessage = [NSString
                stringWithFormat:@"%@%@:%@",
                                 NSLocalizedStringFromTable(@"HaveMentionedForNotification", @"RongCloudKit", nil),
                                 discussion.discussionName, showMessage];
        }
    } else if ([message.objectName isEqualToString:@"RC:RcNtf"]) {
    } else {
        showMessage = [NSString stringWithFormat:@"%@:%@", discussion.discussionName, showMessage];
    }
    return showMessage;
}

- (NSString *)formatOtherNotification:(RCMessage *)message name:(NSString *)name showMessage:(NSString *)showMessage {
    if ([message.objectName isEqualToString:@"RC:RcNtf"]) {
        [self formatRecallMessage:message name:name];
    } else {
        if (@available(iOS 8.2, *)) {
            showMessage = [NSString stringWithFormat:@"%@", showMessage];
        } else {
            showMessage = [NSString stringWithFormat:@"%@:%@", name, showMessage];
        }
    }
    return showMessage;
}

- (NSString *)formatRecallMessage:(RCMessage *)message name:(NSString *)name{
    RCRecallNotificationMessage *recallMessage = (RCRecallNotificationMessage *)message.content;
    if (!recallMessage || !recallMessage.operatorId) {
        return nil;
    }
    
    NSString *currentUserId = [RCIMClient sharedRCIMClient].currentUserInfo.userId;
    NSString *operator= recallMessage.operatorId;
    if (recallMessage.isAdmin) {
        return
        [NSString stringWithFormat:NSLocalizedStringFromTable(@"OtherHasRecalled", @"RongCloudKit", nil),
         NSLocalizedStringFromTable(@"AdminWithMessageRecalled", @"RongCloudKit", nil)];
    }else if ([operator isEqualToString:currentUserId]) {
        return [NSString stringWithFormat:@"%@", NSLocalizedStringFromTable(@"SelfHaveRecalled", @"RongCloudKit", nil)];
    } else {
        NSString *operatorName;
        if ([name length]) {
            operatorName = name;
        } else {
            operatorName= [[NSString alloc] initWithFormat:@"user<%@>", operator];
        }
        if (message.conversationType == ConversationType_GROUP) {
            return [NSString
                    stringWithFormat:NSLocalizedStringFromTable(@"OtherHasRecalled", @"RongCloudKit", nil), operatorName];
        } else {
            return [NSString
                    stringWithFormat:NSLocalizedStringFromTable(@"MessageHasRecalled", @"RongCloudKit", nil)];
        }
    }
    return nil;
}

- (BOOL)pushTitleEffectived:(NSString *)pushTitle {
    // 如果 pushTitle 全为空格时相当于用户未设置
    if (pushTitle && pushTitle.length > 0 && [[pushTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] > 0) {
        return YES;
    }
    return NO;
}

#pragma clang diagnostic pop

@end
