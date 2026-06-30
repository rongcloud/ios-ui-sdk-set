//
//  RCReferenceMessageCell.m
//  RongIMKit
//
//  Created by 张改红 on 2020/2/27.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCReferenceMessageCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCAttributedLabel+Edit.h"
#import "RCMessageCell+Edit.h"
#import "RCMessageCell+Internal.h"

#define bubble_top_space 10
#define bubble_bottom_space 10
#define quote_divider_top_space 6
#define quote_divider_height 1
#define quote_divider_bottom_space 10
#define content_space_left 12
#define content_space_right 12
@interface RCReferenceMessageCell () <RCAttributedLabelDelegate, RCReferencedContentViewDelegate>
@property (nonatomic, strong) UIView *lineView;
@end
@implementation RCReferenceMessageCell

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
    float maxWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat contentMaxWidth = MAX(maxWidth - content_space_left - content_space_right, 0);
    RCReferenceMessage *refenceMessage = (RCReferenceMessage *)model.content;
    NSString *displayText = [RCMessageEditUtil displayTextForOriginalText:refenceMessage.content isEdited:model.hasChanged];
    CGSize textLabelSize = [[self class] getTextLabelSize:displayText
                                                 maxWidth:contentMaxWidth
                                                     font:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
    CGSize contentSize = [[self class] contentInfoSizeWithContent:model maxWidth:contentMaxWidth];
    CGFloat contentWidth = MIN(MAX(textLabelSize.width, contentSize.width), contentMaxWidth);
    contentSize = CGSizeMake(contentWidth, [RCReferencedContentView quoteCardHeightForMessageModel:model maxWidth:contentWidth]);
    CGSize messageContentSize =
        CGSizeMake(content_space_left + contentWidth + content_space_right,
                                            contentSize.height + bubble_top_space +
                                            quote_divider_top_space + quote_divider_height +
                                            quote_divider_bottom_space + textLabelSize.height +
                                            bubble_bottom_space);
    CGFloat __messagecontentview_height = messageContentSize.height;
    __messagecontentview_height += extraHeight;
    __messagecontentview_height += [self edit_editStatusBarHeightWithModel:model];
    
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    [self setAutoLayout];
}

- (void)messageContentViewFrameDidChange {
    [super messageContentViewFrameDidChange];
    [self updateLineViewWidthIfNeeded];
}

#pragma mark - RCReferencedContentViewDelegate

- (void)didTapReferencedContentView:(RCMessageModel *)message {
    RCReferenceMessage *refer = (RCReferenceMessage *)message.content;
    if ([refer.referMsg isKindOfClass:[RCFileMessage class]] ||
        [refer.referMsg isKindOfClass:[RCRichContentMessage class]] ||
        [refer.referMsg isKindOfClass:[RCImageMessage class]]  ||
        [refer.referMsg isKindOfClass:[RCTextMessage class]] ||
        [refer.referMsg isKindOfClass:[RCReferenceMessage class]] ||
        [refer.referMsg isKindOfClass:[RCStreamMessage class]]) {
        if ([self.delegate respondsToSelector:@selector(didTapReferencedContentView:)]) {
            [self.delegate didTapReferencedContentView:message];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
            [self.delegate didTapMessageCell:self.model];
        }
    }
}

#pragma mark - RCAttributedLabelDelegate & RCReferencedContentViewDelegate

- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    NSString *urlString = [url absoluteString];
    urlString = [RCKitUtility checkOrAppendHttpForUrl:urlString];
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:urlString model:self.model];
        return;
    }
}

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

#pragma mark - Private Methods
- (void)initialize {
    [self showBubbleBackgroundView:YES];

    [self.messageContentView addSubview:self.referencedContentView];
    [self.messageContentView addSubview:self.lineView];
    [self.messageContentView addSubview:self.contentLabel];
}

- (void)setAutoLayout {
    if(self.model.messageDirection == MessageDirection_RECEIVE){
        [self.contentLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x262626", @"0xffffffcc")];
    }else{
        [self.contentLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x262626", @"0x040A0F")];
    }
    RCReferenceMessage *refenceMessage = (RCReferenceMessage *)self.model.content;
    if (refenceMessage) {
        [self.contentLabel edit_setTextWithEditedState:refenceMessage.content isEdited:self.model.hasChanged];
    }
    float maxWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat contentMaxWidth = MAX(maxWidth - content_space_left - content_space_right, 0);
    CGSize textLabelSize = [[self class] getTextLabelSize:self.contentLabel.text
                                                 maxWidth:contentMaxWidth
                                                     font:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
    CGSize contentSize = [[self class] contentInfoSizeWithContent:self.model maxWidth:contentMaxWidth];
    CGFloat contentWidth = MIN(MAX(textLabelSize.width, contentSize.width), contentMaxWidth);
    contentSize = CGSizeMake(contentWidth, [RCReferencedContentView quoteCardHeightForMessageModel:self.model maxWidth:contentWidth]);
    CGSize messageContentSize =
        CGSizeMake(content_space_left + contentWidth + content_space_right,
                                                      contentSize.height + bubble_top_space +
                                                      quote_divider_top_space + quote_divider_height +
                                                      quote_divider_bottom_space + textLabelSize.height +
                                                      bubble_bottom_space);
    [self.referencedContentView setMessage:self.model contentSize:contentSize];
    
    self.referencedContentView.frame = CGRectMake(content_space_left, 10, contentSize.width, contentSize.height);
    self.lineView.frame = CGRectMake(content_space_left, CGRectGetMaxY(self.referencedContentView.frame) + quote_divider_top_space, contentSize.width, quote_divider_height);
    self.contentLabel.frame = CGRectMake(content_space_left, CGRectGetMaxY(self.lineView.frame) + quote_divider_bottom_space,
                                         textLabelSize.width, textLabelSize.height);
    self.messageContentView.contentSize = CGSizeMake(messageContentSize.width, messageContentSize.height);
}

- (void)updateLineViewWidthIfNeeded {
    if (CGRectGetWidth(self.lineView.frame) <= 0) {
        return;
    }
    CGFloat contentWidth = CGRectGetWidth(self.messageContentView.bounds);
    if (contentWidth <= 0) {
        contentWidth = self.messageContentView.contentSize.width;
    }
    CGRect frame = self.lineView.frame;
    frame.origin.x = content_space_left;
    frame.size.width = MAX(contentWidth - content_space_left - content_space_right, 0);
    self.lineView.frame = frame;
}

- (NSDictionary *)attributeDictionary {
    return [RCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:self.model.messageDirection];
}

+ (CGSize)contentInfoSizeWithContent:(RCMessageModel *)model maxWidth:(CGFloat)maxWidth {
    RCReferenceMessage *refenceMessage = (RCReferenceMessage *)model.content;
    if (!refenceMessage) {
        return CGSizeMake(maxWidth, RCQuoteCardDefaultHeight);
    }
    return [RCReferencedContentView quoteCardContentSizeForMessageModel:model maxWidth:maxWidth];
}

+ (CGSize)getTextLabelSize:(NSString *)message maxWidth:(CGFloat)maxWidth font:(UIFont *)font {
    if ([message length] > 0) {
        CGSize textSize = [RCKitUtility getTextDrawingSize:message font:font constrainedSize:CGSizeMake(maxWidth, MAXFLOAT)];
        textSize.width = MIN(ceilf(textSize.width), maxWidth);
        textSize.height = ceilf(textSize.height);
        return textSize;
    } else {
        return CGSizeZero;
    }
}

#pragma mark - Getter
- (RCAttributedLabel *)contentLabel{
    if (!_contentLabel) {
        _contentLabel = [[RCAttributedLabel alloc] initWithFrame:CGRectZero];
        _contentLabel.attributeDictionary = [self attributeDictionary];
        _contentLabel.highlightedAttributeDictionary = [self attributeDictionary];
        [_contentLabel setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        _contentLabel.numberOfLines = 0;
        [_contentLabel setLineBreakMode:NSLineBreakByWordWrapping];
        _contentLabel.delegate = self;
        _contentLabel.userInteractionEnabled = YES;
    }
    return _contentLabel;
}

- (RCReferencedContentView *)referencedContentView{
    if (!_referencedContentView) {
        _referencedContentView = [[RCReferencedContentView alloc] init];
        _referencedContentView.delegate = self;
    }
    return _referencedContentView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [UIView new];
        _lineView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xE2E4E5", @"0xE2E4E5");
    }
    return _lineView;
}
@end
