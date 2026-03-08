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
#import "RCBubbleCell.h"
#import "RCStickerHelper.h"
#import "RCAttributedLabel+EditedState.h"
#import "RCMessageCell+EditStatus.h"
#define TEXT_SPACE_LEFT 12
#define TEXT_SPACE_RIGHT 12
#define TEXT_SPACE_TOP 9.5
#define TEXT_SPACE_BOTTOM 9.5
#define DESTRUCT_TEXT_ICON_WIDTH 13
#define DESTRUCT_TEXT_ICON_HEIGHT 28

@interface RCTextMessageCell ()
@property (nonatomic, strong) RCBaseButton *acceptBtn;
@property (nonatomic, strong) RCBaseButton *rejectBtn;
@property (nonatomic, strong) UIView *separateLine;
@property (nonatomic, strong) RCBaseImageView *destructTextImage;
@property (nonatomic, strong) UILabel *tipLablel;
@property (nonatomic, strong) RCBubbleCell *bubbleView;
@property (nonatomic, assign) BOOL isHiddenBubble;
@end

@implementation RCTextMessageCell

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
    CGFloat __messagecontentview_height = [self getMessageContentHeight:model];
    __messagecontentview_height += extraHeight;
    __messagecontentview_height += [self edit_editStatusBarHeightWithModel:model];
    return CGSizeMake(collectionViewWidth, __messagecontentview_height + 6);
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
    [self.messageContentView addSubview:self.destructTextImage];
    
    //新气泡
    _bubbleView = [[RCBubbleCell alloc] initWithFrame:CGRectZero];
    _bubbleView.backgroundColor = [UIColor clearColor];
    [self.bubbleBackgroundView addSubview:_bubbleView];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.textLabel.text = @"";
}

- (void)setAutoLayout {
    
    CGSize labelSize = [RCTextMessageCell getTextSize:self.model];//textlabelsize
    
    float maxWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat bubbleHeight = [RCTextMessageCell getMessageContentHeight:self.model];
    CGFloat bubbleWidth = labelSize.width + TEXT_SPACE_RIGHT + TEXT_SPACE_LEFT;
    if (bubbleWidth >= maxWidth) {
        bubbleWidth = maxWidth;
    }
    if (bubbleHeight < 35) {
        bubbleHeight = 35;
    }
    self.isHiddenBubble = [_bubbleView updateBubble:RCKitConfig.defaultConfig.ui.bubbleData];
    if (bubbleWidth < 165 && self.isHiddenBubble == false) {
        bubbleWidth = 165;
    }
    
    [self setCSEvaUILayout:bubbleWidth bubbleHeight:bubbleHeight];
    
    self.messageContentView.contentSize = CGSizeMake(bubbleWidth, bubbleHeight);
    RCTextMessage *textMessage = (RCTextMessage *)self.model.content;
    self.destructTextImage.hidden = YES;
    NSNumber *numDuration = [[RCCoreClient sharedCoreClient] getDestructMessageRemainDuration:self.model.messageUId];
    if (textMessage.destructDuration > 0 && self.model.messageDirection == MessageDirection_RECEIVE &&
        !numDuration) {
        self.destructTextImage.hidden = NO;
    }
    
    if (self.model.messageDirection == MessageDirection_RECEIVE) {
        [self.textLabel setTextColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0x262626) darkColor:RCMASKCOLOR(0xffffff, 0.8)]];
        float originX = (self.bubbleBackgroundView.frame.size.width - labelSize.width) / 2; //加上气泡的角的宽度
        if ([RCKitUtility isRTL] && !self.destructTextImage.hidden) {
            self.textLabel.frame =  CGRectMake(DESTRUCT_TEXT_ICON_WIDTH / 2 + DESTRUCT_TEXT_ICON_WIDTH + TEXT_SPACE_LEFT, (bubbleHeight - labelSize.height) / 2, labelSize.width, labelSize.height);
        } else {
            self.textLabel.frame =  CGRectMake(originX, (bubbleHeight - labelSize.height) / 2, labelSize.width, labelSize.height);
        }
    } else {
        float originX = (self.bubbleBackgroundView.frame.size.width - labelSize.width) / 2; //加上气泡的角的宽度
        [self.textLabel setTextColor:RCDYCOLOR(0x262626, 0x040A0F)];
        self.textLabel.frame =  CGRectMake(originX, (bubbleHeight - labelSize.height) / 2, labelSize.width, labelSize.height);
    }
    
    if (textMessage.destructDuration > 0 && self.model.messageDirection == MessageDirection_RECEIVE && !numDuration) {
        // 统一调用 edit_setTextWithEditedState 设置文本，防止重复出现问题
        [self.textLabel edit_setTextWithEditedState:RCLocalizedString(@"ClickToView") isEdited:NO];
    } else if (textMessage){
        if ([self.model.content.extra isEqualToString:@"source_game_expression"]) {
            NSAttributedString *attribute = [[RCStickerHelper shared] attributeString:textMessage.content itemSize:CGSizeMake(72, 72)];
            self.textLabel.attributedText = attribute;
        } else {
            [self.textLabel edit_setTextWithEditedState:textMessage.content isEdited:self.model.hasChanged];
        }
    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCTextMessage object");
    }
    
    //新气泡
    if (self.model.messageDirection == MessageDirection_RECEIVE) {
        self.bubbleView.frame = CGRectMake(-10, -25, bubbleWidth+35, bubbleHeight+45);
        [self.bubbleView updateSize:CGSizeMake(bubbleWidth+35, bubbleHeight+45)];
    }else{
        self.bubbleView.frame = CGRectMake(-20, -25, bubbleWidth+35, bubbleHeight+45);
        [self.bubbleView updateSize:CGSizeMake(bubbleWidth+35, bubbleHeight+45)];
    }
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
        [self.separateLine setBackgroundColor:[UIColor lightGrayColor]];

        if (csModel.alreadyEvaluated) {
            self.tipLablel =
                [[UILabel alloc] initWithFrame:CGRectMake(bubbleWidth - 80 - 7, bubbleHeight - 18, 80, 15)];
            self.tipLablel.text = @"感谢您的评价";
            self.tipLablel.textColor = [UIColor lightGrayColor];
            self.tipLablel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
            self.acceptBtn =
                [[RCBaseButton alloc] initWithFrame:CGRectMake(bubbleWidth - 95 - 7 - 3, bubbleHeight - 18, 15, 15)];
            [self.acceptBtn setImage:RCResourceImage(@"cs_eva_complete") forState:UIControlStateNormal];
            [self.acceptBtn setImage:RCResourceImage(@"cs_eva_complete_hover") forState:UIControlStateHighlighted];

            [self.messageContentView addSubview:self.acceptBtn];
        } else {
            self.tipLablel =
                [[UILabel alloc] initWithFrame:CGRectMake(bubbleWidth - 118 - 10, bubbleHeight - 18, 80, 15)];
            self.tipLablel.text = @"您对我的回答";
            self.tipLablel.textColor = [UIColor lightGrayColor];
            self.tipLablel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];

            self.acceptBtn =
                [[RCBaseButton alloc] initWithFrame:CGRectMake(bubbleWidth - 30 - 7 - 6, bubbleHeight - 18, 15, 15)];
            self.rejectBtn =
                [[RCBaseButton alloc] initWithFrame:CGRectMake(bubbleWidth - 15 - 7, bubbleHeight - 18, 15, 15)];
            [self.acceptBtn setImage:RCResourceImage(@"cs_yes") forState:UIControlStateNormal];
            [self.acceptBtn setImage:RCResourceImage(@"cs_yes_hover") forState:UIControlStateHighlighted];

            [self.self.rejectBtn setImage:RCResourceImage(@"cs_no") forState:UIControlStateNormal];
            [self.self.rejectBtn setImage:RCResourceImage(@"cs_yes_no") forState:UIControlStateHighlighted];
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
    // 如果是贴纸表情并且存在就返回固定的大小
    if ([model.content.extra isEqualToString:@"source_game_expression"]) {
        RCTextMessage *textMessage = (RCTextMessage *)model.content;
        if ([[RCStickerHelper shared] containSticker:textMessage.content]) {
            return CGSizeMake(72, 72);
        }
    }
    CGFloat textMaxWidth = [RCMessageCellTool getMessageContentViewMaxWidth] - TEXT_SPACE_LEFT - TEXT_SPACE_RIGHT;
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
        textMessageSize = [RCEditedStateUtil sizeForText:textMessage.content isEdited:model.hasChanged font:font constrainedSize:CGSizeMake(textMaxWidth, 80000)];
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
        [_destructTextImage setImage:RCResourceImage(@"text_burn_img")];
        _destructTextImage.contentMode = UIViewContentModeScaleAspectFit;
        _destructTextImage.hidden = YES;
    }
    return _destructTextImage;
}

-(void)updateBubble:(NSDictionary *)dict{
    //停止
    [_bubbleView stopAllAnimation];
    
    if (dict.allKeys.count == 0){
        if (MessageDirection_RECEIVE == self.messageDirection) {
            UIImage *image = [RCKitUtility imageNamed:@"chat_from_bg_normal" ofBundle:@"RongCloud.bundle"];
            self.bubbleBackgroundView.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.5, image.size.width * 0.5,image.size.height * 0.5, image.size.width * 0.5)];
        }else{
            UIImage *image = [RCKitUtility imageNamed:@"chat_to_bg_normal" ofBundle:@"RongCloud.bundle"];
            self.bubbleBackgroundView.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.5, image.size.width * 0.5,image.size.height * 0.5, image.size.width * 0.5)];
        }
        
        [self.textLabel setTextColor:RCDYCOLOR(0x262626, 0xe0e0e0)];
    }else{
        self.bubbleBackgroundView.image = nil;
        self.textLabel.textColor = [UIColor whiteColor];
    }
    //重新赋值
    self.isHiddenBubble = [_bubbleView updateBubble:dict];
    
    //20250826 如果是贴纸表情就隐藏背景
//    if ([self.model.content.extra isEqualToString:@"source_game_expression"]) {
//        RCTextMessage *textMessage = (RCTextMessage *)self.model.content;
//        if ([[RCStickerHelper shared] containSticker:textMessage.content]) {
//            self.bubbleBackgroundView.hidden = [[RCStickerHelper shared] containSticker:textMessage.content];
//        } else {
//            self.bubbleBackgroundView.hidden = NO;
//        }
//    } else {
//        self.bubbleBackgroundView.hidden = NO;
//    }
    
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
        self.textLabel.textColor = [UIColor whiteColor];
        self.bubbleBackgroundView.backgroundColor = [UIColor clearColor];
        self.bubbleBackgroundView.layer.cornerRadius = 0;
        self.bubbleBackgroundView.layer.masksToBounds = false;
    } else {
        if ([style isEqualToString:@"light"]) {
            if (self.model.messageDirection == MessageDirection_RECEIVE) {
                self.textLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.85];
                self.bubbleBackgroundView.backgroundColor = [UIColor whiteColor];
            } else {
                self.textLabel.textColor = [UIColor whiteColor];
                self.bubbleBackgroundView.backgroundColor = [UIColor colorWithRed:135 / 255.0 green:84 / 255.0 blue:251 / 255.0 alpha:1];
            }
        } else {
            if (self.model.messageDirection == MessageDirection_RECEIVE) {
                self.textLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.85];
                self.bubbleBackgroundView.backgroundColor = [UIColor colorWithRed:34 / 255.0 green:34 / 255.0 blue:34 / 255.0 alpha:1];
            } else {
                self.textLabel.textColor = [UIColor whiteColor];
                self.bubbleBackgroundView.backgroundColor = [UIColor colorWithRed:135 / 255.0 green:84 / 255.0 blue:251 / 255.0 alpha:1];
            }
        }
        self.bubbleBackgroundView.layer.cornerRadius = 8;
        self.bubbleBackgroundView.layer.masksToBounds = true;
    }
}

@end
