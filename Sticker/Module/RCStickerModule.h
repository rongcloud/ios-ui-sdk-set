//
//  RCStickerModule.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RongIMKitHeader.h"

@interface RCStickerModule : NSObject <RongIMKitExtensionModule>

@property (nonatomic, assign) RCConversationType conversationType;

@property (nonatomic, strong) NSString *currentTargetId;

@property (nonatomic, strong) NSString *appKey;

@property (nonatomic, strong) NSString *userId;

@property (nonatomic, strong) RCUserInfo *userInfo;

+ (instancetype)sharedModule;

- (void)reloadEmoticonTabSource;

@end
