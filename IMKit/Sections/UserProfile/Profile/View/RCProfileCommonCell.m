//
//  RCUProfileCommonCell.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCProfileCommonCell.h"
#import "RCKitCommonDefine.h"
#import "RCSemanticContext.h"

#define RCUProfileCommonCellTitleFontSize 17
#define RCUProfileCommonCellTitleLeading 16
#define RCUProfileCommonCellTitleWidth 150
#define RCUProfileCommonCellTitleHeight 20

#define RCUProfileCommonCellArrowTrailing 16
#define RCUProfileCommonCellArrowWidth 8
#define RCUProfileCommonCellArrowHeight 15

@interface RCProfileCommonCell()
@end

@implementation RCProfileCommonCell

- (void)setupView {
    [super setupView];
    [self.paddingContainerView addSubview:self.contentStackView];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:RCUserManagementPadding
                           trailing:-RCUserManagementPadding];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.leadingAnchor constraintEqualToAnchor:self.paddingContainerView.leadingAnchor constant:RCUProfileCommonCellArrowTrailing],
        [self.contentStackView.trailingAnchor constraintEqualToAnchor:self.paddingContainerView.trailingAnchor constant:-RCUProfileCommonCellArrowTrailing],
        [self.contentStackView.topAnchor constraintEqualToAnchor:self.paddingContainerView.topAnchor],
        [self.contentStackView.bottomAnchor constraintEqualToAnchor:self.paddingContainerView.bottomAnchor],
        
        [self.titleLabel.widthAnchor constraintGreaterThanOrEqualToConstant:RCUProfileCommonCellTitleWidth],
        [self.arrowView.widthAnchor constraintEqualToConstant:RCUProfileCommonCellArrowWidth],
        [self.arrowView.heightAnchor constraintEqualToConstant:RCUProfileCommonCellArrowHeight]
    ]];
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x9f9f9f");
        _titleLabel.font = [UIFont systemFontOfSize:RCUProfileCommonCellTitleFontSize];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_titleLabel setContentHuggingPriority:UILayoutPriorityDefaultLow
                                       forAxis:UILayoutConstraintAxisHorizontal];
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _titleLabel;
}

- (RCBaseImageView *)arrowView {
    if (!_arrowView) {
        UIImage *image = RCDynamicImage(@"cell_right_arrow_img", @"right_arrow");
        _arrowView = [[RCBaseImageView alloc] initWithImage: [RCSemanticContext imageflippedForRTL:image]];
        _arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _arrowView;
}

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.axis = UILayoutConstraintAxisHorizontal;
        _contentStackView.alignment = UIStackViewAlignmentCenter;
        _contentStackView.distribution = UIStackViewDistributionFill;
        _contentStackView.spacing = 5;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentStackView;
}
@end
