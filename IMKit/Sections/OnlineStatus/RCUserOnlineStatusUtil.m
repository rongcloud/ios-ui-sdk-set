//
//  RCUserOnlineStatusUtil.m
//  RongIMKit
//
//  Created by Lang on 11/12/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCUserOnlineStatusUtil.h"
#import "RCKitConfig.h"
#import <RongIMLibCore/RongIMLibCore.h>

@implementation RCUserOnlineStatusUtil

+ (BOOL)shouldDisplayOnlineStatus {
    if (RCKitConfigCenter.ui.enableUserOnlineStatus
        && ([RCCoreClient sharedCoreClient].getAppSettings.isOnlineStatusSubscribeEnable
            || [RCCoreClient sharedCoreClient].getAppSettings.isFriendOnlineStatusSubscribeEnable
            )
        ) {
        return YES;
    }
    return NO;
}

@end
