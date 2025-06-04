//
//  RCConversationListViewController+RRS.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/4.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationListViewController+RRS.h"
#import "RCConversationListDataSource.h"
#import "RCKitConfig.h"
#import "RCConversationCellUpdateInfo.h"
#import "RCMessageModel+RRS.h"

@interface RCConversationListViewController ()
@property (nonatomic, strong) RCConversationListDataSource *dataSource;

@end
@implementation RCConversationListViewController (RRS)

- (void)rrs_scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        NSArray *array = [self rrs_modelVisible];
        [self rrs_fetchReadReceiptInfoV5:array];
    }
}

- (void)rrs_scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSArray *array = [self rrs_modelVisible];
    [self rrs_fetchReadReceiptInfoV5:array];
}

- (void)rrs_fetchReadReceiptInfoV5ForVisibleModel {
    NSArray *array = [self rrs_modelVisible];
    [self rrs_fetchReadReceiptInfoV5:array];
}

- (NSArray *)rrs_modelVisible {
    NSArray *array = [self.conversationListTableView indexPathsForVisibleRows];
    NSMutableArray *items = [NSMutableArray array];
    for (NSIndexPath *path in array) {
        RCConversationModel *model = self.dataSource.dataList[path.row];
        if (model) {
            [items addObject:model];
        }
    }
    return items;
}

- (void)rrs_fetchReadReceiptInfoV5:(NSArray<RCConversationModel *> *)models {
    
    if (ConnectionStatus_Connected != [[RCCoreClient sharedCoreClient] getConnectionStatus]){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self rrs_fetchReadReceiptInfoV5WithModel:models];
        });
    } else {
        [self rrs_fetchReadReceiptInfoV5WithModel:models];

    }
}
- (void)rrs_fetchReadReceiptInfoV5WithModel:(NSArray<RCConversationModel *> *)models {
    if (!models.count) {
        return;
    }
    for (RCConversationModel *model in models) {
        if (!model.lastestMessage) {
            continue;;
        }
        RCMessage *m = [[RCCoreClient sharedCoreClient] getMessage:model.lastestMessageId];
        RCMessageModel *msg = [RCMessageModel modelWithMessage:m];
        if ([msg rrs_couldFetchReadReceiptV5]) {
            RCConversationIdentifier *identifier = [RCConversationIdentifier new];
            identifier.targetId = model.targetId;
            identifier.type = model.conversationType;
            [[RCCoreClient sharedCoreClient] getMessageReadReceiptInfoV5:identifier messageUIds:@[msg.messageUId] completion:^(NSArray<RCReadReceiptInfoV5 *> * _Nullable infoList, RCErrorCode code) {
                if (code == RC_SUCCESS) {
                    if (infoList.count) {
                        RCReadReceiptInfoV5 *info = infoList.firstObject;
                        if (info.readCount == 0) {
                            return;
                        }
                        model.readReceiptCount = info.readCount;
                        if (model.lastestMessageDirection == MessageDirection_SEND &&
                            model.sentStatus != SentStatus_READ) {
                            model.sentStatus = SentStatus_READ;
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
                } else {
                }
            }];
            
        }
    }
    
}
@end
