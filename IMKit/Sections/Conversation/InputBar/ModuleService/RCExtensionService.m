//
//  RCExtensionService.m
//  RongExtensionKit
//
//  Created by 岑裕 on 2016/10/9.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCExtensionService.h"
#import "RCExtensionModuleManager.h"

@implementation RCExtensionService

+ (instancetype)sharedService {
    static RCExtensionService *pDefaultService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (pDefaultService == nil) {
            pDefaultService = [[RCExtensionService alloc] init];
        }
    });
    return pDefaultService;
}

- (void)loadAllExtensionModules {
    [[RCExtensionModuleManager sharedManager] loadAllExtensionModules];
}

- (NSArray *)getAllExtensionModules {
    return [[RCExtensionModuleManager sharedManager] getAllExtensionModules];
}

- (void)initWithAppKey:(NSString *)appkey {
    [[RCExtensionModuleManager sharedManager] initWithAppKey:appkey];
}

- (void)didConnect:(NSString *)userId {
    [[RCExtensionModuleManager sharedManager] didConnect:userId];
}

- (void)didDisconnect {
    [[RCExtensionModuleManager sharedManager] didDisconnect];
}

- (void)didCurrentUserInfoUpdated:(RCUserInfo *)userInfo {
    [[RCExtensionModuleManager sharedManager] didCurrentUserInfoUpdated:userInfo];
}

- (BOOL)onOpenUrl:(NSURL *)url {
    return [[RCExtensionModuleManager sharedManager] onOpenUrl:url];
}

- (void)setScheme:(NSString *)scheme forModule:(NSString *)moduleName {
    [[RCExtensionModuleManager sharedManager] setScheme:scheme forModule:moduleName];
}

- (NSArray<RCExtensionPluginItemInfo *> *)getPluginBoardItemInfoList:(RCConversationType)conversationType
                                                            targetId:(NSString *)targetId {
    return [[RCExtensionModuleManager sharedManager] getPluginBoardItemInfoList:conversationType targetId:targetId];
}

- (NSArray<id<RCEmoticonTabSource>> *)getEmoticonTabList:(RCConversationType)conversationType
                                                targetId:(NSString *)targetId {
    return [[RCExtensionModuleManager sharedManager] getEmoticonTabList:conversationType targetId:targetId];
}

- (void)onMessageReceived:(RCMessage *)message {
    [[RCExtensionModuleManager sharedManager] onMessageReceived:message];
}

- (BOOL)handleAlertForMessageReceived:(RCMessage *)message {
    return [[RCExtensionModuleManager sharedManager] handleAlertForMessageReceived:message];
}

- (BOOL)handleNotificationForMessageReceived:(RCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo {
    return [[RCExtensionModuleManager sharedManager] handleNotificationForMessageReceived:message
                                                                                     from:fromName
                                                                                 userInfo:userInfo];
}

- (void)emoticonTab:(RCEmojiBoardView *)emojiView
  didTouchAddButton:(UIButton *)addButton
         inInputBar:(RCChatSessionInputBarControl *)inputBarControl {
    [[RCExtensionModuleManager sharedManager] emoticonTab:emojiView
                                        didTouchAddButton:addButton
                                               inInputBar:inputBarControl];
}

- (void)emoticonTab:(RCEmojiBoardView *)emojiView
    didTouchEmotionIconIndex:(int)index
                  inInputBar:(RCChatSessionInputBarControl *)inputBarControl
         isBlockDefaultEvent:(void (^)(BOOL isBlockDefaultEvent))block {
    [[RCExtensionModuleManager sharedManager] emoticonTab:emojiView
                                 didTouchEmotionIconIndex:index
                                               inInputBar:inputBarControl
                                      isBlockDefaultEvent:block];
}

- (void)emoticonTab:(RCEmojiBoardView *)emojiView
    didTouchSettingButton:(UIButton *)settingButton
               inInputBar:(RCChatSessionInputBarControl *)inputBarControl {
    [[RCExtensionModuleManager sharedManager] emoticonTab:emojiView
                                    didTouchSettingButton:settingButton
                                               inInputBar:inputBarControl];
}

- (void)inputTextViewDidChange:(UITextView *)inputTextView inInputBar:(RCChatSessionInputBarControl *)inputBarControl {
    [[RCExtensionModuleManager sharedManager] inputTextViewDidChange:inputTextView inInputBar:inputBarControl];
}
- (void)inputBarStatusDidChange:(KBottomBarStatus)status inInputBar:(RCChatSessionInputBarControl *)inputBarControl {
    [[RCExtensionModuleManager sharedManager] inputBarStatusDidChange:status inInputBar:inputBarControl];
}

/*!
 是否需要显示表情加号按钮

 @param inputBarControl  输入工具栏
 */
- (BOOL)isEmoticonAddButtonEnabled:(RCChatSessionInputBarControl *)inputBarControl {
    return [[RCExtensionModuleManager sharedManager] isEmoticonAddButtonEnabled:inputBarControl];
}

/*!
 是否需要显示表情设置按钮

 @param inputBarControl  输入工具栏
 */
- (BOOL)isEmoticonSettingButtonEnabled:(RCChatSessionInputBarControl *)inputBarControl {
    return [[RCExtensionModuleManager sharedManager] isEmoticonSettingButtonEnabled:inputBarControl];
}

- (BOOL)isAudioHolding {
    return [[RCExtensionModuleManager sharedManager] isAudioHolding];
}

- (BOOL)isCameraHolding {
    return [[RCExtensionModuleManager sharedManager] isCameraHolding];
}

@end
