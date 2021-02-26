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
#import <RongIMLib/RongIMLib.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "RCPhotoPickImageView.h"
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
@property (nonatomic, strong) UIButton *selectbutton;

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
    _assetModel = nil;
    _photoImageView.image = nil;
    _selectbutton.selected = NO;
}

#pragma mark - Public Methods
- (void)configPickerCellWithItem:(RCAssetModel *)model {
    _assetModel = model;
    [self.photoImageView setPhotoModel:model];
    self.representedAssetIdentifier = [[RCAssetHelper shareAssetHelper] getAssetIdentifier:model.asset];
    if (model.thumbnailImage) {
        _photoImageView.image = model.thumbnailImage;
    } else {
        __weak typeof(self) weakSelf = self;
        [[RCAssetHelper shareAssetHelper]
            getThumbnailWithAsset:model.asset
                             size:CGSizeMake((WIDTH * SCREEN_SCALE), (WIDTH * SCREEN_SCALE))
                           result:^(UIImage *thumbnailImage) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if ([weakSelf.representedAssetIdentifier
                                           isEqualToString:[[RCAssetHelper shareAssetHelper]
                                                               getAssetIdentifier:model.asset]]) {
                                       weakSelf.photoImageView.image = thumbnailImage;
                                   }
                               });
                           }];
    }
    _selectbutton.selected = model.isSelect; 
}

#pragma mark - Private Methods

- (void)onSelectButtonClick:(UIButton *)sender {
    if (self.assetModel) {
        __weak typeof(self) weakSelf = self;
        [[RCAssetHelper shareAssetHelper]
            getOriginImageDataWithAsset:self.assetModel
                                 result:^(NSData *imageData, NSDictionary *info, RCAssetModel *assetModel) {
                                     if (![weakSelf.representedAssetIdentifier isEqualToString:[[RCAssetHelper shareAssetHelper]
                                     getAssetIdentifier:assetModel.asset]]) {
                                         return;
                                     }
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         if ([[weakSelf.assetModel.asset valueForKey:@"uniformTypeIdentifier"]
                                                 isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
                                             if (imageData.length >
                                                 [[RCIMClient sharedRCIMClient] getGIFLimitSize] * 1024) {
                                                 UIViewController *rootVC = [UIApplication sharedApplication]
                                                                                .delegate.window.rootViewController;
                                                 UIAlertController *alertController = [UIAlertController
                                                     alertControllerWithTitle:RCLocalizedString(
                                                                                  @"GIFAboveMaxSize")
                                                                      message:nil
                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                 [alertController
                                                     addAction:[UIAlertAction
                                                                   actionWithTitle:RCLocalizedString(@"OK")
                                                                             style:UIAlertActionStyleDefault
                                                                           handler:nil]];
                                                 [rootVC presentViewController:alertController
                                                                      animated:YES
                                                                    completion:nil];
                                             } else {
                                                 [weakSelf changeMessageModelState:sender.selected
                                                                        assetModel:assetModel];
                                             }
                                         } else {
                                             [weakSelf changeMessageModelState:sender.selected assetModel:assetModel];
                                         }

                                     });
                                 }
                        progressHandler:nil];
    }
}

- (void)changeMessageModelState:(BOOL)originState assetModel:(RCAssetModel *)assetModel {
    bool currentState = self.willChangeSelectedStateBlock ? self.willChangeSelectedStateBlock(assetModel) : NO;
    if (originState != currentState) {
        self.didChangeSelectedStateBlock ? self.didChangeSelectedStateBlock(currentState, assetModel) : nil;
    }
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

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_selectbutton(28)]-2-|"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(_selectbutton)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_selectbutton(28)]-2-|"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(_selectbutton)]];
}

#pragma mark - Getters and Setters


- (RCPhotoPickImageView *)photoImageView{
    if (!_photoImageView) {
        _photoImageView = [[RCPhotoPickImageView alloc] initWithFrame:self.bounds];
        _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
        _photoImageView.clipsToBounds = YES;
    }
    return _photoImageView;;
}

- (UIButton *)selectbutton{
    if (!_selectbutton) {
        _selectbutton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_selectbutton addTarget:self
                          action:@selector(onSelectButtonClick:)
                forControlEvents:UIControlEventTouchUpInside];
        [_selectbutton setImage:RCResourceImage(@"photopicker_state_normal") forState:UIControlStateNormal];
        [_selectbutton setImage:RCResourceImage(@"photopicker_state_selected")
                       forState:UIControlStateSelected];
        _selectbutton.contentEdgeInsets = UIEdgeInsetsMake(12, 12 , 0, 0);
    }
    return _selectbutton;
}
@end
