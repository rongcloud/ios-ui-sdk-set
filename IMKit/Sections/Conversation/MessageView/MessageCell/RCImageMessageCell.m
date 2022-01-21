//
//  RCImageMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCImageMessageCell.h"
#import "RCIM.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCResendManager.h"
@interface RCImageMessageCell ()
@property (nonatomic, strong) UIImageView *destructPicture;
@property (nonatomic, strong) UILabel *destructLabel;
@property (nonatomic, strong) UIImageView *destructBackgroundView;
@end

@implementation RCImageMessageCell
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
    CGFloat messagecontentview_height = [self getMessageContentHeight:model];
    messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    if (self.model && self.model.messageId != model.messageId) {
        [self showProgressView];
        [self.progressView updateProgress:0];
    }
    [super setDataModel:model];

    [self setAutoLayout];
    [self updateStatusContentView:self.model];
    [self updateProgressView];
}

- (void)updateStatusContentView:(RCMessageModel *)model{
    [super updateStatusContentView:model];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (model.content.destructDuration <= 0) {
            weakSelf.messageActivityIndicatorView.hidden = YES;
        }
    });
}
#pragma mark - 阅后即焚
- (void)setDestructViewLayout {
    [super setDestructViewLayout];
    if (self.model.content.destructDuration > 0) {
        [self setDestructUI];
    }
}

- (void)setDestructUI{
    self.destructBackgroundView.hidden = NO;
    self.pictureView.frame = CGRectZero;
    self.messageContentView.contentSize = CGSizeMake(DestructBackGroundWidth, DestructBackGroundHeight);
    self.destructBackgroundView.image = [RCMessageCellTool getDefaultMessageCellBackgroundImage:self.model];
    self.destructBackgroundView.frame = CGRectMake(0, 0, DestructBackGroundWidth, DestructBackGroundHeight);
    self.destructPicture.frame = CGRectMake(50, 43, 31, 25);
    self.destructLabel.frame = CGRectMake(0,CGRectGetMaxY(self.destructPicture.frame)+4, self.destructBackgroundView.frame.size.width, 17);
    if (self.model.messageDirection == MessageDirection_SEND) {
        [self.destructLabel setTextColor:RCDYCOLOR(0x111f2c, 0x040a0f)];
        self.destructPicture.image = RCResourceImage(@"burnPicture");
    }else{
        [self.destructLabel setTextColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:RCMASKCOLOR(0xffffff, 0.8)]];
        self.destructPicture.image = RCResourceImage(@"from_burn_picture");
    }
}

#pragma mark - Private Methods

+ (CGFloat)getMessageContentHeight:(RCMessageModel *)model{
    CGFloat messagecontentview_height = 0.0f;
    if (model.content.destructDuration > 0) {
        messagecontentview_height = DestructBackGroundHeight;
    } else {
        messagecontentview_height = [RCMessageCellTool getThumbnailImageSize:[self getDisplayImage:model]].height;
    }
    if (messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    return messagecontentview_height;
}

+ (UIImage *)getDisplayImage:(RCMessageModel *)model {
    RCImageMessage *imageMessage = (RCImageMessage *)model.content;
    if (imageMessage.thumbnailImage) {
        return imageMessage.thumbnailImage;
    }
    if (model.messageDirection == MessageDirection_SEND) {
        return RCResourceImage(@"to_thumb_image_broken");
    } else {
        return RCResourceImage(@"from_thumb_image_broken");
    }
}

- (void)initialize {
    [self.messageContentView addSubview:self.pictureView];
    [self.messageContentView addSubview:self.destructBackgroundView];
    [self.destructBackgroundView addSubview:self.destructPicture];
    [self.destructBackgroundView addSubview:self.destructLabel];
}

- (void)setAutoLayout {
    self.pictureView.image = nil;
    RCImageMessage *imageMessage = (RCImageMessage *)self.model.content;
    if (imageMessage) {
        if (imageMessage.destructDuration <= 0) {
            self.destructBackgroundView.frame = CGRectZero;
            self.destructBackgroundView.hidden = YES;
            UIImage *displayImage = [[self class] getDisplayImage:self.model];
            CGSize imageSize = [RCMessageCellTool getThumbnailImageSize:displayImage];
            self.pictureView.image = displayImage;
            self.messageContentView.contentSize = imageSize;
            self.pictureView.frame = self.messageContentView.bounds;
            self.progressView.frame = self.pictureView.bounds;
        }
    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCImageMessage object");
    }
}

- (void)updateProgressView{
    if (self.model.sentStatus == SentStatus_SENDING || [[RCResendManager sharedManager] needResend:self.model.messageId]) {
        [self showProgressView];
    } else {
        [self hiddenProgressView];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
   [super messageCellUpdateSendingStatusEvent:notification];
    RCMessageCellNotificationModel *notifyModel = notification.object;
    NSInteger progress = notifyModel.progress;
    if (self.model.messageId == notifyModel.messageId) {
        DebugLog(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            [self showProgressView];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            if (self.model.sentStatus == SentStatus_SENDING) {
                [self showProgressView];
            } else {
                [self hiddenProgressView];
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != SentStatus_READ) {
                [self hiddenProgressView];
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressView];
                [self.progressView updateProgress:progress];
            });
        } else if (self.model.sentStatus == SentStatus_READ && self.isDisplayReadStatus) {
            [self hiddenProgressView];
        }
    }
}

- (void)showProgressView{
    if (self.progressView.hidden) {
        self.progressView.hidden = NO;
        [self.progressView startAnimating];
    }
}

- (void)hiddenProgressView{
    if (!self.progressView.hidden) {
        self.progressView.hidden = YES;
        [self.progressView stopAnimating];
    }
}

#pragma mark - Getter

- (UIImageView *)destructBackgroundView{
    if (!_destructBackgroundView) {
        _destructBackgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _destructBackgroundView;
}

- (UILabel *)destructLabel{
    if (!_destructLabel) {
        _destructLabel = [[UILabel alloc] init];
        _destructLabel.text = RCLocalizedString(@"ClickToView");
        _destructLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _destructLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _destructLabel;
}

- (UIImageView *)destructPicture{
    if (!_destructPicture) {
        _destructPicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 31, 26)];
    }
    return _destructPicture;
}

- (UIImageView *)pictureView{
    if (!_pictureView) {
        _pictureView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _pictureView.layer.masksToBounds = YES;
        _pictureView.layer.cornerRadius = 6;
    }
    return _pictureView;
}

- (RCImageMessageProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[RCImageMessageProgressView alloc] init];
        [self.pictureView addSubview:_progressView];
        _progressView.hidden = YES;
    }
    return _progressView;
}
@end
