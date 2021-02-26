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
#import "RCExtensionService.h"
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
        _assetLibrary = [[ALAssetsLibrary alloc] init];
        __rc__photo__working_queue = dispatch_queue_create("com.rongcloud.photoWorkingQueue", NULL);
        if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        }
    }
    return self;
}

+ (instancetype)shareAssetHelper {
    static RCAssetHelper *assetHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        assetHelper = [[RCAssetHelper alloc] init];
        assetHelper.isSynchronizing = YES;
        [assetHelper getAlbumsFromSystem:^(NSArray *albums) {
            assetHelper.isSynchronizing = NO;
            assetHelper.assetsGroups = albums;
        }
                               groupType:ALAssetsGroupAll];
    });
    return assetHelper;
}

- (BOOL)hasAuthorizationStatusAuthorized {
    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        return [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized;
    } else {
        return [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized;
    }
}

- (void)getGroupsWithALAssetsGroupType:(ALAssetsGroupType)groupType
                      resultCompletion:(void (^)(NSArray *assetGroup))result {
    if (_assetsGroups && _assetsGroups.count > 0 && RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        NSArray *photos = [NSArray arrayWithArray:_assetsGroups];
        result(photos);
    } else {
        [self getAlbumsFromSystem:result groupType:groupType];
    }
}

- (NSArray *)getCachePhotoGroups {
    return _assetsGroups;
}

- (void)getPhotosOfGroup:(id)alGroup results:(void (^)(NSArray<RCAssetModel *> *photos))results {
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
    } else if ([alGroup isKindOfClass:[ALAssetsGroup class]]) {
        [alGroup setAssetsFilter:[ALAssetsFilter allPhotos]];

        [alGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result) {
                RCAssetModel *model = [RCAssetModel modelWithAsset:result];
                [resultArray addObject:model];
            }
        }];
    }
    results(resultArray);
}

- (void)getThumbnailWithAsset:(id)asset size:(CGSize)size result:(void (^)(UIImage *))resultBlock {

    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
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
    } else {
        ALAsset *photo = (ALAsset *)asset;
        UIImage *posterImage = [UIImage imageWithCGImage:photo.thumbnail];
        resultBlock(posterImage);
    }
}

- (void)getPreviewWithAsset:(id)asset result:(void (^)(UIImage *photo, NSDictionary *info))resultBlock {
    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
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
    } else {
        resultBlock([UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]], nil);
    }
}

- (PHImageRequestID)getOriginVideoWithAsset:(id)asset
                                     result:(void (^)(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier))resultBlock
                            progressHandler:(void (^)(double, NSError *, BOOL *, NSDictionary *))progressHandler {
    PHImageRequestID imageRequestID = 0;
    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
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
    } else {
    }
    return imageRequestID;
}

- (PHImageRequestID)
getOriginImageDataWithAsset:(RCAssetModel *)assetModel
                     result:(void (^)(NSData *photo, NSDictionary *info, RCAssetModel *assetModel))resultBlock
            progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler {
    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
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
                                                  if (imageData && resultBlock)
                                                      resultBlock([self exchangeImageDataType:assetModel.asset
                                                                                    imageData:imageData],
                                                                  info, assetModel);
                                              }];
                           }

                       }];
    } else {
        CGImageRef imageRef = [[assetModel.asset defaultRepresentation] fullResolutionImage];
        UIImage *image =
            [UIImage imageWithCGImage:imageRef
                                scale:[assetModel.asset defaultRepresentation].scale
                          orientation:(UIImageOrientation)[assetModel.asset defaultRepresentation].orientation];
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
        resultBlock(imageData, nil, assetModel);
    }
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
                                   resultBlock(imageData.length);
                           }
                       }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAssetRepresentation *representation = [asset defaultRepresentation];
        resultBlock(representation.size);
    }
    return 0;
}

- (NSString *)getAssetIdentifier:(id)asset {
    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        PHAsset *phAsset = (PHAsset *)asset;
        return phAsset.localIdentifier;
    } else {
        ALAsset *alAsset = (ALAsset *)asset;
        NSURL *assetUrl = [alAsset valueForProperty:ALAssetPropertyAssetURL];
        return assetUrl.absoluteString;
    }
}

#pragma mark - Private Methods

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // Photos may call this method on a background queue;
    // switch to the main queue to update the UI.
    if (!self.isSynchronizing) {
        self.isSynchronizing = YES;
        __weak typeof(self) weakSelf = self;
        [self getAlbumsFromSystem:^(NSArray *albumList) {
            weakSelf.assetsGroups = albumList;
            weakSelf.isSynchronizing = NO;
        }
                        groupType:(ALAssetsGroupAll)];
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
        UIImage *image = [UIImage imageWithData:imageData];
        NSData *jpegData = UIImageJPEGRepresentation(image, 1.0);
        if (!jpegData) {
            CIImage *ciImage = [CIImage imageWithData:imageData];
            CIContext *context = [CIContext context];
            jpegData = [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{}];
        }
        imageData = jpegData;
    }
    return imageData;
}

- (void)getAlbumsFromSystem:(void (^)(NSArray *))result groupType:(ALAssetsGroupType)groupType {

    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
                return result(nil);
            }
            PHFetchOptions *option = [[PHFetchOptions alloc] init];
            option.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ];
            PHAssetCollectionSubtype smartAlbumSubtype =
            PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
            //            PHAssetCollectionSubtype smartAlbumSubtype =
            //            PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumVideos;
            // For iOS 9, We need to show ScreenShots Album && SelfPortraits Album
            if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
                smartAlbumSubtype =
                PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded |
                PHAssetCollectionSubtypeSmartAlbumScreenshots | PHAssetCollectionSubtypeSmartAlbumSelfPortraits;
            }
            PHFetchResult *smartAlbums =
            [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                     subtype:smartAlbumSubtype
                                                     options:nil];
            
            PHFetchResult *myAlbums =
            [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                     subtype:PHAssetCollectionSubtypeAlbumRegular |
             PHAssetCollectionSubtypeAlbumSyncedAlbum
                                                     options:nil];
            
            NSArray *allAlbums = @[ smartAlbums, myAlbums ];
            
            dispatch_async(__rc__photo__working_queue, ^{
                NSMutableArray *albumGroups = [NSMutableArray array];
                for (PHFetchResult *fetchResult in allAlbums) {
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
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:groupType
            usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if (group == nil || [group numberOfAssets] < 1) {
                    result(nil);
                    return;
                }
                NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
                dispatch_async(__rc__photo__working_queue, ^{
                    NSMutableArray *albumGroups = [NSMutableArray array];
                    if ([name isEqualToString:@"All Photos"] || [name isEqualToString:@"所有照片"]) {
                        [albumGroups
                            insertObject:[RCAlbumModel modelWithAsset:group name:name count:[group numberOfAssets]]
                                 atIndex:0];
                    } else if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"]) {
                        [albumGroups
                            insertObject:[RCAlbumModel modelWithAsset:group name:name count:[group numberOfAssets]]
                                 atIndex:0];
                    } else if (([name isEqualToString:@"My Photo Stream"] || [name isEqualToString:@"我"
                                                                                                   @"的照片流"])) {
                        if (albumGroups.count > 0) {
                            [albumGroups
                                insertObject:[RCAlbumModel modelWithAsset:group name:name count:[group numberOfAssets]]
                                     atIndex:1];
                        } else {
                            [albumGroups
                                insertObject:[RCAlbumModel modelWithAsset:group name:name count:[group numberOfAssets]]
                                     atIndex:0];
                        }

                    } else {
                        [albumGroups
                            addObject:[RCAlbumModel modelWithAsset:group name:name count:[group numberOfAssets]]];
                    }
                    result(albumGroups);
                });
            }
            failureBlock:^(NSError *error) {
                return result(nil);
            }];
    }
}


- (void)dealloc {
    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}
@end
