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
#import "RCRRSUtil.h"

@interface RCConversationViewController ()
@property (nonatomic, strong) RCConversationVCUtil *util;

@end

@implementation RCConversationViewController (RRS)

- (void)rrs_observeReadReceiptV5 {
    [[RCCoreClient sharedCoreClient] addReadReceiptV5Delegate:self];
}

- (void)rrs_didReceiveMessageReadReceiptResponses:(NSArray<RCReadReceiptResponseV5 *> *)responses {
    for (RCReadReceiptResponseV5 *response in responses) {
        if ([response.identifier.targetId isEqualToString:self.targetId] &&
             self.conversationType == response.identifier.type) {
            for (int i = 0; i < self.conversationDataRepository.count; i++) {
                RCMessageModel *model = self.conversationDataRepository[i];
                if ([model.messageUId isEqualToString:response.messageUId]) {
                    model.readReceiptInfoV5 = [RCRRSUtil infoFromResponse:response];
                    //onReceiveMessageReadReceiptRequest 方法里面发送通知延时处理，response 不延时，会导致时序错乱
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.util sendMessageReadReceiptV5Notification:model];
                    });
                }
            }
        }
    }
    
}
@end
