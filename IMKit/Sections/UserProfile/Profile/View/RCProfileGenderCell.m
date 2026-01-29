//
//  RCProfileGenderCell.m
//  RongIMKit
//
//  Created by zgh on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileGenderCell.h"
#import "RCKitCommonDefine.h"

NSString  * const RCProfileGenderCellIdentifier = @"RCProfileGenderCellIdentifier";

#define RCProfileGenderCellTitleFontSize 17
#define RCProfileGenderCellArrowWidth 20
#define RCProfileGenderCellArrowHeight 20

@implementation RCProfileGenderCell

- (void)setupView {
    [super setupView];
    [self.contentStackView addArrangedSubview:self.titleLabel];
    [self.contentStackView addArrangedSubview:self.selectView];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:RCUserManagementPadding
                           trailing:-RCUserManagementPadding];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.selectView.widthAnchor constraintEqualToConstant:RCProfileGenderCellArrowWidth],
        [self.selectView.heightAnchor constraintEqualToConstant:RCProfileGenderCellArrowHeight],
    ]];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x9f9f9f");
        _titleLabel.font = [UIFont systemFontOfSize:RCProfileGenderCellTitleFontSize];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_titleLabel setContentHuggingPriority:UILayoutPriorityDefaultLow
                                       forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _titleLabel;
}

- (RCBaseImageView *)selectView {
    if (!_selectView) {
        _selectView = [[RCBaseImageView alloc] initWithImage:RCDynamicImage(@"group_manage_gender_cell_check_img", @"message_cell_select")];
        _selectView.translatesAutoresizingMaskIntoConstraints = NO;
        [_selectView setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                       forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _selectView;
}

@end
