//
//  RCExtensionModuleManager.m
//  RongExtensionKit
//
//  Created by 岑裕 on 16/7/2.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCExtensionModuleManager.h"

NSString *const rcExtensionModelNames =
    @"RCCallKitExtensionModule,RCStickerModule,"
    @"RCiFlyKitExtensionModule,RCCCExtensionModule";

#define RCDisplayEmoticonConversationType                                                                              \
    [NSArray arrayWithObjects:@(ConversationType_PRIVATE), @(ConversationType_DISCUSSION), @(ConversationType_GROUP),  \
                              @(ConversationType_CHATROOM), @(ConversationType_SYSTEM), nil]

@interface RCExtensionModuleManager ()
@property (nonatomic, strong) NSMutableArray<id<RCExtensionModule>> *moduleList;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *schemeModuleDict;
@end

@implementation RCExtensionModuleManager

+ (instancetype)sharedManager {
    static RCExtensionModuleManager *pDefaultManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (pDefaultManager == nil) {
            pDefaultManager = [[RCExtensionModuleManager alloc] init];
            pDefaultManager.moduleList = [[NSMutableArray alloc] init];
            pDefaultManager.schemeModuleDict = [[NSMutableDictionary alloc] init];
        }
    });
    return pDefaultManager;
}

- (void)loadAllExtensionModules {
    NSArray *allModelNames = [[rcExtensionModelNames stringByReplacingOccurrencesOfString:@" " withString:@""]
        componentsSeparatedByString:@","];
    if ([allModelNames count] > 0) {
        for (NSString *modelName in allModelNames) {
            Class modelClass = NSClassFromString(modelName);
            if (modelClass) {
                id<RCExtensionModule> module = [modelClass loadRongExtensionModule];
                [self.moduleList addObject:module];
            }
        }
    }
}

- (NSArray<id<RCExtensionModule>> *)getAllExtensionModules {
    return [self.moduleList copy];
}

- (void)initWithAppKey:(NSString *)appkey {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(initWithAppKey:)]) {
            [module initWithAppKey:appkey];
        }
    }
}

- (void)didConnect:(NSString *)userId {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(didConnect:)]) {
            [module didConnect:userId];
        }
    }
}

- (void)didDisconnect {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(didDisconnect)]) {
            [module didDisconnect];
        }
    }
}

- (void)didCurrentUserInfoUpdated:(RCUserInfo *)userInfo {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(didCurrentUserInfoUpdated:)]) {
            [module didCurrentUserInfoUpdated:userInfo];
        }
    }
}

- (BOOL)onOpenUrl:(NSURL *)url {
    NSString *moduleName = self.schemeModuleDict[url.scheme];

    if (moduleName == nil) {
        return NO;
    }

    for (id<RCExtensionModule> module in self.moduleList) {
        if ([NSStringFromClass([module class]) isEqualToString:moduleName] &&
            [module respondsToSelector:@selector(onOpenUrl:)]) {
            return [module onOpenUrl:url];
        }
    }
    return NO;
}

- (void)setScheme:(NSString *)scheme forModule:(NSString *)moduleName {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([NSStringFromClass([module class]) isEqualToString:moduleName] &&
            [module respondsToSelector:@selector(setScheme:)]) {
            [module setScheme:scheme];
            [self.schemeModuleDict setObject:moduleName forKey:scheme];
            return;
        }
    }
}

- (NSArray<RCExtensionPluginItemInfo *> *)getPluginBoardItemInfoList:(RCConversationType)conversationType
                                                            targetId:(NSString *)targetId {
    NSMutableArray<RCExtensionPluginItemInfo *> *items = [NSMutableArray new];
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(getPluginBoardItemInfoList:targetId:)]) {
            [items addObjectsFromArray:[module getPluginBoardItemInfoList:conversationType targetId:targetId]];
        }
    }
    return [items copy];
}

- (NSArray<id<RCEmoticonTabSource>> *)getEmoticonTabList:(RCConversationType)conversationType
                                                targetId:(NSString *)targetId {
    NSMutableArray *tabs = [NSMutableArray new];
    if ([RCDisplayEmoticonConversationType containsObject:@(conversationType)]) {
        for (id<RCExtensionModule> module in self.moduleList) {
            if ([module respondsToSelector:@selector(getEmoticonTabList:targetId:)]) {
                [tabs addObjectsFromArray:[module getEmoticonTabList:conversationType targetId:targetId]];
            }
        }
    }
    return [tabs copy];
}

- (void)onMessageReceived:(RCMessage *)message {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(onMessageReceived:)]) {
            [module onMessageReceived:message];
        }
    }
}

- (BOOL)handleAlertForMessageReceived:(RCMessage *)message {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(handleAlertForMessageReceived:)] &&
            [module handleAlertForMessageReceived:message])
            return YES;
    }
    return NO;
}

- (BOOL)handleNotificationForMessageReceived:(RCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(handleNotificationForMessageReceived:from:userInfo:)] &&
            [module handleNotificationForMessageReceived:message from:fromName userInfo:userInfo])
            return YES;
    }
    return NO;
}

- (void)emoticonTab:(RCEmojiBoardView *)emojiView
  didTouchAddButton:(UIButton *)addButton
         inInputBar:(RCChatSessionInputBarControl *)inputBarControl {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(emoticonTab:didTouchAddButton:inInputBar:)]) {
            [module emoticonTab:emojiView didTouchAddButton:addButton inInputBar:inputBarControl];
        }
    }
}

- (void)emoticonTab:(RCEmojiBoardView *)emojiView
    didTouchEmotionIconIndex:(int)index
                  inInputBar:(RCChatSessionInputBarControl *)inputBarControl
         isBlockDefaultEvent:(void (^)(BOOL isBlockDefaultEvent))block {
    if (self.moduleList.count > 0) {
        BOOL isModuleHandle = NO;
        for (id<RCExtensionModule> module in self.moduleList) {
            if ([module respondsToSelector:@selector(emoticonTab:
                                               didTouchEmotionIconIndex:
                                                             inInputBar:
                                                    isBlockDefaultEvent:)]) {
                [module emoticonTab:emojiView
                    didTouchEmotionIconIndex:index
                                  inInputBar:inputBarControl
                         isBlockDefaultEvent:block];
                isModuleHandle = YES;
            } else {
                if ([[NSString stringWithFormat:@"%@", [module class]] isEqualToString:@"BQMMRongExtensionModule"]) {
                    block(NO);
                    isModuleHandle = YES;
                }
            }
        }
        if (!isModuleHandle) {
            block(NO);
        }
    } else {
        block(NO);
    }
}

- (void)emoticonTab:(RCEmojiBoardView *)emojiView
    didTouchSettingButton:(UIButton *)settingButton
               inInputBar:(RCChatSessionInputBarControl *)inputBarControl {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(emoticonTab:didTouchSettingButton:inInputBar:)]) {
            [module emoticonTab:emojiView didTouchSettingButton:settingButton inInputBar:inputBarControl];
        }
    }
}

- (void)inputTextViewDidChange:(UITextView *)inputTextView inInputBar:(RCChatSessionInputBarControl *)inputBarControl {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(inputTextViewDidChange:inInputBar:)]) {
            [module inputTextViewDidChange:inputTextView inInputBar:inputBarControl];
        }
    }
}

- (void)inputBarStatusDidChange:(KBottomBarStatus)status inInputBar:(RCChatSessionInputBarControl *)inputBarControl {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(inputBarStatusDidChange:inInputBar:)]) {
            [module inputBarStatusDidChange:status inInputBar:inputBarControl];
        }
    }
}

/*!
 是否需要显示表情加号按钮

 @param inputBarControl  输入工具栏
 */
- (BOOL)isEmoticonAddButtonEnabled:(RCChatSessionInputBarControl *)inputBarControl {
    if ([RCDisplayEmoticonConversationType containsObject:@(inputBarControl.conversationType)]) {
        for (id<RCExtensionModule> module in self.moduleList) {
            if ([module respondsToSelector:@selector(isEmoticonAddButtonEnabled:)] &&
                [module isEmoticonAddButtonEnabled:inputBarControl]) {
                return YES;
            }
        }
    }
    return NO;
}

/*!
 是否需要显示表情设置按钮

 @param inputBarControl  输入工具栏
 */
- (BOOL)isEmoticonSettingButtonEnabled:(RCChatSessionInputBarControl *)inputBarControl {
    if ([RCDisplayEmoticonConversationType containsObject:@(inputBarControl.conversationType)]) {
        for (id<RCExtensionModule> module in self.moduleList) {
            if ([module respondsToSelector:@selector(isEmoticonSettingButtonEnabled:)] &&
                [module isEmoticonSettingButtonEnabled:inputBarControl]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)isAudioHolding {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(isAudioHolding)] && [module isAudioHolding]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isCameraHolding {
    for (id<RCExtensionModule> module in self.moduleList) {
        if ([module respondsToSelector:@selector(isCameraHolding)] && [module isCameraHolding]) {
            return YES;
        }
    }
    return NO;
}

@end
