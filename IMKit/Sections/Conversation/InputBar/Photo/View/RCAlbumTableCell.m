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
    self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x111111");
    self.imageView.frame = CGRectMake(0, 0, 65, 65);
    self.imageView.center = CGPointMake(self.imageView.frame.size.width / 2, self.imageView.frame.size.height / 2);
    CGRect labelFrame = self.textLabel.frame;
    if ([RCKitUtility isRTL]) {
        self.imageView.frame = CGRectMake(self.contentView.frame.size.width - 65, 0, 65, 65);
        labelFrame.origin.x = 0;
        labelFrame.size.width = self.contentView.frame.size.width - self.imageView.frame.size.width - 12;
        self.textLabel.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    } else {
        self.textLabel.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;

        labelFrame.origin.x = self.imageView.frame.size.width + self.imageView.frame.origin.x + 12;
        labelFrame.size.width = self.contentView.frame.size.width - labelFrame.origin.x;
    }
    self.textLabel.frame = labelFrame;
}

#pragma mark - Public Methods

- (void)configCellWithItem:(RCAlbumModel *)model {
    self.imageView.clipsToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    UIColor *color = RCDynamicColor(@"text_primary_color", @"0x000000", @"0xffffffe5");
    if (!color) {
        color = [RCKitUtility generateDynamicColor:HEXCOLOR(0x000000) darkColor:[HEXCOLOR(0xffffff) colorWithAlphaComponent:0.9]];
    }
    NSMutableAttributedString *nameString =
        [[NSMutableAttributedString alloc] initWithString:model.albumName
                                               attributes:@{
                                                   NSFontAttributeName : [[RCKitConfig defaultConfig].font fontOfSecondLevel],
                                                   NSForegroundColorAttributeName :color
                                               }];
    UIColor *foreColor = RCDynamicColor(@"disabled_color", @"0xD3D3D3", @"0x585858");
    if (!foreColor) {
        foreColor = [RCKitUtility generateDynamicColor:[UIColor lightGrayColor] darkColor:HEXCOLOR(0x585858)];
    }
    NSAttributedString *countString = [[NSAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"  (%ld)", model.count]
            attributes:@{
                NSFontAttributeName : [[RCKitConfig defaultConfig].font fontOfSecondLevel],
                NSForegroundColorAttributeName :foreColor
            }];
    [nameString appendAttributedString:countString];
    self.textLabel.attributedText = nameString;
    if ([model.asset isKindOfClass:[PHFetchResult class]]) {
        [[RCAssetHelper shareAssetHelper] getThumbnailWithAsset:[model.asset lastObject]
                                                           size:CGSizeMake(65 * SCREEN_SCALE, 65 * SCREEN_SCALE)
                                                         result:^(UIImage *thumbnailImage) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 self.imageView.image = thumbnailImage;
                                                                 self.textLabel.text = @""; //奇怪不给text重新赋值图片显示不出来？
                                                                 self.textLabel.attributedText = nameString;
                                                             });
                                                         }];
    }
}

@end
