//
//  RCUserProfileTextCell.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/16.
//

#import "RCProfileCommonTextCell.h"
#import "RCKitCommonDefine.h"

#define RCUProfileTextCellDetailFont 15
#define RCUProfileTextCellDetailLeadingSpace 26
#define RCUProfileTextCellDetailTrailingSpace 10
#define RCUProfileTextCellDetailWidth 150
#define RCUProfileTextCellDetailHeight 40

NSString  * const RCUProfileTextCellIdentifier = @"RCUProfileTextCellIdentifier";

@implementation RCProfileCommonTextCell

- (void)setupView {
    [super setupView];
    [self.contentView addSubview:self.detailLabel];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.titleLabel sizeToFit];
    [self.detailLabel sizeToFit];

    CGFloat xOffset = CGRectGetMaxX(self.titleLabel.frame) + RCUProfileTextCellDetailLeadingSpace;
    CGFloat yOffset = (CGRectGetHeight(self.contentView.frame)-CGRectGetHeight(self.detailLabel.frame))/2;

    CGFloat width = CGRectGetMinX(self.arrowView.frame) - RCUProfileTextCellDetailTrailingSpace - xOffset;
    self.detailLabel.frame = CGRectMake(xOffset, yOffset, width, CGRectGetHeight(self.detailLabel.frame));
}

#pragma mark - getter

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        _detailLabel.font = [UIFont systemFontOfSize:RCUProfileTextCellDetailFont];
        _detailLabel.textAlignment = NSTextAlignmentRight;
    }
    return _detailLabel;
}
@end
