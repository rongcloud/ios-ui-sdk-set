//
//  RCConversationViewController+RRS.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/3.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationViewController+RRS.h"
#import "RCConversationVCUtil.h"
#import "RCMessageModel+RRS.h"
@interface RCConversationViewController ()
@property (nonatomic, strong) RCConversationVCUtil *util;

@end

@implementation RCConversationViewController (RRS)
- (void)rrs_observeReadReceiptV5 {
    [[RCCoreClient sharedCoreClient] addReadReceiptV5Delegate:self];
}

- (void)rrs_responseReadReceiptV5IfNeed {
    if (self.conversationType != ConversationType_GROUP && self.conversationType != ConversationType_PRIVATE) {
        return;
    }
    NSArray *items = [self.conversationMessageCollectionView indexPathsForVisibleItems];
    NSMutableArray *models = [NSMutableArray array];
    NSMutableArray *messageUIDs = [NSMutableArray array];
    for (NSIndexPath *indexPath in items) {
        RCMessageModel *model = self.conversationDataRepository[indexPath.row];
        if (model) {
            [models addObject:model];
        }
        if ([model rrs_shouldResponseReadReceiptV5]) {
                [messageUIDs addObject:model.messageUId];
        }
    }
    if (messageUIDs.count) {
        RCConversationIdentifier *identifier = [RCConversationIdentifier new];
        identifier.targetId = self.targetId;
        identifier.type = self.conversationType;
        [[RCCoreClient sharedCoreClient] sendReadReceiptResponseV5:identifier
                                                       messageUIds:messageUIDs
                                                        completion:^(RCErrorCode code) {
            if (code == RC_SUCCESS) {
                for (RCMessageModel *model in models) {
                    model.sentReceipt = YES;
                }
            }
        }];
    }
}

- (void)rrs_didReceiveMessageReadReceiptResponses:(NSArray<RCReadReceiptResponseV5 *> *)responses {
    
    for (RCReadReceiptResponseV5 *response in responses) {
        if ([response.identifier.targetId isEqualToString:self.targetId] &&
             self.conversationType == response.identifier.type) {
            for (int i = 0; i < self.conversationDataRepository.count; i++) {
                RCMessageModel *model = self.conversationDataRepository[i];
                if ([model.messageUId isEqualToString:response.messageUId]) {
                    model.readReceiptCount = response.readCount;
                    //onReceiveMessageReadReceiptRequest 方法里面发送通知延时处理，response 不延时，会导致时序错乱
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_READCOUNT messageId:model.messageId progress:model.readReceiptCount];
                    });
                }
            }
        }
    }
    
}
@end
