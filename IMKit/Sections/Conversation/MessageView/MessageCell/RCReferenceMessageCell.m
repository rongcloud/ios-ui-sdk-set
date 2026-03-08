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
#import "RCBubbleCell.h"
#import "RCAttributedLabel+EditedState.h"
#import "RCMessageCell+EditStatus.h"

#define bubble_top_space 12
#define bubble_bottom_space 12
#define refer_and_text_space 6
#define content_space_left 12
#define content_space_right 12
@interface RCReferenceMessageCell () <RCAttributedLabelDelegate, RCReferencedContentViewDelegate>
@property (nonatomic, strong) RCBubbleCell *bubbleView;
@property (nonatomic, assign) BOOL isHiddenBubble;
@end
@implementation RCReferenceMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.isHiddenBubble = true;
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.isHiddenBubble = true;
        [self initialize];
    }
    return self;
}

#pragma mark - Super Methods
+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    float maxWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    RCReferenceMessage *refenceMessage = (RCReferenceMessage *)model.content;
    NSString *displayText = [RCEditedStateUtil displayTextForOriginalText:refenceMessage.content isEdited:model.hasChanged];
    CGSize textLabelSize = [[self class] getTextLabelSize:displayText
                                                 maxWidth:maxWidth - 33
                                                     font:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
    CGSize contentSize = [[self class] contentInfoSizeWithContent:model maxWidth:maxWidth - 33];
    CGSize messageContentSize =
        CGSizeMake(textLabelSize.width, textLabelSize.height + contentSize.height + bubble_top_space +
                                            bubble_bottom_space + refer_and_text_space);
    CGFloat __messagecontentview_height = messageContentSize.height;
    __messagecontentview_height += extraHeight;
    __messagecontentview_height += [self edit_editStatusBarHeightWithModel:model];

    return CGSizeMake(collectionViewWidth, __messagecontentview_height + 6);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    [self setAutoLayout];
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
    [self.messageContentView addSubview:self.contentLabel];
    
    //新气泡
    _bubbleView = [[RCBubbleCell alloc] initWithFrame:CGRectZero];
    _bubbleView.backgroundColor = [UIColor clearColor];
    [self.bubbleBackgroundView addSubview:_bubbleView];
}

- (void)setAutoLayout {
    if(self.model.messageDirection == MessageDirection_RECEIVE){
        [self.contentLabel setTextColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0x262626) darkColor:RCMASKCOLOR(0xffffff, 0.8)]];
    }else{
        [self.contentLabel setTextColor:RCDYCOLOR(0x262626, 0x040A0F)];
    }
    RCReferenceMessage *refenceMessage = (RCReferenceMessage *)self.model.content;
    if (refenceMessage) {
        [self.contentLabel edit_setTextWithEditedState:refenceMessage.content isEdited:self.model.hasChanged];
    }
    float maxWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGSize textLabelSize = [[self class] getTextLabelSize:self.contentLabel.text
                                                 maxWidth:maxWidth - 33
                                                     font:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
    CGSize contentSize = [[self class] contentInfoSizeWithContent:self.model maxWidth:maxWidth - 33];
    CGSize messageContentSize =
        CGSizeMake(textLabelSize.width + 16 + 10, textLabelSize.height + contentSize.height + bubble_top_space +
                                                      bubble_bottom_space + refer_and_text_space);
    [self.referencedContentView setMessage:self.model contentSize:contentSize];
    
    self.referencedContentView.frame = CGRectMake(content_space_left, 10, contentSize.width, contentSize.height);
    self.contentLabel.frame = CGRectMake(content_space_left, CGRectGetMaxY(self.referencedContentView.frame) + refer_and_text_space,
                                         textLabelSize.width, textLabelSize.height);
    self.messageContentView.contentSize = CGSizeMake(messageContentSize.width, messageContentSize.height);
    
    //新气泡
    if(self.model.messageDirection == MessageDirection_RECEIVE){
        self.bubbleView.frame = CGRectMake(-10, -25, messageContentSize.width+35, messageContentSize.height+45);
        [self.bubbleView updateSize:CGSizeMake(messageContentSize.width+35, messageContentSize.height+45)];
    }else{
        self.bubbleView.frame = CGRectMake(-20, -25, messageContentSize.width+35, messageContentSize.height+45);
        [self.bubbleView updateSize:CGSizeMake(messageContentSize.width+35, messageContentSize.height+45)];
    }
}

- (NSDictionary *)attributeDictionary {
    return [RCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:self.model.messageDirection];
}

+ (CGSize)contentInfoSizeWithContent:(RCMessageModel *)model maxWidth:(CGFloat)maxWidth {
    RCReferenceMessage *refenceMessage = (RCReferenceMessage *)model.content;
    RCMessageContent *content = refenceMessage.referMsg;
    CGFloat height = 17;//名字显示高度
    BOOL isDeletedOrRecalled = (refenceMessage.referMsgStatus == RCReferenceMessageStatusRecalled
                                || refenceMessage.referMsgStatus == RCReferenceMessageStatusDeleted);
    if ([content isKindOfClass:[RCImageMessage class]] && !isDeletedOrRecalled) {
        RCImageMessage *msg = (RCImageMessage *)content;
        height = [RCMessageCellTool getThumbnailImageSize:msg.thumbnailImage].height + height + name_and_image_view_space;
    } else {
        height = 34;//两行文本高度
    }
    return CGSizeMake(maxWidth, height);
}

+ (CGSize)getTextLabelSize:(NSString *)message maxWidth:(CGFloat)maxWidth font:(UIFont *)font {
    if ([message length] > 0) {
        CGSize textSize = [RCKitUtility getTextDrawingSize:message font:font constrainedSize:CGSizeMake(maxWidth, MAXFLOAT)];
        textSize.height = ceilf(textSize.height);
        return CGSizeMake(maxWidth, textSize.height);
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

-(void)updateBubble:(NSDictionary *)dict{
    //停止
    [_bubbleView stopAllAnimation];
    if (dict.allKeys.count == 0){
        if (MessageDirection_RECEIVE == self.messageDirection) {
            UIImage *image = [RCKitUtility imageNamed:@"chat_from_bg_normal" ofBundle:@"RongCloud.bundle"];
            self.referencedContentView.textLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x939393) darkColor:HEXCOLOR(0x939393)];
            self.bubbleBackgroundView.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.5, image.size.width * 0.5,image.size.height * 0.5, image.size.width * 0.5)];
        }else{
            UIImage *image = [RCKitUtility imageNamed:@"chat_to_bg_normal" ofBundle:@"RongCloud.bundle"];
            self.referencedContentView.textLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x999999) darkColor:HEXCOLOR(0x999999)];
            self.bubbleBackgroundView.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.5, image.size.width * 0.5,image.size.height * 0.5, image.size.width * 0.5)];
        }
        self.contentLabel.textColor = RCDYCOLOR(0x262626, 0xe0e0e0);
        
    }else{
        self.bubbleBackgroundView.image = nil;
        self.contentLabel.textColor = [UIColor whiteColor];
        self.referencedContentView.textLabel.textColor = [UIColor whiteColor];
    }
    //重新赋值
    self.isHiddenBubble = [_bubbleView updateBubble:dict];
    
    if (RCKitConfig.defaultConfig.ui.enableDarkMode == true ) {
        [self updateAppearanceWith:@"dark"];
    } else {
        [self updateAppearanceWith:@"light"];
    }
}

- (void)themeColorDidChange:(NSNotification *)notification {
    if ([notification.userInfo.allKeys containsObject:@"style"]) {
        NSString *style = [NSString stringWithFormat:@"%@", notification.userInfo[@"style"]];
        if ([style containsString:@"dark"]) {
            [self updateAppearanceWith:@"dark"];
        } else {
            [self updateAppearanceWith:@"light"];
        }
    }
}

- (void)updateAppearanceWith:(NSString *)style {
    self.bubbleBackgroundView.image = nil;
    // 是否有气泡（VIP）
    if (self.isHiddenBubble == false) {
        self.contentLabel.textColor = [UIColor whiteColor];
        self.bubbleBackgroundView.backgroundColor = [UIColor clearColor];
        self.bubbleBackgroundView.layer.cornerRadius = 0;
        self.bubbleBackgroundView.layer.masksToBounds = false;
    } else {
        if ([style isEqualToString:@"light"]) {
            if (self.model.messageDirection == MessageDirection_RECEIVE) {
                self.contentLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.85];
                self.bubbleBackgroundView.backgroundColor = [UIColor whiteColor];
            } else {
                self.contentLabel.textColor = [UIColor whiteColor];
                self.bubbleBackgroundView.backgroundColor = [UIColor colorWithRed:135 / 255.0 green:84 / 255.0 blue:251 / 255.0 alpha:1];
            }
        } else {
            if (self.model.messageDirection == MessageDirection_RECEIVE) {
                self.contentLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.85];
                self.bubbleBackgroundView.backgroundColor = [UIColor colorWithRed:34 / 255.0 green:34 / 255.0 blue:34 / 255.0 alpha:1];
            } else {
                self.contentLabel.textColor = [UIColor whiteColor];
                self.bubbleBackgroundView.backgroundColor = [UIColor colorWithRed:135 / 255.0 green:84 / 255.0 blue:251 / 255.0 alpha:1];
            }
        }
        self.bubbleBackgroundView.layer.cornerRadius = 8;
        self.bubbleBackgroundView.layer.masksToBounds = true;
    }
}

@end
