//
//  RCUProfileCommonCell.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCProfileCommonCell.h"
#import "RCKitCommonDefine.h"

#define RCUProfileCommonCellTitleFontSize 17
#define RCUProfileCommonCellTitleLeading 12
#define RCUProfileCommonCellTitleTop 12
#define RCUProfileCommonCellTitleWidth 150
#define RCUProfileCommonCellTitleHeight 20

#define RCUProfileCommonCellArrowTop 14
#define RCUProfileCommonCellArrowTrailing 14
#define RCUProfileCommonCellArrowLeading (SCREEN_WIDTH-RCUProfileCommonCellArrowTrailing-RCUProfileCommonCellArrowWidth)
#define RCUProfileCommonCellArrowWidth 8
#define RCUProfileCommonCellArrowHeight 15
@implementation RCProfileCommonCell

- (void)setupView {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.arrowView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(RCUProfileCommonCellTitleLeading, RCUProfileCommonCellTitleTop, RCUProfileCommonCellTitleWidth, RCUProfileCommonCellTitleHeight);
    self.arrowView.frame = CGRectMake(RCUProfileCommonCellArrowLeading, RCUProfileCommonCellArrowTop, RCUProfileCommonCellArrowWidth, RCUProfileCommonCellArrowHeight);
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = RCDYCOLOR(0x111f2c, 0x9f9f9f);
        _titleLabel.font = [UIFont systemFontOfSize:RCUProfileCommonCellTitleFontSize];
    }
    return _titleLabel;
}

- (RCBaseImageView *)arrowView {
    if (!_arrowView) {
        _arrowView = [[RCBaseImageView alloc] initWithImage:RCDynamicImage(@"cell_right_arrow_img", @"right_arrow")];
    }
    return _arrowView;
}
@end
