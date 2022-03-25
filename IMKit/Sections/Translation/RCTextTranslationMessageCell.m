//
//  RCTextTranslationMessageCell.m
//  RongIMKit
//
//  Created by RobinCui on 2022/2/24.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCTextTranslationMessageCell.h"
#import "RCMessageModel+Translation.h"
#import "RCCustomerServiceMessageModel.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCIMClient+Destructing.h"


@interface RCTextMessageCell()
- (void)initialize;
- (NSDictionary *)attributeDictionary;
@end

@interface RCTextTranslationMessageCell() {
   
}
@property (nonatomic, strong) UIImageView *translationBackgroundView;
@property (nonatomic, strong) UIView *translationContainer;
/*!
 显示翻译内容的Label
 */
@property (strong, nonatomic) RCAttributedLabel *translationLabel;
@end

@implementation RCTextTranslationMessageCell

- (void)initialize {
    [super initialize];
    [self setupView];
}
- (void)setupView {
    [self.baseContentView addSubview:self.translationContainer];
    [self.translationContainer addSubview:self.translationBackgroundView];
    [self.translationContainer addSubview:self.translationLabel];
}


/// 布局翻译UI
- (void)layoutTranslationViews {
    CGSize translationSize = self.model.translationSize;
    CGFloat width = translationSize.width+RCTranslationTextSpaceLeft+RCTranslationTextSpaceRight;
    CGFloat height = translationSize.height+RCTranslationTextSpaceBottom+RCTranslationTextSpaceTop;
    CGFloat xOffset = 0;
    if (self.model.messageDirection == MessageDirection_RECEIVE) {
        xOffset = self.messageContentView.frame.origin.x;
    } else {
        xOffset = self.messageContentView.frame.origin.x - (width - self.messageContentView.frame.size.width);
    }
    CGFloat yOffset = self.messageContentView.frame.origin.y+self.messageContentView.frame.size.height+RCTranslationTextSpaceOffset;
    CGRect frame = CGRectMake(xOffset, yOffset,width, height);
    self.translationContainer.frame = frame;
    self.translationBackgroundView.frame = self.translationContainer.bounds;
    CGRect labFrame = CGRectMake(0, 0, translationSize.width, translationSize.height);
    self.translationLabel.frame = labFrame;
    self.translationLabel.center = self.translationBackgroundView.center;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutTranslationViews];
}

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height = [self getMessageContentHeight:model];
    __messagecontentview_height += extraHeight;

    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    self.translationLabel.text = model.translationString;
    self.translationBackgroundView.image = [RCMessageCellTool translationTextBackgroundImage];
}

+ (CGFloat)getMessageContentHeight:(RCMessageModel *)model {
    return model.finalSize.height;
}

#pragma mark -- Property
- (UIImageView *)translationBackgroundView{
    if (!_translationBackgroundView) {
        _translationBackgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];
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

- (RCAttributedLabel *)translationLabel{
    if (!_translationLabel) {
        _translationLabel = [[RCAttributedLabel alloc] initWithFrame:CGRectZero];
        [_translationLabel setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
        _translationLabel.numberOfLines = 0;
        [_translationLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [_translationLabel setTextAlignment:NSTextAlignmentLeft];
        _translationLabel.delegate = self;
        _translationLabel.userInteractionEnabled = YES;
        _translationLabel.attributeDictionary = [self attributeDictionary];
        _translationLabel.highlightedAttributeDictionary = [self attributeDictionary];
        _translationLabel.accessibilityLabel = @"translationLabel";
    }
    return _translationLabel;
}
@end
