//
//  RCIM+Deprecated.m
//  RongIMKit
//
//  Created by Sin on 2020/7/2.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCIM+Deprecated.h"
#import "RCKitConfig.h"

@implementation RCIM (Deprecated)
#pragma mark - config 接口兼容

- (BOOL)disableMessageNotificaiton {
    return RCKitConfigCenter.message.disableMessageNotificaiton;
}
- (void)setDisableMessageNotificaiton:(BOOL)disableMessageNotificaiton {
    RCKitConfigCenter.message.disableMessageNotificaiton = disableMessageNotificaiton;
}

- (BOOL)disableMessageAlertSound {
    return RCKitConfigCenter.message.disableMessageAlertSound;
}
- (void)setDisableMessageAlertSound:(BOOL)disableMessageAlertSound {
    RCKitConfigCenter.message.disableMessageAlertSound = disableMessageAlertSound;
}

- (BOOL)enableTypingStatus {
    return RCKitConfigCenter.message.enableTypingStatus;
}
- (void)setEnableTypingStatus:(BOOL)enableTypingStatus {
    RCKitConfigCenter.message.enableTypingStatus = enableTypingStatus;
}

//enabledReadReceiptConversationTypeList
- (NSArray *)enabledReadReceiptConversationTypeList {
    return RCKitConfigCenter.message.enabledReadReceiptConversationTypeList;
}
- (void)setEnabledReadReceiptConversationTypeList:(NSArray *)enabledReadReceiptConversationTypeList {
    RCKitConfigCenter.message.enabledReadReceiptConversationTypeList = enabledReadReceiptConversationTypeList;
}
//
- (NSUInteger)maxReadRequestDuration {
    return RCKitConfigCenter.message.maxReadRequestDuration;
}
- (void)setMaxReadRequestDuration:(NSUInteger)maxReadRequestDuration {
    RCKitConfigCenter.message.maxReadRequestDuration = maxReadRequestDuration;
}
//enableSyncReadStatus
- (BOOL)enableSyncReadStatus {
    return RCKitConfigCenter.message.enableSyncReadStatus;
}
- (void)setEnableSyncReadStatus:(BOOL)enableSyncReadStatus {
    RCKitConfigCenter.message.enableSyncReadStatus = enableSyncReadStatus;
}
//enableMessageMentioned
- (BOOL)enableMessageMentioned {
    return RCKitConfigCenter.message.enableMessageMentioned;
}
- (void)setEnableMessageMentioned:(BOOL)enableMessageMentioned {
    RCKitConfigCenter.message.enableMessageMentioned = enableMessageMentioned;
}
//enableMessageRecall
- (BOOL)enableMessageRecall {
    return RCKitConfigCenter.message.enableMessageRecall;
}
- (void)setEnableMessageRecall:(BOOL)enableMessageRecall {
    RCKitConfigCenter.message.enableMessageRecall = enableMessageRecall;
}
//maxRecallDuration
- (NSUInteger)maxRecallDuration {
    return RCKitConfigCenter.message.maxRecallDuration;
}
- (void)setMaxRecallDuration:(NSUInteger)maxRecallDuration {
    RCKitConfigCenter.message.maxRecallDuration = maxRecallDuration;
}
//showUnkownMessage
- (BOOL)showUnkownMessage {
    return RCKitConfigCenter.message.showUnkownMessage;
}
- (void)setShowUnkownMessage:(BOOL)showUnkownMessage {
    RCKitConfigCenter.message.showUnkownMessage = showUnkownMessage;
}
//showUnkownMessageNotificaiton
- (BOOL)showUnkownMessageNotificaiton {
    return RCKitConfigCenter.message.showUnkownMessageNotificaiton;
}
- (void)setShowUnkownMessageNotificaiton:(BOOL)showUnkownMessageNotificaiton {
    RCKitConfigCenter.message.showUnkownMessageNotificaiton = showUnkownMessageNotificaiton;
}
//maxVoiceDuration
- (NSUInteger)maxVoiceDuration {
    return RCKitConfigCenter.message.maxVoiceDuration;
}
- (void)setMaxVoiceDuration:(NSUInteger)maxVoiceDuration {
    RCKitConfigCenter.message.maxVoiceDuration = maxVoiceDuration;
}
//isExclusiveSoundPlayer
- (BOOL)isExclusiveSoundPlayer {
    return RCKitConfigCenter.message.isExclusiveSoundPlayer;
}
- (void)setIsExclusiveSoundPlayer:(BOOL)isExclusiveSoundPlayer {
    RCKitConfigCenter.message.isExclusiveSoundPlayer = isExclusiveSoundPlayer;
}
//isMediaSelectorContainVideo
- (BOOL)isMediaSelectorContainVideo {
    return RCKitConfigCenter.message.isMediaSelectorContainVideo;
}
- (void)setIsMediaSelectorContainVideo:(BOOL)isMediaSelectorContainVideo {
    RCKitConfigCenter.message.isMediaSelectorContainVideo = isMediaSelectorContainVideo;
}
//globalNavigationBarTintColor
- (UIColor *)globalNavigationBarTintColor {
    return RCKitConfigCenter.ui.globalNavigationBarTintColor;
}
- (void)setGlobalNavigationBarTintColor:(UIColor *)globalNavigationBarTintColor {
    RCKitConfigCenter.ui.globalNavigationBarTintColor = globalNavigationBarTintColor;
}
//globalConversationAvatarStyle
- (RCUserAvatarStyle)globalConversationAvatarStyle {
    return RCKitConfigCenter.ui.globalConversationAvatarStyle;
}
- (void)setGlobalConversationAvatarStyle:(RCUserAvatarStyle)globalConversationAvatarStyle {
    RCKitConfigCenter.ui.globalConversationAvatarStyle = globalConversationAvatarStyle;
}
//globalConversationPortraitSize
- (CGSize)globalConversationPortraitSize {
    return RCKitConfigCenter.ui.globalConversationPortraitSize;
}
- (void)setGlobalConversationPortraitSize:(CGSize)globalConversationPortraitSize {
    RCKitConfigCenter.ui.globalConversationPortraitSize = globalConversationPortraitSize;
}
//globalMessageAvatarStyle
- (RCUserAvatarStyle)globalMessageAvatarStyle {
    return RCKitConfigCenter.ui.globalMessageAvatarStyle;
}
- (void)setGlobalMessageAvatarStyle:(RCUserAvatarStyle)globalMessageAvatarStyle {
    RCKitConfigCenter.ui.globalMessageAvatarStyle = globalMessageAvatarStyle;
}
//globalMessagePortraitSize
- (CGSize)globalMessagePortraitSize {
    return RCKitConfigCenter.ui.globalMessagePortraitSize;
}
- (void)setGlobalMessagePortraitSize:(CGSize)globalMessagePortraitSize {
    RCKitConfigCenter.ui.globalMessagePortraitSize = globalMessagePortraitSize;
}
//portraitImageViewCornerRadius
- (CGFloat)portraitImageViewCornerRadius {
    return RCKitConfigCenter.ui.portraitImageViewCornerRadius;
}
- (void)setPortraitImageViewCornerRadius:(CGFloat)portraitImageViewCornerRadius {
    RCKitConfigCenter.ui.portraitImageViewCornerRadius = portraitImageViewCornerRadius;
}
//GIFMsgAutoDownloadSize
- (NSInteger)GIFMsgAutoDownloadSize {
    return RCKitConfigCenter.message.GIFMsgAutoDownloadSize;
}
- (void)setGIFMsgAutoDownloadSize:(NSInteger)GIFMsgAutoDownloadSize {
    RCKitConfigCenter.message.GIFMsgAutoDownloadSize = GIFMsgAutoDownloadSize;
}
//enableSendCombineMessage
- (BOOL)enableSendCombineMessage {
    return RCKitConfigCenter.message.enableSendCombineMessage;
}
- (void)setEnableSendCombineMessage:(BOOL)enableSendCombineMessage {
    RCKitConfigCenter.message.enableSendCombineMessage = enableSendCombineMessage;
}
//enableDestructMessage
- (BOOL)enableDestructMessage {
    return RCKitConfigCenter.message.enableDestructMessage;
}
- (void)setEnableDestructMessage:(BOOL)enableDestructMessage {
    RCKitConfigCenter.message.enableDestructMessage = enableDestructMessage;
}
//enableDarkMode
- (BOOL)enableDarkMode {
    return RCKitConfigCenter.ui.enableDarkMode;
}
- (void)setEnableDarkMode:(BOOL)enableDarkMode {
    RCKitConfigCenter.ui.enableDarkMode = enableDarkMode;
}
//reeditDuration
- (NSUInteger)reeditDuration {
    return RCKitConfigCenter.message.reeditDuration;
}
- (void)setReeditDuration:(NSUInteger)reeditDuration {
    RCKitConfigCenter.message.reeditDuration = reeditDuration;
}
//enableMessageReference
- (BOOL)enableMessageReference {
    return RCKitConfigCenter.message.enableMessageReference;
}
- (void)setEnableMessageReference:(BOOL)enableMessageReference {
    RCKitConfigCenter.message.enableMessageReference = enableMessageReference;
}
//sightRecordMaxDuration
- (NSUInteger)sightRecordMaxDuration {
    return RCKitConfigCenter.message.sightRecordMaxDuration;
}
- (void)setSightRecordMaxDuration:(NSUInteger)sightRecordMaxDuration {
    RCKitConfigCenter.message.sightRecordMaxDuration = sightRecordMaxDuration;
}
@end
