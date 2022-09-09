//
//  RCTextMessageTranslatingCell.m
//  RongIMKit
//
//  Created by RobinCui on 2022/2/28.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCTextMessageTranslatingCell.h"
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

@interface RCTextMessageTranslatingCell() {
   
}
@property (nonatomic, strong) UIImageView *translationBackgroundView;
@property (nonatomic, strong) UIView *translationContainer;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@end

@implementation RCTextMessageTranslatingCell

- (void)initialize {
    [super initialize];
    [self setupView];
}

- (void)setupView {
    [self.baseContentView addSubview:self.translationContainer];
    [self.translationContainer addSubview:self.translationBackgroundView];
    [self.translationContainer addSubview:self.indicatorView];
}

/// 布局翻译UI
- (void)layoutTranslationViews {
    CGFloat xOffset = 0;
    if (self.model.messageDirection == MessageDirection_RECEIVE) {
        xOffset = self.messageContentView.frame.origin.x;
    } else {
        xOffset = self.messageContentView.frame.origin.x - (RCTranslationContentTranslatingSize - self.messageContentView.frame.size.width);
    }
    CGFloat yOffset = self.messageContentView.frame.origin.y+self.messageContentView.frame.size.height+RCTranslationTextSpaceOffset;
    CGRect frame = CGRectMake(xOffset,
                              yOffset,
                              RCTranslationContentTranslatingSize,
                              RCTranslationContentTranslatingSize);
    self.translationContainer.frame = frame;
    self.translationBackgroundView.frame = self.translationContainer.bounds;
    self.indicatorView.center = self.translationBackgroundView.center;
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
    [self.indicatorView startAnimating];
    self.translationBackgroundView.image = [RCMessageCellTool translationTextBackgroundImage];
}

+ (CGFloat)getMessageContentHeight:(RCMessageModel *)model {
    return model.translatingSize.height;
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

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_indicatorView startAnimating];
    }
    return _indicatorView;
}
@end
