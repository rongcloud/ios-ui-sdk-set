//
//  RCStickerPreviewView.m
//  RongSticker
//
//  Created by liyan on 2018/8/17.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerPreviewView.h"
#import "RCAnimatedView.h"
#import "RCStickerDataManager.h"
#import "RCAnimated.h"
#import "RCStickerUtility.h"

static CGFloat RCStickerViewTopPadding = 15.0;
static CGFloat RCStickerViewLeftRightPadding = 15.0;
static CGFloat RCStickerViewWidth = 120.0;
static CGFloat RCStickerViewLength = 120.0;

@interface RCStickerPreviewView ()
@property (nonatomic, strong) RCAnimatedView *stickerView;
@end

@implementation RCStickerPreviewView

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.stickerView];
    }
    return self;
}
- (RCAnimatedView *)stickerView {
    if (!_stickerView) {
        _stickerView = [[RCAnimatedView alloc] init];
    }
    return _stickerView;
}
- (void)setStickerModel:(RCStickerSingle *)stickerModel {
    if (_stickerModel != stickerModel) {
        _stickerModel = stickerModel;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.stickerModel) {
        return;
    }
    UIImage *backgroudImage;
    switch (self.previewPosition) {
    case 0:
        backgroudImage = RongStickerImage(@"zuoyulan");
        break;
    case 1:
        backgroudImage = RongStickerImage(@"zhongyulan");
        break;
    case 2:
        backgroudImage = RongStickerImage(@"youyulan");
        break;
    }
    self.image = backgroudImage;
    self.stickerView.frame =
        CGRectMake(RCStickerViewLeftRightPadding, RCStickerViewTopPadding, RCStickerViewWidth, RCStickerViewLength);
    [[RCStickerDataManager sharedManager] getStickerOriginalImage:self.packageId
                                                        stickerId:self.stickerModel.stickerId
                                                    completeBlock:^(NSData *originalImage) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            if (originalImage) {
                                                                self.stickerView.animatedImage =
                                                                    [RCAnimated animatedImageWithGIFData:originalImage];
                                                            }
                                                        });
                                                    }];
}

@end
