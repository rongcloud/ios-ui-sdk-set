//
//  RCFileMessageCell.m
//  RongIMKit
//
//  Created by liulin on 16/7/21.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCFileMessageCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCResendManager.h"
#import "RCReferencedContentView.h"
#import "RCMessageCell+Internal.h"
#import "RCMessageModel+MessageReaction.h"
extern NSString *const RCKitDispatchDownloadMediaNotification;

#define FILE_CONTENT_HEIGHT 69.f
#define FILE_CONTENT_MIN_WIDTH 180.f
#define FILE_QUOTE_CONTENT_HEIGHT 50.f
#define QUOTE_CARD_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_TOP_SPACING 6
#define QUOTE_DIVIDER_HEIGHT 1
#define QUOTE_DIVIDER_BOTTOM_SPACING 10
#define QUOTE_BODY_BOTTOM_SPACING 10
#define FILE_CONTENT_HORIZONTAL_INSET 12
#define FILE_ICON_SIZE 48
#define FILE_ICON_TEXT_SPACING 10
#define FILE_QUOTE_CONTENT_HORIZONTAL_INSET 8
#define FILE_QUOTE_ICON_SIZE 32
#define FILE_QUOTE_ICON_TEXT_SPACING 8
#define FILE_QUOTE_NAME_TOP 7
#define FILE_QUOTE_BOTTOM_INSET 7
#define FILE_QUOTE_SIZE_HEIGHT 15
#define FILE_REACTION_CARD_VERTICAL_INSET 12

static CGFloat RCFileMessageQuoteContentOffset(RCMessageModel *model, CGFloat bubbleWidth) {
    CGFloat cardWidth = MAX(bubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGFloat cardHeight = [RCReferencedContentView quoteCardHeightForMessageModel:model maxWidth:cardWidth];
    return RCQuoteCardTopMargin + cardHeight;
}

static CGFloat RCFileMessageQuoteBodyTopSpacing(void) {
    return QUOTE_DIVIDER_TOP_SPACING + QUOTE_DIVIDER_HEIGHT + QUOTE_DIVIDER_BOTTOM_SPACING;
}

static CGFloat RCFileMessageBodyCardWidth(RCMessageModel *model, CGFloat maxWidth) {
    if (maxWidth <= 0) {
        return 0;
    }
    RCFileMessage *fileMessage = [model.content isKindOfClass:[RCFileMessage class]] ? (RCFileMessage *)model.content : nil;
    CGFloat maxTextWidth = MAX(maxWidth - FILE_QUOTE_CONTENT_HORIZONTAL_INSET * 2 -
                               FILE_QUOTE_ICON_SIZE - FILE_QUOTE_ICON_TEXT_SPACING, 0);
    NSString *fileName = fileMessage.name ?: @"";
    NSString *fileSize = fileMessage ? [RCKitUtility getReadableStringForFileSize:fileMessage.size] : @"";
    CGSize nameSize = [RCKitUtility getTextDrawingSize:fileName
                                                  font:[[RCKitConfig defaultConfig].font fontOfGuideLevel]
                                       constrainedSize:CGSizeMake(CGFLOAT_MAX, FILE_CONTENT_HEIGHT)];
    CGSize sizeSize = [RCKitUtility getTextDrawingSize:fileSize
                                                  font:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]
                                       constrainedSize:CGSizeMake(CGFLOAT_MAX, FILE_CONTENT_HEIGHT)];
    CGFloat textWidth = MIN(MAX(ceilf(nameSize.width), ceilf(sizeSize.width)), maxTextWidth);
    CGFloat width = FILE_QUOTE_CONTENT_HORIZONTAL_INSET * 2 + FILE_QUOTE_ICON_SIZE +
                    FILE_QUOTE_ICON_TEXT_SPACING + textWidth;
    return MIN(MAX(width, MIN(FILE_CONTENT_MIN_WIDTH, maxWidth)), maxWidth);
}

static CGFloat RCFileMessageQuoteBubbleWidth(RCMessageModel *model) {
    CGFloat maxBubbleWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat maxContentWidth = MAX(maxBubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGSize quoteCardSize = [RCReferencedContentView quoteCardContentSizeForMessageModel:model
                                                                               maxWidth:maxContentWidth];
    CGFloat fileCardWidth = RCFileMessageBodyCardWidth(model, maxContentWidth);
    CGFloat contentWidth = MAX(quoteCardSize.width, fileCardWidth);
    return MIN(contentWidth + QUOTE_CARD_HORIZONTAL_INSET * 2, maxBubbleWidth);
}

static UIImage *RCFileMessageResizableBubbleImage(UIImage *image) {
    if (!image) {
        return nil;
    }
    CGFloat halfWidth = image.size.width * 0.5;
    CGFloat halfHeight = image.size.height * 0.5;
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(halfHeight, halfWidth, halfHeight, halfWidth)];
}

@interface RCFileMessageCell ()

@property (nonatomic, strong) NSMutableArray *messageContentConstraint;
@property (nonatomic, strong) NSMutableArray *layoutConstraints;
@property (nonatomic, strong) UIView *quoteDividerView;
@property (nonatomic, strong) UIView *fileContainerView;


@end

@implementation RCFileMessageCell

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
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:model];
    CGFloat __messagecontentview_height = showsQuoteCard ? FILE_QUOTE_CONTENT_HEIGHT : FILE_CONTENT_HEIGHT;

    if (__messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    // 有引用卡片时增加内容体与卡片之间的间距
    if (showsQuoteCard) {
        __messagecontentview_height += RCFileMessageQuoteBodyTopSpacing() + QUOTE_BODY_BOTTOM_SPACING;
    } else if ([model rc_hasVisibleReactions]) {
        __messagecontentview_height += FILE_REACTION_CARD_VERTICAL_INSET * 2;
    }
    __messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    RCFileMessage *fileMessage = (RCFileMessage *)self.model.content;
    self.nameLabel.text = fileMessage.name;
    self.sizeLabel.text = [RCKitUtility getReadableStringForFileSize:fileMessage.size];
    self.typeIconView.image = [RCKitUtility imageWithFileSuffix:fileMessage.type];
    [self setAutoLayout];
}

- (void)messageContentViewFrameDidChange {
    [super messageContentViewFrameDidChange];
    [self updateFileContainerLayoutIfNeeded];
    [self updateQuoteDividerLayoutIfNeeded];
}

- (UIImage *)getDefaultMessageCellBackgroundImage {
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    BOOL usesReactionContainer = !showsQuoteCard && [self.model rc_hasVisibleReactions];
    if (self.model.messageDirection == MessageDirection_SEND && (showsQuoteCard || usesReactionContainer)) {
        UIImage *bubbleImage = RCDynamicImage(@"conversation_msg_cell_bg_to_img", @"chat_to_bg_normal");
        if (bubbleImage.imageAsset) {
            bubbleImage = [bubbleImage.imageAsset imageWithTraitCollection:self.traitCollection];
        }
        if ([RCKitUtility isRTL]) {
            bubbleImage = [bubbleImage imageFlippedForRightToLeftLayoutDirection];
        }
        return RCFileMessageResizableBubbleImage(bubbleImage);
    }
    return [super getDefaultMessageCellBackgroundImage];
}

- (void)updateStatusContentView:(RCMessageModel *)model {
    if (self.model.sentStatus == SentStatus_SENDING) {
        self.messageFailedStatusView.hidden = YES;
        self.progressView.hidden = NO;
        self.cancelSendButton.hidden = NO;
        self.messageActivityIndicatorView.hidden = YES;
    } else {
        [super updateStatusContentView:model];
    }
}

#pragma mark - Target Action
- (void)cancelSend {
    if ([self.delegate respondsToSelector:@selector(didTapCancelUploadButton:)]) {
        [self.delegate didTapCancelUploadButton:self.model];
    }
}

- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    if (self.model.messageId == [statusDic[@"messageId"] longValue]) {
        if ([statusDic[@"type"] isEqualToString:@"success"]) {
            RCFileMessage *fileMessage = (RCFileMessage *)self.model.content;
            fileMessage.localPath = statusDic[@"mediaPath"];
        }
    }
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    [super messageCellUpdateSendingStatusEvent:notification];
    RCMessageCellNotificationModel *notifyModel = notification.object;
    NSInteger progress = notifyModel.progress;
    if (self.model.messageId == notifyModel.messageId) {
        DebugLog(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            self.cancelSendButton.hidden = YES;
            [self updateProgressView:progress];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            self.cancelSendButton.hidden = YES;
            [self updateProgressView:progress];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != SentStatus_READ) {
                [self updateProgressView:progress];
            }
            self.cancelSendButton.hidden = YES;
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            [self updateProgressView:progress];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_CANCELED]) {
            self.cancelSendButton.hidden = YES;
            self.progressView.hidden = YES;
            [self displayCancelLabel];
        } else if (self.model.sentStatus == SentStatus_READ && self.isDisplayReadStatus) {
            self.progressView.hidden = YES;
            self.progressView.progress = 0;
        }
    }
}

#pragma mark - Private Methods

- (void)initialize {
    self.messageContentConstraint = [[NSMutableArray alloc] init];
    self.layoutConstraints = [[NSMutableArray alloc] init];

    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.fileContainerView];
    [self.fileContainerView addSubview:self.nameLabel];
    [self.fileContainerView addSubview:self.sizeLabel];
    [self.fileContainerView addSubview:self.typeIconView];
    [self.typeIconView addSubview:self.progressView];
    [self.fileContainerView addSubview:self.cancelLabel];

    // 引用卡片与文件内容之间的分隔线
    self.quoteDividerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.quoteDividerView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xE2E4E5", @"0x3a3a3a");
    self.quoteDividerView.hidden = YES;
    [self.messageContentView addSubview:self.quoteDividerView];

    [self updateBubbleBackgroundViewConstraintsWithTopInset:10];
    self.messageActivityIndicatorView.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:RCKitDispatchDownloadMediaNotification
                                               object:nil];
}

- (void)setAutoLayout {
    self.cancelSendButton.hidden = YES;
    self.cancelLabel.hidden = YES;

    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    BOOL usesReactionContainer = !showsQuoteCard && [self.model rc_hasVisibleReactions];
    BOOL usesInnerFileCard = showsQuoteCard || usesReactionContainer;
    CGFloat bubbleWidth = showsQuoteCard ? RCFileMessageQuoteBubbleWidth(self.model) : [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat quoteOffset = showsQuoteCard ? RCFileMessageQuoteContentOffset(self.model, bubbleWidth) : 0;
    CGFloat bodyOffset = showsQuoteCard ? RCFileMessageQuoteBodyTopSpacing() : 0;
    CGFloat verticalInset = usesReactionContainer ? FILE_REACTION_CARD_VERTICAL_INSET : 0;
    CGFloat bottomOffset = showsQuoteCard ? QUOTE_BODY_BOTTOM_SPACING : verticalInset;
    CGFloat fileBodyHeight = showsQuoteCard ? FILE_QUOTE_CONTENT_HEIGHT : FILE_CONTENT_HEIGHT;
    CGFloat contentHeight = fileBodyHeight + quoteOffset + bodyOffset + verticalInset + bottomOffset;
    CGFloat fileContainerX = usesInnerFileCard ? FILE_CONTENT_HORIZONTAL_INSET : 0;
    CGFloat fileContainerWidth = usesInnerFileCard ? MAX(bubbleWidth - FILE_CONTENT_HORIZONTAL_INSET * 2, 0) : bubbleWidth;

    self.messageContentView.contentSize = CGSizeMake(bubbleWidth, contentHeight);
    self.fileContainerView.frame = CGRectMake(fileContainerX,
                                              quoteOffset + bodyOffset + verticalInset,
                                              fileContainerWidth,
                                              fileBodyHeight);
    [self updateFileContainerStyleForInnerCard:usesInnerFileCard];

    // 根据引用卡片偏移重建内容约束
    [self updateBubbleBackgroundViewConstraintsWithTopInset:10];

    // 分隔线
    self.quoteDividerView.hidden = !showsQuoteCard;
    if (showsQuoteCard) {
        CGFloat dividerWidth = MAX(bubbleWidth - QUOTE_DIVIDER_HORIZONTAL_INSET * 2, 0);
        self.quoteDividerView.frame = CGRectMake(QUOTE_DIVIDER_HORIZONTAL_INSET,
                                                  quoteOffset + QUOTE_DIVIDER_TOP_SPACING,
                                                  dividerWidth,
                                                  QUOTE_DIVIDER_HEIGHT);
        [self.messageContentView bringSubviewToFront:self.quoteDividerView];
    } else {
        self.quoteDividerView.frame = CGRectZero;
    }
    [self updateQuoteDividerLayoutIfNeeded];

    if (MessageDirection_RECEIVE == self.messageDirection) {
        self.progressView.hidden = YES;
    } else {
        self.progressView.hidden = YES;
        if (self.model.sentStatus == SentStatus_CANCELED) {
            [self displayCancelLabel];
        }else if (self.model.sentStatus == SentStatus_SENDING) {
            self.progressView.hidden = NO;
            [self updateProgressView:self.progressView.progress];
        }else if (self.model.sentStatus == SentStatus_SENT || self.model.sentStatus == SentStatus_RECEIVED) {
            self.progressView.hidden = YES;
            self.messageActivityIndicatorView.hidden = YES;
        } else if (self.model.sentStatus == SentStatus_FAILED) {
            self.cancelSendButton.hidden = YES;
            if ([[RCResendManager sharedManager] needResend:self.model.messageId]) {
                self.messageActivityIndicatorView.hidden = NO;
                [self.messageActivityIndicatorView startAnimating];
                self.progressView.hidden = NO;
            } else {
                self.progressView.hidden = YES;
                self.messageActivityIndicatorView.hidden = YES;
            }
        }
    }
}

- (void)updateProgressView:(NSUInteger)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((self.model.sentStatus == SentStatus_SENDING && progress != 100) || [[RCResendManager sharedManager] needResend:self.model.messageId]) {
            self.progressView.hidden = NO;
            self.progressView.progress = (float)progress / 100.f;
            // 发送失败时 progress = 0，此时显示菊花，当 progress > 0 时显示取消按钮
            if ([[RCResendManager sharedManager] needResend:self.model.messageId] && progress == 0) {
                self.cancelSendButton.hidden = YES;
                self.messageActivityIndicatorView.hidden = NO;
                [self.messageActivityIndicatorView startAnimating];
            } else {
                self.cancelSendButton.hidden = NO;
                self.messageActivityIndicatorView.hidden = YES;
            }
        } else {
            self.progressView.hidden = YES;
        }
    });
}

/// 重建文件内容子视图的约束，topInset 控制距文件卡片顶部的偏移
- (void)updateBubbleBackgroundViewConstraintsWithTopInset:(CGFloat)topInset {
    // 移除旧约束
    if (self.layoutConstraints.count > 0) {
        [self.fileContainerView removeConstraints:self.layoutConstraints];
        [self.layoutConstraints removeAllObjects];
    }
    if (self.messageContentConstraint.count > 0) {
        [self.fileContainerView removeConstraints:self.messageContentConstraint];
        [self.messageContentConstraint removeAllObjects];
    }

    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.sizeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.typeIconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cancelSendButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.cancelLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self displayCancelButton];

    NSDictionary *views = NSDictionaryOfVariableBindings(_nameLabel, _sizeLabel, _typeIconView);
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    CGFloat iconSize = showsQuoteCard ? FILE_QUOTE_ICON_SIZE : FILE_ICON_SIZE;
    CGFloat iconTop = showsQuoteCard ? (FILE_QUOTE_CONTENT_HEIGHT - FILE_QUOTE_ICON_SIZE) / 2.0 : topInset;
    CGFloat iconTextSpacing = showsQuoteCard ? FILE_QUOTE_ICON_TEXT_SPACING : FILE_ICON_TEXT_SPACING;
    CGFloat horizontalInset = showsQuoteCard ? FILE_QUOTE_CONTENT_HORIZONTAL_INSET : FILE_CONTENT_HORIZONTAL_INSET;
    CGFloat nameTop = showsQuoteCard ? FILE_QUOTE_NAME_TOP : topInset;
    CGFloat bottomInset = showsQuoteCard ? FILE_QUOTE_BOTTOM_INSET : 10;
    CGFloat sizeHeight = showsQuoteCard ? FILE_QUOTE_SIZE_HEIGHT : 13;
    NSDictionary *metrics = @{
        @"iconTop": @(iconTop),
        @"nameTop": @(nameTop),
        @"bottom": @(bottomInset),
        @"iconSize": @(iconSize),
        @"sizeHeight": @(sizeHeight),
        @"left": @(horizontalInset),
        @"right": @(horizontalInset),
        @"spacing": @(iconTextSpacing)
    };
    self.progressView.frame = CGRectMake(-10, -10, iconSize + 20, iconSize + 20);

    NSArray *c1 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-iconTop-[_typeIconView(iconSize)]"
                                                          options:0
                                                          metrics:metrics
                                                            views:views];
    NSArray *c2 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[_typeIconView(iconSize)]-spacing-[_nameLabel]-right-|"
                                                          options:0
                                                          metrics:metrics
                                                            views:views];
    NSArray *c3 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-nameTop-[_nameLabel]-(>=0)-[_sizeLabel(sizeHeight)]-bottom-|"
                                                          options:0
                                                          metrics:metrics
                                                            views:views];
    NSArray *c4 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_typeIconView]-spacing-[_sizeLabel]"
                                                          options:0
                                                          metrics:metrics
                                                            views:views];

    [self.layoutConstraints addObjectsFromArray:c1];
    [self.layoutConstraints addObjectsFromArray:c2];
    [self.layoutConstraints addObjectsFromArray:c3];
    [self.layoutConstraints addObjectsFromArray:c4];
    [self.fileContainerView addConstraints:self.layoutConstraints];
}

- (void)updateFileContainerStyleForInnerCard:(BOOL)usesInnerFileCard {
    if (usesInnerFileCard) {
        self.fileContainerView.backgroundColor = RCDynamicColor(@"file_quote_card_background", @"0xffffff", @"0x1f1f1f");
        self.fileContainerView.layer.cornerRadius = 6;
        self.fileContainerView.layer.borderWidth = 0.5;
        self.fileContainerView.layer.borderColor = RCDynamicColor(@"line_background_color", @"0xE2E4E5", @"0x3a3a3a").CGColor;
        self.fileContainerView.layer.masksToBounds = YES;
    } else {
        self.fileContainerView.backgroundColor = UIColor.clearColor;
        self.fileContainerView.layer.cornerRadius = 0;
        self.fileContainerView.layer.borderWidth = 0;
        self.fileContainerView.layer.borderColor = UIColor.clearColor.CGColor;
        self.fileContainerView.layer.masksToBounds = NO;
    }
}

- (void)updateFileContainerLayoutIfNeeded {
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    BOOL usesReactionContainer = !showsQuoteCard && [self.model rc_hasVisibleReactions];
    if (!usesReactionContainer || CGRectIsEmpty(self.fileContainerView.frame)) {
        return;
    }
    CGFloat contentWidth = CGRectGetWidth(self.messageContentView.bounds);
    if (contentWidth <= 0) {
        return;
    }
    CGRect frame = self.fileContainerView.frame;
    frame.origin.x = FILE_CONTENT_HORIZONTAL_INSET;
    frame.origin.y = FILE_REACTION_CARD_VERTICAL_INSET;
    frame.size.width = MAX(contentWidth - FILE_CONTENT_HORIZONTAL_INSET * 2, 0);
    frame.size.height = FILE_CONTENT_HEIGHT;
    self.fileContainerView.frame = frame;
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

- (void)displayCancelLabel {
    [self.fileContainerView addSubview:self.cancelLabel];
    [self.messageContentConstraint
        addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_cancelLabel]-16.5-|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(
                                                                                _nameLabel, _sizeLabel, _typeIconView, _cancelLabel)]];
    [self.messageContentConstraint addObject:[NSLayoutConstraint constraintWithItem:_cancelLabel
                                                                          attribute:NSLayoutAttributeCenterY
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.sizeLabel
                                                                          attribute:NSLayoutAttributeCenterY
                                                                         multiplier:1
                                                                           constant:0]];
    [self.fileContainerView addConstraints:self.messageContentConstraint];
    self.cancelLabel.hidden = NO;
}

- (void)displayCancelButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if([RCKitUtility isRTL]){
            self.baseContentView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }else{
            self.baseContentView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
        [self.baseContentView addSubview:self.cancelSendButton];
        RCContentView *messageContentView = self.messageContentView;
        [self.baseContentView
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[_cancelSendButton(20)]"
                                                   options:0
                                                   metrics:nil
                                                     views:NSDictionaryOfVariableBindings(_cancelSendButton)]];

        [self.baseContentView
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:[_cancelSendButton(20)]-13-[messageContentView]"
                                                   options:0
                                                   metrics:nil
                                                     views:NSDictionaryOfVariableBindings(messageContentView,
                                                                                          _cancelSendButton)]];

        [self.baseContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cancelSendButton
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.messageContentView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1
                                                                          constant:0]];

    });
}

#pragma mark - Getter
- (UILabel *)nameLabel{
    if(!_nameLabel){
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_nameLabel setFont:[[RCKitConfig defaultConfig].font fontOfGuideLevel]];
        _nameLabel.numberOfLines = 2;
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc");
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        if([RCKitUtility isRTL]){
            _nameLabel.textAlignment = NSTextAlignmentRight;
        }else{
            _nameLabel.textAlignment = NSTextAlignmentLeft;
        }
    }
    return _nameLabel;
}

- (UILabel *)sizeLabel{
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_sizeLabel setFont:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]];
        _sizeLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xc7cbce", @"0xffffff66");
    }
    return _sizeLabel;
}

- (RCBaseImageView *)typeIconView{
    if (!_typeIconView) {
        _typeIconView = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
        _typeIconView.clipsToBounds = YES;
    }
    return _typeIconView;
}

- (RCProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[RCProgressView alloc] initWithFrame:CGRectMake(-10, -10, self.typeIconView.frame.size.width+20, self.typeIconView.frame.size.height+20)];
        [_progressView setHidden:YES];
    }
    return _progressView;
}

- (RCBaseButton *)cancelSendButton{
    if (!_cancelSendButton) {
        _cancelSendButton = [[RCBaseButton alloc] initWithFrame:CGRectZero];
        [_cancelSendButton setImage:RCDynamicImage(@"conversation_msg_cell_cancel_img",@"cancelButton") forState:UIControlStateNormal];
        [_cancelSendButton addTarget:self action:@selector(cancelSend) forControlEvents:UIControlEventTouchUpInside];
        _cancelSendButton.hidden = YES;
    }
    return _cancelSendButton;
}

- (UILabel *)cancelLabel{
    if (!_cancelLabel) {
        _cancelLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _cancelLabel.text = RCLocalizedString(@"CancelSendFile");
        _cancelLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xa8a8a8", @"0xa8a8a8");
        _cancelLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _cancelLabel.hidden = YES;
    }
    return _cancelLabel;
}

- (UIView *)fileContainerView {
    if (!_fileContainerView) {
        _fileContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return _fileContainerView;
}
@end
