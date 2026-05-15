//
//  RCTextMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCTextMessageCell.h"
#import "RCCustomerServiceMessageModel.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCCoreClient+Destructing.h"
#import "RCAttributedLabel+Edit.h"
#import "RCMessageCell+Edit.h"
#import "RCReferencedContentView.h"
#define TEXT_SPACE_LEFT 12
#define TEXT_SPACE_RIGHT 12
#define TEXT_SPACE_TOP 9.5
#define TEXT_SPACE_BOTTOM 9.5
#define DESTRUCT_TEXT_ICON_WIDTH 13
#define DESTRUCT_TEXT_ICON_HEIGHT 28
#define QUOTE_CARD_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_TOP_SPACING 6
#define QUOTE_DIVIDER_HEIGHT 1
#define QUOTE_DIVIDER_BOTTOM_SPACING 10
#define QUOTE_BODY_BOTTOM_PADDING 10
#define QUOTE_BODY_TRAILING_PADDING 14
#define QUOTE_TEXT_HORIZONTAL_PADDING 26

static CGFloat RCTextMessageQuoteMaxBubbleWidth(void) {
    return MAX([RCMessageCellTool getMessageContentViewMaxWidth], 0);
}

static CGFloat RCTextMessageQuoteMaxTextWidth(void) {
    return MAX(RCTextMessageQuoteMaxBubbleWidth() - QUOTE_TEXT_HORIZONTAL_PADDING, 0);
}

static CGFloat RCTextMessageQuoteTextWidth(CGFloat bubbleWidth) {
    return MAX(bubbleWidth - QUOTE_TEXT_HORIZONTAL_PADDING, 0);
}

static CGFloat RCTextMessageQuoteBubbleWidth(RCMessageModel *model, CGSize labelSize) {
    CGFloat maxBubbleWidth = RCTextMessageQuoteMaxBubbleWidth();
    CGFloat maxCardWidth = MAX(maxBubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGSize quoteCardSize = [RCReferencedContentView quoteCardContentSizeForMessageModel:model maxWidth:maxCardWidth];
    CGFloat quoteWidth = quoteCardSize.width + QUOTE_CARD_HORIZONTAL_INSET * 2;
    CGFloat textWidth = labelSize.width + QUOTE_TEXT_HORIZONTAL_PADDING;
    return MIN(MAX(quoteWidth, textWidth), maxBubbleWidth);
}

static CGFloat RCTextMessageQuoteContentOffset(RCMessageModel *model, CGFloat bubbleWidth) {
    CGFloat cardWidth = MAX(bubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGFloat cardHeight = [RCReferencedContentView quoteCardHeightForMessageModel:model maxWidth:cardWidth];
    return RCQuoteCardTopMargin + cardHeight;
}

static CGFloat RCTextMessageQuoteBodyTopSpacing(void) {
    return QUOTE_DIVIDER_TOP_SPACING + QUOTE_DIVIDER_HEIGHT + QUOTE_DIVIDER_BOTTOM_SPACING;
}

static CGFloat RCTextMessageQuoteBodyHeight(RCMessageModel *model, CGSize labelSize) {
    CGFloat bodyHeight = RCTextMessageQuoteBodyTopSpacing() + labelSize.height + QUOTE_BODY_BOTTOM_PADDING;
    if ([model isKindOfClass:[RCCustomerServiceMessageModel class]] &&
        [((RCCustomerServiceMessageModel *)model) isNeedEvaluateArea]) {
        bodyHeight += 25;
    }
    return bodyHeight;
}

@interface RCTextMessageCell ()
@property (nonatomic, strong) RCBaseButton *acceptBtn;
@property (nonatomic, strong) RCBaseButton *rejectBtn;
@property (nonatomic, strong) UIView *separateLine;
@property (nonatomic, strong) UIView *quoteDividerView;
@property (nonatomic, strong) RCBaseImageView *destructTextImage;
@property (nonatomic, strong) UILabel *tipLablel;
+ (CGSize)getQuoteTextSize:(RCMessageModel *)model;
+ (CGSize)getTextSize:(RCMessageModel *)model maxWidth:(CGFloat)textMaxWidth;
@end

@implementation RCTextMessageCell

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
    CGFloat __messagecontentview_height = [self getMessageContentHeight:model];
    if (showsQuoteCard) {
        CGSize labelSize = [self getQuoteTextSize:model];
        CGFloat bubbleWidth = RCTextMessageQuoteBubbleWidth(model, labelSize);
        CGFloat quoteOffset = RCTextMessageQuoteContentOffset(model, bubbleWidth);
        __messagecontentview_height = quoteOffset + RCTextMessageQuoteBodyHeight(model, labelSize);
        // 文本消息使用 top layout，引用卡片高度已包含在上方计算中；
        // 但 referenceExtraHeight: 对所有消息统一追加了 quoteCardHeight + RCQuoteCardTopMargin，
        // 需扣除以避免重复计算导致气泡下方出现大面积空白
        CGFloat duplicatedCardHeight =
            [RCReferencedContentView quoteCardHeightForMessageModel:model
                                                           maxWidth:[RCMessageCellTool getMessageContentViewMaxWidth]];
        extraHeight -= (duplicatedCardHeight + RCQuoteCardTopMargin);
    }
    __messagecontentview_height += extraHeight;
    __messagecontentview_height += [self edit_editStatusBarHeightWithModel:model];
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    [self setAutoLayout];
}

#pragma mark - RCAttributedLabelDelegate

- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    NSString *urlString = [url absoluteString];
    urlString = [RCKitUtility checkOrAppendHttpForUrl:urlString];
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:urlString model:self.model];
        return;
    }
}

/**
 Tells the delegate that the user did select a link to an address.

 @param label The label whose link was selected.
 @param addressComponents The components of the address for the selected link.
 */
- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithAddress:(NSDictionary *)addressComponents {
}

/**
 Tells the delegate that the user did select a link to a phone number.

 @param label The label whose link was selected.
 @param phoneNumber The phone number for the selected link.
 */
- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    NSString *number = [@"tel://" stringByAppendingString:phoneNumber];
    if ([self.delegate respondsToSelector:@selector(didTapPhoneNumberInMessageCell:model:)]) {
        [self.delegate didTapPhoneNumberInMessageCell:number model:self.model];
        return;
    }
}

- (void)attributedLabel:(RCAttributedLabel *)label didTapLabel:(NSString *)content {
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

#pragma mark - 阅后即焚

- (void)setDestructViewLayout {
    [super setDestructViewLayout];
    if (self.model.content.destructDuration > 0) {
        if ([RCKitUtility isRTL]) {
            self.destructTextImage.frame = CGRectMake(DESTRUCT_TEXT_ICON_WIDTH , (CGRectGetHeight(self.messageContentView.frame) - DESTRUCT_TEXT_ICON_HEIGHT) / 2, DESTRUCT_TEXT_ICON_WIDTH, DESTRUCT_TEXT_ICON_HEIGHT);
        } else {
            self.destructTextImage.frame = CGRectMake(self.messageContentView.frame.size.width-DESTRUCT_TEXT_ICON_WIDTH-TEXT_SPACE_RIGHT,(CGRectGetHeight(self.messageContentView.frame) - DESTRUCT_TEXT_ICON_HEIGHT)/ 2, DESTRUCT_TEXT_ICON_WIDTH, DESTRUCT_TEXT_ICON_HEIGHT);
        }
    }
}

#pragma mark - Target Action
- (void)didAccepted:(id)sender {
    [self evaluate:YES];
}

- (void)didRejected:(id)sender {
    [self evaluate:NO];
}

#pragma mark - Private Methods
- (void)initialize {
    [self showBubbleBackgroundView:YES];

    [self.messageContentView addSubview:self.textLabel];
    [self.messageContentView addSubview:self.quoteDividerView];
    [self.messageContentView addSubview:self.destructTextImage];
}


- (void)setAutoLayout {
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    CGSize labelSize = showsQuoteCard ? [RCTextMessageCell getQuoteTextSize:self.model] : [RCTextMessageCell getTextSize:self.model];
    
    float maxWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat bubbleHeight = [RCTextMessageCell getMessageContentHeight:self.model];
    CGFloat quoteBubbleWidth = showsQuoteCard ? RCTextMessageQuoteBubbleWidth(self.model, labelSize) : 0;
    CGFloat quoteOffset = showsQuoteCard ? RCTextMessageQuoteContentOffset(self.model, quoteBubbleWidth) : 0;
    CGFloat contentHeight = bubbleHeight + quoteOffset;
    CGFloat textOriginY = quoteOffset + (bubbleHeight - labelSize.height) / 2;
    CGFloat bubbleWidth = labelSize.width + TEXT_SPACE_RIGHT + TEXT_SPACE_LEFT;
    if (bubbleWidth >= maxWidth) {
        bubbleWidth = maxWidth;
    }
    if (showsQuoteCard) {
        bubbleWidth = quoteBubbleWidth;
        contentHeight = quoteOffset + RCTextMessageQuoteBodyHeight(self.model, labelSize);
        textOriginY = quoteOffset + RCTextMessageQuoteBodyTopSpacing();
    }
    
    [self setCSEvaUILayout:bubbleWidth bubbleHeight:contentHeight];

    self.messageContentView.contentSize = CGSizeMake(bubbleWidth, contentHeight);
    self.quoteDividerView.hidden = !showsQuoteCard;
    if (showsQuoteCard) {
        CGFloat dividerWidth = MAX(bubbleWidth - QUOTE_TEXT_HORIZONTAL_PADDING, 0);
        self.quoteDividerView.frame = CGRectMake(QUOTE_DIVIDER_HORIZONTAL_INSET,
                                                 quoteOffset + QUOTE_DIVIDER_TOP_SPACING,
                                                 dividerWidth,
                                                 QUOTE_DIVIDER_HEIGHT);
        [self.messageContentView bringSubviewToFront:self.quoteDividerView];
    } else {
        self.quoteDividerView.frame = CGRectZero;
    }
    RCTextMessage *textMessage = (RCTextMessage *)self.model.content;
    self.destructTextImage.hidden = YES;
    NSNumber *numDuration = [[RCCoreClient sharedCoreClient] getDestructMessageRemainDuration:self.model.messageUId];
    if (textMessage.destructDuration > 0 && self.model.messageDirection == MessageDirection_RECEIVE &&
        !numDuration) {
        self.destructTextImage.hidden = NO;
    }
    
    if (self.model.messageDirection == MessageDirection_RECEIVE) {
        [self.textLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x262626", @"0xffffffcc")];
        if ([RCKitUtility isRTL] && !self.destructTextImage.hidden) {
            CGFloat textOriginX = DESTRUCT_TEXT_ICON_WIDTH / 2 + DESTRUCT_TEXT_ICON_WIDTH + TEXT_SPACE_LEFT;
            CGFloat textWidth = showsQuoteCard ? MAX(bubbleWidth - textOriginX - QUOTE_BODY_TRAILING_PADDING, 0) : labelSize.width;
            self.textLabel.frame =  CGRectMake(textOriginX, textOriginY, textWidth, labelSize.height);
        } else {
            CGFloat textWidth = showsQuoteCard ? RCTextMessageQuoteTextWidth(bubbleWidth) : labelSize.width;
            self.textLabel.frame =  CGRectMake(TEXT_SPACE_LEFT, textOriginY, textWidth, labelSize.height);
        }
    } else {
        [self.textLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x262626", @"0x040A0F")];
        CGFloat textWidth = showsQuoteCard ? RCTextMessageQuoteTextWidth(bubbleWidth) : labelSize.width;
        self.textLabel.frame =  CGRectMake(TEXT_SPACE_LEFT, textOriginY, textWidth, labelSize.height);
    }
    
    if (textMessage.destructDuration > 0 && self.model.messageDirection == MessageDirection_RECEIVE && !numDuration) {
        // 统一调用 edit_setTextWithEditedState 设置文本，防止 cell 重用出现问题
        [self.textLabel edit_setTextWithEditedState:RCLocalizedString(@"ClickToView") isEdited:NO];
    } else if (textMessage){
        [self.textLabel edit_setTextWithEditedState:textMessage.content isEdited:self.model.hasChanged];
    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCTextMessage object");
    }
}

- (BOOL)usesTopQuoteCardLayout {
    return YES;
}

- (NSDictionary *)attributeDictionary {
    return [RCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:self.model.messageDirection];
}

- (void)setCSEvaUILayout:(CGFloat)bubbleWidth bubbleHeight:(CGFloat)bubbleHeight{
    if ([self.model isKindOfClass:[RCCustomerServiceMessageModel class]] &&
        [((RCCustomerServiceMessageModel *)self.model)isNeedEvaluateArea]) {

        RCCustomerServiceMessageModel *csModel = (RCCustomerServiceMessageModel *)self.model;

        if (bubbleWidth < 150) { //太短了，评价显示不下，加长吧
            bubbleWidth = 150;
        }

        if (self.separateLine) {
            [self.acceptBtn removeFromSuperview];
            [self.rejectBtn removeFromSuperview];
            [self.separateLine removeFromSuperview];
            [self.tipLablel removeFromSuperview];
        }
        self.separateLine =
            [[UIView alloc] initWithFrame:CGRectMake(15, bubbleHeight - 23, bubbleWidth - 15 - 5, 0.5)];
        [self.separateLine setBackgroundColor:RCDynamicColor(@"line_background_color", @"0xD3D3D3", @"0xD3D3D3")];

        if (csModel.alreadyEvaluated) {
            self.tipLablel =
                [[UILabel alloc] initWithFrame:CGRectMake(bubbleWidth - 80 - 7, bubbleHeight - 18, 80, 15)];
            self.tipLablel.text = @"感谢您的评价";
            self.tipLablel.textColor = RCDynamicColor(@"line_background_color", @"0xD3D3D3", @"0xD3D3D3");
            self.tipLablel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
            self.acceptBtn =
                [[RCBaseButton alloc] initWithFrame:CGRectMake(bubbleWidth - 95 - 7 - 3, bubbleHeight - 18, 15, 15)];
            [self.acceptBtn setImage:RCDynamicImage(@"conversation_msg_cell_eva_complete_img",@"cs_eva_complete")
                            forState:UIControlStateNormal];
            [self.acceptBtn setImage:RCDynamicImage(@"conversation_msg_cell_eva_complete_hover_img",@"cs_eva_complete_hover")
                            forState:UIControlStateHighlighted];

            [self.messageContentView addSubview:self.acceptBtn];
        } else {
            self.tipLablel =
                [[UILabel alloc] initWithFrame:CGRectMake(bubbleWidth - 118 - 10, bubbleHeight - 18, 80, 15)];
            self.tipLablel.text = @"您对我的回答";
            self.tipLablel.textColor = RCDynamicColor(@"line_background_color", @"0xD3D3D3", @"0xD3D3D3");
            self.tipLablel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];

            self.acceptBtn =
                [[RCBaseButton alloc] initWithFrame:CGRectMake(bubbleWidth - 30 - 7 - 6, bubbleHeight - 18, 15, 15)];
            self.rejectBtn =
                [[RCBaseButton alloc] initWithFrame:CGRectMake(bubbleWidth - 15 - 7, bubbleHeight - 18, 15, 15)];
            [self.acceptBtn setImage:RCDynamicImage(@"conversation_msg_cell_cs_yes_img",@"cs_yes")
                            forState:UIControlStateNormal];
            [self.acceptBtn setImage:RCDynamicImage(@"conversation_msg_cell_cs_yes_hover_img",@"cs_yes_hover") forState:UIControlStateHighlighted];

            [self.self.rejectBtn setImage:RCDynamicImage(@"conversation_msg_cell_cs_no_img",@"cs_no") forState:UIControlStateNormal];
            [self.messageContentView addSubview:self.acceptBtn];
            [self.messageContentView addSubview:self.rejectBtn];

            [self.acceptBtn addTarget:self action:@selector(didAccepted:) forControlEvents:UIControlEventTouchDown];
            [self.rejectBtn addTarget:self action:@selector(didRejected:) forControlEvents:UIControlEventTouchDown];
        }

        [self.messageContentView addSubview:self.tipLablel];
        [self.messageContentView addSubview:self.separateLine];

    } else {
        [self.acceptBtn removeFromSuperview];
        [self.rejectBtn removeFromSuperview];
        [self.separateLine removeFromSuperview];
        [self.tipLablel removeFromSuperview];
        self.acceptBtn = nil;
        self.rejectBtn = nil;
        self.separateLine = nil;
        self.tipLablel = nil;
    }
}

- (void)evaluate:(BOOL)isresolved {
    if ([self.delegate respondsToSelector:@selector(didTapCustomerService:RobotResoluved:)]) {
        [self.delegate didTapCustomerService:self.model RobotResoluved:isresolved];
    }
}

+ (CGFloat)getMessageContentHeight:(RCMessageModel *)model{
    CGSize textMessageSize = [self getTextSize:model];
    //背景图的最小高度
    CGFloat messagecontentview_height = textMessageSize.height + TEXT_SPACE_TOP + TEXT_SPACE_BOTTOM;

    if ([model isKindOfClass:[RCCustomerServiceMessageModel class]] &&
        [((RCCustomerServiceMessageModel *)model)isNeedEvaluateArea]) { //机器人评价高度
        messagecontentview_height += 25;
    }
    if (messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    return messagecontentview_height;
}

+ (CGSize)getTextSize:(RCMessageModel *)model{
    CGFloat textMaxWidth = [RCMessageCellTool getMessageContentViewMaxWidth] - TEXT_SPACE_LEFT - TEXT_SPACE_RIGHT;
    return [self getTextSize:model maxWidth:textMaxWidth];
}

+ (CGSize)getQuoteTextSize:(RCMessageModel *)model {
    return [self getTextSize:model maxWidth:RCTextMessageQuoteMaxTextWidth()];
}

+ (CGSize)getTextSize:(RCMessageModel *)model maxWidth:(CGFloat)textMaxWidth{
    RCTextMessage *textMessage = (RCTextMessage *)model.content;
    NSNumber *numDuration = [[RCCoreClient sharedCoreClient] getDestructMessageRemainDuration:model.messageUId];
    CGSize textMessageSize;
    if (textMessage.destructDuration > 0 && model.messageDirection == MessageDirection_RECEIVE &&
        !numDuration) {
        textMessageSize =
            [RCKitUtility getTextDrawingSize:RCLocalizedString(@"ClickToView")
                                        font:[[RCKitConfig defaultConfig].font fontOfSecondLevel]
                             constrainedSize:CGSizeMake(textMaxWidth, 80000)];
        textMessageSize.width += 20;
    } else {
        UIFont *font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
        textMessageSize = [RCMessageEditUtil sizeForText:textMessage.content isEdited:model.hasChanged font:font constrainedSize:CGSizeMake(textMaxWidth, 80000)];
    }
    if (textMessageSize.width > textMaxWidth) {
        textMessageSize.width = textMaxWidth;
    }
    textMessageSize = CGSizeMake(ceilf(textMessageSize.width), ceilf(textMessageSize.height));
    return textMessageSize;
}

#pragma mark - Getter & Setter
- (RCAttributedLabel *)textLabel{
    if (!_textLabel) {
        _textLabel = [[RCAttributedLabel alloc] initWithFrame:CGRectZero];
        [_textLabel setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        _textLabel.numberOfLines = 0;
        [_textLabel setLineBreakMode:NSLineBreakByWordWrapping];
        if([RCKitUtility isRTL]){
            _textLabel.textAlignment = NSTextAlignmentRight;
        }else{
            _textLabel.textAlignment = NSTextAlignmentLeft;
        }
        _textLabel.delegate = self;
        _textLabel.userInteractionEnabled = YES;
        _textLabel.attributeDictionary = [self attributeDictionary];
        _textLabel.highlightedAttributeDictionary = [self attributeDictionary];
    }
    return _textLabel;
}

- (RCBaseImageView *)destructTextImage{
    if (!_destructTextImage) {
        _destructTextImage = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 13, 28)];
        [_destructTextImage setImage:RCDynamicImage(@"conversation_msg_status_text_destruct_img", @"text_burn_img")];
        _destructTextImage.contentMode = UIViewContentModeScaleAspectFit;
        _destructTextImage.hidden = YES;
    }
    return _destructTextImage;
}

- (UIView *)quoteDividerView {
    if (!_quoteDividerView) {
        _quoteDividerView = [UIView new];
        _quoteDividerView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xE2E4E5", @"0xE2E4E5");
        _quoteDividerView.hidden = YES;
    }
    return _quoteDividerView;
}
@end
