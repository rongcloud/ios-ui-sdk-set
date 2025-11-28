//
//  RCStickerMessageCell.m
//  RongSticker
//
//  Created by liyan on 2018/8/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerMessageCell.h"
#import "RCStickerMessage.h"
#import "RCStickerUtility.h"
#define MAXHEIGHT 120.0f
#define FAIELDIMAGEEHEIGHT 43.0f
#define FAIELDLABLEWIDTHT 80.0f
#define FAIELDLABLEHEIGHT 15.0f
#define LABLESET 12.0f

@interface RCStickerMessageCell ()
@property (nonatomic, strong) RCBaseImageView *loadingImageView;
@property (nonatomic, strong) RCBaseImageView *loadfailedBackImageview;
@property (nonatomic, strong) RCBaseImageView *loadfailedImageView;
@property (nonatomic, strong) UILabel *loadFailedLable;
@property (nonatomic, strong) UIView *destructView;

- (void)initialize;
@end

@implementation RCStickerMessageCell
+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height = 0.0f;
    CGFloat imageHeight = MAXHEIGHT;
    RCStickerMessage *stickerMessage = (RCStickerMessage *)model.content;
    if (stickerMessage && stickerMessage.height) {
        imageHeight = stickerMessage.height / 2.0f;
    }
    __messagecontentview_height = imageHeight;

    if (__messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    __messagecontentview_height += extraHeight;

    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}
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
- (void)initialize {
    self.loadingImageView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
    self.loadingImageView.contentMode = UIViewContentModeCenter;
    [self.messageContentView addSubview:self.loadingImageView];

    self.loadfailedBackImageview = [[RCBaseImageView alloc]
        initWithFrame:CGRectMake(0, 0, FAIELDLABLEWIDTHT, FAIELDIMAGEEHEIGHT + FAIELDLABLEHEIGHT + LABLESET)];
    self.loadfailedBackImageview.contentMode = UIViewContentModeCenter;
    [self.messageContentView addSubview:self.loadfailedBackImageview];

    self.loadfailedImageView =
        [[RCBaseImageView alloc] initWithFrame:CGRectMake((FAIELDLABLEWIDTHT - FAIELDIMAGEEHEIGHT) / 2, 0,
                                                      FAIELDIMAGEEHEIGHT, FAIELDIMAGEEHEIGHT)];
    self.loadfailedImageView.contentMode = UIViewContentModeCenter;
    self.loadfailedImageView.image = RongStickerImage(@"loading_failed_image");
    [self.loadfailedBackImageview addSubview:self.loadfailedImageView];

    self.loadFailedLable = [[UILabel alloc]
        initWithFrame:CGRectMake(0, FAIELDIMAGEEHEIGHT + LABLESET, FAIELDLABLEWIDTHT, FAIELDLABLEHEIGHT)];
    self.loadFailedLable.textAlignment = NSTextAlignmentCenter;
    self.loadFailedLable.font = [UIFont systemFontOfSize:12];
    self.loadFailedLable.textColor =
    RCDynamicColor(@"text_secondary_color",@"0xC8C7CC", @"0xC8C7CC");
    self.loadFailedLable.text = RongStickerString(@"loadingfailed");
    [self.loadfailedBackImageview addSubview:self.loadFailedLable];

    self.rcStickerView = [[RCAnimatedView alloc] initWithFrame:CGRectZero];
    self.rcStickerView.layer.masksToBounds = YES;
    [self.messageContentView addSubview:self.rcStickerView];

    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    [self.rcStickerView addGestureRecognizer:longPress];
}

- (void)prepareForReuse {
    [super prepareForReuse];
}
- (void)hiddenLoafFailedView:(BOOL)hidden {
    self.loadfailedBackImageview.hidden = hidden;
    self.loadfailedImageView.hidden = hidden;
    self.loadFailedLable.hidden = hidden;
}
- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    self.loadingImageView.image = nil;
    self.rcStickerView.animatedImage = nil;
    [self hiddenLoafFailedView:YES];
    self.loadingImageView.hidden = NO;
    RCStickerMessage *stickerMessage = (RCStickerMessage *)model.content;
    if (stickerMessage) {
        CGSize imageSize = CGSizeMake(stickerMessage.width / 2.0f, stickerMessage.height / 2.0f);
        if (!imageSize.width || !imageSize.height) {
            imageSize = CGSizeMake(MAXHEIGHT, MAXHEIGHT);
        }
        CGRect messageContentViewRect = self.messageContentView.frame;

        if (model.messageDirection == MessageDirection_RECEIVE) {

        } else {
            if ([RCKitUtility isRTL]) {
                messageContentViewRect.origin.x =
                self.baseContentView.bounds.origin.x + HeadAndContentSpacing + RCKitConfigCenter.ui.globalMessagePortraitSize.width + 10;
            } else {
                messageContentViewRect.origin.x =
                self.baseContentView.bounds.size.width -
                (imageSize.width + HeadAndContentSpacing + RCKitConfigCenter.ui.globalMessagePortraitSize.width + 10);
            }
        }
        messageContentViewRect.size = CGSizeMake(imageSize.width, imageSize.height);
        self.messageContentView.frame = messageContentViewRect;
        self.rcStickerView.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
        self.loadingImageView.frame = self.rcStickerView.frame;
        self.loadfailedBackImageview.center = self.rcStickerView.center;
        self.loadingImageView.image = RongStickerImage(@"loading");
        [self startAnimation];
        __weak typeof(self) weakSelf = self;
        [[RCStickerDataManager sharedManager]
            getStickerOriginalImage:stickerMessage.packageId
                          stickerId:stickerMessage.stickerId
                      completeBlock:^(NSData *originalImage) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [weakSelf stopAnimation];
                              if (originalImage) {
                                  weakSelf.loadingImageView.hidden = YES;
                                  weakSelf.rcStickerView.animatedImage =
                                      [RCAnimated animatedImageWithGIFData:originalImage];
                              } else {
                                  weakSelf.loadingImageView.hidden = NO;
                                  weakSelf.loadingImageView.image = RongStickerImage(@"loading_failed_back");
                                  [weakSelf hiddenLoafFailedView:NO];
                              }
                          });
                      }];
    } else {
        RongStickerLog(@"[RongStickerLog]: RCMessageModel.content is NOT RCStickerMessage object");
    }

    [self setDestructViewLayout];

    [self updateStatusContentView:self.model];
    if (model.sentStatus == SentStatus_SENDING) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.rcStickerView.userInteractionEnabled = NO;
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.rcStickerView.userInteractionEnabled = YES;
        });
    }
}

- (void)setDestructViewLayout {
    RCStickerMessage *stickerMessage = (RCStickerMessage *)self.model.content;
    if (stickerMessage.destructDuration > 0) {
        self.destructView.hidden = NO;
        [self.messageContentView bringSubviewToFront:self.destructView];
        if (self.messageDirection == MessageDirection_RECEIVE) {
            self.destructView.frame = CGRectMake(CGRectGetMaxX(self.rcStickerView.frame) + 4.5,
                                                 CGRectGetMaxY(self.rcStickerView.frame) - 13 - 8.5, 21, 12);
        } else {
            self.destructView.frame = CGRectMake(CGRectGetMinX(self.rcStickerView.frame) - 25.5,
                                                 CGRectGetMaxY(self.rcStickerView.frame) - 13 - 8.5, 21, 12);
        }
    } else {
        self.destructView.hidden = YES;
        self.destructView.frame = CGRectZero;
    }
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    [super messageCellUpdateSendingStatusEvent:notification];
    RCMessageCellNotificationModel *notifyModel = notification.object;

    if (self.model.messageId == notifyModel.messageId) {
        RongStickerLog(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.rcStickerView.userInteractionEnabled = NO;
            });

        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.rcStickerView.userInteractionEnabled = YES;
            });
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != SentStatus_READ) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.rcStickerView.userInteractionEnabled = YES;
                });
            }
        }  else if (self.model.sentStatus == SentStatus_READ && self.isDisplayReadStatus) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.rcStickerView.userInteractionEnabled = YES;
            });
        }
    }
}

// override
- (void)msgStatusViewTapEventHandler:(id)sender {
    //[super msgStatusViewTapEventHandler:sender];

    // to do something.
}

- (void)longPressed:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongTouchMessageCell:self.model inView:self.rcStickerView];
    }
}

- (void)startAnimation {
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = 1.5;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = MAXFLOAT;
    [_loadingImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopAnimation {
    [_loadingImageView.layer removeAnimationForKey:@"rotationAnimation"];
}

@end
