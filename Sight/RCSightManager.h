//
//  RCSightManager.h
//  RongSight
//
//  Created by Jue on 2018/11/15.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RongSight.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCSightManager : NSObject

/**
 初始化RCSightViewController

 @param mode 功能模式
 @return 返回RCSightViewController实例
 */
+ (id)createSightViewControllerWithCaptureMode:(NSUInteger)mode;

/**
 初始化RCSightPlayerController

 @param assetURL 视频的本地或者远程url
 @param isauto 初始化完成后是否自动开始播放
 @return 返回SightPlayerController实例
 */
+ (id)createSightPlayerControllerWithURL:(NSURL *)assetURL autoPlay:(BOOL)isauto;

@end

NS_ASSUME_NONNULL_END
