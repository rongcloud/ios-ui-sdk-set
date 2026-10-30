//
//  RCSightMessageCell.m
//  RongIMKit
//
//  Created by LiFei on 2016/12/5.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCSightMessageCell.h"
#import "RCKitCommonDefine.h"
#import "RCSightMessageProgressView.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCResendManager.h"
#import "RCReferencedContentView.h"
#import "RCMessageCell+Internal.h"
#import "RCMessageModel+MessageReaction.h"
extern NSString *const RCKitDispatchDownloadMediaNotification;

#define QUOTE_CARD_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_TOP_OFFSET 8
#define QUOTE_DIVIDER_HEIGHT 1
#define QUOTE_BODY_TOP_SPACING 10
#define QUOTE_MIN_BUBBLE_WIDTH 170.0f
#define QUOTE_MEDIA_INSET QUOTE_DIVIDER_HORIZONTAL_INSET

static CGFloat RCSightMessageQuoteContentOffset(RCMessageModel *model, CGFloat bubbleWidth) {
    CGFloat cardWidth = MAX(bubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGFloat cardHeight = [RCReferencedContentView quoteCardHeightForMessageModel:model maxWidth:cardWidth];
    return RCQuoteCardTopMargin + cardHeight;
}

static CGFloat RCSightMessageQuoteMinimumBubbleWidth(void) {
    CGFloat maxContentWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    return maxContentWidth < QUOTE_MIN_BUBBLE_WIDTH ? maxContentWidth : QUOTE_MIN_BUBBLE_WIDTH;
}

static CGFloat RCSightMessageQuoteBubbleWidth(RCMessageModel *model, CGSize imageSize) {
    CGFloat maxBubbleWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat maxCardWidth = MAX(maxBubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGSize quoteCardSize = [RCReferencedContentView quoteCardContentSizeForMessageModel:model maxWidth:maxCardWidth];
    CGFloat contentWidth = MAX(imageSize.width, quoteCardSize.width);
    CGFloat bubbleWidth = contentWidth + QUOTE_MEDIA_INSET * 2;
    return MIN(MAX(bubbleWidth, RCSightMessageQuoteMinimumBubbleWidth()), maxBubbleWidth);
}

@interface RCSightMessageCell ()
@property (nonatomic, strong) UIView *playButtonView;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) RCBaseImageView *playImage;
@property (nonatomic, strong) RCBaseImageView *destructPicture;
@property (nonatomic, strong) UILabel *destructLabel;
@property (nonatomic, strong) UILabel *destructDurationLabel;
@property (nonatomic, strong) RCBaseImageView *destructBackgroundView;
@property (nonatomic, strong) UIView *quoteDividerView;
@end

@implementation RCSightMessageCell

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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat messagecontentview_height = 0.0f;
    if (model.content.destructDuration > 0) {
        messagecontentview_height = DestructBackGroundHeight;
    } else {
        messagecontentview_height = [self getSightImageSize:model].height;
    }
    if (messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    messagecontentview_height += extraHeight;
    if (model.content.destructDuration <= 0) {
        BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:model];
        if (showsQuoteCard) {
            messagecontentview_height += QUOTE_DIVIDER_TOP_OFFSET + QUOTE_DIVIDER_HEIGHT + QUOTE_BODY_TOP_SPACING + QUOTE_MEDIA_INSET;
        } else if ([model rc_hasVisibleReactions]) {
            messagecontentview_height += QUOTE_BODY_TOP_SPACING + QUOTE_MEDIA_INSET;
        }
    }
    return CGSizeMake(collectionViewWidth, messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    self.thumbnailView.image = nil;
    RCSightMessage *sightMessage = (RCSightMessage *)model.content;
    if (sightMessage) {
        if (sightMessage.destructDuration <= 0) {
            self.destructBackgroundView.frame = CGRectZero;
            self.destructBackgroundView.hidden = YES;
            CGSize imageSize = [RCSightMessageCell getSightImageSize:self.model];
            self.durationLabel.text = [self getSightDurationLabelText:sightMessage.duration];
            self.thumbnailView.image = sightMessage.thumbnailImage;

            BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
            BOOL usesBubbleContainer = showsQuoteCard || [self.model rc_hasVisibleReactions];
            CGFloat contentWidth = imageSize.width;
            CGFloat mediaInset = 0;
            if (usesBubbleContainer) {
                contentWidth = RCSightMessageQuoteBubbleWidth(self.model, imageSize);
                mediaInset = QUOTE_MEDIA_INSET;
            }
            CGFloat quoteOffset = showsQuoteCard ? RCSightMessageQuoteContentOffset(self.model, contentWidth) : 0;
            CGFloat bodyOffset = [self bodyTopOffsetWithQuoteCardVisible:showsQuoteCard
                                                     bubbleContainerUsed:usesBubbleContainer];

            self.messageContentView.contentSize = CGSizeMake(contentWidth, imageSize.height + quoteOffset + bodyOffset + mediaInset);
            [self updateSightMediaFrameWithImageSize:imageSize
                                         contentWidth:contentWidth
                                         quoteOffset:quoteOffset
                                          bodyOffset:bodyOffset
                                          mediaInset:mediaInset
                                      showsQuoteCard:showsQuoteCard];
            self.quoteDividerView.hidden = !showsQuoteCard;
            self.bubbleBackgroundView.hidden = !usesBubbleContainer;
            if (showsQuoteCard) {
                CGFloat dividerWidth = MAX(contentWidth - QUOTE_DIVIDER_HORIZONTAL_INSET * 2, 0);
                self.quoteDividerView.frame = CGRectMake(QUOTE_DIVIDER_HORIZONTAL_INSET,
                                                         quoteOffset + QUOTE_DIVIDER_TOP_OFFSET,
                                                         dividerWidth,
                                                         QUOTE_DIVIDER_HEIGHT);
                [self.messageContentView bringSubviewToFront:self.quoteDividerView];
            } else {
                self.quoteDividerView.frame = CGRectZero;
            }
            [self updateQuoteDividerLayoutIfNeeded];

            if (self.progressView.superview) {
                [self.progressView removeFromSuperview];
            }
            self.progressView = [[RCSightMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
            [self.progressView setHidden:YES];
            self.progressView.progressTintColor =  RCDynamicColor(@"control_title_white_color", @"0xFFFFFF", @"0xFFFFFF");
            [self.thumbnailView addSubview:self.progressView];
            [self.playImage setCenter:CGPointMake(self.thumbnailView.bounds.size.width / 2,
                                                  self.thumbnailView.bounds.size.height / 2)];
            self.progressView.center = self.playImage.center;
            CGRect durationLabelBgFrame =
                CGRectMake(0, self.thumbnailView.bounds.size.height - 21, self.thumbnailView.bounds.size.width, 21);
            self.durationLabel.superview.frame = durationLabelBgFrame;
            self.durationLabel.frame =
                CGRectMake(0, 0, durationLabelBgFrame.size.width-5, durationLabelBgFrame.size.height);
        }
    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCsightMessage object");
    }

    [self updateStatusContentView:self.model];
    
    [self updateSightPlayStatus];
}

- (void)messageContentViewFrameDidChange {
    [super messageContentViewFrameDidChange];
    [self updateSightMediaFrameIfNeeded];
    [self updateQuoteDividerLayoutIfNeeded];
}

- (void)updateSightPlayStatus{
    if (self.model.sentStatus == SentStatus_SENDING || [[RCResendManager sharedManager] needResend:self.model.messageId]) {
        [self.playButtonView setHidden:YES];
        [self.progressView startIndeterminateAnimation];
        [self.progressView setHidden:NO];
    } else {
        [self.playButtonView setHidden:NO];
        [self.progressView stopIndeterminateAnimation];
        [self.progressView setHidden:YES];
    }
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
    if (self.model.content.destructDuration > 0) {
        RCSightMessage *sightMessage = (RCSightMessage *)self.model.content;
        self.destructDurationLabel.text = [self getSightDurationLabelText:sightMessage.duration];
        [self updateDestructViews];
    }
    [super setDestructViewLayout];
}

- (void)updateDestructViews{
    self.destructBackgroundView.hidden = NO;
    self.destructBackgroundView.frame = CGRectZero;
    self.thumbnailView.frame = CGRectZero;
    self.messageContentView.contentSize = CGSizeMake(DestructBackGroundWidth, DestructBackGroundWidth);
    self.destructBackgroundView.frame = self.messageContentView.bounds;
    self.destructBackgroundView.image = [self getDefaultMessageCellBackgroundImage];
    self.destructPicture.frame = CGRectMake(55, 43, 22, 22);
    self.destructLabel.frame = CGRectMake(0, CGRectGetMaxY(self.destructPicture.frame)+8, self.destructBackgroundView.frame.size.width, 14);
    CGRect durationLabelFrame = CGRectMake(0, self.destructBackgroundView.bounds.size.height - 20, self.destructBackgroundView.bounds.size.width - 8, 14);
    self.destructDurationLabel.frame = durationLabelFrame;
    if (self.model.messageDirection == MessageDirection_SEND) {
        self.destructDurationLabel.textColor =
        RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F");
        self.destructLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F");
        self.destructPicture.image = RCDynamicImage(@"conversation_msg_cell_destruct_video_img", @"burn_video_picture");
    }else{
        self.destructDurationLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc");
        self.destructLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc");
        self.destructPicture.image = RCDynamicImage(@"conversation_msg_cell_receive_destruct_video_img",@"from_burn_video_picture");
    }
}

#pragma mark - Private Methods

+ (CGSize)getSightImageSize:(RCMessageModel *)model{
    RCSightMessage *sightMessage = (RCSightMessage *)model.content;

    CGSize imageSize = sightMessage.thumbnailImage.size;
    //兼容240
    CGFloat rate = imageSize.width / imageSize.height;
    CGFloat imageWidth = 0;
    CGFloat imageHeight = 0;

    if (imageSize.width != 0 && imageSize.height != 0) {
        if (rate > 1.0f) {
            imageWidth = 160;
            imageHeight = 160 / rate;
        } else {
            imageHeight = 160;
            imageWidth = 160 * rate;
        }
    } else {
        imageWidth = imageSize.width;
        imageHeight = imageSize.height;
    }
    return CGSizeMake(imageWidth, imageHeight);
}

- (void)initialize {
    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.thumbnailView];
    [self.messageContentView addSubview:self.quoteDividerView];
    [self.messageContentView addSubview:self.destructBackgroundView];

    [self.destructBackgroundView addSubview:self.destructPicture];
    [self.destructBackgroundView addSubview:self.destructLabel];
    [self.destructBackgroundView addSubview:self.destructDurationLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:RCKitDispatchDownloadMediaNotification
                                               object:nil];
}

- (NSString *)getSightDurationLabelText:(long)duration{
    NSInteger minutes = duration / 60;
    NSInteger seconds = round(duration - minutes * 60);
    if (seconds == 60) {
        minutes += 1;
        seconds = 0;
    }
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    if (self.model.messageId == [statusDic[@"messageId"] longValue]) {
        if ([statusDic[@"type"] isEqualToString:@"progress"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.progressView isHidden]) {
                    [self.progressView setHidden:NO];
                    [self.progressView startIndeterminateAnimation];
                }
                [self.progressView setProgress:[statusDic[@"progress"] intValue] animated:YES];
            });
        } else if ([statusDic[@"type"] isEqualToString:@"success"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressView stopIndeterminateAnimation];
                [self.progressView setHidden:YES];
                RCSightMessage *sightContent = (RCSightMessage *)self.model.content;
                [sightContent setValue:statusDic[@"mediaPath"] forKey:@"localPath"];
            });
        } else if ([statusDic[@"type"] isEqualToString:@"error"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self.progressView isHidden]) {
                    [self.progressView stopIndeterminateAnimation];
                    [self.progressView setHidden:YES];
                }

                UIViewController *rootVC = [RCKitUtility getKeyWindow].rootViewController;
                UIAlertController *alertController = [UIAlertController
                    alertControllerWithTitle:nil
                                     message:RCLocalizedString(@"FileDownloadFailed")
                              preferredStyle:UIAlertControllerStyleAlert];
                [alertController
                    addAction:[UIAlertAction actionWithTitle:RCLocalizedString(@"OK")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *_Nonnull action){
                                                     }]];
                [rootVC presentViewController:alertController animated:YES completion:nil];
            });
        }
    }
}

- (void)updateSightMediaFrameIfNeeded {
    if (self.model.content.destructDuration > 0 || CGRectIsEmpty(self.thumbnailView.frame)) {
        return;
    }
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    BOOL usesBubbleContainer = showsQuoteCard || [self.model rc_hasVisibleReactions];
    self.bubbleBackgroundView.hidden = !usesBubbleContainer;
    if (!usesBubbleContainer) {
        return;
    }
    CGSize imageSize = self.thumbnailView.frame.size;
    CGFloat contentWidth = CGRectGetWidth(self.messageContentView.bounds);
    CGFloat quoteOffset = showsQuoteCard ? RCSightMessageQuoteContentOffset(self.model, contentWidth) : 0;
    CGFloat bodyOffset = [self bodyTopOffsetWithQuoteCardVisible:showsQuoteCard
                                             bubbleContainerUsed:usesBubbleContainer];
    [self updateSightMediaFrameWithImageSize:imageSize
                                 contentWidth:contentWidth
                                 quoteOffset:quoteOffset
                                  bodyOffset:bodyOffset
                                  mediaInset:QUOTE_MEDIA_INSET
                              showsQuoteCard:showsQuoteCard];
}

- (CGFloat)bodyTopOffsetWithQuoteCardVisible:(BOOL)showsQuoteCard
                         bubbleContainerUsed:(BOOL)usesBubbleContainer {
    if (showsQuoteCard) {
        return QUOTE_DIVIDER_TOP_OFFSET + QUOTE_DIVIDER_HEIGHT + QUOTE_BODY_TOP_SPACING;
    }
    return usesBubbleContainer ? QUOTE_BODY_TOP_SPACING : 0;
}

- (void)updateSightMediaFrameWithImageSize:(CGSize)imageSize
                              contentWidth:(CGFloat)contentWidth
                               quoteOffset:(CGFloat)quoteOffset
                                bodyOffset:(CGFloat)bodyOffset
                                mediaInset:(CGFloat)mediaInset
                             showsQuoteCard:(BOOL)showsQuoteCard {
    CGFloat contentX = mediaInset;
    if (mediaInset > 0) {
        BOOL hasVisibleReactions = [self.model rc_hasVisibleReactions];
        BOOL alignsTrailing = (hasVisibleReactions || showsQuoteCard)
            ? [RCKitUtility isRTL]
            : ([RCKitUtility isRTL]
               ? self.model.messageDirection == MessageDirection_RECEIVE
               : self.model.messageDirection == MessageDirection_SEND);
        if (alignsTrailing) {
            contentX = MAX(contentWidth - imageSize.width - mediaInset, mediaInset);
        }
    }
    self.thumbnailView.frame = CGRectMake(contentX, quoteOffset + bodyOffset, imageSize.width, imageSize.height);
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    [super messageCellUpdateSendingStatusEvent:notification];
    RCMessageCellNotificationModel *notifyModel = notification.object;
    NSInteger progress = notifyModel.progress;
    if (self.model.messageId == notifyModel.messageId) {
        DebugLog(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            [self.progressView startIndeterminateAnimation];
            [self.progressView setHidden:NO];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            [self updateSightPlayStatus];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != SentStatus_READ) {
                [self.playButtonView setHidden:NO];
                [self.progressView stopIndeterminateAnimation];
                [self.progressView setHidden:YES];
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            if (self.progressView.hidden) {
                [self.playButtonView setHidden:YES];
                [self.progressView startIndeterminateAnimation];
                [self.progressView setHidden:NO];
            }
            float pro = progress / 100.0f;
            [self.progressView setProgress:pro animated:YES];
        } else if (self.model.sentStatus == SentStatus_READ && self.isDisplayReadStatus) {
            [self.progressView stopIndeterminateAnimation];
            [self.progressView setHidden:YES];
        }
    }
}

#pragma mark - Getters and Setters

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 21)];
        [_durationLabel setTextAlignment:NSTextAlignmentRight];
        [_durationLabel setBackgroundColor:[UIColor clearColor]];
        [_durationLabel setTextColor:RCDynamicColor(@"control_title_white_color", @"0xFFFFFF", @"0xFFFFFF")];
        [_durationLabel setFont:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]];
    }
    return _durationLabel;
}

- (RCBaseImageView *)playImage {
    if (!_playImage) {
        _playImage = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 41, 41)];
        UIImage *image = RCDynamicImage(@"conversation_msg_cell_sight_icon_img",@"sight_message_icon");
        _playImage.image = image;
    }
    return _playImage;
}

- (UIView *)playButtonView {
    if (!_playButtonView) {
        _playButtonView = [[UIView alloc] initWithFrame:self.thumbnailView.bounds];
        [_playButtonView addSubview:self.playImage];
        [self.thumbnailView addSubview:_playButtonView];
        RCBaseImageView *backgroudView =
            [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, self.thumbnailView.bounds.size.height - 21,
                                                          self.thumbnailView.bounds.size.width, 21)];
        backgroudView.image = RCDynamicImage(@"conversation_msg_cell_player_shadow_bottom_img",@"player_shadow_bottom");
        [_playButtonView addSubview:backgroudView];
        [backgroudView addSubview:self.durationLabel];
    }
    return _playButtonView;
}

- (RCBaseImageView *)thumbnailView{
    if (!_thumbnailView) {
        _thumbnailView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
        _thumbnailView.layer.masksToBounds = YES;
        _thumbnailView.layer.cornerRadius = 6;
    }
    return _thumbnailView;
}

- (RCBaseImageView *)destructBackgroundView{
    if (!_destructBackgroundView) {
        _destructBackgroundView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
    }
    return _destructBackgroundView;
}

- (RCBaseImageView *)destructPicture{
    if (!_destructPicture) {
        _destructPicture = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 31, 26)];
    }
    return _destructPicture;
}

- (UILabel *)destructLabel{
    if (!_destructLabel) {
        _destructLabel = [[UILabel alloc] init];
        _destructLabel.text = RCLocalizedString(@"ClickToPlay");
        _destructLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _destructLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _destructLabel;
}

- (UILabel *)destructDurationLabel{
    if (!_destructDurationLabel) {
        _destructDurationLabel = [[UILabel alloc] init];
        _destructDurationLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        [_destructDurationLabel setTextAlignment:NSTextAlignmentRight];
        [_destructDurationLabel setBackgroundColor:[UIColor clearColor]];
    }
    return _destructDurationLabel;
}

- (UIView *)quoteDividerView {
    if (!_quoteDividerView) {
        _quoteDividerView = [[UIView alloc] initWithFrame:CGRectZero];
        _quoteDividerView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xE2E4E5", @"0xE2E4E5");
        _quoteDividerView.hidden = YES;
    }
    return _quoteDividerView;
}

- (void)updateQuoteDividerLayoutIfNeeded {
    if (![RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model]) {
        return;
    }
    if (self.quoteDividerView.hidden || CGRectGetWidth(self.quoteDividerView.frame) <= 0) {
        return;
    }
    CGFloat bubbleWidth = CGRectGetWidth(self.messageContentView.bounds);
    if (bubbleWidth <= 0) {
        return;
    }
    CGRect frame = self.quoteDividerView.frame;
    frame.size.width = MAX(bubbleWidth - QUOTE_DIVIDER_HORIZONTAL_INSET * 2, 0);
    self.quoteDividerView.frame = frame;
}

- (BOOL)usesTopQuoteCardLayout {
    return YES;
}

@end
