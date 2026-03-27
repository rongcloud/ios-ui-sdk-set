//
//  RCKitMessageConf.m
//  RongIMKit
//
//  Created by Sin on 2020/6/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCKitMessageConf.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCKitCommonDefine.h"

@implementation RCKitMessageConf
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.disableMessageNotificaiton = NO;
        self.disableMessageAlertSound = [[NSUserDefaults standardUserDefaults] boolForKey:@"rcMessageBeep"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.maxVoiceDuration = 60;
#pragma clang diagnostic pop
        self.enableMessageRecall = YES;
        self.enableMessageMentioned = YES;
        self.maxRecallDuration = 120;
        self.maxReadRequestDuration = 120;
        self.enabledReadReceiptConversationTypeList =
            @[ @(ConversationType_PRIVATE), @(ConversationType_DISCUSSION), @(ConversationType_GROUP) ];
        self.enableTypingStatus = YES;
        self.enableSyncReadStatus = YES;
        self.showUnkownMessage = YES;
        self.GIFMsgAutoDownloadSize = 1024;
        self.enableSendCombineMessage = NO;
        self.enableDestructMessage = NO;
        self.reeditDuration = 300;
        self.enableMessageReference = YES;
        self.sightRecordMaxDuration = 10;
        self.enableMessageResend = YES;
        self.enableEditMessage = NO;
    }
    return self;
}

- (void)setDisableMessageAlertSound:(BOOL)disableMessageAlertSound {
    [[NSUserDefaults standardUserDefaults] setBool:disableMessageAlertSound forKey:@"rcMessageBeep"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _disableMessageAlertSound = disableMessageAlertSound;
}
- (NSTimeInterval)uploadVideoDurationLimit {
    return [[RCCoreClient sharedCoreClient] getVideoDurationLimit];
}

- (UIColor *)editedTextColor {
    if (!_editedTextColor) {
        _editedTextColor = RCDYCOLOR(0x7C838E, 0xFFFFFF);
    }
    return _editedTextColor;
}

@end
