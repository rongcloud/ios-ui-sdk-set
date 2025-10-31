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
#define RCProfileGenderCellTitleLeading 12
#define RCProfileGenderCellTitleTop 12
#define RCProfileGenderCellTitleWidth 150
#define RCProfileGenderCellTitleHeight 20

#define RCProfileGenderCellArrowTop 12
#define RCProfileGenderCellArrowTrailing 18
#define RCProfileGenderCellArrowLeading (SCREEN_WIDTH-RCProfileGenderCellArrowTrailing-RCProfileGenderCellArrowWidth)
#define RCProfileGenderCellArrowWidth 20
#define RCProfileGenderCellArrowHeight 20

@implementation RCProfileGenderCell

- (void)setupView {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.selectView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(RCProfileGenderCellTitleLeading, RCProfileGenderCellTitleTop, RCProfileGenderCellTitleWidth, RCProfileGenderCellTitleHeight);
    self.selectView.frame = CGRectMake(RCProfileGenderCellArrowLeading, RCProfileGenderCellArrowTop, RCProfileGenderCellArrowWidth, RCProfileGenderCellArrowHeight);
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
//    self.selectView.hidden = !selected;
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = RCDYCOLOR(0x111f2c, 0x9f9f9f);
        _titleLabel.font = [UIFont systemFontOfSize:RCProfileGenderCellTitleFontSize];
    }
    return _titleLabel;
}

- (RCBaseImageView *)selectView {
    if (!_selectView) {
        _selectView = [[RCBaseImageView alloc] initWithImage:RCDynamicImage(@"conversation_msg_cell_select_img", @"message_cell_select")];
    }
    return _selectView;
}

@end
