//
//  RCPhotoPickImageView.m
//  RongIMKit
//
//  Created by 张改红 on 2020/12/8.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCPhotoPickImageView.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "RCBaseImageView.h"
#import "RCSemanticContext.h"
#import "RCBaseLabel.h"
//#import <QuartzCore/QuartzCore.h>
typedef NS_ENUM(NSUInteger, RCPotoPickStatus) {
    RCPotoPickStatusNormal = 0,
    RCPotoPickStatusSelect,
};
@interface RCPhotoPickImageView()

@property (nonatomic, strong) UIView *maskCoverView;
@property (nonatomic, strong) UIView *typeBackgroundView;

@property (nonatomic, strong) UILabel *gifLabel;

@property (nonatomic, strong) RCBaseLabel *durationLabel;
@property (nonatomic, strong) RCBaseImageView *videoIcon;
@end

@implementation RCPhotoPickImageView

- (void)setPhotoModel:(RCAssetModel *)model{
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        [self showSightTypeView];
        self.durationLabel.text = model.durationText;
    } else if([[model.asset valueForKey:@"uniformTypeIdentifier"]
               isEqualToString:(__bridge NSString *)kUTTypeGIF]){
        [self showGifTypeView];
    } else {
        [self hiddenTypeView];
    }
    [self setPickStatus:(model.isSelect ? RCPotoPickStatusSelect : RCPotoPickStatusNormal)];
}

#pragma mark - privite
- (void)setPickStatus:(RCPotoPickStatus)pickStatus{
    switch (pickStatus) {
        case RCPotoPickStatusNormal:
            _maskCoverView.backgroundColor = [UIColor clearColor];
            break;
        case RCPotoPickStatusSelect:
            _maskCoverView.backgroundColor = RCMASKCOLOR(0x000000, 0.4);
            break;
        default:
            break;
    }
}

- (void)hiddenTypeView{
    self.typeBackgroundView.hidden = YES;
    self.gifLabel.hidden = YES;
    self.videoIcon.hidden = YES;
    self.durationLabel.hidden = YES;
}

- (void)showSightTypeView{
    self.typeBackgroundView.hidden = NO;
    self.gifLabel.hidden = YES;
    self.videoIcon.hidden = NO;
    self.durationLabel.hidden = NO;
}

- (void)showGifTypeView{
    self.typeBackgroundView.hidden = NO;
    self.gifLabel.hidden = NO;
    self.videoIcon.hidden = YES;
    self.durationLabel.hidden = YES;
}

#pragma mark - getter
- (UIView *)maskCoverView{
    if (!_maskCoverView) {
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:view];
        _maskCoverView = view;
    }
    return _maskCoverView;
}

- (UIView *)typeBackgroundView{
    if (!_typeBackgroundView) {
        _typeBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height-28, self.bounds.size.width, 28)];
        _typeBackgroundView.hidden = YES;
        //初始化CAGradientlayer对象，使它的大小为UIView的大小
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = _typeBackgroundView.bounds;
        //将CAGradientlayer对象添加在我们要设置背景色的视图的layer层
        [_typeBackgroundView.layer addSublayer:gradientLayer];
        
        //设置渐变区域的起始和终止位置（范围为0-1）
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(0, 1);
        
        //设置颜色数组
        gradientLayer.colors = @[(__bridge id)RCMASKCOLOR(0xffffff,0).CGColor,
                                 (__bridge id)RCMASKCOLOR(0x696969,0.2).CGColor,
                                 (__bridge id)RCMASKCOLOR(0x696969,0.6).CGColor];
        
        //设置颜色分割点（范围：0-1）
        gradientLayer.locations = @[@(0.35f), @(0.7f), @(1.0f)];
        [self addSubview:_typeBackgroundView];
    }
    return _typeBackgroundView;
}

- (RCBaseLabel *)durationLabel {
    if (!_durationLabel) {
        CGRect frame = CGRectMake(33, 9.5, self.typeBackgroundView.frame.size.width-33, 14);
        if ([RCKitUtility isRTL]) {
            frame = CGRectMake(0, 9.5, self.typeBackgroundView.frame.size.width-33, 14);
        }
        _durationLabel = [[RCBaseLabel alloc] initWithFrame:frame];
        _durationLabel.textColor = RCDynamicColor(@"control_title_white_color", @"0xffffff", @"0xffffff");
        _durationLabel.font = [[RCKitConfig defaultConfig].font fontOfAssistantLevel];
        [self.typeBackgroundView addSubview:_durationLabel];
    }
    return _durationLabel;
}

- (RCBaseImageView *)videoIcon {
    if (!_videoIcon) {
        CGRect frame = (CGRect){6, self.typeBackgroundView.frame.size.height-21, 19, 19};
        UIImage *image = RCDynamicImage(@"photo_picker_cell_video_img", @"fileicon_video_wall");
        if ([RCKitUtility isRTL]) {
            frame =(CGRect){self.typeBackgroundView.frame.size.width - 6-19, self.typeBackgroundView.frame.size.height-21, 19, 19};
        }
        _videoIcon = [[RCBaseImageView alloc] initWithFrame:frame];
        _videoIcon.image = [RCSemanticContext imageflippedForRTL:image];
        [self.typeBackgroundView addSubview:_videoIcon];
    }
    return _videoIcon;
}

- (RCBaseLabel *)gifLabel {
    if (!_gifLabel) {
        CGRect frame = CGRectMake(6, 9.5, self.typeBackgroundView.frame.size.width-6, 14);
        if ([RCKitUtility isRTL]) {
            frame =CGRectMake(0, 9.5, self.typeBackgroundView.frame.size.width-6, 14);
        }
        _gifLabel = [[RCBaseLabel alloc] initWithFrame:frame];
        _gifLabel.textColor = RCDynamicColor(@"pop_layer_background_color", @"0xffffff", @"0xffffff");
        _gifLabel.font = [[RCKitConfig defaultConfig].font fontOfAssistantLevel];
        _gifLabel.text = @"GIF";
        [self.typeBackgroundView addSubview:_gifLabel];
    }
    return _gifLabel;
}
@end
