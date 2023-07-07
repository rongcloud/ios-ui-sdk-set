//
//  RCForwardManager.h
//  SealTalk
//
//  Created by 孙浩 on 2019/6/17.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCForwardManager : NSObject

+ (RCForwardManager *)sharedInstance;

- (void)doForwardMessageList:(NSArray *)messageList
            conversationList:(NSArray *)conversationList
                   isCombine:(BOOL)isCombine
     forwardConversationType:(RCConversationType)forwardConversationType
                   completed:(void (^)(BOOL success))completedBlock;

@end

NS_ASSUME_NONNULL_END
