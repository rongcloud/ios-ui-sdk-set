//
//  RCiFlyKitExtensionModule.h
//  RongiFlyKit
//
//  Created by Sin on 16/11/15.
//  Copyright © 2016年 Sin. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<RongIMKit/RongIMKit.h>)
#import <RongIMKit/RongIMKit.h>
#else
#import "RongIMKit.h"
#endif

@interface RCiFlyKitExtensionModule : NSObject <RongIMKitExtensionModule, RCExtensionModule>
@property (nonatomic, assign) BOOL isSpeechHolding;

+ (instancetype)sharedRCiFlyKitExtensionModule;
- (void)setiFlyAppkey:(NSString *)key;
@end
