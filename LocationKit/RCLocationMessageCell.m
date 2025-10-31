//
//  RCLocationMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCLocationMessageCell.h"
#import <RongLocation/RongLocation.h>

@interface RCLocationMessageCell ()
@property (nonatomic, strong) RCBaseImageView *maskView;
@property (nonatomic, strong) RCBaseImageView *shadowMaskView;
@end

@implementation RCLocationMessageCell
#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    float configImageHeight = [RCLocalConfiguration sharedInstance].locationImageHeight;
    CGFloat __messagecontentview_height = configImageHeight / 2.0f;

    if (__messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }

    __messagecontentview_height += extraHeight;

    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    [self beginDestructing];
    [self setAutoLayout];
}

#pragma mark - 阅后即焚

- (void)beginDestructing {
    RCLocationMessage *_locationMessage = (RCLocationMessage *)self.model.content;
    if (self.model.messageDirection == MessageDirection_RECEIVE && _locationMessage.destructDuration > 0 &&
        [UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        [[RCCoreClient sharedCoreClient]
            messageBeginDestruct:[[RCCoreClient sharedCoreClient] getMessage:self.model.messageId]];
    }
}

#pragma mark - Private Methods

- (void)initialize {
    [self.pictureView addSubview:self.locationNameLabel];
    [self.messageContentView addSubview:self.pictureView];
}

- (void)setMaskImage:(UIImage *)maskImage {
    if (_maskView == nil) {
        _maskView = [[RCBaseImageView alloc] initWithImage:maskImage];

        _maskView.frame = self.pictureView.bounds;
        self.pictureView.layer.mask = _maskView.layer;
        self.pictureView.layer.masksToBounds = YES;
    } else {
        _maskView.image = maskImage;
        _maskView.frame = self.pictureView.bounds;
    }
    if (_shadowMaskView) {
        [_shadowMaskView removeFromSuperview];
    }
    _shadowMaskView = [[RCBaseImageView alloc] initWithImage:maskImage];
    _shadowMaskView.frame = self.pictureView.bounds;
    [self.messageContentView addSubview:_shadowMaskView];
    [self.messageContentView bringSubviewToFront:self.pictureView];
}

- (void)setAutoLayout {
    RCLocationMessage *locationMessage = (RCLocationMessage *)self.model.content;
    if (locationMessage) {
        self.locationNameLabel.text = [@"  " stringByAppendingString:locationMessage.locationName ?: @""];
        float configImageWidth = [RCLocalConfiguration sharedInstance].locationImageWidth;
        float configImageHeight = [RCLocalConfiguration sharedInstance].locationImageHeight;
        CGSize imageSize = CGSizeMake(configImageWidth / 2.0f, configImageHeight / 2.0f);
        self.pictureView.image = locationMessage.thumbnailImage;
        self.shadowMaskView.image = nil;
        self.messageContentView.contentSize = imageSize;
        self.pictureView.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
        self.locationNameLabel.frame = CGRectMake(0, self.pictureView.frame.size.height - 25,self.pictureView.frame.size.width, 25);
        [self setMaskImage:[RCMessageCellTool getDefaultMessageCellBackgroundImage:self.model]];
    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCLocationMessage object");
    }
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.locationNameLabel.bounds
                                                   byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight
                                                         cornerRadii:CGSizeMake(8, 8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.locationNameLabel.bounds;
    maskLayer.path = maskPath.CGPath;
    self.locationNameLabel.layer.mask = maskLayer;
}

#pragma mark - Getter
- (RCBaseImageView *)pictureView{
    if (!_pictureView) {
        _pictureView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
        _pictureView.clipsToBounds = YES;
        _pictureView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _pictureView;
}

- (UILabel *)locationNameLabel{
    if (!_locationNameLabel) {
        _locationNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _locationNameLabel.backgroundColor = RCDynamicColor(@"mask_color", @"0x00000066", @"0x00000066");
        _locationNameLabel.textAlignment = NSTextAlignmentLeft;
        _locationNameLabel.textColor = RCDynamicColor(@"control_title_white_color", @"0xffffff", @"0xffffff");
        _locationNameLabel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
        _locationNameLabel.clipsToBounds = YES;
    }
    return _locationNameLabel;
}


@end
