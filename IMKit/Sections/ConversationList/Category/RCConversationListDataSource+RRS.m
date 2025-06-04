//
//  RCConversationListDataSource+RRS.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/3.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationListDataSource+RRS.h"
#import "RCKitConfig.h"
#import "RCConversationCellUpdateInfo.h"
#import "RCMessageModel+RRS.h"

@implementation RCConversationListDataSource (RRS)

- (void)rrs_didReceiveMessageReadReceiptResponses:(NSArray<RCReadReceiptResponseV5 *> *)responses {
    for (RCReadReceiptResponseV5 *res in responses) {
        if (res.identifier.type != ConversationType_PRIVATE) {
            continue;
        }
        if (![self.displayConversationTypeArray containsObject:@(ConversationType_PRIVATE)]) {
            continue;
        }
        if (![RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(res.identifier.type)]) {
            continue;
        }
        long readTime = 0;
        if (res.users.count) {
            RCReadReceiptUser *user = res.users.firstObject;
            readTime = user.timestamp;
        }
        for (RCConversationModel *model in self.dataList) {
            if ([model isMatching:res.identifier.type targetId:res.identifier.targetId]) {
                if (model.lastestMessageDirection == MessageDirection_SEND &&
                    model.sentTime <= readTime && model.sentStatus != SentStatus_READ) {
                    model.sentStatus = SentStatus_READ;
                    model.readReceiptCount = res.readCount;
                    RCConversationCellUpdateInfo *updateInfo =
                    [[RCConversationCellUpdateInfo alloc] init];
                    updateInfo.model = model;
                    updateInfo.updateType = RCConversationCell_SentStatus_Update;
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:RCKitConversationCellUpdateNotification
                     object:updateInfo
                     userInfo:nil];
                }
            }
        }
    }
}
@end
