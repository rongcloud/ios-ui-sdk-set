//
//  RCConversationViewController+internal.h
//  RongIMKit
//
//  Created by RongCloud on 2020/12/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#ifndef RCConversationViewController_internal_h
#define RCConversationViewController_internal_h
@interface RCConversationViewController ()
@property (nonatomic, strong, readonly) RCConversationVCUtil *util;
@property (nonatomic, strong, readonly) RCConversationCSUtil *csUtil;
@property (nonatomic, strong, readonly) RCConversationCollectionViewHeader *collectionViewHeader;
@property (nonatomic, assign, readonly) BOOL isConversationAppear;
@property (nonatomic, assign) BOOL sendMsgAndNeedScrollToBottom;

- (void)updateUnreadMsgCountLabel;
- (void)updateForMessageSendSuccess:(long)messageId content:(RCMessageContent *)content;
- (void)fetchPublicServiceProfile;
@end

#endif /* RCConversationViewController_internal_h */
