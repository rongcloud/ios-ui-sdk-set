//
//  RCVoiceTranslationMessageCell.m
//  RongIMKit
//
//  Created by RobinCui on 2022/2/25.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCVoiceTranslationMessageCell.h"
#import "RCMessageModel+Translation.h"
#import "RCCustomerServiceMessageModel.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCIMClient+Destructing.h"

@interface RCVoiceMessageCell()
- (void)initialize;
@end


@interface RCVoiceTranslationMessageCell()
@property (nonatomic, strong) UIImageView *translationBackgroundView;
@property (nonatomic, strong) UIView *translationContainer;
/*!
 显示语音内容的Label
 */
@property (strong, nonatomic) RCAttributedLabel *textLabel;

/*!
 显示翻译内容的Label
 */
@property (strong, nonatomic) RCAttributedLabel *translationLabel;
@end

@implementation RCVoiceTranslationMessageCell

- (void)initialize {
    [super initialize];
    [self setupView];
}

- (void)setupView {
    [self.baseContentView addSubview:self.translationContainer];
    [self.translationContainer addSubview:self.translationBackgroundView];
    [self.translationContainer addSubview:self.translationLabel];
    [self.translationContainer addSubview:self.textLabel];
}


/// 布局翻译UI
- (void)layoutTranslationViews {
    CGSize translationSize = self.model.translationSize;
    CGSize voiceStringSize = self.model.voiceStringSize;
    CGFloat xOffset = 0;
    CGFloat width = translationSize.width+RCTranslationTextSpaceLeft+RCTranslationTextSpaceRight;
    CGFloat height = translationSize.height+RCTranslationTextSpaceBottom+RCTranslationTextSpaceTop+voiceStringSize.height;
    if (self.model.messageDirection == MessageDirection_RECEIVE) {
        xOffset = self.messageContentView.frame.origin.x;
    } else {
        xOffset = self.messageContentView.frame.origin.x - (width - self.messageContentView.frame.size.width);
    }
    CGFloat yOffset = self.bubbleBackgroundView.frame.origin.y+self.bubbleBackgroundView.frame.size.height+RCTranslationTextSpaceOffset;
    CGRect frame = CGRectMake(xOffset, yOffset,width, height);
    self.translationContainer.frame = frame;
    self.translationBackgroundView.frame = self.translationContainer.bounds;
    CGRect labFrame = CGRectMake(RCTranslationTextSpaceLeft,
                                 RCTranslationTextSpaceTop,
                                 self.model.voiceStringSize.width,
                                 self.model.voiceStringSize.height);
    self.textLabel.frame = labFrame;
    labFrame = CGRectMake(labFrame.origin.x,
                          labFrame.origin.y + labFrame.size.height,
                                 self.model.translationSize.width,
                                 self.model.translationSize.height);
    self.translationLabel.frame = labFrame;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutTranslationViews];
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    self.translationLabel.text = model.translationString;
    self.textLabel.text = model.voiceString;
    self.translationBackgroundView.image = [RCMessageCellTool getDefaultMessageCellBackgroundImage:self.model];
    
}

+ (CGFloat)getMessageContentHeight:(RCMessageModel *)model {
    return model.finalSize.height;
}

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height = [self getMessageContentHeight:model];
    __messagecontentview_height += extraHeight;

    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (NSDictionary *)attributeDictionary {
    return [RCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:self.model.messageDirection];
}

#pragma mark -- Property
- (UIImageView *)translationBackgroundView{
    if (!_translationBackgroundView) {
        _translationBackgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _translationBackgroundView.image = self.bubbleBackgroundView.image;
        _translationBackgroundView.accessibilityLabel = @"translationBackgroundView";
    }
    return _translationBackgroundView;
}

- (UIView *)translationContainer {
    if (!_translationContainer) {
        _translationContainer = [UIView new];
        _translationContainer.accessibilityLabel = @"translationContainer";
    }
    return _translationContainer;
}

- (RCAttributedLabel *)textLabel{
    if (!_textLabel) {
        _textLabel = [[RCAttributedLabel alloc] initWithFrame:CGRectZero];
        [_textLabel setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        _textLabel.numberOfLines = 0;
        [_textLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [_textLabel setTextAlignment:NSTextAlignmentLeft];
//        _textLabel.delegate = self;
        _textLabel.textColor = [UIColor darkTextColor];
        _textLabel.userInteractionEnabled = YES;
      NSDictionary *info =  @{@(NSTextCheckingTypeLink) : @{NSForegroundColorAttributeName : RCDYCOLOR(0x0099ff, 0x1290e2)},
                 @(NSTextCheckingTypePhoneNumber) : @{ NSForegroundColorAttributeName : [RCKitUtility generateDynamicColor:HEXCOLOR(0x0099ff) darkColor:HEXCOLOR(0x1000e2)]
                 }
        };
        _textLabel.attributeDictionary = info;
        _textLabel.highlightedAttributeDictionary = [self attributeDictionary];
        _textLabel.accessibilityLabel = @"translationLabel";
    }
    return _textLabel;
}

- (RCAttributedLabel *)translationLabel{
    if (!_translationLabel) {
        _translationLabel = [[RCAttributedLabel alloc] initWithFrame:CGRectZero];
        [_translationLabel setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        _translationLabel.numberOfLines = 0;
        [_translationLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [_translationLabel setTextAlignment:NSTextAlignmentLeft];
        _translationLabel.userInteractionEnabled = YES;
        _translationLabel.attributeDictionary = [self attributeDictionary];
        _translationLabel.highlightedAttributeDictionary = [self attributeDictionary];
        _translationLabel.accessibilityLabel = @"translationLabel";
    }
    return _translationLabel;
}
@end
