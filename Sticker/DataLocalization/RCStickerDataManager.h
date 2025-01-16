//
//  RCStickerDataManager.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/3.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RCStickerPackageConfig.h"
#import "RCStickerPackage.h"
#import "RCStickerSingle.h"

//发送该通知会触发 IMKit 刷新 TabSource
FOUNDATION_EXPORT NSString *const RCKitExtensionEmoticonTabNeedReloadNotification;

/**
 表情包正在下载时的通知
 @dission Notification 的 object 为 nil
 userInfo 为 NSDictionary 对象，@{@"packageId":packageId,@"progress":@(progress)}, 进度为100代表下载完成。
 */
FOUNDATION_EXPORT NSString *const RCStickersDownloadingNotification;

/**
 表情包下载失败的通知
 @dission Notification的object 为 nil
 userInfo 为 NSDictionary 对象，@{@"packageId":packageId,@"errorCode":@(errorCode)}
 */
FOUNDATION_EXPORT NSString *const RCStickersDownloadFiledNotification;

/**
 表情包扩展类型

 - RCStickerCategoryTypeRecommend: 推荐
 - RCStickerCategoryTypeUnknow: 未知
 */
typedef NS_ENUM(NSUInteger, RCStickerCategoryType) {
    RCStickerCategoryTypeRecommend = 0,
    RCStickerCategoryTypeUnknow = 1
};

/**
 表情包类型

 - RCStickerPackageTypePreload: 预加载
 - RCStickerPackageTypeManual: 直推
 - RCStickerPackageTypeUnknow: 未知类型
 */
typedef NS_ENUM(NSUInteger, RCStickerPackageType) {
    RCStickerPackageTypePreload = 0,
    RCStickerPackageTypeManual = 1,
    RCStickerPackageTypeUnknow = 2
};

/**
 Data localization manager
 */
@interface RCStickerDataManager : NSObject

+ (instancetype)sharedManager;

/**
 初始化单例类
 */
- (void)managerInitialize;

/**
 获取所有下载完成的表情包

 @return 表情包数组
 */
- (NSArray<RCStickerPackage *> *)getAllDownloadedPackages;

/**
 获取表情原图

 @param packageId 表情包 Id
 @param stickerId 表情 Id
 @param completeBlock 完成回调
 */
- (void)getStickerOriginalImage:(NSString *)packageId
                      stickerId:(NSString *)stickerId
                  completeBlock:(void (^)(NSData *originalImage))completeBlock;

/**
 获取表情缩略图

 @param packageId 表情包 Id
 @param stickerId 表情 Id
 @param completeBlock 完成回调
 */
- (void)getStickerThumbImage:(NSString *)packageId
                   stickerId:(NSString *)stickerId
               completeBlock:(void (^)(NSData *thumbImage))completeBlock;

/**
 开始下载表情包

 @param packageId 表情包 Id
 @param progressBlock 下载中回调
 @param successBlock 下载完成回调
 @param errorBlock 下载失败回调
 */
- (void)downloadPackagesZip:(NSString *)packageId
                   progress:(void (^)(int progress))progressBlock
                    success:(void (^)(NSArray<RCStickerSingle *> *stickers))successBlock
                      error:(void (^)(int errorCode))errorBlock;

/**
 通过表情包 Id 获取表情包 icon

 @param packageId 表情包 Id
 @return icon data
 */
- (NSData *)packageIconById:(NSString *)packageId;

/**
 通过表情包 Id 获取表情包 cover

 @param packageId 表情包 Id
 @return cover data
 */
- (NSData *)packageCoverById:(NSString *)packageId;

/**
 通过表情包 Id 获取表情包配置

 @param packageId 表情包 Id
 @return 表情包配置
 */
- (RCStickerPackageConfig *)packageConfigById:(NSString *)packageId;

/**
 删除表情包

 @param packageId 表情包 Id
 */
- (void)deletePackage:(NSString *)packageId;

/**
 获取表情包下载进度，如果未下载则返回nil

 @param packageId 表情包Id
 @return 下载进度
 */
- (NSNumber *)getDownloadProgress:(NSString *)packageId;

/**
 所有预加载的表情包 + 非预加载但是用户手动下载好的

 @return 表情包数组
 */
- (NSArray<RCStickerPackage *> *)getAllPackages;

/**
 扩展中所有的表情包配置

 @param categoryType 扩展类型
 @return 表情包配置数组
 */
- (NSArray<RCStickerPackageConfig *> *)getCategoryPackagesConfig:(RCStickerCategoryType)categoryType;

/**
 获取单个表情包中的表情个数

 @param packageId 表情包Id
 @return 表情个数
 */
- (int)getPackageStickerCount:(NSString *)packageId;

/**
 获取扩展页中的表情包个数

 @param categoryType 扩展类型
 @return 表情包个数
 */
- (int)getCategoryPackageCount:(RCStickerCategoryType)categoryType;

/**
 通过表情包 Id 获取所有表情

 @param packageId 表情包 Id
 @return 表情数组
 */
- (NSArray<RCStickerSingle *> *)getStickersWithPackageId:(NSString *)packageId;

@end
