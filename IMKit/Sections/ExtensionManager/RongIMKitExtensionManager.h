//
//  RongIMKitExtensionManager.h
//  RongIMKit
//
//  Created by 岑裕 on 2016/10/18.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RongIMKitExtensionModule.h"
#import <Foundation/Foundation.h>

@interface RongIMKitExtensionManager : NSObject

+ (instancetype)sharedManager;

- (void)loadAllExtensionModules;
- (void)initWithAppKey:(NSString *)appkey;
- (void)didConnect:(NSString *)userId;
- (void)didDisconnect;
- (void)didCurrentUserInfoUpdated:(RCUserInfo *)userInfo;

- (void)onMessageReceived:(RCMessage *)message;
- (BOOL)handleAlertForMessageReceived:(RCMessage *)message;
- (BOOL)handleNotificationForMessageReceived:(RCMessage *)message
                                        from:(NSString *)fromName
                                    userInfo:(NSDictionary *)userInfo;

- (BOOL)onOpenUrl:(NSURL *)url;
- (void)setScheme:(NSString *)scheme forModule:(NSString *)moduleName;

- (NSArray<RCExtensionMessageCellInfo *> *)getMessageCellInfoList:(RCConversationType)conversationType
                                                         targetId:(NSString *)targetId;
- (void)didTapMessageCell:(RCMessageModel *)messageModel;

- (void)extensionViewWillAppear:(RCConversationType)conversationType
                       targetId:(NSString *)targetId
                  extensionView:(UIView *)extensionView;

- (void)extensionViewWillDisappear:(RCConversationType)conversationType targetId:(NSString *)targetId;

- (void)containerViewWillDestroy:(RCConversationType)conversationType targetId:(NSString *)targetId;

@end
