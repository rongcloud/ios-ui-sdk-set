//
//  RCMessageModel.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCMessageModel.h"
#import "RCCustomerServiceMessageModel.h"

@interface RCMessageModel ()

@property (nonatomic, strong) id cellViewModel;

@end

@implementation RCMessageModel

+ (instancetype)modelWithMessage:(RCMessage *)rcMessage {
    if (rcMessage.conversationType == ConversationType_CUSTOMERSERVICE) {
        return [[RCCustomerServiceMessageModel alloc] initWithMessage:rcMessage];
    } else {
        return [[RCMessageModel alloc] initWithMessage:rcMessage];
    }
}

- (instancetype)initWithMessage:(RCMessage *)rcMessage {
    self = [super init];
    if (self) {
        self.conversationType = rcMessage.conversationType;
        self.targetId = rcMessage.targetId;
        self.messageId = rcMessage.messageId;
        self.messageDirection = rcMessage.messageDirection;
        self.senderUserId = rcMessage.senderUserId;
        self.receivedStatusInfo = rcMessage.receivedStatusInfo;
        self.sentStatus = rcMessage.sentStatus;
        self.sentTime = rcMessage.sentTime;
        self.objectName = rcMessage.objectName;
        self.content = rcMessage.content;
        self.isDisplayMessageTime = NO;
        self.userInfo = nil;
        self.receivedTime = rcMessage.receivedTime;
        self.extra = rcMessage.extra;
        self.cellSize = CGSizeMake(0, 0);
        self.messageUId = rcMessage.messageUId;
        self.readReceiptInfo = rcMessage.readReceiptInfo;
        if (self.readReceiptInfo && self.readReceiptInfo.userIdList) {
            self.readReceiptCount = self.readReceiptInfo.userIdList.count;
        }
        self.canIncludeExpansion = rcMessage.canIncludeExpansion;
        self.expansionDic = rcMessage.expansionDic;
 		self.hasChanged = rcMessage.hasChanged;
        self.modifyInfo = rcMessage.modifyInfo;
        self.needReceipt = rcMessage.needReceipt;
        self.sentReceipt = rcMessage.sentReceipt;
    }

    return self;
}

- (BOOL)isEqual:(id)object {
    if (!object || ![object isKindOfClass:[RCMessageModel class]]) {
        return NO;
    }
    if (object == self) {
        return YES;
    }
    
    RCMessageModel *model = (RCMessageModel *)object;
    if ([model.targetId isEqualToString:self.targetId] && model.conversationType == self.conversationType && model.messageId == self.messageId) {
        return YES;
    }
    return NO;
}

#pragma mark - setter & getter

- (void)setReceivedStatus:(RCReceivedStatus)receivedStatus {
    self.receivedStatusInfo = [[RCReceivedStatusInfo alloc] initWithReceivedStatus:receivedStatus];
}

- (RCReceivedStatus)receivedStatus {
    RCMessage *msg = [[RCMessage alloc] init];
    msg.receivedStatusInfo = self.receivedStatusInfo;
    return msg.receivedStatus;
}

- (RCReceivedStatusInfo *)receivedStatusInfo {
    if (!_receivedStatusInfo) {
        _receivedStatusInfo = [[RCReceivedStatusInfo alloc] initWithReceivedStatus:0];
    }
    return _receivedStatusInfo;
}

@end
