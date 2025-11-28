//
//  RCAssetHelper.m
//  RongExtensionKit
//
//  Created by Liv on 15/3/24.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCAssetHelper.h"
#import "RCAlbumModel.h"
#import "RCAssetModel.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

dispatch_queue_t __rc__photo__working_queue = NULL;
@interface RCAssetHelper () <PHPhotoLibraryChangeObserver>
@property (nonatomic, assign) BOOL isSynchronizing;
@property (nonatomic, strong) NSArray *assetsGroups;
@end

@implementation RCAssetHelper
#pragma mark - Public Methods
- (instancetype)init {
    if (self = [super init]) {
        __rc__photo__working_queue = dispatch_queue_create("com.rongcloud.photoWorkingQueue", NULL);
    }
    return self;
}

+ (instancetype)shareAssetHelper {
    static RCAssetHelper *assetHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        assetHelper = [[RCAssetHelper alloc] init];
    });
    [assetHelper addRegisterIfNeed];
    return assetHelper;
}

//bugID=50382
- (void)addRegisterIfNeed {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    BOOL authed = NO;
    if (@available(iOS 14, *)) {
        authed = (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited);
    } else {
        authed = (status == PHAuthorizationStatusAuthorized);
    }
    if (authed) {
        static dispatch_once_t onceToken2;
        dispatch_once(&onceToken2, ^{
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        });
    }
}

- (BOOL)hasAuthorizationStatusAuthorized {
    return [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized;
}

- (NSArray *)getCachePhotoGroups {
    return _assetsGroups;
}

- (void)getPhotosOfGroup:(id)alGroup results:(void (^)(NSArray<RCAssetModel *> *photos))results {
    @autoreleasepool {
        NSMutableArray *resultArray = [NSMutableArray array];
        if ([alGroup isKindOfClass:[PHFetchResult class]]) {
            BOOL isContainVideo = RCKitConfigCenter.message.isMediaSelectorContainVideo;
            for (PHAsset *asset in alGroup) {
                if (!isContainVideo && asset.mediaType == PHAssetMediaTypeVideo) {
                    continue;
                }
                RCAssetModel *model = [RCAssetModel modelWithAsset:asset];
                [resultArray addObject:model];
            }
        }
        results([resultArray copy]);
    }
}

- (void)getThumbnailWithAsset:(id)asset size:(CGSize)size result:(void (^)(UIImage *))resultBlock {
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.networkAccessAllowed = YES;
    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:size
                                              contentMode:PHImageContentModeAspectFill
                                                  options:imageRequestOptions
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result) {
            resultBlock(result);
        }
    }];
}

- (void)getPreviewWithAsset:(id)asset result:(void (^)(UIImage *photo, NSDictionary *info))resultBlock {
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.networkAccessAllowed = YES;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    PHCachingImageManager *cachingImageManager = [[PHCachingImageManager alloc] init];
    CGSize size = [UIScreen mainScreen].bounds.size;
    [cachingImageManager requestImageForAsset:asset
                                   targetSize:CGSizeMake(size.width * screenScale, size.height * screenScale)
                                  contentMode:PHImageContentModeAspectFill
                                      options:imageRequestOptions
                                resultHandler:^(UIImage *_Nullable result, NSDictionary *_Nullable info) {
        if (resultBlock)
            resultBlock(result, info);
    }];
    cachingImageManager.allowsCachingHighQualityImages = NO;
}

- (PHImageRequestID)getOriginVideoWithAsset:(id)asset
                                     result:(void (^)(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier))resultBlock
                            progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler {
    PHImageRequestID imageRequestID = 0;
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.version = PHVideoRequestOptionsVersionOriginal;
    
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler) {
                progressHandler(progress, error, stop, info);
            }
        });
    };
    options.networkAccessAllowed = YES;
    imageRequestID = [[PHImageManager defaultManager]
                      requestAVAssetForVideo:asset
                      options:options
                      resultHandler:^(AVAsset *_Nullable avAsset, AVAudioMix *_Nullable audioMix,
                                      NSDictionary *_Nullable info) {
        if (asset && resultBlock) {
            resultBlock(avAsset, info, [[RCAssetHelper shareAssetHelper] getAssetIdentifier:asset]);
        }
    }];
    return imageRequestID;
}

- (PHImageRequestID)
getOriginImageDataWithAsset:(RCAssetModel *)assetModel
                     result:(void (^)(NSData *photo, NSDictionary *info, RCAssetModel *assetModel))resultBlock
progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler {
    PHImageRequestOptions *imageRequestOption = [[PHImageRequestOptions alloc] init];
    //        imageRequestOption.networkAccessAllowed = YES;
    PHCachingImageManager *cachingImageManager = [[PHCachingImageManager alloc] init];
    cachingImageManager.allowsCachingHighQualityImages = NO;
    return [cachingImageManager
            requestImageDataForAsset:assetModel.asset
            options:imageRequestOption
            resultHandler:^(NSData *_Nullable imageData, NSString *_Nullable dataUTI,
                            UIImageOrientation orientation, NSDictionary *_Nullable info) {
        if (imageData && resultBlock) {
            resultBlock([self exchangeImageDataType:assetModel.asset imageData:imageData], info,
                        assetModel);
            return;
        }
        // Download image from iCloud / 从iCloud下载图片
        if ([info objectForKey:PHImageResultIsInCloudKey] && !imageData) {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.progressHandler =
            ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progressHandler) {
                        progressHandler(progress, error, stop, info);
                    }
                });
            };
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            [[PHImageManager defaultManager]
             requestImageDataForAsset:assetModel.asset
             options:options
             resultHandler:^(NSData *imageData, NSString *dataUTI,
                             UIImageOrientation orientation, NSDictionary *info) {
                if(resultBlock) {
                    NSData *data = imageData;
                    if(imageData) {
                        data = [self exchangeImageDataType:assetModel.asset
                                                 imageData:imageData];
                    }
                    resultBlock(data,info,assetModel);
                }
                
            }];
        }
        
    }];
    return 0;
}

- (PHImageRequestID)getAssetDataSizeWithAsset:(id)asset result:(void (^)(CGFloat))resultBlock {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHImageRequestOptions *imageRequestOption = [[PHImageRequestOptions alloc] init];
        imageRequestOption.networkAccessAllowed = YES;
        return [[PHImageManager defaultManager]
            requestImageDataForAsset:asset
                             options:imageRequestOption
                       resultHandler:^(NSData *_Nullable imageData, NSString *_Nullable dataUTI,
                                       UIImageOrientation orientation, NSDictionary *_Nullable info) {
                           BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                                   ![info objectForKey:PHImageErrorKey] &&
                                                   ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                           if (downloadFinined) {
                               if (resultBlock)
                                   resultBlock([self exchangeImageDataType:asset imageData:imageData].length);
                           }
                       }];
    }
    return 0;
}

- (NSString *)getAssetIdentifier:(id)asset {
    PHAsset *phAsset = (PHAsset *)asset;
    return phAsset.localIdentifier;
}

#pragma mark - Private Methods

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // Photos may call this method on a background queue;
    // switch to the main queue to update the UI.
    if (!self.isSynchronizing) {
        self.isSynchronizing = YES;
        [self getAlbumsFromSystem:^(NSArray *albumList) {
            self.assetsGroups = albumList;
            self.isSynchronizing = NO;
        }];
    }
}

- (NSData *)exchangeImageDataType:(PHAsset *)asset imageData:(NSData *)imageData {
    NSArray *resources = [PHAssetResource assetResourcesForAsset:asset];
    BOOL isHeic = NO;
    for (PHAssetResource *res in resources) {
        NSString *fileName = [res.originalFilename lowercaseString];
        if ([res.uniformTypeIdentifier isEqualToString:@"public.heic"] ||
            [res.uniformTypeIdentifier isEqualToString:@"public.heif"] || [fileName hasSuffix:@".heic"] ||
            [fileName hasSuffix:@".heif"]) {
            isHeic = YES;
            break;
        }
    }
    if (isHeic) {
        CIImage *ciImage = [CIImage imageWithData:imageData];
        CIContext *context = [CIContext context];
        NSData *jpegData = [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{}];
        imageData = jpegData;
    }
    return imageData;
}

- (void)requestAuthorization:(void(^)(PHAuthorizationStatus status))handler{
    if([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined){
        if (@available(iOS 14, *)) {
            [PHPhotoLibrary requestAuthorizationForAccessLevel:(PHAccessLevelReadWrite) handler:handler];
        } else {
            [PHPhotoLibrary requestAuthorization:handler];
        }
    }else{
        if(handler){
            if (@available(iOS 14, *)) {
                handler([PHPhotoLibrary authorizationStatusForAccessLevel:(PHAccessLevelReadWrite)]);
            } else {
                handler([PHPhotoLibrary authorizationStatus]);
            }
        }
    }
    
}

- (void)getAlbumsFromSystem:(void (^)(NSArray *assetGroup))result {
    [self requestAuthorization:^(PHAuthorizationStatus status) {
        if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
            return result(nil);
        }
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        option.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ];
        NSMutableArray *smartAlbumSubtypes = [NSMutableArray arrayWithArray: @[@(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                                                               @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                                                                               @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                                                             @(PHAssetCollectionSubtypeSmartAlbumFavorites),
                                                                               @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos)]];
        NSMutableArray *albums = [NSMutableArray array];
        // For iOS 9, We need to show ScreenShots Album && SelfPortraits Album
        if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            [smartAlbumSubtypes addObject:@(PHAssetCollectionSubtypeSmartAlbumScreenshots)];
            [smartAlbumSubtypes addObject:@(PHAssetCollectionSubtypeSmartAlbumSelfPortraits)];
            [smartAlbumSubtypes addObject:@(PHAssetCollectionSubtypeSmartAlbumLivePhotos)];
        }
        
        for (NSNumber *typs in smartAlbumSubtypes) {
            PHFetchResult *smartAlbums =
            [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                     subtype:[typs integerValue]
                                                     options:nil];
            if (smartAlbums) {
                [albums addObject:smartAlbums];
            }
        }

        NSArray *mySubTypes = @[@(PHAssetCollectionSubtypeAlbumRegular),@(PHAssetCollectionSubtypeAlbumSyncedAlbum)];
        for (NSNumber *typs in mySubTypes) {
            PHFetchResult *album =
            [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                     subtype:[typs integerValue]
                                                     options:nil];
            if (album) {
                [albums addObject:album];
            }
        }
        dispatch_async(__rc__photo__working_queue, ^{
            NSMutableArray *albumGroups = [NSMutableArray array];
            for (PHFetchResult *fetchResult in albums) {
                for (PHAssetCollection *collection in fetchResult) {
                    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
                    if (fetchResult.count < 1)
                        continue;
                    PHAssetCollectionSubtype subtype = collection.assetCollectionSubtype;
                    // '最近删除' 知道值为（1000000201）但没找到对应的TypedefName
                    if (subtype == 1000000201 ) continue;
                    
                    // 是否开启包含媒体消息 去掉慢动作 视频 延时摄影
                    BOOL isContainVideo = RCKitConfigCenter.message.isMediaSelectorContainVideo;
                    if (!isContainVideo &&
                        (subtype == PHAssetCollectionSubtypeSmartAlbumVideos || subtype == PHAssetCollectionSubtypeSmartAlbumSlomoVideos || subtype == PHAssetCollectionSubtypeSmartAlbumTimelapses)) continue;
                    
                    
                    if (!NSClassFromString(@"RCSightCapturer")) {
                        if (subtype == PHAssetCollectionSubtypeSmartAlbumVideos) continue;
                    }
                    
                    RCAlbumModel *albumModel = [RCAlbumModel modelWithAsset:fetchResult
                                                                       name:collection.localizedTitle
                                                                      count:fetchResult.count];
                    
                    if (subtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                        [albumGroups insertObject:albumModel atIndex:0];
                    } else if (subtype == PHAssetCollectionSubtypeAlbumMyPhotoStream) {
                        if (albumGroups.count > 0) {
                            [albumGroups insertObject:albumModel atIndex:1];
                        } else {
                            [albumGroups insertObject:albumModel atIndex:0];
                        }
                    } else {
                        [albumGroups addObject:albumModel];
                    }
                }
            }
            return result(albumGroups);
        });
    }];
}

+ (void)savePhotosAlbumWithImage:(UIImage *)image authorizationStatusBlock:(nullable dispatch_block_t)authorizationStatusBlock resultBlock:(nullable void (^)(BOOL success))resultBlock {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (PHAuthorizationStatusRestricted == status || PHAuthorizationStatusDenied == status) {
        if (authorizationStatusBlock) {
            authorizationStatusBlock();
        }
        return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (resultBlock) {
                resultBlock(nil == error);
            }
        });
    }];
}

+ (void)savePhotosAlbumWithPath:(NSString *)localPath authorizationStatusBlock:(nullable dispatch_block_t)authorizationStatusBlock resultBlock:(nullable void (^)(BOOL success))resultBlock {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (PHAuthorizationStatusRestricted == status || PHAuthorizationStatusDenied == status) {
        if (authorizationStatusBlock) {
            authorizationStatusBlock();
        }
        return;
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:localPath]){
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL URLWithString:localPath]];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (resultBlock) {
                    resultBlock(nil == error);
                }
            });
        }];
    }else{
        if (resultBlock) {
            resultBlock(NO);
        }
    }
}

+ (void)savePhotosAlbumWithVideoPath:(NSString *)videoPath authorizationStatusBlock:(nullable dispatch_block_t)authorizationStatusBlock resultBlock:(nullable void (^)(BOOL success))resultBlock {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (PHAuthorizationStatusRestricted == status || PHAuthorizationStatusDenied == status) {
        if (authorizationStatusBlock) {
            authorizationStatusBlock();
        }
        return;
    }

    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:videoPath]];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (resultBlock) {
                resultBlock(nil == error);
            }
        });
    }];

}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}
@end
