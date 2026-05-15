//
//  RCLocationMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCLocationMessageCell.h"
#import <RongLocation/RongLocation.h>

#define QUOTE_CARD_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_TOP_OFFSET 8
#define QUOTE_BODY_TOP_SPACING 16
#define QUOTE_MIN_BUBBLE_WIDTH 170.0f
#define QUOTE_MEDIA_INSET QUOTE_DIVIDER_HORIZONTAL_INSET

extern CGFloat const RCQuoteCardTopMargin;

static CGFloat RCLocationMessageQuoteContentOffset(RCMessageModel *model, CGFloat bubbleWidth) {
    CGFloat cardWidth = MAX(bubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGFloat cardHeight = [RCReferencedContentView quoteCardHeightForMessageModel:model maxWidth:cardWidth];
    return RCQuoteCardTopMargin + cardHeight;
}

static CGFloat RCLocationMessageContentViewMaxWidth(void) {
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenRatio = screenWidth <= 320.0f ? 0.6f : 0.637f;
    return (CGFloat)((int)(screenWidth * screenRatio) + 7);
}

static CGFloat RCLocationMessageQuoteMinimumBubbleWidth(void) {
    CGFloat maxContentWidth = RCLocationMessageContentViewMaxWidth();
    return maxContentWidth < QUOTE_MIN_BUBBLE_WIDTH ? maxContentWidth : QUOTE_MIN_BUBBLE_WIDTH;
}

static UIImage *RCLocationMessageResizableBubbleImage(UIImage *image) {
    if (!image) {
        return nil;
    }
    CGFloat halfWidth = image.size.width * 0.5f;
    CGFloat halfHeight = image.size.height * 0.5f;
    UIEdgeInsets capInsets = UIEdgeInsetsMake(halfHeight, halfWidth, halfHeight, halfWidth);
    return [image resizableImageWithCapInsets:capInsets];
}

@interface RCLocationMessageCell ()
@property (nonatomic, strong) RCBaseImageView *maskView;
@property (nonatomic, strong) RCBaseImageView *shadowMaskView;
@property (nonatomic, strong) UIView *quoteDividerView;
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
    if ([RCReferencedContentView shouldShowQuoteCardForMessageModel:model]) {
        __messagecontentview_height += QUOTE_BODY_TOP_SPACING + QUOTE_MEDIA_INSET;
    }

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
    [self showBubbleBackgroundView:YES];
    [self.pictureView addSubview:self.locationNameLabel];
    [self.messageContentView addSubview:self.pictureView];
    [self.messageContentView addSubview:self.quoteDividerView];
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
    _shadowMaskView.frame = self.pictureView.frame;
    [self.messageContentView addSubview:_shadowMaskView];
    [self.messageContentView bringSubviewToFront:self.pictureView];
}

- (UIImage *)getDefaultMessageCellBackgroundImage {
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    if (showsQuoteCard && self.model.messageDirection == MessageDirection_SEND) {
        UIImage *bubbleImage = RCDynamicImage(@"conversation_msg_cell_bg_to_img", @"chat_to_bg_normal");
        if (bubbleImage.imageAsset) {
            bubbleImage = [bubbleImage.imageAsset imageWithTraitCollection:self.traitCollection];
        }
        if ([RCKitUtility isRTL]) {
            bubbleImage = [bubbleImage imageFlippedForRightToLeftLayoutDirection];
        }
        return RCLocationMessageResizableBubbleImage(bubbleImage);
    }
    return [super getDefaultMessageCellBackgroundImage];
}

- (void)setAutoLayout {
    RCLocationMessage *locationMessage = (RCLocationMessage *)self.model.content;
    if (locationMessage) {
        self.locationNameLabel.text = [@"  " stringByAppendingString:locationMessage.locationName ?: @""];
        float configImageWidth = [RCLocalConfiguration sharedInstance].locationImageWidth;
        float configImageHeight = [RCLocalConfiguration sharedInstance].locationImageHeight;
        CGSize imageSize = CGSizeMake(configImageWidth / 2.0f, configImageHeight / 2.0f);
        BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
        CGFloat contentWidth = imageSize.width;
        CGFloat mediaInset = 0;
        if (showsQuoteCard) {
            contentWidth = MAX(contentWidth + QUOTE_MEDIA_INSET * 2, RCLocationMessageQuoteMinimumBubbleWidth());
            mediaInset = QUOTE_MEDIA_INSET;
        }
        CGFloat quoteOffset = showsQuoteCard ? RCLocationMessageQuoteContentOffset(self.model, contentWidth) : 0;
        CGFloat bodyOffset = showsQuoteCard ? QUOTE_BODY_TOP_SPACING : 0;
        CGFloat contentX = mediaInset;
        if (showsQuoteCard) {
            BOOL alignsTrailing = ([RCKitUtility isRTL]
                                   ? self.model.messageDirection == MessageDirection_RECEIVE
                                   : self.model.messageDirection == MessageDirection_SEND);
            if (alignsTrailing) {
                contentX = MAX(contentWidth - imageSize.width - mediaInset, mediaInset);
            }
        }
        self.pictureView.image = locationMessage.thumbnailImage;
        self.shadowMaskView.image = nil;
        self.messageContentView.contentSize = CGSizeMake(contentWidth, imageSize.height + quoteOffset + bodyOffset + mediaInset);
        self.pictureView.frame = CGRectMake(contentX, quoteOffset + bodyOffset, imageSize.width, imageSize.height);
        self.locationNameLabel.frame = CGRectMake(0, self.pictureView.frame.size.height - 25,self.pictureView.frame.size.width, 25);
        self.quoteDividerView.hidden = !showsQuoteCard;
        self.bubbleBackgroundView.hidden = !showsQuoteCard;
        if (showsQuoteCard) {
            CGFloat dividerWidth = MAX(contentWidth - QUOTE_DIVIDER_HORIZONTAL_INSET * 2, 0);
            self.quoteDividerView.frame = CGRectMake(QUOTE_DIVIDER_HORIZONTAL_INSET,
                                                     quoteOffset + QUOTE_DIVIDER_TOP_OFFSET,
                                                     dividerWidth,
                                                     1);
            [self.messageContentView bringSubviewToFront:self.quoteDividerView];
        } else {
            self.quoteDividerView.frame = CGRectZero;
        }
        UIImage *bubbleImage = [self getDefaultMessageCellBackgroundImage];
        self.bubbleBackgroundView.image = bubbleImage;
        [self setMaskImage:bubbleImage];
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

- (BOOL)usesTopQuoteCardLayout {
    return YES;
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

- (UIView *)quoteDividerView {
    if (!_quoteDividerView) {
        _quoteDividerView = [[UIView alloc] initWithFrame:CGRectZero];
        _quoteDividerView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xE2E4E5", @"0xE2E4E5");
        _quoteDividerView.hidden = YES;
    }
    return _quoteDividerView;
}

@end
