//
//  RCStickerCollectionViewCell.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/14.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerCollectionViewCell.h"
#import "RCStickerDataManager.h"
#import "RCStickerUtility.h"
#import "RongStickerAdaptiveHeader.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenScale ScreenWidth / 375.f

@interface RCStickerCollectionViewCell ()

@property (nonatomic, strong) NSString *packageId;

@property (nonatomic, strong) RCBaseImageView *thumbImageView;

@property (nonatomic, strong) UILabel *digestLabel;

@end

@implementation RCStickerCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.stickerBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        self.stickerBackgroundView.layer.cornerRadius = 4.f;
        self.stickerBackgroundView.layer.masksToBounds = YES;
        self.center = CGPointMake(30, 30);
        [self addSubview:self.stickerBackgroundView];
        [self addSubview:self.thumbImageView];
        [self addSubview:self.digestLabel];
        self.thumbImageView.frame = CGRectMake(0, 0, 60, 60);
        self.thumbImageView.center = CGPointMake(30, 30);
        self.digestLabel.frame =
            CGRectMake(0, CGRectGetMaxY(self.thumbImageView.frame) + 3, self.bounds.size.width, 18);
    }
    return self;
}

- (void)configWithModel:(RCStickerSingle *)model packageId:(NSString *)packageId {

    self.packageId = packageId;
    __weak typeof(self) weakSelf = self;
    self.thumbImageView.image = RongStickerImage(@"loading_failed");
    [[RCStickerDataManager sharedManager] getStickerThumbImage:packageId
                                                     stickerId:model.stickerId
                                                 completeBlock:^(NSData *thumbImage) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         if (thumbImage != nil && thumbImage.length > 0) {
                                                             weakSelf.thumbImageView.image =
                                                                 [UIImage imageWithData:thumbImage];
                                                         }
                                                     });
                                                 }];
    weakSelf.digestLabel.text = model.digest;
}

- (RCBaseImageView *)thumbImageView {
    if (_thumbImageView == nil) {
        _thumbImageView = [[RCBaseImageView alloc] init];
        _thumbImageView.backgroundColor = [UIColor clearColor];
        _thumbImageView.contentMode = UIViewContentModeScaleAspectFit;
        if ([RCKitUtility isRTL]) {
            [_thumbImageView setTransform:CGAffineTransformMakeScale(-1, 1)];
        }
    }
    return _thumbImageView;
}

- (UILabel *)digestLabel {
    if (_digestLabel == nil) {
        _digestLabel = [[UILabel alloc] init];
        _digestLabel.textColor = HEXCOLOR(0x999999);
        _digestLabel.font = [UIFont systemFontOfSize:13];
        _digestLabel.textAlignment = NSTextAlignmentCenter;
        if ([RCKitUtility isRTL]) {
            [_digestLabel setTransform:CGAffineTransformMakeScale(-1, 1)];
        }
    }
    return _digestLabel;
}

@end
