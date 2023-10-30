//
//  RCCXCall.m
//  RongCallKit
//
//  Created by LiFei on 2018/1/17.
//  Copyright © 2018年 Rong Cloud. All rights reserved.
//

#import "RCCXCall.h"
#import "RCCall.h"
#import "RCUserInfoCacheManager.h"

//RCCallKit_Delete_end

#import <AVFoundation/AVFoundation.h>
#import "RCCallKitUtility.h"

#define RCCXCallLocalizedName @"RongCloud"

//RCCallKit_Delete_end
@interface RCCXCall ()
@property (nonatomic, strong) NSUUID *currentUUID;
@end
//RCCallKit_Delete_end

@implementation RCCXCall

+ (instancetype)sharedInstance {
    static RCCXCall *pCall;
    static dispatch_once_t onceToken;
    if (([UIDevice currentDevice].systemVersion.floatValue < 10.0)) {
        return nil;
    }
    dispatch_once(&onceToken, ^{
        if (pCall == nil) {
            pCall = [[RCCXCall alloc] init];
            pCall.acceptedFromCallKit = NO;
            //RCCallKit_Delete_end
        }
    });
    return pCall;
}

- (void)startCallId:(NSString *)callId userId:(NSString *)userId {
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callId];
    self.currentUUID = uuid;
    //RCCallKit_Delete_end
}

- (void)reportOutgoingCallConnected {
    //RCCallKit_Delete_end
}

- (void)reportIncomingCallWithCallId:(NSString *)callId
                             inviter:(NSString *)inviterId
                          userIdList:(NSArray<NSString *> *)userIdList
                             isVideo:(BOOL)isVideo {
    //RCCallKit_Delete_end
}

- (void)answerCXCall {
    //RCCallKit_Delete_end
    self.currentUUID = nil;
    //RCCallKit_Delete_end
}

- (void)endCXCall {
    //RCCallKit_Delete_end
    self.currentUUID = nil;
    //RCCallKit_Delete_end
}

- (void)hangupIfNeedWithUUID:(NSString *)UUID {
    if (UUID.length == 0) {
        return;
    }
    if (![UUID isEqualToString:self.currentUUID.UUIDString]) {
        [[RCCall sharedRCCall].currentCallSession hangup];
    }
}

//RCCallKit_Delete_end

@end
