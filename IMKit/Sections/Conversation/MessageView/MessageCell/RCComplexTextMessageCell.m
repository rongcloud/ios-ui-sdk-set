//
//  RCComplexTextMessageCell.m
//  RongIMKit
//
//  Created by RobinCui on 2022/5/20.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCComplexTextMessageCell.h"
#import "RCAsyncLabel.h"
#import "RCCustomerServiceMessageModel.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCCoreClient+Destructing.h"
#import "RCMessageModel+Txt.h"
#import "RCBaseButton.h"
#define TEXT_SPACE_LEFT 12
#define TEXT_SPACE_RIGHT 12
#define TEXT_SPACE_TOP 9.5
#define TEXT_SPACE_BOTTOM 9.5
#define DESTRUCT_TEXT_ICON_WIDTH 13
#define DESTRUCT_TEXT_ICON_HEIGHT 28

NSString *const RCComplexTextMessageCellIdentifier = @"RCComplexTextMessageCellIdentifier";

@interface RCComplexTextMessageCell()<RCAsyncLabelDelegate>
@property (nonatomic, strong) RCAsyncLabel *contentAyncLab;
@property (nonatomic, strong) RCBaseButton *acceptBtn;
@property (nonatomic, strong) RCBaseButton *rejectBtn;
@property (nonatomic, strong) UIView *separateLine;
@property (nonatomic, strong) RCBaseImageView *destructTextImage;
@property (nonatomic, strong) UILabel *tipLablel;
@end

@implementation RCComplexTextMessageCell

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

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.contentAyncLab clean];
}

#pragma mark - Super Methods
+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height = [self getMessageContentHeight:model];
    __messagecontentview_height += extraHeight;

    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    [self setAutoLayout];
}

#pragma mark - 阅后即焚
- (void)setDestructViewLayout {
    [super setDestructViewLayout];
    if (self.model.content.destructDuration > 0) {
        if ([RCKitUtility isRTL]) {
            self.destructTextImage.frame = CGRectMake(DESTRUCT_TEXT_ICON_WIDTH , CGRectGetMidY(self.messageContentView.frame) - DESTRUCT_TEXT_ICON_HEIGHT / 2, DESTRUCT_TEXT_ICON_WIDTH, DESTRUCT_TEXT_ICON_HEIGHT);
        } else {
            self.destructTextImage.frame = CGRectMake(self.messageContentView.frame.size.width-DESTRUCT_TEXT_ICON_WIDTH-TEXT_SPACE_RIGHT,CGRectGetMidY(self.messageContentView.frame) - DESTRUCT_TEXT_ICON_HEIGHT / 2, DESTRUCT_TEXT_ICON_WIDTH, DESTRUCT_TEXT_ICON_HEIGHT);
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
    [self.messageContentView addSubview:self.contentAyncLab];
    [self.messageContentView addSubview:self.destructTextImage];
}


- (void)setAutoLayout {
    CGSize labelSize = [[self class] getTextSize:self.model];//textlabelsize
    
    float maxWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat bubbleHeight = [[self class] getMessageContentHeight:self.model];
    CGFloat bubbleWidth = labelSize.width + TEXT_SPACE_RIGHT + TEXT_SPACE_LEFT;
    if (bubbleWidth >= maxWidth) {
        bubbleWidth = maxWidth;
    }
    
    [self setCSEvaUILayout:bubbleWidth bubbleHeight:bubbleHeight];

    self.messageContentView.contentSize = CGSizeMake(bubbleWidth, bubbleHeight);
    if (self.model.messageDirection == MessageDirection_RECEIVE) {
        if ([RCKitUtility isRTL] && !self.destructTextImage.hidden) {
            self.contentAyncLab.frame =  CGRectMake(DESTRUCT_TEXT_ICON_WIDTH / 2 + DESTRUCT_TEXT_ICON_WIDTH + TEXT_SPACE_LEFT, (bubbleHeight - labelSize.height) / 2, labelSize.width, labelSize.height);
        } else {
            self.contentAyncLab.frame =  CGRectMake(TEXT_SPACE_LEFT, (bubbleHeight - labelSize.height) / 2, labelSize.width, labelSize.height);
        }
    } else {
        self.contentAyncLab.frame =  CGRectMake(TEXT_SPACE_LEFT, (bubbleHeight - labelSize.height) / 2, labelSize.width, labelSize.height);
    }

    RCTextMessage *textMessage = (RCTextMessage *)self.model.content;
    self.destructTextImage.hidden = YES;
    NSNumber *numDuration = [[RCCoreClient sharedCoreClient] getDestructMessageRemainDuration:self.model.messageUId];
    if (textMessage.destructDuration > 0 && self.model.messageDirection == MessageDirection_RECEIVE &&
        !numDuration) {
        self.contentAyncLab.text = RCLocalizedString(@"ClickToView");
        self.destructTextImage.hidden = NO;
    }else if(textMessage){
        self.contentAyncLab.text = textMessage.content;
    }else{
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCTextMessage object");
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
        [self.separateLine setBackgroundColor:RCDynamicColor(@"line_background_color", @"0xD3D3D3", @"0xD3D3D3")];

        if (csModel.alreadyEvaluated) {
            self.tipLablel =
                [[UILabel alloc] initWithFrame:CGRectMake(bubbleWidth - 80 - 7, bubbleHeight - 18, 80, 15)];
            self.tipLablel.text = @"感谢您的评价";
            self.tipLablel.textColor = RCDynamicColor(@"text_secondary_color", @"0xD3D3D3", @"0xD3D3D3");
            self.tipLablel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
            self.acceptBtn =
                [[RCBaseButton alloc] initWithFrame:CGRectMake(bubbleWidth - 95 - 7 - 3, bubbleHeight - 18, 15, 15)];
            [self.acceptBtn setImage:RCDynamicImage(@"conversation_msg_cell_eva_complete_img",@"cs_eva_complete") forState:UIControlStateNormal];
            [self.acceptBtn setImage:RCDynamicImage(@"conversation_msg_cell_eva_complete_hover_img",@"cs_eva_complete_hover") forState:UIControlStateHighlighted];

            [self.messageContentView addSubview:self.acceptBtn];
        } else {
            self.tipLablel =
                [[UILabel alloc] initWithFrame:CGRectMake(bubbleWidth - 118 - 10, bubbleHeight - 18, 80, 15)];
            self.tipLablel.text = @"您对我的回答";
            self.tipLablel.textColor =  RCDynamicColor(@"text_secondary_color", @"0xD3D3D3", @"0xD3D3D3");
            self.tipLablel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];

            self.acceptBtn =
                [[RCBaseButton alloc] initWithFrame:CGRectMake(bubbleWidth - 30 - 7 - 6, bubbleHeight - 18, 15, 15)];
            self.rejectBtn =
                [[RCBaseButton alloc] initWithFrame:CGRectMake(bubbleWidth - 15 - 7, bubbleHeight - 18, 15, 15)];
            [self.acceptBtn setImage:RCDynamicImage(@"conversation_msg_cell_cs_yes_img", @"cs_yes") forState:UIControlStateNormal];
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
    CGSize textMessageSize = [model txt_textSize];
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
    RCTextMessage *textMessage = (RCTextMessage *)model.content;
    CGSize textMessageSize;
    NSNumber *numDuration = [[RCCoreClient sharedCoreClient] getDestructMessageRemainDuration:model.messageUId];
    if (textMessage.destructDuration > 0 && model.messageDirection == MessageDirection_RECEIVE &&
        !numDuration) {
        textMessageSize =
            [RCKitUtility getTextDrawingSize:RCLocalizedString(@"ClickToView")
                                        font:[[RCKitConfig defaultConfig].font fontOfSecondLevel]
                             constrainedSize:CGSizeMake(textMaxWidth, 80000)];
        textMessageSize.width += 20;
    } else {
        textMessageSize = [model txt_textSize];
//        [RCKitUtility getTextDrawingSize:textMessage.content
//                                                       font:[[RCKitConfig defaultConfig].font fontOfSecondLevel]
//                                            constrainedSize:CGSizeMake(textMaxWidth, 80000)];
    }
    if (textMessageSize.width > textMaxWidth) {
        textMessageSize.width = textMaxWidth;
    }
    textMessageSize = CGSizeMake(ceilf(textMessageSize.width), ceilf(textMessageSize.height));
    return textMessageSize;
}

#pragma mark - Getter & Setter

- (RCBaseImageView *)destructTextImage{
    if (!_destructTextImage) {
        _destructTextImage = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 13, 28)];
        [_destructTextImage setImage:RCDynamicImage(@"conversation_msg_status_text_destruct_img", @"text_burn_img")];
        _destructTextImage.contentMode = UIViewContentModeScaleAspectFit;
        _destructTextImage.hidden = YES;
    }
    return _destructTextImage;
}

#pragma mark - RCAsyncLabelDelegate

- (BOOL)shouldDetectText {
    return YES;
}

- (NSDictionary *)textAttributesInfo {
    if (self.attributeDictionary) {
        return self.attributeDictionary;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    UIColor *linkColor = RCDynamicColor(@"link_color", @"0x0000FF", @"0xFFBE6a");
    if (linkColor) {
        NSDictionary *numAttr =  @{
             NSForegroundColorAttributeName :linkColor,
             NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
             NSUnderlineColorAttributeName : linkColor
         };
         dic[@(NSTextCheckingTypePhoneNumber)] = numAttr;
        NSDictionary *linkAttr =  @{
            NSForegroundColorAttributeName :linkColor,
            NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
            NSUnderlineColorAttributeName :linkColor
        };
        dic[@(NSTextCheckingTypeLink)] = linkAttr;
    }
   
    if (self.model.messageDirection == MessageDirection_RECEIVE) {
        UIColor *color = RCDynamicColor(@"text_primary_color", @"0x262626", @"0xffffffcc");
        dic[NSForegroundColorAttributeName] = color;
    } else {
        UIColor *color = RCDynamicColor(@"text_primary_color", @"0x262626", @"0x040A0F");
        dic[NSForegroundColorAttributeName] = color;
    }
    return dic;
}


- (void)asyncLabel:(RCAsyncLabel *)label didSelectLinkWithURL:(NSURL *)url {
    NSLog(@"url: %@", url);
    NSString *urlString = [url absoluteString];
    urlString = [RCKitUtility checkOrAppendHttpForUrl:urlString];
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:urlString model:self.model];
        return;
    }
}

- (void)asyncLabel:(RCAsyncLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    NSLog(@"phoneNumber: %@", phoneNumber);
    NSString *number = [@"tel://" stringByAppendingString:phoneNumber];
    if ([self.delegate respondsToSelector:@selector(didTapPhoneNumberInMessageCell:model:)]) {
        [self.delegate didTapPhoneNumberInMessageCell:number model:self.model];
        return;
    }
}

- (void)didTapAsyncLabel:(RCAsyncLabel *)label {
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}
#pragma mark - Property

- (RCAsyncLabel *)contentAyncLab {
    if (!_contentAyncLab) {
        _contentAyncLab = [RCAsyncLabel new];
        _contentAyncLab.delegate = self;
        _contentAyncLab.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    }
    return _contentAyncLab;
}

@end
