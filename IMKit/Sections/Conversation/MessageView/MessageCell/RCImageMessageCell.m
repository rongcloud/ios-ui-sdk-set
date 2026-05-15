//
//  RCImageMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCImageMessageCell.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCResendManager.h"
#import "RCReferencedContentView.h"

#define QUOTE_CARD_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_TOP_OFFSET 8
#define QUOTE_BODY_TOP_SPACING 16
#define QUOTE_MEDIA_INSET QUOTE_DIVIDER_HORIZONTAL_INSET

static CGFloat RCImageMessageQuoteContentOffset(RCMessageModel *model, CGFloat bubbleWidth) {
    CGFloat cardWidth = MAX(bubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGFloat cardHeight = [RCReferencedContentView quoteCardHeightForMessageModel:model maxWidth:cardWidth];
    return RCQuoteCardTopMargin + cardHeight;
}

static CGFloat RCImageMessageQuoteBubbleWidth(RCMessageModel *model, CGSize imageSize) {
    CGFloat maxBubbleWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat maxCardWidth = MAX(maxBubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGSize quoteCardSize = [RCReferencedContentView quoteCardContentSizeForMessageModel:model maxWidth:maxCardWidth];
    CGFloat contentWidth = MAX(imageSize.width, quoteCardSize.width);
    return MIN(contentWidth + QUOTE_MEDIA_INSET * 2, maxBubbleWidth);
}

@interface RCImageMessageCell ()
@property (nonatomic, strong) RCBaseImageView *destructPicture;
@property (nonatomic, strong) UILabel *destructLabel;
@property (nonatomic, strong) RCBaseImageView *destructBackgroundView;
@property (nonatomic, strong) UIView *quoteDividerView;
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
    if ([RCReferencedContentView shouldShowQuoteCardForMessageModel:model]) {
        messagecontentview_height += QUOTE_BODY_TOP_SPACING + QUOTE_MEDIA_INSET;
    }
    return CGSizeMake(collectionViewWidth, messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    if (self.model && self.model.messageId != model.messageId) {
        [self showProgressView];
        [self.progressView updateProgress:model.uploadProgress];
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
    self.destructBackgroundView.image = [self getDefaultMessageCellBackgroundImage];
    self.destructBackgroundView.frame = CGRectMake(0, 0, DestructBackGroundWidth, DestructBackGroundHeight);
    self.destructPicture.frame = CGRectMake(50, 43, 31, 25);
    self.destructLabel.frame = CGRectMake(0,CGRectGetMaxY(self.destructPicture.frame)+4, self.destructBackgroundView.frame.size.width, 17);
    if (self.model.messageDirection == MessageDirection_SEND) {
        [self.destructLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F")];
        self.destructPicture.image = RCDynamicImage(@"conversation_msg_cell_destruct_pic_img",@"burnPicture");
    }else{
        [self.destructLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc")];
        self.destructPicture.image = RCDynamicImage(@"conversation_msg_cell_receive_destruct_pic_img", @"from_burn_picture");
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
        return RCDynamicImage(@"conversation_msg_cell_to_thumb_broken_img", @"to_thumb_image_broken");
    } else {
        return RCDynamicImage(@"conversation_msg_cell_from_thumb_broken_img",@"from_thumb_image_broken");
    }
}

- (void)initialize {
    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.pictureView];
    [self.messageContentView addSubview:self.quoteDividerView];
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
            BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
            CGFloat contentWidth = imageSize.width;
            CGFloat mediaInset = 0;
            if (showsQuoteCard) {
                contentWidth = RCImageMessageQuoteBubbleWidth(self.model, imageSize);
                mediaInset = QUOTE_MEDIA_INSET;
            }
            CGFloat quoteOffset = showsQuoteCard ? RCImageMessageQuoteContentOffset(self.model, contentWidth) : 0;
            CGFloat bodyOffset = showsQuoteCard ? QUOTE_BODY_TOP_SPACING : 0;
            CGFloat contentX = mediaInset;
            self.pictureView.image = displayImage;
            self.messageContentView.contentSize = CGSizeMake(contentWidth, imageSize.height + quoteOffset + bodyOffset + mediaInset);
            self.pictureView.frame = CGRectMake(contentX, quoteOffset + bodyOffset, imageSize.width, imageSize.height);
            self.progressView.frame = self.pictureView.bounds;
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
        }
    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCImageMessage object");
    }
}

- (BOOL)usesTopQuoteCardLayout {
    return YES;
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
                self.model.uploadProgress = progress;
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

- (RCBaseImageView *)destructBackgroundView{
    if (!_destructBackgroundView) {
        _destructBackgroundView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
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

- (RCBaseImageView *)destructPicture{
    if (!_destructPicture) {
        _destructPicture = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 31, 26)];
    }
    return _destructPicture;
}

- (RCBaseImageView *)pictureView{
    if (!_pictureView) {
        _pictureView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
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

- (UIView *)quoteDividerView {
    if (!_quoteDividerView) {
        _quoteDividerView = [[UIView alloc] initWithFrame:CGRectZero];
        _quoteDividerView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xE2E4E5", @"0xE2E4E5");
        _quoteDividerView.hidden = YES;
    }
    return _quoteDividerView;
}
@end
