//
//  RCAlbumTableCell.m
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/18.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCAlbumTableCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@implementation RCAlbumTableCell
- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                          darkColor:HEXCOLOR(0x111111)];
    self.imageView.frame = CGRectMake(0, 0, 65, 65);
    self.imageView.center = CGPointMake(self.imageView.frame.size.width / 2, self.imageView.frame.size.height / 2);
    CGRect labelFrame = self.textLabel.frame;
    if ([RCKitUtility isRTL]) {
        self.imageView.frame = CGRectMake(self.contentView.frame.size.width - 65, 0, 65, 65);
        labelFrame.origin.x = 0;
        labelFrame.size.width = self.contentView.frame.size.width - self.imageView.frame.size.width - 12;
    } else {
        labelFrame.origin.x = self.imageView.frame.size.width + self.imageView.frame.origin.x + 12;
        labelFrame.size.width = self.contentView.frame.size.width - labelFrame.origin.x;
    }
    self.textLabel.frame = labelFrame;
}

#pragma mark - Public Methods

- (void)configCellWithItem:(RCAlbumModel *)model {
    self.imageView.clipsToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;

    NSMutableAttributedString *nameString =
        [[NSMutableAttributedString alloc] initWithString:model.albumName
                                               attributes:@{
                                                   NSFontAttributeName : [[RCKitConfig defaultConfig].font fontOfSecondLevel],
                                                   NSForegroundColorAttributeName : [RCKitUtility generateDynamicColor:HEXCOLOR(0x000000) darkColor:[HEXCOLOR(0xffffff) colorWithAlphaComponent:0.9]]
                                               }];
    NSAttributedString *countString = [[NSAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"  (%ld)", model.count]
            attributes:@{
                NSFontAttributeName : [[RCKitConfig defaultConfig].font fontOfSecondLevel],
                NSForegroundColorAttributeName :
                    [RCKitUtility generateDynamicColor:[UIColor lightGrayColor] darkColor:RCDYCOLOR(0x666666, 0x585858)]
            }];
    [nameString appendAttributedString:countString];
    self.textLabel.attributedText = nameString;

    __weak typeof(self) weakSelf = self;
    if ([model.asset isKindOfClass:[PHFetchResult class]]) {
        [[RCAssetHelper shareAssetHelper] getThumbnailWithAsset:[model.asset lastObject]
                                                           size:CGSizeMake(65 * SCREEN_SCALE, 65 * SCREEN_SCALE)
                                                         result:^(UIImage *thumbnailImage) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 weakSelf.imageView.image = thumbnailImage;
                                                                 weakSelf.textLabel.text =
                                                                     @""; //奇怪不给text重新赋值图片显示不出来？
                                                                 weakSelf.textLabel.attributedText = nameString;
                                                             });
                                                         }];
    } else {
        CGImageRef posterImage_CGImageRef_ = [model.asset posterImage];
        UIImage *posterImage_ = [UIImage imageWithCGImage:posterImage_CGImageRef_];

        self.imageView.image = posterImage_;
    }
}

@end
