//
//  RCStickerHTTPUtility.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/15.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCStickerHTTPRequestResult.h"

@interface RCStickerHTTPUtility : NSObject

/**
 从 server 同步所有的表情包配置

 @param completionHandle 请求完成回调
 */
+ (void)syncAllPackagesConfig:(void (^)(RCStickerHTTPRequestResult *result))completionHandle;

/**
 通过 packageId 获取表情包 zip 文件的 url

 @param packageId 表情包 Id
 @param completionHandle 请求完成回调
 */
+ (void)getPackageZipWith:(NSString *)packageId
         completionHandle:(void (^)(RCStickerHTTPRequestResult *result))completionHandle;

/**
 通过 packageId 和 stickerId 到 server 获取对应表情

 @param packageId 表情包 Id
 @param stickerId 表情 Id
 @param completionHandle 请求完成回调
 */
+ (void)getStickerWith:(NSString *)packageId
             stickerId:(NSString *)stickerId
      completionHandle:(void (^)(RCStickerHTTPRequestResult *result))completionHandle;

@end
