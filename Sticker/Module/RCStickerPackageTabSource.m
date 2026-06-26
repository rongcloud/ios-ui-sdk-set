//
//  RCStickerPackageTabSource.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/13.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerPackageTabSource.h"
#import "RCStickerDataManager.h"
#import "RCStickerCollectionView.h"
#import "RCStickerPackageView.h"

@interface RCStickerPackageTabSource ()

@property (nonatomic, strong) NSMutableDictionary *viewCache;

@end

@implementation RCStickerPackageTabSource

- (instancetype)init {
    self = [super init];
    if (self) {
        self.viewCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - RCEmoticonTabSource

- (NSString *)identify {
    return self.packageId;
}

- (UIImage *)image {
    NSData *imageData = [[RCStickerDataManager sharedManager] packageIconById:self.packageId];
    if (imageData) {
        return [UIImage imageWithData:imageData];
    }
    return [UIImage imageNamed:@"占位图"];
}

- (int)pageCount {
    int packageCount = 0;
    int stickerCount = [[RCStickerDataManager sharedManager] getPackageStickerCount:self.packageId];
    if (stickerCount % 8 == 0) {
        packageCount = stickerCount / 8;
    } else {
        packageCount = stickerCount / 8 + 1;
    }
    return packageCount;
}

- (UIView *)loadEmoticonView:(NSString *)identify index:(int)index {

    if (index > self.pageCount - 1) {
        return [UIView new];
    }

    NSArray *stickers = [[RCStickerDataManager sharedManager] getStickersWithPackageId:self.packageId];
    if (!stickers || stickers.count <= 0) {
        RCStickerPackageConfig *packageConfig = [[RCStickerDataManager sharedManager] packageConfigById:self.packageId];
        RCStickerPackageView *packageView = [[RCStickerPackageView alloc] initWithPackageConfig:packageConfig];
        return packageView;
    }
    NSArray *subArray;
    if (index * 8 + 8 > stickers.count) {
        subArray = [stickers subarrayWithRange:NSMakeRange(index * 8, stickers.count - index * 8)];
    } else {
        subArray = [stickers subarrayWithRange:NSMakeRange(index * 8, 8)];
    }

    RCStickerCollectionView *collectionView = [self.viewCache objectForKey:[NSString stringWithFormat:@"%d", index]];
    if (collectionView) {
        return collectionView;
    }
    collectionView = [[RCStickerCollectionView alloc] initWithStickers:subArray];
    collectionView.packageId = self.packageId;
    [self.viewCache setObject:collectionView forKey:[NSString stringWithFormat:@"%d", index]];
    return collectionView;
}

@end
