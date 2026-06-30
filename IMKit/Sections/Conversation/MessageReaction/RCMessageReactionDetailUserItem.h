//
//  RCMessageReactionDetailUserItem.h
//  RongIMKit
//
//  Created by RC on 2026/6/12.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RCMessageReactionUser;

@interface RCMessageReactionDetailUserItem : NSObject

@property (nonatomic, strong) RCMessageReactionUser *user;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy, nullable) NSString *portraitUri;

- (instancetype)initWithUser:(RCMessageReactionUser *)user
                 displayName:(NSString *)displayName
                 portraitUri:(nullable NSString *)portraitUri;

@end

NS_ASSUME_NONNULL_END
