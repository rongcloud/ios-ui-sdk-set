//
//  RCPhotoPickerCollectCell.m
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/17.
//  Copyright © 2016年 张改红. All rights reserved.
//

#import "RCPhotoPickerCollectCell.h"
#import "RCAssetModel.h"
#import "RCKitCommonDefine.h"
#import "RCAssetHelper.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "RCPhotoPickImageView.h"
#import "RCAlertView.h"
#import "RCBaseButton.h"
#define WIDTH (([UIScreen mainScreen].bounds.size.width - 20) / 4)
#define SIZE CGSizeMake(WIDTH, WIDTH)

@interface RCPhotoPickerCollectCell ()
@property (nonatomic, strong) RCAssetModel *assetModel;
/**
 *  显示图片
 */
@property (nonatomic, strong) RCPhotoPickImageView *photoImageView;
/**
 *  cell被选中小图
 */
@property (nonatomic, strong) RCBaseButton *selectbutton;

@property (nonatomic, weak) id<RCPhotoPickerCollectCellDelegate> delegate;

@property (nonatomic, strong) UIImage *thumbnailImage;

@end
@implementation RCPhotoPickerCollectCell

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupSubviews];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.assetModel = nil;
    self.photoImageView.image = nil;
    self.selectbutton.selected = NO;
}

#pragma mark - Public Methods
- (void)configPickerCellWithItem:(RCAssetModel *)model delegate:(id<RCPhotoPickerCollectCellDelegate>)delegate{
    self.assetModel = model;
    self.delegate = delegate;
    [self.photoImageView setPhotoModel:model];
    _selectbutton.selected = model.isSelect;
    
    NSString *modelIdentifier = [[RCAssetHelper shareAssetHelper] getAssetIdentifier:model.asset];
    if([self.representedAssetIdentifier isEqualToString:modelIdentifier]) {
        if(self.thumbnailImage) {
            self.photoImageView.image = self.thumbnailImage;
            return ;
        }
    }else {
        self.photoImageView.image = nil;
    }
    self.representedAssetIdentifier = modelIdentifier;
    
    // 获取缩略图
    [[RCAssetHelper shareAssetHelper]
        getThumbnailWithAsset:model.asset
                         size:CGSizeMake((WIDTH * SCREEN_SCALE), (WIDTH * SCREEN_SCALE))
                       result:^(UIImage *thumbnailImage) {
        dispatch_main_async_safe(^{
            self.thumbnailImage = thumbnailImage;
            self.photoImageView.image = thumbnailImage;
        });
    }];
}

#pragma mark - Private Methods

- (void)onSelectButtonClick:(UIButton *)sender {
    if(!self.assetModel) {
        return;
    }
    if(self.assetModel.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        [[RCAssetHelper shareAssetHelper] getOriginVideoWithAsset:self.assetModel.asset result:^(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier) {
            if (![[[RCAssetHelper shareAssetHelper] getAssetIdentifier:self.assetModel.asset] isEqualToString:imageIdentifier]) {
                return;
            }
            dispatch_main_async_safe(^{
                if (!avAsset) {
                    if(self.delegate && [self.delegate respondsToSelector:@selector(downloadFailFromiCloud)]) {
                        [self.delegate downloadFailFromiCloud];
                    }
                    return;
                }
                [self changeMessageModelState:sender.selected
                                   assetModel:self.assetModel];
            });
        } progressHandler:^(double progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
            
        }];
        return;
    }
    [[RCAssetHelper shareAssetHelper]
        getOriginImageDataWithAsset:self.assetModel
                             result:^(NSData *imageData, NSDictionary *info, RCAssetModel *assetModel) {
                                 if (![self.representedAssetIdentifier isEqualToString:[[RCAssetHelper shareAssetHelper]
                                 getAssetIdentifier:assetModel.asset]]) {
                                     return;
                                 }
        
                                 dispatch_main_async_safe(^{
                                     if(!imageData || [self.assetModel isVideoAssetInvalid]) {
                                         if(self.delegate && [self.delegate respondsToSelector:@selector(downloadFailFromiCloud)]) {
                                             [self.delegate downloadFailFromiCloud];
                                         }
                                         return;
                                     }
                                     self.assetModel.imageSize = imageData.length;
                                     [self changeMessageModelState:sender.selected assetModel:assetModel];
                                     
                                 });
                             }
                    progressHandler:^(double progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
        
    }];
}

- (void)changeMessageModelState:(BOOL)originState assetModel:(RCAssetModel *)assetModel {
    bool currentState = NO;
    if(self.delegate && [self.delegate respondsToSelector:@selector(canChangeSelectedState:)]) {
        currentState = [self.delegate canChangeSelectedState:assetModel];
    }
    if (originState != currentState) {
        assetModel.thumbnailImage = self.thumbnailImage;
        if(self.delegate && [self.delegate respondsToSelector:@selector(didChangeSelectedState:model:)]) {
            [self.delegate didChangeSelectedState:currentState model:assetModel];
        }
    }
    self.selectbutton.selected = currentState;
}

- (void)animationWithLayer:(CALayer *)layer {
    NSNumber *animationScale1 = @(0.7);
    NSNumber *animationScale2 = @(0.92);
    [UIView animateWithDuration:0.15
        delay:0
        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
        animations:^{
            [layer setValue:animationScale1 forKeyPath:@"transform.scale"];
        }
        completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15
                delay:0
                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                animations:^{
                    [layer setValue:animationScale2 forKeyPath:@"transform.scale"];
                }
                completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1
                                          delay:0
                                        options:UIViewAnimationOptionBeginFromCurrentState |
                                                UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         [layer setValue:@(1.0) forKeyPath:@"transform.scale"];
                                     }
                                     completion:nil];
                }];
        }];
}

- (void)setupSubviews{
    [self.contentView addSubview:self.photoImageView];
    [self.contentView addSubview:self.selectbutton];

    [_selectbutton setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[_selectbutton(44)]"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(_selectbutton)]];  
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_selectbutton(44)]-2-|"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(_selectbutton)]];
}

- (void)didTapPhotoImageView {
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapPickerCollectCell:)]) {
        [self.delegate didTapPickerCollectCell:self.assetModel];
    }
    
}

#pragma mark - Getters and Setters


- (RCPhotoPickImageView *)photoImageView{
    if (!_photoImageView) {
        _photoImageView = [[RCPhotoPickImageView alloc] initWithFrame:self.bounds];
        _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
        UITapGestureRecognizer *tap =
                    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPhotoImageView)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [_photoImageView addGestureRecognizer:tap];
        _photoImageView.userInteractionEnabled = YES;
        _photoImageView.clipsToBounds = YES;
    }
    return _photoImageView;;
}

- (RCBaseButton *)selectbutton{
    if (!_selectbutton) {
        _selectbutton = [[RCBaseButton alloc] initWithFrame:CGRectZero];
        [_selectbutton addTarget:self
                          action:@selector(onSelectButtonClick:)
                forControlEvents:UIControlEventTouchUpInside];
        [_selectbutton setImage:RCDynamicImage(@"media_file_state_uncheck_img", @"photopicker_state_normal") forState:UIControlStateNormal];
        [_selectbutton setImage:RCDynamicImage(@"media_file_state_check_img",@"photopicker_state_selected")
                       forState:UIControlStateSelected];
        if ([RCKitUtility isRTL]) {
            _selectbutton.contentEdgeInsets = UIEdgeInsetsMake(0, 0 , 28, 28);
        } else {
            _selectbutton.contentEdgeInsets = UIEdgeInsetsMake(0, 28 , 28, 0);
        }
    }
    return _selectbutton;
}
@end
