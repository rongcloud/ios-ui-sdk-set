//
//  RCSightExtensionModule.h
//  RongSight
//
//  Created by RongCloud on 16/7/2.
//  Copyright © 2016年 Rong Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RongSightAdaptiveHeader.h"

/*!
 RongSight 插件类

 @discussion IMKit会通过这个类将RongSight加载起来。
 */
@interface RCSightExtensionModule : NSObject <RCExtensionModule>

@property (nonatomic, assign) BOOL isSightCameraHolding;
@property (nonatomic, assign) BOOL isSightPlayerHolding;

+ (instancetype)sharedInstance;

@end
