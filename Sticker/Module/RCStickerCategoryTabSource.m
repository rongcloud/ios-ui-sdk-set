//
//  RCStickerCategoryTabSource.m
//
//
//  Created by Zhaoqianyu on 2018/8/13.
//

#import "RCStickerCategoryTabSource.h"
#import "RCStickerPackageView.h"
#import "RCStickerUtility.h"

@implementation RCStickerCategoryTabSource

#pragma mark - RCEmoticonTabSource

- (NSString *)identify {
    return [NSString stringWithFormat:@"RCStickerCategory - %lu", (long)self.categoryType];
}

- (UIImage *)image {
    UIImage *bundleImage = RongStickerImage(@"recommand");
    return bundleImage;
}

- (int)pageCount {
    return [[RCStickerDataManager sharedManager] getCategoryPackageCount:self.categoryType];
}

- (UIView *)loadEmoticonView:(NSString *)identify index:(int)index {

    if (index > self.pageCount - 1) {
        return [UIView new];
    }

    NSArray<RCStickerPackageConfig *> *packagesConfig =
        [[RCStickerDataManager sharedManager] getCategoryPackagesConfig:RCStickerCategoryTypeRecommend];
    RCStickerPackageView *packageView = [[RCStickerPackageView alloc] initWithPackageConfig:packagesConfig[index]];
    return packageView;
}

@end
