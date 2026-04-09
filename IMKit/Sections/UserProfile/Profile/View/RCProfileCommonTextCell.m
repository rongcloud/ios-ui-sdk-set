//
//  RCUserProfileTextCell.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/16.
//

#import "RCProfileCommonTextCell.h"
#import "RCKitCommonDefine.h"

#define RCUProfileTextCellDetailFont 15


NSString  * const RCUProfileTextCellIdentifier = @"RCUProfileTextCellIdentifier";



@implementation RCProfileCommonTextCell

- (void)setupView {
    [super setupView];
    [self.contentStackView addArrangedSubview:self.titleLabel];
    [self.contentStackView addArrangedSubview:self.detailLabel];
    [self.contentStackView addArrangedSubview:self.arrowView];
}
#pragma mark - getter

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xA0A5Ab", @"0x878787");
        _detailLabel.font = [UIFont systemFontOfSize:RCUProfileTextCellDetailFont];
        _detailLabel.textAlignment = NSTextAlignmentNatural;
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_detailLabel setContentHuggingPriority:UILayoutPriorityRequired
                                        forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _detailLabel;
}
@end
