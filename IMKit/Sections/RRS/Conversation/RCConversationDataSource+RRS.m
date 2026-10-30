//
//  RCConversationDataSource+RRS.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/3.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationDataSource+RRS.h"
#import "RCMessageModel+RRS.h"
#import "RCConversationVCUtil.h"
#import "RCConversationViewController+RRS.h"

@interface RCConversationViewController ()
@property (nonatomic, strong, readonly) RCConversationVCUtil *util;
@end
@interface RCConversationDataSource ()

@property (nonatomic, weak) RCConversationViewController *chatVC;
@end
@implementation RCConversationDataSource (RRS)

- (void)rrs_fetchReadReceiptV5Info:(NSArray <RCMessageModel *>*)models {
    if (!models.count) {
        return;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    for (RCMessageModel *model in models) {
        if ([model rrs_shouldFetchReadReceiptV5]) {
            dic[model.messageUId] = model;
        }
    }
    if([dic allKeys].count) {
        NSArray *messageUIDs = [dic allKeys];
        RCConversationIdentifier *identifier = [RCConversationIdentifier new];
        identifier.type = self.chatVC.conversationType;
        identifier.targetId = self.chatVC.targetId;
        [[RCCoreClient sharedCoreClient] getMessageReadReceiptInfoV5:identifier
                                                         messageUIds:messageUIDs
                                                          completion:^(NSArray<RCReadReceiptInfoV5 *> * _Nullable infoList, RCErrorCode code) {
            if (code == RC_SUCCESS) {
                for (RCReadReceiptInfoV5 *info in infoList) {
                    if (info.messageUId && info.readCount > 0) {
                        RCMessageModel *model = dic[info.messageUId];
                        model.readReceiptInfoV5 = info;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self.chatVC.util sendMessageReadReceiptV5Notification:model];
                        });
                    }
                }
            }
        }];
    }
}

- (void)rrs_responseReadReceiptV5Info:(NSDictionary *)dic {
    if([dic allKeys].count) {
        NSArray *messageUIDs = [dic allKeys];
        RCConversationIdentifier *identifier = [RCConversationIdentifier new];
        identifier.type = self.chatVC.conversationType;
        identifier.targetId = self.chatVC.targetId;
        [[RCCoreClient sharedCoreClient] sendReadReceiptResponseV5:identifier messageUIds:messageUIDs completion:^(RCErrorCode code) {
            if (code == RC_SUCCESS) {
                NSArray *models = [dic allValues];
                for (RCMessageModel *model in models) {
                    model.sentReceipt = YES;
                }
            }
        }];
    }
}

@end
