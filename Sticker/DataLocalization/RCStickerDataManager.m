//
//  RCStickerDataManager.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/3.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerDataManager.h"
#import "RCStickerHTTPUtility.h"
#import "RCStickerDownloader.h"
#import "RCUnzip.h"
#import "RCStickerModule.h"
#import "RCStickerUtility.h"
#import "RCSThreadLock.h"


NSString *const RCStickersDownloadingNotification = @"RCStickersDownloadingNotification";

NSString *const RCStickersDownloadFiledNotification = @"RCStickersDownloadFiledNotification";

#define FileManager [NSFileManager defaultManager]

// Directory name
#define RCStickerDiskTotalDir @"RongSticker"
#define RCStickerDiskStickersResourceDir @"Stickers_resource"
#define RCStickerDiskPackagesDir @"Packages"

// file name
#define RCStickerDiskPackagesConfig @"stickerPackagesConfig.plist"
#define RCStickerDiskPackages @"packages.plist"

// dict key
#define RCStickerPreloadKey @"preload"
#define RCStickerManualLoadKey @"manualLoad"
#define RCStickerStickersKey @"stickers"

@interface RCStickerDataManager ()

/**
 服务端下发的表情包配置（预加载）
 */
@property (nonatomic, strong) NSMutableArray *preloadPackagesConfig;

/**
 服务端下发的表情包配置
 */
@property (nonatomic, strong) NSMutableArray *manualLoadPackagesConfig;

/**
 本地的表情包（预加载）
 */
@property (nonatomic, strong) NSMutableArray *preloadPackages;

/**
 本地的表情包
 */
@property (nonatomic, strong) NSMutableArray *manualLoadPackages;

/**
 正在下载的表情包
 */
@property (nonatomic, strong) NSMutableDictionary *downloadingPackages;

@property(nonatomic, strong) RCSThreadLock *packagesConfigLock;
@property(nonatomic, strong) RCSThreadLock *preloadPackagesLock;
@property(nonatomic, strong) RCSThreadLock *manualLoadPackagesLock;
@property(nonatomic, strong) RCSThreadLock *downloadingPackagesLock;
@end

@implementation RCStickerDataManager

+ (instancetype)sharedManager {
    static RCStickerDataManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[RCStickerDataManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.downloadingPackages = [[NSMutableDictionary alloc] init];
        self.packagesConfigLock = [[RCSThreadLock alloc] init];
        self.preloadPackagesLock = [[RCSThreadLock alloc] init];
        self.manualLoadPackagesLock = [[RCSThreadLock alloc] init];
        self.downloadingPackagesLock = [[RCSThreadLock alloc] init];
        [self managerInitialize];
    }
    return self;
}

#pragma mark - preloadPackages

- (NSArray *)preloadPackagesData {
    __block NSArray *array = nil;
    [self.preloadPackagesLock performReadLockBlock:^{
        array = [self.preloadPackages copy];
    }];
    return array;
}

- (void)savePreloadPackages:(NSArray *)array {
    [self.preloadPackagesLock performWriteLockBlock:^{
        [self.preloadPackages removeAllObjects];
        if (array) {
            [self.preloadPackages addObjectsFromArray:array];
        }
    }];
}

- (NSMutableArray *)preloadPackages {
    if (!_preloadPackages) {
        _preloadPackages = [[NSMutableArray alloc] init];
    }
    return _preloadPackages;
}

#pragma mark - manualLoadPackages

- (NSArray *)manualLoadPackagesData {
    __block NSArray *array = nil;
    [self.manualLoadPackagesLock performReadLockBlock:^{
        array = [self.manualLoadPackages copy];
    }];
    return array;
}

- (void)saveManualLoadPackages:(NSArray *)array {
    [self.manualLoadPackagesLock performWriteLockBlock:^{
        [self.manualLoadPackages removeAllObjects];
        if (array) {
            [self.manualLoadPackages addObjectsFromArray:array];
        }
    }];
}

- (void)removeManualLoadPackages:(id)obj {
    [self.manualLoadPackagesLock performWriteLockBlock:^{
        if (obj) {
            [self.manualLoadPackages removeObject:obj];
        }
    }];
}

- (void)insertManualLoadPackages:(id)obj {
    [self.manualLoadPackagesLock performWriteLockBlock:^{
        if (obj) {
            [self.manualLoadPackages insertObject:obj atIndex:0];
        }
    }];
}

- (NSMutableArray *)manualLoadPackages {
    if (!_manualLoadPackages) {
        _manualLoadPackages = [NSMutableArray array];
    }
    return _manualLoadPackages;
}

#pragma mark - preloadPackagesConfig

- (NSArray *)preloadPackagesConfigData {
    __block NSArray *array = nil;
    [self.packagesConfigLock performReadLockBlock:^{
        array = [self.preloadPackagesConfig copy];
    }];
    return array;
}

- (void)savePreloadPackagesConfig:(NSArray *)array {
    [self.packagesConfigLock performWriteLockBlock:^{
        [self.preloadPackagesConfig removeAllObjects];
        if (array) {
            [self.preloadPackagesConfig addObjectsFromArray:array];
        }
    }];
}

- (NSMutableArray *)preloadPackagesConfig {
    if (!_preloadPackagesConfig) {
        _preloadPackagesConfig = [NSMutableArray array];
    }
    return _preloadPackagesConfig;
}

#pragma mark - manualLoadPackagesConfig

- (NSArray *)manualLoadPackagesConfigData {
    __block NSArray *array = nil;
    [self.packagesConfigLock performReadLockBlock:^{
        array = [self.manualLoadPackagesConfig copy];
    }];
    return array;
}

- (void)saveManualLoadPackagesConfig:(NSArray *)array {
    [self.preloadPackagesLock performWriteLockBlock:^{
        [self.manualLoadPackagesConfig removeAllObjects];
        if (array) {
            [self.manualLoadPackagesConfig addObjectsFromArray:array];
        }
    }];
}

- (NSMutableArray *)manualLoadPackagesConfig {
    if (!_manualLoadPackagesConfig) {
        _manualLoadPackagesConfig = [NSMutableArray array];
    }
    return _manualLoadPackagesConfig;
}

#pragma mark - downloadingPackages

- (void)saveDownladingPackage:(id)obj forKey:(NSString *)key {
    if (!key) {
        return;
    }
    [self.downloadingPackagesLock performWriteLockBlock:^{
        self.downloadingPackages[key] = obj;
    }];
}

- (id)downladingPackageForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    __block id obj = nil;
    [self.downloadingPackagesLock performReadLockBlock:^{
        obj = self.downloadingPackages[key];
    }];
    return obj;
}

- (void)removeDownloadingPackageForKey:(NSString *)key {
    [self saveDownladingPackage:nil forKey:key];
}

- (void)managerInitialize {

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    //创建所有的本地化文件夹
    [self createDirectoryIfNeed];

    //使用本地已有的数据将内存数组填充
    [self fillMemoryCacheData];

    //从服务端同步表情包配置
    [self syncPackagesConfig];
}

- (void)createDirectoryIfNeed {

    if (![FileManager fileExistsAtPath:[self stickersTotalDirPath]]) {
        [FileManager createDirectoryAtPath:[self stickersTotalDirPath]
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    if (![FileManager fileExistsAtPath:[self packagesDirPath]]) {
        [FileManager createDirectoryAtPath:[self packagesDirPath]
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    if (![FileManager fileExistsAtPath:[self stickersResourceDirPath]]) {
        [FileManager createDirectoryAtPath:[self stickersResourceDirPath]
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    if (![FileManager fileExistsAtPath:[self packagesConfigPath]]) {
        [FileManager createFileAtPath:[self packagesConfigPath] contents:nil attributes:nil];
    }
    if (![FileManager fileExistsAtPath:[self packagesPath]]) {
        [FileManager createFileAtPath:[self packagesPath] contents:nil attributes:nil];
    }
}

- (void)fillMemoryCacheData {

    NSMutableDictionary *totalPackageConfigDict =
        [NSMutableDictionary dictionaryWithContentsOfFile:[self packagesConfigPath]];
   NSArray *preloadPackagesConfig = [[RCStickerPackageConfig
       modelArrayWithDictArray:[totalPackageConfigDict objectForKey:RCStickerPreloadKey]] mutableCopy];
    [self savePreloadPackagesConfig:preloadPackagesConfig];
    
    NSArray *manualLoadPackagesConfig = [[RCStickerPackageConfig
        modelArrayWithDictArray:[totalPackageConfigDict objectForKey:RCStickerManualLoadKey]] mutableCopy];
    [self saveManualLoadPackagesConfig:manualLoadPackagesConfig];

    NSMutableDictionary *totalPackageDict = [NSMutableDictionary dictionaryWithContentsOfFile:[self packagesPath]];
    NSArray *preloadPackages =  [[RCStickerPackage modelArrayWithDictArray:[totalPackageDict objectForKey:RCStickerPreloadKey]] mutableCopy];
    [self savePreloadPackages:preloadPackages];
    
    NSArray *manualLoadPackages =
    [[RCStickerPackage modelArrayWithDictArray:[totalPackageDict objectForKey:RCStickerManualLoadKey]] mutableCopy];
    [self saveManualLoadPackages:manualLoadPackages];
}

- (void)syncPackagesConfig {

    __weak typeof(self) weakSelf = self;
    [RCStickerHTTPUtility syncAllPackagesConfig:^(RCStickerHTTPRequestResult *result) {
        // Server 数据下来先将packagesConfig内存数组更新
        if (result.success) {
            NSDictionary *totalPackageConfigDict = result.data;
           NSArray *preloadPackagesConfig = [[RCStickerPackageConfig
                modelArrayWithDictArray:[totalPackageConfigDict objectForKey:RCStickerPreloadKey]] mutableCopy];
            [weakSelf savePreloadPackagesConfig:preloadPackagesConfig];
            
            NSArray *manualLoadPackagesConfig = [[RCStickerPackageConfig
                                                  modelArrayWithDictArray:[totalPackageConfigDict objectForKey:RCStickerManualLoadKey]] mutableCopy];
            [self saveManualLoadPackagesConfig:manualLoadPackagesConfig];
            
            [weakSelf refreshStickersModule];

            //下载icon和cover
            [weakSelf handleIconAndCover];

            //处理预加载数据
            [weakSelf handlePreloadPackages];
        }
    }];
}

/**
 处理icon和cover
 */
- (void)handleIconAndCover {
    NSArray *preloadPackagesConfig = [self preloadPackagesConfigData];
    NSMutableArray *tmpArray = [NSMutableArray arrayWithArray:[preloadPackagesConfig copy]];
    NSArray *manualLoadPackagesConfig = [self manualLoadPackagesConfigData];
    [tmpArray addObjectsFromArray:[manualLoadPackagesConfig copy]];
    for (RCStickerPackageConfig *packageConfig in tmpArray) {
        if (![self packageIconById:packageConfig.packageId]) {
            [self getPackageIcon:packageConfig.packageId
                   completeBlock:^(NSData *icon){
                   }];
        }
        if (![self packageCoverById:packageConfig.packageId]) {
            [self getPackageCover:packageConfig.packageId
                    completeBlock:^(NSData *cover){
                    }];
        }
    }
}

/**
 处理预加载数据
 */
- (void)handlePreloadPackages {
    //先将本地预加载表情包中未下载好的移除，并且删除新拉下来的数据中不包含的表情包
    NSArray *array = [self preloadPackagesData];
    NSMutableArray *copyArray = [array mutableCopy];
    NSMutableArray *preloadPackages = [NSMutableArray array];
    NSArray *preloadPackagesConfig = [self preloadPackagesConfigData];
    for (RCStickerPackageConfig *packageConfig in preloadPackagesConfig) {
        BOOL isDownloaded = NO;
        BOOL isDeleted = NO;
        for (RCStickerPackage *copyPackage in copyArray) {
            if ([copyPackage.packageId isEqualToString:packageConfig.packageId]) {
                isDownloaded = copyPackage.isDownloaded;
                isDeleted = copyPackage.isDeleted;
                break;
            }
        }
        RCStickerPackage *package = [[RCStickerPackage alloc] init];
        [package setConfig:packageConfig];
        package.isDownloaded = isDownloaded;
        package.isDeleted = isDeleted;
        [preloadPackages addObject:package];
    }
    [self savePreloadPackages:preloadPackages];
    for (RCStickerPackage *package in preloadPackages) {
        if (package.isDownloaded == NO && package.isDeleted == NO) {
            [self downloadPackagesZip:package.packageId
                progress:^(int progress) {

                }
                success:^(NSArray<RCStickerSingle *> *stickers) {

                }
                error:^(int errorCode){

                }];
        }
    }
}

- (void)downloadPackagesZip:(NSString *)packageId
                   progress:(void (^)(int progress))progressBlock
                    success:(void (^)(NSArray<RCStickerSingle *> *stickers))successBlock
                      error:(void (^)(int errorCode))errorBlock {

    __weak typeof(self) weakSelf = self;
    [self saveDownladingPackage:@(0) forKey:packageId];
    [RCStickerHTTPUtility
        getPackageZipWith:packageId
         completionHandle:^(RCStickerHTTPRequestResult *result) {
             NSDictionary *dataDict = result.data;
             NSString *downloadURL = [dataDict objectForKey:@"downloadUrl"];
             if (result.success && downloadURL) {
                 [[RCStickerDownloader shareDownloader] downloadWithURLString:downloadURL
                     identifier:packageId
                     progress:^(int progress) {
                     [weakSelf saveDownladingPackage:@(progress) forKey:packageId];
                         [[NSNotificationCenter defaultCenter] postNotificationName:RCStickersDownloadingNotification
                                                                             object:nil
                                                                           userInfo:@{
                                                                               @"packageId" : packageId,
                                                                               @"progress" : @(progress)
                                                                           }];
                         if (progressBlock) {
                             progressBlock(progress);
                         }
                     }
                     success:^(NSURL *localURL) {
                         NSString *zipPath =
                             [NSString stringWithFormat:@"%@/%@.zip", [self packagesDirPath], packageId];
                         [FileManager createFileAtPath:zipPath contents:nil attributes:nil];
                         [FileManager replaceItemAtURL:[NSURL fileURLWithPath:zipPath isDirectory:NO]
                                         withItemAtURL:[NSURL fileURLWithPath:[localURL path] isDirectory:NO]
                                        backupItemName:nil
                                               options:0
                                      resultingItemURL:nil
                                                 error:nil];
                         BOOL zipSuccess =
                             unzipFile((char *)[zipPath UTF8String], (char *)[[self packagesDirPath] UTF8String]);
                         if (!zipSuccess) {
                             [weakSelf removeDownloadingPackageForKey:packageId];
                             [[NSNotificationCenter defaultCenter]
                                 postNotificationName:RCStickersDownloadFiledNotification
                                               object:nil
                                             userInfo:@{
                                                 @"packageId" : packageId,
                                                 @"errorCode" : @(0)
                                             }];
                             if (errorBlock) {
                                 errorBlock(0);
                             }
                             RongStickerLog(@"unzip failed path: %@", zipPath);
                             return;
                         }
                         NSString *zipDirPath =
                             [NSString stringWithFormat:@"%@/%@/", [self packagesDirPath], packageId];

                         // 2: json文件直接以 packageId 命名存下来，里面存放所有表情数据
                         NSArray<RCStickerSingle *> *stickers;
                         NSString *stickersPath = [[self packagesDirPath]
                             stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", packageId]];
                         NSString *jsonPath = [zipDirPath stringByAppendingPathComponent:@"meta.json"];
                         if ([FileManager fileExistsAtPath:jsonPath]) {
                             NSData *dictData = [NSData dataWithContentsOfFile:jsonPath];
                             NSDictionary *stickersDict =
                                 [NSJSONSerialization JSONObjectWithData:dictData options:kNilOptions error:nil];
                             [stickersDict writeToFile:stickersPath atomically:YES];
                             stickers = [RCStickerSingle
                                 modelArrayWithDictArray:[stickersDict objectForKey:RCStickerStickersKey]];
                         } else {
                             [weakSelf removeDownloadingPackageForKey:packageId];
                             [[NSNotificationCenter defaultCenter]
                                 postNotificationName:RCStickersDownloadFiledNotification
                                               object:nil
                                             userInfo:@{
                                                 @"packageId" : packageId,
                                                 @"errorCode" : @(0)
                                             }];
                             RongStickerLog(@"resource:%@ can't find meta.json at path: %@", downloadURL, zipPath);
                             if (errorBlock) {
                                 errorBlock(0);
                             }
                             return;
                         }

                         // 3: 所有的图片直接放到 Stickers_resource 路径下
                         NSDirectoryEnumerator *enumerator;
                         enumerator = [FileManager enumeratorAtPath:zipDirPath];
                         NSString *fileName;
                         while ((fileName = [enumerator nextObject]) != nil) {
                             if ([[fileName pathExtension] isEqualToString:@"png"] ||
                                 [[fileName pathExtension] isEqualToString:@"jpg"] ||
                                 [[fileName pathExtension] isEqualToString:@"gif"]) {
                                 NSError *error;
                                 [FileManager moveItemAtPath:[zipDirPath stringByAppendingPathComponent:fileName]
                                                      toPath:[[self stickersResourceDirPath]
                                                                 stringByAppendingPathComponent:fileName]
                                                       error:&error];
                             }
                         }

                         [FileManager removeItemAtPath:zipPath error:nil];
                         [FileManager removeItemAtPath:zipDirPath error:nil];

                         // 4: 将本地isDownload属性置成YES,内存中的下载进度变成 100
                     [weakSelf removeDownloadingPackageForKey:packageId];

                         RCStickerPackageType packageType = [self getPackageType:packageId];
                         if (packageType == RCStickerPackageTypePreload) {
                             RCStickerPackage *package = [self packageById:packageId];
                             package.isDownloaded = YES;
                         } else if (packageType == RCStickerPackageTypeManual) {
                             RCStickerPackageConfig *config = [self packageConfigById:packageId];
                             RCStickerPackage *package = [[RCStickerPackage alloc] init];
                             [package setConfig:config];
                             package.isDownloaded = YES;
                             package.isDeleted = NO;
                             [self insertManualLoadPackages:package];
                         }

                         // 5: 将json文件转换成 NSArray<RCStickerSingle *> 格式返回给block
                         if (successBlock) {
                             successBlock(stickers);
                         }

                         // 6: 发出通知
                         [[NSNotificationCenter defaultCenter] postNotificationName:RCStickersDownloadingNotification
                                                                             object:nil
                                                                           userInfo:@{
                                                                               @"packageId" : packageId,
                                                                               @"progress" : @(100)
                                                                           }];

                         // 7: 刷新ExtensionKit
                         [weakSelf refreshStickersModule];

                         // 8: 同步本地沙盒数据
                         [weakSelf writeDataInDisk];

                     }
                     error:^(int errorCode) {
//                         [weakSelf.downloadingPackages removeObjectForKey:packageId];
                            [weakSelf removeDownloadingPackageForKey:packageId];

                         [[NSNotificationCenter defaultCenter] postNotificationName:RCStickersDownloadFiledNotification
                                                                             object:nil
                                                                           userInfo:@{
                                                                               @"packageId" : packageId,
                                                                               @"errorCode" : @(errorCode)
                                                                           }];
                         if (errorBlock) {
                             errorBlock(errorCode);
                         }
                     }];

             } else {
                 [weakSelf removeDownloadingPackageForKey:packageId];

                 [[NSNotificationCenter defaultCenter] postNotificationName:RCStickersDownloadFiledNotification
                                                                     object:nil
                                                                   userInfo:@{
                                                                       @"packageId" : packageId,
                                                                       @"errorCode" : @(0)
                                                                   }];
                 if (errorBlock) {
                     errorBlock(0);
                 }
             }
         }];
}

#pragma mark - Local data query

- (RCStickerPackage *)packageById:(NSString *)packageId {
    NSArray *preloadPackages = [self preloadPackagesData];
    for (RCStickerPackage *package in preloadPackages) {
        if ([package.packageId isEqualToString:packageId]) {
            return package;
        }
    }
    NSArray *manualLoadPackages = [self manualLoadPackagesData];
    for (RCStickerPackage *package in manualLoadPackages) {
        if ([package.packageId isEqualToString:packageId]) {
            return package;
        }
    }
    return nil;
}

- (RCStickerPackageConfig *)packageConfigById:(NSString *)packageId {
    NSArray *preloadPackagesConfig = [self preloadPackagesConfigData];
    for (RCStickerPackageConfig *packageConfig in preloadPackagesConfig) {
        if ([packageConfig.packageId isEqualToString:packageId]) {
            return packageConfig;
        }
    }
    
    NSArray *manualLoadPackagesConfig = [self manualLoadPackagesConfigData];
    for (RCStickerPackageConfig *packageConfig in manualLoadPackagesConfig) {
        if ([packageConfig.packageId isEqualToString:packageId]) {
            return packageConfig;
        }
    }
    return nil;
}

- (NSData *)packageIconById:(NSString *)packageId {
    __weak typeof(self) weakSelf = self;
    NSString *iconFileName = [NSString stringWithFormat:@"icon_%@", packageId];
    NSString *iconPath = [[self stickersResourceDirPath] stringByAppendingPathComponent:iconFileName];
    NSData *iconData = [self getImageDataWithPath:iconPath];
    if (iconData) {
        return iconData;
    } else {
        [self getPackageIcon:packageId
               completeBlock:^(NSData *icon) {
                   if (icon) {
                       [weakSelf refreshStickersModule];
                   }
               }];
    }
    return nil;
}

- (NSData *)packageCoverById:(NSString *)packageId {
    __weak typeof(self) weakSelf = self;
    NSString *coverFileName = [NSString stringWithFormat:@"cover_%@", packageId];
    NSString *coverPath = [[self stickersResourceDirPath] stringByAppendingPathComponent:coverFileName];
    NSData *coverData = [self getImageDataWithPath:coverPath];
    if (coverData) {
        return coverData;
    } else {
        [self getPackageCover:packageId
                completeBlock:^(NSData *cover) {
                    if (cover) {
                        [weakSelf refreshStickersModule];
                    }
                }];
    }
    return nil;
}

- (NSArray<RCStickerSingle *> *)getStickersWithPackageId:(NSString *)packageId {
    NSString *stickersPath =
        [[self packagesDirPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", packageId]];
    if (![FileManager fileExistsAtPath:stickersPath]) {
        return nil;
    }
    NSDictionary *stickersDict = [NSDictionary dictionaryWithContentsOfFile:stickersPath];
    NSArray<RCStickerSingle *> *stickers =
        [RCStickerSingle modelArrayWithDictArray:[stickersDict objectForKey:RCStickerStickersKey]];
    return stickers;
}

- (RCStickerSingle *)getStickerWithPackageId:(NSString *)packageId stickerId:(NSString *)stickerId {
    NSArray<RCStickerSingle *> *stickers = [self getStickersWithPackageId:packageId];
    RCStickerSingle *sticker;
    for (RCStickerSingle *tmpSticker in stickers) {
        if ([tmpSticker.stickerId isEqualToString:stickerId]) {
            sticker = tmpSticker;
            break;
        }
    }
    return sticker;
}

#pragma mark - Open interface

- (NSArray<RCStickerPackage *> *)getAllDownloadedPackages {
    NSMutableArray *allDownloadedPackges = [[NSMutableArray alloc] init];
    NSArray *preloadPackages = [self preloadPackagesData];
    for (RCStickerPackage *package in preloadPackages) {
        if (package.isDownloaded) {
            RCStickerPackageConfig *packageConfig = [self packageConfigById:package.packageId];
            if (packageConfig) {
                [allDownloadedPackges addObject:packageConfig];
            }
        }
    }
    NSArray *manualLoadPackages = [self manualLoadPackagesData];
    for (RCStickerPackage *package in manualLoadPackages) {
        if (package.isDownloaded) {
            [allDownloadedPackges addObject:package];
        }
    }
    return [allDownloadedPackges copy];
}

- (void)getPackageIcon:(NSString *)packageId completeBlock:(void (^)(NSData *icon))completeBlock {
    __block RCStickerPackageConfig *blockPackageConfig = [self packageConfigById:packageId];
    [[RCStickerDownloader shareDownloader] downloadWithURLString:blockPackageConfig.icon
        identifier:[NSString stringWithFormat:@"icon_%@", blockPackageConfig.packageId]
        progress:^(int progress) {

        }
        success:^(NSURL *localURL) {
            NSData *iconData = [NSData dataWithContentsOfURL:localURL];
            NSString *pathExtension = [blockPackageConfig.icon pathExtension];
            NSString *iconName = [NSString stringWithFormat:@"icon_%@.%@", blockPackageConfig.packageId, pathExtension];
            NSString *iconPath = [[self stickersResourceDirPath] stringByAppendingPathComponent:iconName];
            BOOL moveSuccess =
                [FileManager moveItemAtURL:localURL toURL:[NSURL fileURLWithPath:iconPath isDirectory:NO] error:nil];
            if (moveSuccess) {
                if (completeBlock) {
                    completeBlock(iconData);
                }
            } else {
                if (completeBlock) {
                    completeBlock(nil);
                }
            }
        }
        error:^(int errorCode) {
            if (completeBlock) {
                completeBlock(nil);
            }
        }];
}

- (void)getPackageCover:(NSString *)packageId completeBlock:(void (^)(NSData *cover))completeBlock {
    __block RCStickerPackageConfig *blockPackageConfig = [self packageConfigById:packageId];
    [[RCStickerDownloader shareDownloader] downloadWithURLString:blockPackageConfig.cover
        identifier:[NSString stringWithFormat:@"cover_%@", blockPackageConfig.packageId]
        progress:^(int progress) {

        }
        success:^(NSURL *localURL) {
            NSData *coverData = [NSData dataWithContentsOfURL:localURL];
            NSString *pathExtension = [blockPackageConfig.cover pathExtension];
            NSString *coverName =
                [NSString stringWithFormat:@"cover_%@.%@", blockPackageConfig.packageId, pathExtension];
            NSString *coverPath = [[self stickersResourceDirPath] stringByAppendingPathComponent:coverName];
            BOOL moveSuccess =
                [FileManager moveItemAtURL:localURL toURL:[NSURL fileURLWithPath:coverPath isDirectory:NO] error:nil];
            if (moveSuccess) {
                if (completeBlock) {
                    completeBlock(coverData);
                }
            } else {
                if (completeBlock) {
                    completeBlock(nil);
                }
            }
        }
        error:^(int errorCode) {
            if (completeBlock) {
                completeBlock(nil);
            }
        }];
}

- (NSNumber *)getDownloadProgress:(NSString *)packageId {
    NSNumber *progress = [self downladingPackageForKey:packageId];
    if (progress) {
        return progress;
    }
    return nil;
}

- (void)getStickerOriginalImage:(NSString *)packageId
                      stickerId:(NSString *)stickerId
                  completeBlock:(void (^)(NSData *originalImage))completeBlock {
    __weak typeof(self) weakSelf = self;
    NSString *imageName = [NSString stringWithFormat:@"image_%@", stickerId];
    NSString *imagePath = [[self stickersResourceDirPath] stringByAppendingPathComponent:imageName];
    NSData *imageData = [self getImageDataWithPath:imagePath];
    if (imageData && completeBlock) {
        completeBlock(imageData);
    } else {
        //先从服务端拿URL，再去七牛取图片
        [RCStickerHTTPUtility
              getStickerWith:packageId
                   stickerId:stickerId
            completionHandle:^(RCStickerHTTPRequestResult *result) {
                NSDictionary *dataDict = result.data;
                NSString *url = [dataDict objectForKey:@"url"];
                if (result.success && url) {
                    [[RCStickerDownloader shareDownloader] downloadWithURLString:url
                        identifier:stickerId
                        progress:^(int progress) {

                        }
                        success:^(NSURL *localURL) {
                            NSData *imageData = [NSData dataWithContentsOfURL:localURL];
                            if (completeBlock) {
                                completeBlock(imageData);
                            }
                            NSString *pathExtension = [url pathExtension];
                            NSString *imageName = [NSString stringWithFormat:@"image_%@.%@", stickerId, pathExtension];
                            NSString *imagePath =
                                [[weakSelf stickersResourceDirPath] stringByAppendingPathComponent:imageName];
                            [FileManager moveItemAtURL:localURL toURL:[NSURL fileURLWithPath:imagePath] error:nil];
                        }
                        error:^(int errorCode) {
                            if (completeBlock) {
                                completeBlock(nil);
                            }
                        }];
                } else {
                    if (completeBlock) {
                        completeBlock(nil);
                    }
                }
            }];
    }
}

- (void)getStickerThumbImage:(NSString *)packageId
                   stickerId:(NSString *)stickerId
               completeBlock:(void (^)(NSData *thumbImage))completeBlock {
    __weak typeof(self) weakSelf = self;
    NSString *imageName = [NSString stringWithFormat:@"thumb_%@", stickerId];
    NSString *imagePath = [[self stickersResourceDirPath] stringByAppendingPathComponent:imageName];
    NSData *imageData = [self getImageDataWithPath:imagePath];
    if (imageData && completeBlock) {
        completeBlock(imageData);
    } else {
        [RCStickerHTTPUtility
              getStickerWith:packageId
                   stickerId:stickerId
            completionHandle:^(RCStickerHTTPRequestResult *result) {
                NSDictionary *dataDict = result.data;
                NSString *thumbUrl = [dataDict objectForKey:@"thumbUrl"];
                if (result.success && thumbUrl) {
                    [[RCStickerDownloader shareDownloader] downloadWithURLString:thumbUrl
                        identifier:stickerId
                        progress:^(int progress) {

                        }
                        success:^(NSURL *localURL) {
                            NSData *imageData = [NSData dataWithContentsOfURL:localURL];
                            if (completeBlock) {
                                completeBlock(imageData);
                            }
                            NSString *pathExtension = [thumbUrl pathExtension];
                            NSString *imageName = [NSString stringWithFormat:@"thumb_%@.%@", stickerId, pathExtension];
                            NSString *imagePath =
                                [[weakSelf stickersResourceDirPath] stringByAppendingPathComponent:imageName];
                            [FileManager moveItemAtURL:localURL toURL:[NSURL fileURLWithPath:imagePath] error:nil];
                        }
                        error:^(int errorCode) {
                            if (completeBlock) {
                                completeBlock(nil);
                            }
                        }];
                } else {
                    if (completeBlock) {
                        completeBlock(nil);
                    }
                }
            }];
    }
}

- (NSArray<RCStickerPackage *> *)getAllPackages {
    NSArray *preloadPackages = [self preloadPackagesData];
    NSMutableArray *packagesConfig = [[NSMutableArray alloc] init];
    for (RCStickerPackage *package in preloadPackages) {
        if (package.isDeleted == NO) {
            [packagesConfig addObject:package];
        }
    }
    NSArray *manualLoadPackages = [self manualLoadPackagesData];
    for (RCStickerPackage *package in manualLoadPackages) {
        [packagesConfig addObject:package];
    }
    return [packagesConfig copy];
}

- (NSArray<RCStickerPackageConfig *> *)getCategoryPackagesConfig:(RCStickerCategoryType)categoryType {

    NSMutableArray *packageConfigArray;
    switch (categoryType) {
        case RCStickerCategoryTypeRecommend: {
            packageConfigArray = [[NSMutableArray alloc] init];
            NSArray *manualLoadPackagesConfig = [self manualLoadPackagesConfigData];
            for (RCStickerPackageConfig *packageConfig in manualLoadPackagesConfig) {
                BOOL isDownload = NO;
                NSArray *manualLoadPackages = [self manualLoadPackagesData];

                for (RCStickerPackage *package in manualLoadPackages) {
                    if ([packageConfig.packageId isEqualToString:package.packageId] && package.isDownloaded == YES) {
                        isDownload = YES;
                        break;
                    }
                }
                if (!isDownload) {
                    [packageConfigArray addObject:packageConfig];
                }
            }
        }
        break;
    default:
        break;
    }
    return [packageConfigArray copy];
}

- (int)getPackageStickerCount:(NSString *)packageId {
    RCStickerPackage *package = [self packageById:packageId];
    if (package.isDownloaded == NO) {
        return 0;
    }
    NSArray<RCStickerSingle *> *stickers = [self getStickersWithPackageId:packageId];
    return (int)stickers.count;
}

- (int)getCategoryPackageCount:(RCStickerCategoryType)categoryType {
    int count = 0;
    switch (categoryType) {
    case RCStickerCategoryTypeRecommend:
        count = (int)[self getCategoryPackagesConfig:categoryType].count;
        break;
    default:
        break;
    }
    return count;
}

- (void)deletePackage:(NSString *)packageId {
    RCStickerPackage *package = [self packageById:packageId];
    [self removeDownloadingPackageForKey:packageId];
    if (package) {
        NSString *stickersPath =
            [[self packagesDirPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", packageId]];
        [FileManager removeItemAtPath:stickersPath error:nil];
        RCStickerPackageType type = [self getPackageType:packageId];
        switch (type) {
        case RCStickerPackageTypePreload:
            package.isDeleted = YES;
            package.isDownloaded = NO;
            break;
        case RCStickerPackageTypeManual:
        case RCStickerPackageTypeUnknow:
                [self removeManualLoadPackages:package];
            break;
        }
        [self refreshStickersModule];
        [self writeDataInDisk];
    }
}

#pragma mark - Notification

- (void)applicationWillTerminate {
    [self writeDataInDisk];
}

- (void)applicationDidEnterBackground {
    [self writeDataInDisk];
}

- (void)writeDataInDisk {
    NSMutableDictionary *totalPackageConfigDict = [[NSMutableDictionary alloc] init];
    NSArray *preloadPackagesConfig = [self preloadPackagesConfigData];
    [totalPackageConfigDict setObject:[RCStickerPackageConfig dictArrayWithModelArray:preloadPackagesConfig]
                               forKey:RCStickerPreloadKey];
    
    NSArray *manualLoadPackagesConfig = [self manualLoadPackagesConfigData];
    [totalPackageConfigDict setObject:[RCStickerPackageConfig dictArrayWithModelArray:manualLoadPackagesConfig]
                               forKey:RCStickerManualLoadKey];
    [totalPackageConfigDict writeToFile:[self packagesConfigPath] atomically:YES];

    NSMutableDictionary *totalPackageDict = [[NSMutableDictionary alloc] init];
    NSArray *preloadPackages = [self preloadPackagesData];
    [totalPackageDict setObject:[RCStickerPackage dictArrayWithModelArray:preloadPackages]
                         forKey:RCStickerPreloadKey];
    
    NSArray *manualLoadPackages = [self manualLoadPackagesData];
    [totalPackageDict setObject:[RCStickerPackage dictArrayWithModelArray:manualLoadPackages]
                         forKey:RCStickerManualLoadKey];
    [totalPackageDict writeToFile:[self packagesPath] atomically:YES];
}

#pragma mark - Utilities

- (NSString *)stickersTotalDirPath {
    NSString *libraryPath =
        NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    NSString *rongPath = [libraryPath stringByAppendingPathComponent:@"RongCloud"];
    NSString *appKeyPath = [rongPath stringByAppendingPathComponent:[RCStickerModule sharedModule].appKey];
    NSString *userIdPath = [appKeyPath stringByAppendingPathComponent:[RCStickerModule sharedModule].userId];
    NSString *directoryPath = [userIdPath stringByAppendingPathComponent:RCStickerDiskTotalDir];
    return directoryPath;
}

- (NSString *)stickersResourceDirPath {
    NSString *stickersResourceDirPath =
        [[self stickersTotalDirPath] stringByAppendingPathComponent:RCStickerDiskStickersResourceDir];
    return stickersResourceDirPath;
}

- (NSString *)packagesDirPath {
    NSString *packagesDirPath = [[self stickersTotalDirPath] stringByAppendingPathComponent:RCStickerDiskPackagesDir];
    return packagesDirPath;
}

- (NSString *)packagesConfigPath {
    NSString *packagesDirPath = [self packagesDirPath];
    NSString *packagesConfigPath = [packagesDirPath stringByAppendingPathComponent:RCStickerDiskPackagesConfig];
    return packagesConfigPath;
}

- (NSString *)packagesPath {
    NSString *packagesDirPath = [self packagesDirPath];
    NSString *packagesConfigPath = [packagesDirPath stringByAppendingPathComponent:RCStickerDiskPackages];
    return packagesConfigPath;
}

- (RCStickerPackageType)getPackageType:(NSString *)packageId {
    NSArray *preloadPackagesConfig = [self preloadPackagesConfigData];
    for (RCStickerPackageConfig *packageConfig in preloadPackagesConfig) {
        if ([packageConfig.packageId isEqualToString:packageId]) {
            return RCStickerPackageTypePreload;
        }
    }
    
    NSArray *manualLoadPackagesConfig = [self manualLoadPackagesConfigData];
    for (RCStickerPackageConfig *packageConfig in manualLoadPackagesConfig) {
        if ([packageConfig.packageId isEqualToString:packageId]) {
            return RCStickerPackageTypeManual;
        }
    }
    return RCStickerPackageTypeUnknow;
}

- (void)refreshStickersModule {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitExtensionEmoticonTabNeedReloadNotification
                                                            object:@[]];
    });
    [[RCStickerModule sharedModule] reloadEmoticonTabSource];
}

- (NSData *)getImageDataWithPath:(NSString *)imagePath {
    NSString *pngPath = [imagePath stringByAppendingString:@".png"];
    NSString *gifPath = [imagePath stringByAppendingString:@".gif"];
    NSString *jpgPath = [imagePath stringByAppendingString:@".jpg"];
    NSString *jpegPath = [imagePath stringByAppendingString:@".jpeg"];

    if ([FileManager fileExistsAtPath:pngPath]) {
        return [NSData dataWithContentsOfFile:pngPath];
    }
    if ([FileManager fileExistsAtPath:gifPath]) {
        return [NSData dataWithContentsOfFile:gifPath];
    }
    if ([FileManager fileExistsAtPath:jpgPath]) {
        return [NSData dataWithContentsOfFile:jpgPath];
    }
    if ([FileManager fileExistsAtPath:jpegPath]) {
        return [NSData dataWithContentsOfFile:jpegPath];
    }
    return nil;
}

@end
