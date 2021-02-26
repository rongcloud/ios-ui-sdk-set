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
    RCImageMessage *imageMessage = (RCImageMessage *)model.content;
    if (model.content.destructDuration > 0) {
        messagecontentview_height = DestructBackGroundHeight;
    } else {
        messagecontentview_height = [RCMessageCellTool getThumbnailImageSize:imageMessage.thumbnailImage].height;
    }
    if (messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    return messagecontentview_height;
}

- (void)initialize {
    [self.messageContentView addSubview:self.pictureView];
    [self.messageContentView addSubview:self.destructBackgroundView];
    [self.destructBackgroundView addSubview:self.destructPicture];
    [self.destructBackgroundView addSubview:self.destructLabel];
    self.progressView = [[RCImageMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
}

- (void)setAutoLayout {
    self.pictureView.image = nil;
    RCImageMessage *imageMessage = (RCImageMessage *)self.model.content;
    if (imageMessage) {
        if (imageMessage.destructDuration <= 0) {
            self.destructBackgroundView.frame = CGRectZero;
            self.destructBackgroundView.hidden = YES;
            CGSize imageSize = [RCMessageCellTool getThumbnailImageSize:imageMessage.thumbnailImage];
            self.pictureView.image = imageMessage.thumbnailImage;
            self.messageContentView.contentSize = imageSize;
            self.pictureView.frame = self.messageContentView.bounds;
        }
    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCImageMessage object");
    }
}

- (void)updateProgressView{
    if (self.model.sentStatus == SentStatus_SENDING || [[RCResendManager sharedManager] needResend:self.model.messageId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pictureView addSubview:self.progressView];
            [self.progressView setFrame:self.pictureView.bounds];
            [self.progressView startAnimating];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView removeFromSuperview];
        });
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
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.pictureView addSubview:_progressView];
                [self.progressView setFrame:self.pictureView.bounds];
                [self.progressView startAnimating];
            });
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            if (self.model.sentStatus == SentStatus_SENDING) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.pictureView addSubview:_progressView];
                    [self.progressView setFrame:self.pictureView.bounds];
                    [self.progressView startAnimating];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressView stopAnimating];
                    [self.progressView removeFromSuperview];
                });
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != SentStatus_READ) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressView stopAnimating];
                    [self.progressView removeFromSuperview];
                });
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressView updateProgress:progress];
            });
        } else if (self.model.sentStatus == SentStatus_READ && self.isDisplayReadStatus) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressView stopAnimating];
                [self.progressView removeFromSuperview];
            });
        }
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

@end
